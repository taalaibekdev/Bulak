import '../../core/utils/youtube_link.dart';

/// Одно видео в библиотеке ребёнка.
///
/// Храним минимум: идентификатор YouTube, понятное название, автора,
/// длительность, привязку к коллекции и — если родитель скачал видео —
/// имя локального файла. Превью не сохраняем: оно подгружается по адресу
/// `i.ytimg.com` и кэшируется на устройстве.
class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.addedAt,
    this.author,
    this.durationSeconds,
    this.collectionId,
    this.favorite = false,
    this.watchedSeconds = 0,
    this.lastWatchedAt,
    this.localFileName,
    this.downloadedAt,
    this.fileSizeBytes,
    this.downloadQuality,
  });

  /// Идентификатор видео на YouTube (11 символов).
  final String id;

  /// Название, которое видит ребёнок. Родитель может его переписать.
  final String title;

  /// Автор (канал). Необязательно: если метаданные не загрузились.
  final String? author;

  /// Длительность в секундах. `null`, если неизвестна.
  final int? durationSeconds;

  /// Коллекция, в которую родитель положил видео.
  final String? collectionId;

  /// Добавлено в избранное (ребёнок или родитель).
  final bool favorite;

  /// Когда видео добавили в библиотеку.
  final DateTime addedAt;

  /// Сколько секунд уже просмотрено — для полоски «продолжить просмотр».
  final int watchedSeconds;

  /// Когда видео смотрели в последний раз.
  final DateTime? lastWatchedAt;

  /// Имя скачанного файла в каталоге загрузок приложения.
  ///
  /// Храним именно имя, а не полный путь: на iOS путь к контейнеру
  /// приложения меняется после обновления, и абсолютный путь стал бы битым.
  final String? localFileName;

  /// Когда видео скачали на устройство.
  final DateTime? downloadedAt;

  /// Размер скачанного файла в байтах.
  final int? fileSizeBytes;

  /// Качество скачанного файла, например `360p`.
  final String? downloadQuality;

  Duration? get duration =>
      durationSeconds == null ? null : Duration(seconds: durationSeconds!);

  /// Доля просмотра от 0 до 1. Если длительность неизвестна — 0.
  double get progress {
    final total = durationSeconds;
    if (total == null || total <= 0) return 0;
    return (watchedSeconds / total).clamp(0.0, 1.0);
  }

  /// Считается ли видео «досмотренным» (больше 92 %).
  bool get isFinished => progress >= 0.92;

  /// Есть ли что продолжать: начато, но не закончено.
  bool get isInProgress => watchedSeconds > 15 && !isFinished;

  /// Видео лежит на устройстве и может играть без интернета.
  bool get isDownloaded => localFileName != null && localFileName!.isNotEmpty;

  /// Ссылка на превью в максимальном качестве.
  String get thumbnailUrl => YouTubeLink.maxThumbnail(id);

  /// Запасные варианты превью — от лучшего к гарантированному.
  List<String> get thumbnailCandidates => YouTubeLink.thumbnailCandidates(id);

  VideoItem copyWith({
    String? title,
    String? author,
    int? durationSeconds,
    Object? collectionId = _sentinel,
    bool? favorite,
    int? watchedSeconds,
    Object? lastWatchedAt = _sentinel,
    Object? localFileName = _sentinel,
    Object? downloadedAt = _sentinel,
    Object? fileSizeBytes = _sentinel,
    Object? downloadQuality = _sentinel,
  }) {
    return VideoItem(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      collectionId: collectionId == _sentinel
          ? this.collectionId
          : collectionId as String?,
      favorite: favorite ?? this.favorite,
      addedAt: addedAt,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      lastWatchedAt: lastWatchedAt == _sentinel
          ? this.lastWatchedAt
          : lastWatchedAt as DateTime?,
      localFileName: localFileName == _sentinel
          ? this.localFileName
          : localFileName as String?,
      downloadedAt: downloadedAt == _sentinel
          ? this.downloadedAt
          : downloadedAt as DateTime?,
      fileSizeBytes: fileSizeBytes == _sentinel
          ? this.fileSizeBytes
          : fileSizeBytes as int?,
      downloadQuality: downloadQuality == _sentinel
          ? this.downloadQuality
          : downloadQuality as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (author != null) 'author': author,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (collectionId != null) 'collectionId': collectionId,
    'favorite': favorite,
    'addedAt': addedAt.toIso8601String(),
    'watchedSeconds': watchedSeconds,
    if (lastWatchedAt != null)
      'lastWatchedAt': lastWatchedAt!.toIso8601String(),
    if (localFileName != null) 'localFileName': localFileName,
    if (downloadedAt != null) 'downloadedAt': downloadedAt!.toIso8601String(),
    if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
    if (downloadQuality != null) 'downloadQuality': downloadQuality,
  };

  static VideoItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    if (id is! String || id.isEmpty) return null;
    return VideoItem(
      id: id,
      title: title is String && title.trim().isNotEmpty ? title : id,
      author: raw['author'] is String ? raw['author'] as String : null,
      durationSeconds: raw['durationSeconds'] is num
          ? (raw['durationSeconds'] as num).toInt()
          : null,
      collectionId: raw['collectionId'] is String
          ? raw['collectionId'] as String
          : null,
      favorite: raw['favorite'] == true,
      addedAt: _parseDate(raw['addedAt']) ?? DateTime.now(),
      watchedSeconds: raw['watchedSeconds'] is num
          ? (raw['watchedSeconds'] as num).toInt()
          : 0,
      lastWatchedAt: _parseDate(raw['lastWatchedAt']),
      localFileName: raw['localFileName'] is String
          ? raw['localFileName'] as String
          : null,
      downloadedAt: _parseDate(raw['downloadedAt']),
      fileSizeBytes: raw['fileSizeBytes'] is num
          ? (raw['fileSizeBytes'] as num).toInt()
          : null,
      downloadQuality: raw['downloadQuality'] is String
          ? raw['downloadQuality'] as String
          : null,
    );
  }

  static const Object _sentinel = Object();

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  @override
  bool operator ==(Object other) =>
      other is VideoItem &&
      other.id == id &&
      other.title == title &&
      other.author == author &&
      other.durationSeconds == durationSeconds &&
      other.collectionId == collectionId &&
      other.favorite == favorite &&
      other.watchedSeconds == watchedSeconds &&
      other.localFileName == localFileName;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    durationSeconds,
    collectionId,
    favorite,
    watchedSeconds,
    localFileName,
  );
}
