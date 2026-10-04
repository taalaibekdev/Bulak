import 'dart:convert';

import '../../core/app_config.dart';
import '../../core/utils/youtube_link.dart';
import '../models/video_item.dart';

/// Одно видео внутри файла обмена.
class TransferVideo {
  const TransferVideo({
    required this.id,
    this.title,
    this.author,
    this.durationSeconds,
  });

  final String id;
  final String? title;
  final String? author;
  final int? durationSeconds;

  Map<String, dynamic> toJson() => {
    'id': id,
    if (title != null && title!.isNotEmpty) 'title': title,
    if (author != null && author!.isNotEmpty) 'author': author,
    if (durationSeconds != null) 'duration': durationSeconds,
  };

  static TransferVideo? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = YouTubeLink.extractVideoId(raw['id']?.toString() ?? '');
    if (id == null) return null;
    return TransferVideo(
      id: id,
      title: raw['title'] is String ? raw['title'] as String : null,
      author: raw['author'] is String ? raw['author'] as String : null,
      durationSeconds: raw['duration'] is num
          ? (raw['duration'] as num).toInt()
          : null,
    );
  }
}

/// Разобранная подборка, полученная от другого человека.
class TransferPayload {
  const TransferPayload({
    required this.videos,
    this.title,
    this.note,
    this.fromFile = false,
  });

  final List<TransferVideo> videos;

  /// Название подборки — предлагается как имя новой коллекции.
  final String? title;

  /// Пара слов от того, кто поделился.
  final String? note;

  /// Данные пришли структурированным файлом, а не списком ссылок.
  final bool fromFile;

  bool get isEmpty => videos.isEmpty;
}

/// Обмен подборками: выгрузка списка ссылок и разбор чужого списка.
///
/// Формат намеренно простой и человекочитаемый: с одной стороны — JSON
/// с названиями и длительностями, с другой — обычный список ссылок, который
/// можно переслать в мессенджере и вставить руками.
class LibraryTransfer {
  const LibraryTransfer._();

  /// Метка формата: по ней узнаём свой файл среди чужих JSON.
  static const String formatTag = 'bulak.library';

  /// Версия формата. Читаем любую версию, пишем текущую.
  static const int formatVersion = 1;

  /// Расширение файла для «Поделиться файлом».
  static const String fileExtension = 'bulak';

  /// Собирает JSON для передачи другому человеку.
  static String encode({
    required String title,
    required List<VideoItem> videos,
    String? note,
  }) {
    final payload = <String, dynamic>{
      'format': formatTag,
      'version': formatVersion,
      'app': AppConfig.brandName,
      'title': title,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'exportedAt': DateTime.now().toIso8601String(),
      'videos': [
        for (final video in videos)
          TransferVideo(
            id: video.id,
            title: video.title,
            author: video.author,
            durationSeconds: video.durationSeconds,
          ).toJson(),
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Простой список ссылок — для мессенджеров, где JSON неудобен.
  static String toPlainLinks(Iterable<VideoItem> videos) =>
      videos.map((video) => YouTubeLink.watchUrl(video.id)).join('\n');

  /// Разбирает то, что вставил или прислал другой человек.
  ///
  /// Понимает три вида данных: наш JSON, произвольный JSON-массив видео
  /// и обычный текст со ссылками. Возвращает `null`, если ничего не нашлось.
  static TransferPayload? decode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final json = _tryDecodeJson(text);
    if (json != null) return json;

    final ids = YouTubeLink.extractMany(text);
    if (ids.isEmpty) return null;

    return TransferPayload(
      videos: [for (final id in ids) TransferVideo(id: id)],
    );
  }

  static TransferPayload? _tryDecodeJson(String text) {
    // JSON может прийти внутри текста письма или подписи к файлу, поэтому
    // вырезаем сбалансированный фрагмент, а не «всё до конца строки».
    for (final candidate in _jsonCandidates(text)) {
      Object? decoded;
      try {
        decoded = jsonDecode(candidate);
      } catch (_) {
        continue;
      }

      if (decoded is Map<String, dynamic>) {
        final videos = decoded['videos'];
        if (videos is! List) continue;
        final parsed = videos
            .map(TransferVideo.fromJson)
            .whereType<TransferVideo>()
            .toList();
        if (parsed.isEmpty) continue;
        return TransferPayload(
          videos: parsed,
          title: decoded['title'] is String
              ? (decoded['title'] as String).trim()
              : null,
          note: decoded['note'] is String ? decoded['note'] as String : null,
          fromFile: decoded['format'] == formatTag,
        );
      }

      if (decoded is List) {
        final parsed = decoded
            .map(TransferVideo.fromJson)
            .whereType<TransferVideo>()
            .toList();
        if (parsed.isEmpty) continue;
        return TransferPayload(videos: parsed, fromFile: true);
      }
    }

    return null;
  }

  /// Вырезает из текста все сбалансированные фрагменты `{…}` и `[…]`.
  static List<String> _jsonCandidates(String text) {
    final candidates = <String>[];
    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      if (char != '{' && char != '[') continue;

      final open = char;
      final close = char == '{' ? '}' : ']';
      var depth = 0;
      var inString = false;
      var escaped = false;

      for (var cursor = index; cursor < text.length; cursor++) {
        final current = text[cursor];
        if (inString) {
          if (escaped) {
            escaped = false;
          } else if (current == r'\') {
            escaped = true;
          } else if (current == '"') {
            inString = false;
          }
          continue;
        }
        if (current == '"') {
          inString = true;
          continue;
        }
        if (current == open) depth++;
        if (current == close) {
          depth--;
          if (depth == 0) {
            candidates.add(text.substring(index, cursor + 1));
            break;
          }
        }
      }
    }
    return candidates;
  }
}
