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

/// Работа с YouTube: метаданные для карточек и прямой поток для плеера.
///
/// Библиотека `youtube_explode_dart` — единственный внешний «движок»,
/// поэтому все обращения к ней собраны здесь, а остальное приложение
/// работает с простыми типами.
class YouTubeService implements VideoMetadataSource {
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
    try {
      final manifest = await _client.videos.streamsClient
          .getManifest(videoId)
          .timeout(_timeout);
      final muxed = manifest.muxed;
      if (muxed.isEmpty) return null;
      return muxed.withHighestBitrate().url;
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
