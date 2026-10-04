/// Коллекция (папка) с видео: «Мультики», «Учёба», «Музыка».
///
/// Коллекции создаёт родитель, ребёнок просто выбирает яркую плитку.
class VideoCollection {
  const VideoCollection({
    required this.id,
    required this.title,
    required this.createdAt,
    this.emoji = '🎬',
    this.colorIndex = 0,
    this.sortOrder = 0,
  });

  /// Внутренний идентификатор (генерируется приложением, не связан с YouTube).
  final String id;

  /// Название, которое видит ребёнок.
  final String title;

  /// Эмодзи-значок плитки.
  final String emoji;

  /// Индекс градиента в `AppColors.collectionGradients`.
  final int colorIndex;

  /// Порядок плиток на экране коллекций.
  final int sortOrder;

  final DateTime createdAt;

  VideoCollection copyWith({
    String? title,
    String? emoji,
    int? colorIndex,
    int? sortOrder,
  }) {
    return VideoCollection(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      colorIndex: colorIndex ?? this.colorIndex,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'colorIndex': colorIndex,
    'sortOrder': sortOrder,
    'createdAt': createdAt.toIso8601String(),
  };

  static VideoCollection? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    if (id is! String || id.isEmpty) return null;
    return VideoCollection(
      id: id,
      title: title is String && title.trim().isNotEmpty ? title : 'Коллекция',
      emoji: raw['emoji'] is String && (raw['emoji'] as String).isNotEmpty
          ? raw['emoji'] as String
          : '🎬',
      colorIndex: raw['colorIndex'] is num
          ? (raw['colorIndex'] as num).toInt()
          : 0,
      sortOrder: raw['sortOrder'] is num
          ? (raw['sortOrder'] as num).toInt()
          : 0,
      createdAt:
          DateTime.tryParse(raw['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VideoCollection &&
      other.id == id &&
      other.title == title &&
      other.emoji == emoji &&
      other.colorIndex == colorIndex &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(id, title, emoji, colorIndex, sortOrder);
}
