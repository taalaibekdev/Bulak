import 'dart:io';

import 'package:bulak/data/repositories/library_repository.dart';
import 'package:bulak/data/services/download_service.dart';
import 'package:bulak/data/services/youtube_service.dart';
import 'package:bulak/data/storage/key_value_store.dart';
import 'package:bulak/state/download_controller.dart';
import 'package:bulak/state/library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Источник, который отдаёт файл заданного размера и умеет «подвисать»,
/// чтобы можно было проверить отмену и очередь.
class _FakeSource implements VideoDownloadSource {
  _FakeSource({this.delay = Duration.zero, this.chunks = 2});

  /// Размер «файла» — одинаковый во всех проверках этого файла.
  static const int sizeBytes = 512;

  final Duration delay;
  final int chunks;
  int calls = 0;

  @override
  Future<DownloadInfo?> fetchDownloadInfo(String videoId) async => DownloadInfo(
    sizeBytes: sizeBytes,
    extension: 'mp4',
    quality: '360p',
    isThrottled: false,
  );

  @override
  Future<bool> downloadToFile(
    String videoId,
    File target, {
    required void Function(int received, int total) onProgress,
    bool Function()? isCancelled,
  }) async {
    calls++;
    final sink = target.openWrite();
    final chunk = List<int>.filled((sizeBytes / chunks).ceil(), 3);
    var written = 0;

    for (var index = 0; index < chunks; index++) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (isCancelled?.call() ?? false) {
        await sink.close();
        return false;
      }
      sink.add(chunk);
      written += chunk.length;
      onProgress(written, sizeBytes);
    }
    await sink.close();
    return true;
  }
}

class _NeverSource implements VideoMetadataSource {
  @override
  Future<VideoMetadata?> fetchMetadata(String videoId) async => null;
}

void main() {
  late Directory tempDir;
  late InMemoryStore store;
  late LibraryController library;
  late DownloadService service;
  late _FakeSource source;
  late DownloadController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bulak-queue-test');
    store = InMemoryStore();
    source = _FakeSource();
    service = DownloadService(
      source: source,
      directoryProvider: () async => tempDir,
    );
    library = LibraryController(
      repository: LibraryRepository(store),
      youtube: _NeverSource(),
    );
    await library.load();
    controller = DownloadController(service: service, library: library);
  });

  tearDown(() async {
    controller.dispose();
    library.dispose();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> addVideos(List<String> ids) async {
    await library.addVideos([
      for (final id in ids) VideoDraft(id: id, title: 'Видео $id'),
    ]);
  }

  /// Ждёт, пока очередь опустеет.
  Future<void> waitForQueue() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (!controller.hasActiveDownloads) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  /// Ждёт наступления условия — так тесты не зависят от скорости машины.
  Future<void> waitUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    fail('Условие не наступило за $timeout');
  }

  test('скачивание отмечает видео в библиотеке', () async {
    await addVideos(['aaaaaaaaaaa']);
    controller.enqueue(library.byId('aaaaaaaaaaa')!);
    await waitForQueue();

    final video = library.byId('aaaaaaaaaaa')!;
    expect(video.isDownloaded, isTrue);
    expect(video.localFileName, 'aaaaaaaaaaa.mp4');
    expect(video.fileSizeBytes, 512);
    expect(video.downloadQuality, '360p');
    expect(controller.taskFor('aaaaaaaaaaa')?.state, DownloadState.done);
  });

  test('уже скачанное видео не ставится в очередь повторно', () async {
    await addVideos(['aaaaaaaaaaa']);
    final video = library.byId('aaaaaaaaaaa')!;

    controller.enqueue(video);
    await waitForQueue();
    final callsAfterFirst = source.calls;

    controller.enqueue(library.byId('aaaaaaaaaaa')!);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(source.calls, callsAfterFirst);
  });

  test('отмена оставляет библиотеку без отметки', () async {
    source = _FakeSource(delay: const Duration(milliseconds: 30), chunks: 6);
    service = DownloadService(
      source: source,
      directoryProvider: () async => tempDir,
    );
    controller.dispose();
    controller = DownloadController(service: service, library: library);

    await addVideos(['aaaaaaaaaaa']);
    controller.enqueue(library.byId('aaaaaaaaaaa')!);
    controller.cancel('aaaaaaaaaaa');

    await waitUntil(
      () => controller.taskFor('aaaaaaaaaaa')?.state == DownloadState.cancelled,
    );
    // Даём фоновой задаче возможность закончиться, если она ещё работает.
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(library.byId('aaaaaaaaaaa')!.isDownloaded, isFalse);
    expect(controller.taskFor('aaaaaaaaaaa')?.state, DownloadState.cancelled);
    expect(await service.usedBytes(), 0);
  });

  test('удаление загрузки снимает отметку и убирает файл', () async {
    await addVideos(['aaaaaaaaaaa']);
    controller.enqueue(library.byId('aaaaaaaaaaa')!);
    await waitForQueue();

    await controller.removeDownload(library.byId('aaaaaaaaaaa')!);

    expect(library.byId('aaaaaaaaaaa')!.isDownloaded, isFalse);
    expect(await service.usedBytes(), 0);
  });

  test('удаление всех загрузок очищает и файлы, и отметки', () async {
    await addVideos(['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    controller.enqueueAll(library.videos);
    await waitForQueue();
    expect(controller.downloadedCount, 2);

    await controller.removeAllDownloads();

    expect(controller.downloadedCount, 0);
    expect(await service.usedBytes(), 0);
  });

  test('reconcileWithDisk снимает отметки о пропавших файлах', () async {
    await addVideos(['aaaaaaaaaaa']);
    controller.enqueue(library.byId('aaaaaaaaaaa')!);
    await waitForQueue();
    expect(library.byId('aaaaaaaaaaa')!.isDownloaded, isTrue);

    // Имитируем ручную очистку каталога загрузок.
    await service.deleteAll();
    await controller.reconcileWithDisk();

    expect(library.byId('aaaaaaaaaaa')!.isDownloaded, isFalse);
  });

  test('refreshStorage считает занятое место', () async {
    await addVideos(['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    controller.enqueueAll(library.videos);
    await waitForQueue();
    await controller.refreshStorage();

    expect(controller.storageBytes, 1024);
  });

  test('прогресс показывается во время загрузки', () async {
    source = _FakeSource(delay: const Duration(milliseconds: 40), chunks: 6);
    service = DownloadService(
      source: source,
      directoryProvider: () async => tempDir,
    );
    controller.dispose();
    controller = DownloadController(service: service, library: library);

    await addVideos(['aaaaaaaaaaa']);
    controller.enqueue(library.byId('aaaaaaaaaaa')!);

    // Ждём, пока придёт хотя бы один кусок: состояние уже running,
    // а прогресс ещё нулевой.
    await waitUntil(
      () => (controller.taskFor('aaaaaaaaaaa')?.received ?? 0) > 0,
    );

    final task = controller.taskFor('aaaaaaaaaaa');
    expect(task, isNotNull);
    expect(task!.state, DownloadState.running);
    expect(task.progress, isNotNull);
    expect(task.progress, greaterThan(0));

    await waitForQueue();
    expect(controller.taskFor('aaaaaaaaaaa')!.state, DownloadState.done);
  });
}
