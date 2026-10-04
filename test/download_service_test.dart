import 'dart:io';

import 'package:bulak/data/models/video_item.dart';
import 'package:bulak/data/services/download_service.dart';
import 'package:bulak/data/services/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Заглушка вместо YouTube: отдаёт заранее заданные байты.
class _FakeSource implements VideoDownloadSource {
  _FakeSource({
    this.sizeBytes = 1024,
    this.extension = 'mp4',
    this.failInfo = false,
    this.failDownload = false,
    this.chunks = 4,
    this.onChunk,
  });

  final int sizeBytes;
  final String extension;
  final bool failInfo;
  final bool failDownload;
  final int chunks;

  /// Позволяет вмешаться в процесс: например, отменить загрузку на середине.
  final void Function(int index)? onChunk;

  int downloadCalls = 0;

  @override
  Future<DownloadInfo?> fetchDownloadInfo(String videoId) async {
    if (failInfo) return null;
    return DownloadInfo(
      sizeBytes: sizeBytes,
      extension: extension,
      quality: '360p',
      isThrottled: false,
    );
  }

  @override
  Future<bool> downloadToFile(
    String videoId,
    File target, {
    required void Function(int received, int total) onProgress,
    bool Function()? isCancelled,
  }) async {
    downloadCalls++;
    if (failDownload) return false;

    final sink = target.openWrite();
    final chunkSize = (sizeBytes / chunks).ceil();
    var written = 0;

    for (var index = 0; index < chunks; index++) {
      onChunk?.call(index);
      if (isCancelled?.call() ?? false) {
        await sink.close();
        return false;
      }
      final chunk = List<int>.filled(chunkSize, 7);
      sink.add(chunk);
      written += chunk.length;
      onProgress(written, sizeBytes);
    }

    await sink.close();
    return true;
  }
}

VideoItem _video(String id) =>
    VideoItem(id: id, title: 'Видео $id', addedAt: DateTime(2026, 1, 1));

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bulak-download-test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  DownloadService serviceWith(VideoDownloadSource source) =>
      DownloadService(source: source, directoryProvider: () async => tempDir);

  group('DownloadService', () {
    test('скачивает файл и возвращает его размер', () async {
      final service = serviceWith(_FakeSource(sizeBytes: 2048));
      final result = await service.download(
        _video('aaaaaaaaaaa'),
        onProgress: (_, _) {},
      );

      expect(result.success, isTrue);
      expect(result.fileName, 'aaaaaaaaaaa.mp4');
      expect(result.sizeBytes, 2048);
      expect(result.quality, '360p');

      final file = await service.fileForName(result.fileName!);
      expect(await file.exists(), isTrue);
      expect(await file.length(), 2048);
    });

    test('файлы лежат в подкаталоге media', () async {
      final service = serviceWith(_FakeSource());
      await service.download(_video('aaaaaaaaaaa'), onProgress: (_, _) {});

      final directory = await service.mediaDirectory();
      expect(directory.path, contains(DownloadService.folderName));
      expect(await directory.list().length, 1);
    });

    test('отмена удаляет недописанный файл', () async {
      var cancelled = false;
      final source = _FakeSource(
        chunks: 10,
        onChunk: (index) {
          if (index == 3) cancelled = true;
        },
      );
      final service = serviceWith(source);

      final result = await service.download(
        _video('aaaaaaaaaaa'),
        onProgress: (_, _) {},
        isCancelled: () => cancelled,
      );

      expect(result.success, isFalse);
      expect(result.cancelled, isTrue);
      final directory = await service.mediaDirectory();
      expect(await directory.list().isEmpty, isTrue);
    });

    test('ошибка скачивания не оставляет файл', () async {
      final service = serviceWith(_FakeSource(failDownload: true));
      final result = await service.download(
        _video('aaaaaaaaaaa'),
        onProgress: (_, _) {},
      );

      expect(result.success, isFalse);
      final directory = await service.mediaDirectory();
      expect(await directory.list().isEmpty, isTrue);
    });

    test('без сведений о потоке скачивание не начинается', () async {
      final source = _FakeSource(failInfo: true);
      final service = serviceWith(source);

      final result = await service.download(
        _video('aaaaaaaaaaa'),
        onProgress: (_, _) {},
      );

      expect(result.success, isFalse);
      expect(source.downloadCalls, 0);
    });

    test('подозрительный идентификатор не превращается в путь', () async {
      final source = _FakeSource();
      final service = serviceWith(source);

      final result = await service.download(
        _video('../../etc/passwd'),
        onProgress: (_, _) {},
      );

      expect(result.success, isFalse);
      expect(source.downloadCalls, 0);
    });

    test('неизвестное расширение заменяется на mp4', () async {
      final service = serviceWith(_FakeSource(extension: 'exe'));
      final result = await service.download(
        _video('aaaaaaaaaaa'),
        onProgress: (_, _) {},
      );

      expect(result.fileName, 'aaaaaaaaaaa.mp4');
    });

    test('прогресс растёт до размера файла', () async {
      final service = serviceWith(_FakeSource(sizeBytes: 4000, chunks: 4));
      final seen = <int>[];

      await service.download(
        _video('aaaaaaaaaaa'),
        onProgress: (received, _) => seen.add(received),
      );

      expect(seen, isNotEmpty);
      expect(seen.last, greaterThanOrEqualTo(4000));
      expect(seen, orderedEquals(List<int>.from(seen)..sort()));
    });

    test('повторное скачивание заменяет файл другого формата', () async {
      final service = serviceWith(_FakeSource(extension: 'mp4'));
      final first = await service.download(
        _video('aaaaaaaaaaa'),
        onProgress: (_, _) {},
      );
      expect(first.fileName, 'aaaaaaaaaaa.mp4');

      final webmService = serviceWith(_FakeSource(extension: 'webm'));
      final second = await webmService.download(
        _video('aaaaaaaaaaa'),
        onProgress: (_, _) {},
      );
      expect(second.fileName, 'aaaaaaaaaaa.webm');

      final directory = await webmService.mediaDirectory();
      final names = await directory
          .list()
          .map((entity) => entity.path.split(Platform.pathSeparator).last)
          .toList();
      expect(names, ['aaaaaaaaaaa.webm']);
    });

    test('localFileFor возвращает null, если файла нет', () async {
      final service = serviceWith(_FakeSource());
      final video = _video('aaaaaaaaaaa')
          .copyWith(localFileName: 'aaaaaaaaaaa.mp4');

      expect(await service.localFileFor(video), isNull);

      await service.download(video, onProgress: (_, _) {});
      expect(await service.localFileFor(video), isNotNull);
    });

    test('без отметки о загрузке localFileFor ничего не ищет', () async {
      final service = serviceWith(_FakeSource());
      expect(await service.localFileFor(_video('aaaaaaaaaaa')), isNull);
    });

    test('usedBytes и deleteAll считают и очищают место', () async {
      final service = serviceWith(_FakeSource(sizeBytes: 1000));
      await service.download(_video('aaaaaaaaaaa'), onProgress: (_, _) {});
      await service.download(_video('bbbbbbbbbbb'), onProgress: (_, _) {});

      expect(await service.usedBytes(), 2000);
      expect(await service.deleteAll(), 2000);
      expect(await service.usedBytes(), 0);
    });

    test('existingFileNames перечисляет файлы', () async {
      final service = serviceWith(_FakeSource());
      await service.download(_video('aaaaaaaaaaa'), onProgress: (_, _) {});

      expect(await service.existingFileNames(), {'aaaaaaaaaaa.mp4'});
    });

    test('delete не падает, если файла нет', () async {
      final service = serviceWith(_FakeSource());
      await service.delete('missing.mp4');
      await service.delete(null);
    });
  });

  group('DownloadInfo.humanSize', () {
    test('переводит байты в понятные единицы', () {
      expect(
        const DownloadInfo(
          sizeBytes: 0,
          extension: 'mp4',
          quality: '360p',
          isThrottled: false,
        ).humanSize,
        '',
      );
      expect(
        const DownloadInfo(
          sizeBytes: 2 * 1024 * 1024,
          extension: 'mp4',
          quality: '360p',
          isThrottled: false,
        ).humanSize,
        '2.0 МБ',
      );
    });
  });
}
