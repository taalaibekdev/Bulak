/// Разбор ссылок YouTube и построение вспомогательных адресов.
///
/// Родитель копирует ссылку откуда угодно — из приложения YouTube, из
/// браузера, из мессенджера — поэтому разбор должен быть терпеливым:
/// принимаем и полные адреса, и короткие `youtu.be`, и просто идентификатор.
/// При этом ссылки на посторонние сайты разбирать нельзя: «watch?v=…»
/// встречается и вне YouTube.
class YouTubeLink {
  const YouTubeLink._();

  /// Идентификатор видео YouTube: ровно 11 символов.
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Полноценные ссылки внутри произвольного текста.
  static final RegExp _urlPattern = RegExp(r'https?://[^\s]+|www\.[^\s]+');

  /// Признак того, что текст похож на адрес сайта.
  static final RegExp _domainPattern = RegExp(r'[A-Za-z0-9-]+\.[A-Za-z]{2,}');

  /// Пути, после которых идёт идентификатор видео.
  static final List<RegExp> _pathPatterns = [
    RegExp(r'/watch/([A-Za-z0-9_-]{11})'),
    RegExp(r'/embed/([A-Za-z0-9_-]{11})'),
    RegExp(r'/shorts/([A-Za-z0-9_-]{11})'),
    RegExp(r'/live/([A-Za-z0-9_-]{11})'),
    RegExp(r'/v/([A-Za-z0-9_-]{11})'),
  ];

  static final RegExp _queryPattern = RegExp(r'[?&]v=([A-Za-z0-9_-]{11})');
  static final RegExp _barePattern = RegExp(
    r'(?:^|[\s=(])([A-Za-z0-9_-]{11})(?:$|[\s)&#?])',
  );
  static final RegExp _anyIdPattern = RegExp(r'[A-Za-z0-9_-]{11}');

  /// Возвращает идентификатор видео или `null`, если ссылку не понять.
  static String? extractVideoId(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    // 1. Родитель вставил просто идентификатор.
    if (_idPattern.hasMatch(text)) return text;

    // 2. Ищем полноценные ссылки внутри текста: «Смотри тут https://…».
    for (final match in _urlPattern.allMatches(text)) {
      final id = _fromUrl(match.group(0)!);
      if (id != null) return id;
    }

    // 3. Ссылка без схемы: «youtube.com/watch?v=…».
    final direct = _fromUrl(text);
    if (direct != null) return direct;

    // 4. Если в тексте всё-таки есть домен, значит это чужая ссылка —
    //    дальше искать наугад нельзя.
    if (_domainPattern.hasMatch(text)) return null;

    // 5. Хвостовые случаи: «v=ID», «ID?t=30», идентификатор в скобках.
    final queryMatch = _queryPattern.firstMatch(text);
    if (queryMatch != null) return queryMatch.group(1);

    final bare = _barePattern.firstMatch(text);
    if (bare != null) return bare.group(1);

    // 6. Последняя попытка: единственная подходящая последовательность.
    final all = _anyIdPattern.allMatches(text).toList();
    if (all.length == 1) return all.first.group(0);

    return null;
  }

  /// Проверяет, что строку можно превратить в ссылку на видео.
  static bool isValid(String raw) => extractVideoId(raw) != null;

  /// Достаёт идентификаторы из многострочного текста.
  ///
  /// Родитель может вставить сразу несколько ссылок — по одной в строке.
  /// Порядок сохраняется, повторы убираются.
  static List<String> extractMany(String raw) {
    final ids = <String>[];
    for (final line in raw.split(RegExp(r'[\r\n]+'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final id = extractVideoId(trimmed);
      if (id != null && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  /// Ссылка на превью в максимальном доступном качестве.
  static String maxThumbnail(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';

  /// Превью, которое есть практически у любого видео (16:9, 320×180).
  static String safeThumbnail(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

  /// Среднее превью (480×360, всегда доступно).
  static String mediumThumbnail(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  /// Порядок запасных вариантов превью: сначала красивое, потом гарантированное.
  static List<String> thumbnailCandidates(String videoId) => [
    maxThumbnail(videoId),
    safeThumbnail(videoId),
    mediumThumbnail(videoId),
  ];

  /// Обычная ссылка на видео — её открывают во внешнем приложении.
  static String watchUrl(String videoId) =>
      'https://www.youtube.com/watch?v=$videoId';

  /// Адрес для встроенного плеера.
  ///
  /// `rel=0` убирает блок похожих видео с чужих каналов,
  /// `modestbranding=1` — минимум брендинга YouTube,
  /// `playsinline=1` — не разворачивать на весь экран средствами iOS,
  /// `iv_load_policy=3` — без аннотаций поверх видео.
  static String embedUrl(
    String videoId, {
    bool autoplay = true,
    bool privacyEnhanced = true,
  }) {
    final host = privacyEnhanced
        ? 'https://www.youtube-nocookie.com'
        : 'https://www.youtube.com';
    final params = <String, String>{
      'rel': '0',
      'modestbranding': '1',
      'playsinline': '1',
      'iv_load_policy': '3',
      'fs': '1',
      if (autoplay) 'autoplay': '1',
    };
    return Uri.parse('$host/embed/$videoId')
        .replace(queryParameters: params)
        .toString();
  }

  /// Достаёт идентификатор из адреса. Возвращает `null`, если это не YouTube.
  static String? _fromUrl(String candidate) {
    final uri = Uri.tryParse(_withScheme(candidate));
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (host.isEmpty) return null;

    if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
      if (uri.pathSegments.isEmpty) return null;
      final segment = uri.pathSegments.first;
      return _idPattern.hasMatch(segment) ? segment : null;
    }

    if (!_isYouTubeHost(host)) return null;

    final queryMatch = _queryPattern.firstMatch('?${uri.query}');
    if (queryMatch != null) return queryMatch.group(1);

    for (final pattern in _pathPatterns) {
      final match = pattern.firstMatch(uri.path);
      if (match != null) return match.group(1);
    }

    return null;
  }

  /// Домены, которые действительно относятся к YouTube.
  static bool _isYouTubeHost(String host) {
    const hosts = ['youtube.com', 'youtube-nocookie.com', 'googlevideo.com'];
    for (final allowed in hosts) {
      if (host == allowed || host.endsWith('.$allowed')) return true;
    }
    return false;
  }

  /// Дополняет строку схемой, если её забыли.
  static String _withScheme(String text) {
    if (text.startsWith('//')) return 'https:$text';
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(text)) return text;
    return 'https://$text';
  }

  /// Оставляет от ссылки понятную человеку подпись.
  static String prettify(String raw) {
    final id = extractVideoId(raw);
    if (id == null) return raw.trim();
    return 'youtube.com/watch?v=$id';
  }
}
