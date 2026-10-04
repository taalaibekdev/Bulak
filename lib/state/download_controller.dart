import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/video_item.dart';
import '../data/services/download_service.dart';
import 'library_controller.dart';

/// Состояние одной загрузки.
enum DownloadState { queued, running, done, failed, cancelled }

/// Что происходит с конкретным видео.
class DownloadTask {
  const DownloadTask({
    required this.videoId,
    this.state = DownloadState.queued,
    this.received = 0,
    this.total = 0,
  });

  final String videoId;
  final DownloadState state;
  final int received;
  final int total;

  /// Доля загрузки от 0 до 1, если размер известен.
  double? get progress {
    if (total <= 0) return null;
    return (received / total).clamp(0.0, 1.0);
  }

  bool get isActive =>
      state == DownloadState.queued || state == DownloadState.running;

  DownloadTask copyWith({DownloadState? state, int? received, int? total}) =>
      DownloadTask(
        videoId: videoId,
        state: state ?? this.state,
        received: received ?? this.received,
        total: total ?? this.total,
      );
}

/// Очередь загрузок видео на устройство.
///
/// Загрузки идут по одной: так сеть не «забивается», а родитель видит
/// понятный прогресс вместо десятка одновременных полосок.
class DownloadController extends ChangeNotifier {
  DownloadController({
    required DownloadService service,
    required LibraryController library,
  }) : _service = service,
       _library = library;

  final DownloadService _service;
  final LibraryController _library;

  final Map<String, DownloadTask> _tasks = {};
  final List<String> _queue = [];

  bool _working = false;
  bool _disposed = false;

  /// Сколько байт записано на диск. Обновляется по запросу [refreshStorage].
  int _storageBytes = 0;
  int get storageBytes => _storageBytes;

  int get downloadedCount => _library.downloaded.length;

  bool get hasActiveDownloads => _tasks.values.any((task) => task.isActive);

  int get activeCount => _tasks.values.where((task) => task.isActive).length;

  DownloadTask? taskFor(String videoId) => _tasks[videoId];

  /// Обновляет сведения о занятом месте.
  Future<void> refreshStorage() async {
    _storageBytes = await _service.usedBytes();
    _notify();
  }

  /// Ставит видео в очередь на скачивание.
  void enqueue(VideoItem video) {
    if (video.isDownloaded) return;
    final existing = _tasks[video.id];
    if (existing != null && existing.isActive) return;

    _tasks[video.id] = DownloadTask(videoId: video.id);
    if (!_queue.contains(video.id)) _queue.add(video.id);
    _notify();
    unawaited(_pump());
  }

  /// Ставит в очередь несколько видео.
  void enqueueAll(Iterable<VideoItem> videos) {
    for (final video in videos) {
      enqueue(video);
    }
  }

  /// Отменяет загрузку. Уже записанный кусок файла будет удалён.
  void cancel(String videoId) {
    final task = _tasks[videoId];
    if (task == null || !task.isActive) return;
    _queue.remove(videoId);
    _tasks[videoId] = task.copyWith(state: DownloadState.cancelled);
    _notify();
  }

  /// Отменяет все загрузки в очереди.
  void cancelAll() {
    for (final videoId in _tasks.keys.toList()) {
      cancel(videoId);
    }
  }

  /// Удаляет скачанный файл и снимает отметку в библиотеке.
  Future<void> removeDownload(VideoItem video) async {
    await _service.delete(video.localFileName);
    await _library.clearDownload(video.id);
    _tasks.remove(video.id);
    await refreshStorage();
  }

  /// Удаляет все скачанные файлы.
  Future<void> removeAllDownloads() async {
    cancelAll();
    await _service.deleteAll();
    for (final video in _library.downloaded) {
      await _library.clearDownload(video.id);
    }
    _tasks.clear();
    await refreshStorage();
  }

  /// Убирает из библиотеки отметки о файлах, которых больше нет на диске.
  ///
  /// Такое бывает, если родитель очистил данные приложения или файл удалили
  /// другим способом. Без этой проверки карточка показывала бы «скачано»,
  /// а плеер не смог бы открыть файл.
  Future<void> reconcileWithDisk() async {
    final existing = await _service.existingFileNames();
    var changed = false;
    for (final video in _library.downloaded) {
      if (!existing.contains(video.localFileName)) {
        await _library.clearDownload(video.id);
        changed = true;
      }
    }
    await refreshStorage();
    if (changed) _notify();
  }

  Future<void> _pump() async {
    if (_working) return;
    _working = true;
    try {
      while (_queue.isNotEmpty) {
        final videoId = _queue.removeAt(0);
        final video = _library.byId(videoId);
        if (video == null) continue;
        if (_tasks[videoId]?.state == DownloadState.cancelled) continue;
        await _run(video);
      }
    } finally {
      _working = false;
      _notify();
      unawaited(refreshStorage());
    }
  }

  Future<void> _run(VideoItem video) async {
    _update(video.id, state: DownloadState.running);

    // Уведомляем не на каждый байт, а когда меняется процент: иначе
    // интерфейс перерисовывается сотни раз в секунду.
    var lastPercent = -1;

    final result = await _service.download(
      video,
      onProgress: (received, total) {
        final percent = total <= 0 ? 0 : (received * 100 ~/ total);
        if (percent == lastPercent) {
          _tasks[video.id] = DownloadTask(
            videoId: video.id,
            state: DownloadState.running,
            received: received,
            total: total,
          );
          return;
        }
        lastPercent = percent;
        _update(
          video.id,
          state: DownloadState.running,
          received: received,
          total: total,
        );
      },
      isCancelled: () => _tasks[video.id]?.state == DownloadState.cancelled,
    );

    if (result.success && result.fileName != null) {
      await _library.markDownloaded(
        video.id,
        fileName: result.fileName!,
        sizeBytes: result.sizeBytes,
        quality: result.quality ?? '',
      );
      _update(video.id, state: DownloadState.done);
      return;
    }

    if (result.cancelled) {
      _update(video.id, state: DownloadState.cancelled);
      return;
    }
    _update(video.id, state: DownloadState.failed);
  }

  void _update(
    String videoId, {
    DownloadState? state,
    int? received,
    int? total,
  }) {
    final current = _tasks[videoId] ?? DownloadTask(videoId: videoId);
    _tasks[videoId] = DownloadTask(
      videoId: videoId,
      state: state ?? current.state,
      received: received ?? current.received,
      total: total ?? current.total,
    );
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _queue.clear();
    super.dispose();
  }
}
