import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../core/utils/youtube_link.dart';
import '../models/playback_result.dart';

/// Сведения о видео, которые удаётся получить с YouTube.
class VideoMetadata {
  const VideoMetadata({
    required this.id,
    required this.title,
    this.author,
    this.duration,
  });

  final String id;
  final String title;
  final String? author;
  final Duration? duration;

  /// Резервное название, если сеть недоступна: вместо пустоты показываем
  /// понятную подпись, которую родитель сможет исправить.
  static String fallbackTitle(String id) => 'Видео $id';
}

/// Ошибка получения метаданных — родителю важно понимать, что именно случилось.
class MetadataException implements Exception {
  MetadataException(this.message);

  final String message;

  @override
  String toString() => 'MetadataException: $message';
}

/// Источник сведений о видео.
///
/// Выделен в отдельный интерфейс, чтобы контроллер библиотеки не зависел
/// от сети: в тестах подставляется простая заглушка.
abstract class VideoMetadataSource {
  Future<VideoMetadata?> fetchMetadata(String videoId);
}

/// Источник, из которого можно скачать видеофайл.
///
/// Тоже интерфейс: сервис загрузок тестируется без обращения к YouTube.
abstract class VideoDownloadSource {
  Future<DownloadInfo?> fetchDownloadInfo(String videoId);

  Future<bool> downloadToFile(
    String videoId,
    File target, {
    required void Function(int received, int total) onProgress,
    bool Function()? isCancelled,
  });
}

/// Сведения о потоке, который можно скачать на устройство.
class DownloadInfo {
  const DownloadInfo({
    required this.sizeBytes,
    required this.extension,
    required this.quality,
    required this.isThrottled,
  });

  /// Размер файла в байтах. `0`, если YouTube его не сообщил.
  final int sizeBytes;

  /// Расширение контейнера: `mp4`, `webm`, `3gpp`.
  final String extension;

  /// Качество, как его показывает YouTube: `360p`, `240p`.
  final String quality;

  /// Отдаёт ли YouTube поток с ограничением скорости.
  final bool isThrottled;

  /// Оценка размера в «человеческом» виде — для интерфейса родителя.
  String get humanSize {
    if (sizeBytes <= 0) return '';
    const units = ['Б', 'КБ', 'МБ', 'ГБ'];
    var size = sizeBytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final digits = size >= 100 || unit == 0 ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${units[unit]}';
  }
}

/// Работа с YouTube: метаданные для карточек и прямой поток для плеера.
///
/// Библиотека `youtube_explode_dart` — единственный внешний «движок»,
/// поэтому все обращения к ней собраны здесь, а остальное приложение
/// работает с простыми типами.
class YouTubeService implements VideoMetadataSource, VideoDownloadSource {
  YouTubeService({YoutubeExplode? client, http.Client? httpClient})
    : _client = client ?? YoutubeExplode(),
      _httpClient = httpClient ?? http.Client();

  final YoutubeExplode _client;
  final http.Client _httpClient;

  /// Насколько долго ждём ответа YouTube, прежде чем сдаться.
  static const Duration _timeout = Duration(seconds: 20);

  /// Сведения о видео: название, автор, длительность.
  ///
  /// Ошибки не пробрасываем наружу: если YouTube не ответил, родитель всё
  /// равно сможет добавить видео вручную — библиотека важнее метаданных.
  @override
  Future<VideoMetadata?> fetchMetadata(String videoId) async {
    try {
      final video = await _client.videos.get(videoId).timeout(_timeout);
      return VideoMetadata(
        id: videoId,
        title: video.title.trim().isEmpty
            ? VideoMetadata.fallbackTitle(videoId)
            : video.title.trim(),
        author: video.author.trim().isEmpty ? null : video.author.trim(),
        duration: video.duration,
      );
    } catch (_) {
      return null;
    }
  }

  /// Проверяет, что видео вообще доступно для воспроизведения.
  Future<bool> isPlayable(String videoId) async {
    try {
      final manifest = await _client.videos.streamsClient
          .getManifest(videoId)
          .timeout(_timeout);
      return manifest.muxed.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Подбирает прямой адрес видеопотока.
  ///
  /// YouTube отдаёт «склеенные» (muxed) потоки максимум в 360p — зато они
  /// играются любым системным плеером без рекламы и без интерфейса YouTube.
  /// Именно это и нужно детскому приложению.
  Future<Uri?> resolveStreamUrl(String videoId) async {
    final stream = await _pickMuxedStream(videoId);
    return stream?.url;
  }

  /// Сведения о потоке, который будет скачан: размер, формат, качество.
  @override
  Future<DownloadInfo?> fetchDownloadInfo(String videoId) async {
    final stream = await _pickMuxedStream(videoId);
    if (stream == null) return null;
    return DownloadInfo(
      sizeBytes: stream.size.totalBytes,
      extension: stream.container.name,
      quality: stream.qualityLabel,
      isThrottled: stream.isThrottled,
    );
  }

  /// Скачивает видео в файл [target], сообщая о прогрессе.
  ///
  /// Возвращает `true`, если файл записан целиком. Если родитель отменил
  /// загрузку или что-то пошло не так, недописанный файл удаляется —
  /// «полувидео» в библиотеке хуже, чем его отсутствие.
  @override
  Future<bool> downloadToFile(
    String videoId,
    File target, {
    required void Function(int received, int total) onProgress,
    bool Function()? isCancelled,
  }) async {
    final stream = await _pickMuxedStream(videoId);
    if (stream == null) return false;

    final total = stream.size.totalBytes;
    IOSink? sink;
    var completed = false;

    try {
      sink = target.openWrite();
      var received = 0;
      await for (final chunk in _client.videos.streamsClient.get(stream)) {
        if (isCancelled?.call() ?? false) break;
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await sink.flush();
      completed = received > 0 && (total <= 0 || received >= total * 0.98);
    } catch (_) {
      completed = false;
    } finally {
      try {
        await sink?.close();
      } catch (_) {
        // Сокет уже закрыт — это не повод считать загрузку удачной.
      }
    }

    if (!completed) {
      try {
        if (await target.exists()) await target.delete();
      } catch (_) {
        // Если файл не удалось удалить, следующий запуск просто перезапишет его.
      }
    }

    return completed;
  }

  /// Выбирает «склеенный» поток для скачивания и воспроизведения.
  ///
  /// Предпочитаем mp4: его понимают и ExoPlayer, и AVPlayer на iOS.
  /// WebM на iOS не проигрывается, поэтому в приоритете контейнер mp4.
  Future<MuxedStreamInfo?> _pickMuxedStream(String videoId) async {
    try {
      final manifest = await _client.videos.streamsClient
          .getManifest(videoId)
          .timeout(_timeout);
      final muxed = manifest.muxed;
      if (muxed.isEmpty) return null;

      final mp4 = muxed
          .where((stream) => stream.container.name.toLowerCase() == 'mp4')
          .toList();
      final pool = mp4.isNotEmpty ? mp4 : muxed;
      return pool.withHighestBitrate();
    } catch (_) {
      return null;
    }
  }

  /// Быстрая проверка «есть ли интернет» без загрузки видео.
  Future<bool> hasConnection() async {
    try {
      final response = await _httpClient
          .head(Uri.parse('https://i.ytimg.com/generate_204'))
          .timeout(const Duration(seconds: 6));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Освобождает сетевые ресурсы. Вызывается при закрытии приложения.
  void dispose() {
    _client.close();
    _httpClient.close();
  }

  /// Заготовка на будущее: если видео недоступно, вернуть понятную причину.
  Future<PlaybackFailureReason?> diagnose(String videoId) async {
    if (!YouTubeLink.isValid(videoId)) {
      return PlaybackFailureReason.invalidLink;
    }
    if (!await hasConnection()) {
      return PlaybackFailureReason.offline;
    }
    final url = await resolveStreamUrl(videoId);
    if (url == null) return PlaybackFailureReason.notPlayable;
    return null;
  }
}
