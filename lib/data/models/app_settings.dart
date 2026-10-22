import '../../core/app_config.dart';

/// Как оформлено приложение.
enum AppThemeChoice { system, light, dark }

/// Каким способом проигрывать видео.
///
/// * [auto] — сначала пробуем прямой поток без рекламы, при неудаче
///   автоматически переключаемся на встроенный плеер сервиса;
/// * [direct] — только прямой поток (чистая картинка, качество до 360p);
/// * [embed] — только официальный встроенный плеер сервиса.
enum PlaybackMode { auto, direct, embed }

/// Откуда брать видео для просмотра.
enum PlaybackSource {
  /// Сначала скачать на устройство, потом играть файл.
  ///
  /// Так просмотр не зависит ни от интернета, ни от того, отдаёт ли сервис
  /// поток прямо сейчас: ссылки на поток живут ограниченное время, и на
  /// длинном видео просмотр из-за этого обрывается.
  downloaded,

  /// Играть потоком, если файла нет. Быстрее начать, но менее надёжно.
  stream,
}

/// Настройки приложения. Всё хранится на устройстве.
class AppSettings {
  const AppSettings({
    this.pinHash,
    this.pinSalt,
    this.dailyLimitMinutes = 0,
    this.playbackMode = PlaybackMode.auto,
    this.themeChoice = AppThemeChoice.system,
    this.localeCode,
    this.kidLockEnabled = true,
    this.showFavorites = true,
    this.showHistory = true,
    this.onboardingCompleted = false,
    this.watchedSecondsToday = 0,
    this.dayKey = '',
    this.autoDownload = false,
    this.playbackSource = PlaybackSource.downloaded,
    this.preferLocalPlayback = true,
  });

  /// Хэш PIN-кода родителя (SHA-256 от соли и кода). Сам код не хранится.
  final String? pinHash;

  /// Случайная соль для хэша PIN-кода.
  final String? pinSalt;

  /// Дневной лимит просмотра в минутах. `0` — без ограничений.
  final int dailyLimitMinutes;

  final PlaybackMode playbackMode;
  final AppThemeChoice themeChoice;

  /// Код языка (`ru`, `en`). `null` — как в системе.
  final String? localeCode;

  /// Показывать ребёнку кнопку-замочек в плеере.
  final bool kidLockEnabled;

  /// Показывать раздел «Избранное» в нижнем меню.
  final bool showFavorites;

  /// Показывать раздел «История» в нижнем меню.
  final bool showHistory;

  /// Пройден ли первичный мастер настройки.
  final bool onboardingCompleted;

  /// Сколько секунд просмотрено сегодня.
  final int watchedSecondsToday;

  /// День, к которому относится счётчик (формат `ГГГГ-ММ-ДД`).
  final String dayKey;

  /// Скачивать видео на устройство сразу при добавлении в библиотеку.
  final bool autoDownload;

  /// Откуда брать видео: из скачанного файла или потоком.
  final PlaybackSource playbackSource;

  /// Играть скачанный файл, даже когда есть интернет.
  ///
  /// Так видео не «зависает» на середине из-за того, что сервис перестал
  /// отдавать поток: скачанный файл играется с диска. Отключать смысла мало,
  /// но пусть будет возможность сравнить качество.
  final bool preferLocalPlayback;

  /// Источник воспроизведения с учётом того, как собрано приложение.
  ///
  /// В сборке для магазинов скачивание отключено (`BULAK_DISABLE_DOWNLOADS`),
  /// поэтому там остаётся только поток — иначе приложение не смогло бы
  /// проиграть вообще ничего.
  PlaybackSource get effectivePlaybackSource =>
      AppConfig.downloadsEnabled ? playbackSource : PlaybackSource.stream;

  /// Нужно ли сначала скачать видео, прежде чем показывать его.
  bool get requiresDownloadFirst =>
      effectivePlaybackSource == PlaybackSource.downloaded;

  bool get hasPin =>
      (pinHash?.isNotEmpty ?? false) && (pinSalt?.isNotEmpty ?? false);

  bool get hasDailyLimit => dailyLimitMinutes > 0;

  /// Остаток лимита на сегодня. `null` — лимита нет.
  Duration? get remainingToday {
    if (!hasDailyLimit) return null;
    final remaining = dailyLimitMinutes * 60 - watchedSecondsToday;
    return Duration(seconds: remaining.clamp(0, dailyLimitMinutes * 60));
  }

  bool get isLimitReached {
    if (!hasDailyLimit) return false;
    return watchedSecondsToday >= dailyLimitMinutes * 60;
  }

  /// Ключ сегодняшнего дня — по нему сбрасывается счётчик.
  static String dayKeyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Настройки с обнулённым счётчиком, если наступил новый день.
  AppSettings normalized({DateTime? now}) {
    final today = dayKeyFor(now ?? DateTime.now());
    if (dayKey == today) return this;
    return copyWith(watchedSecondsToday: 0, dayKey: today);
  }

  AppSettings copyWith({
    Object? pinHash = _sentinel,
    Object? pinSalt = _sentinel,
    int? dailyLimitMinutes,
    PlaybackMode? playbackMode,
    AppThemeChoice? themeChoice,
    Object? localeCode = _sentinel,
    bool? kidLockEnabled,
    bool? showFavorites,
    bool? showHistory,
    bool? onboardingCompleted,
    int? watchedSecondsToday,
    String? dayKey,
    bool? autoDownload,
    PlaybackSource? playbackSource,
    bool? preferLocalPlayback,
  }) {
    return AppSettings(
      pinHash: pinHash == _sentinel ? this.pinHash : pinHash as String?,
      pinSalt: pinSalt == _sentinel ? this.pinSalt : pinSalt as String?,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      playbackMode: playbackMode ?? this.playbackMode,
      themeChoice: themeChoice ?? this.themeChoice,
      localeCode: localeCode == _sentinel
          ? this.localeCode
          : localeCode as String?,
      kidLockEnabled: kidLockEnabled ?? this.kidLockEnabled,
      showFavorites: showFavorites ?? this.showFavorites,
      showHistory: showHistory ?? this.showHistory,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      watchedSecondsToday: watchedSecondsToday ?? this.watchedSecondsToday,
      dayKey: dayKey ?? this.dayKey,
      playbackSource: playbackSource ?? this.playbackSource,
      autoDownload: autoDownload ?? this.autoDownload,
      preferLocalPlayback: preferLocalPlayback ?? this.preferLocalPlayback,
    );
  }

  Map<String, dynamic> toJson() => {
    if (pinHash != null) 'pinHash': pinHash,
    if (pinSalt != null) 'pinSalt': pinSalt,
    'dailyLimitMinutes': dailyLimitMinutes,
    'playbackMode': playbackMode.name,
    'themeChoice': themeChoice.name,
    if (localeCode != null) 'localeCode': localeCode,
    'kidLockEnabled': kidLockEnabled,
    'showFavorites': showFavorites,
    'showHistory': showHistory,
    'onboardingCompleted': onboardingCompleted,
    'watchedSecondsToday': watchedSecondsToday,
    'dayKey': dayKey,
    'playbackSource': playbackSource.name,
    'autoDownload': autoDownload,
    'preferLocalPlayback': preferLocalPlayback,
  };

  static AppSettings fromJson(Object? raw) {
    if (raw is! Map) return const AppSettings();
    return AppSettings(
      pinHash: raw['pinHash'] is String ? raw['pinHash'] as String : null,
      pinSalt: raw['pinSalt'] is String ? raw['pinSalt'] as String : null,
      dailyLimitMinutes: raw['dailyLimitMinutes'] is num
          ? (raw['dailyLimitMinutes'] as num).toInt()
          : 0,
      playbackMode: _playbackMode(raw['playbackMode']),
      themeChoice: _themeChoice(raw['themeChoice']),
      localeCode: raw['localeCode'] is String
          ? raw['localeCode'] as String
          : null,
      kidLockEnabled: raw['kidLockEnabled'] != false,
      showFavorites: raw['showFavorites'] != false,
      showHistory: raw['showHistory'] != false,
      onboardingCompleted: raw['onboardingCompleted'] == true,
      watchedSecondsToday: raw['watchedSecondsToday'] is num
          ? (raw['watchedSecondsToday'] as num).toInt()
          : 0,
      dayKey: raw['dayKey'] is String ? raw['dayKey'] as String : '',
      playbackSource: _playbackSource(raw['playbackSource']),
      autoDownload: raw['autoDownload'] == true,
      preferLocalPlayback: raw['preferLocalPlayback'] != false,
    );
  }

  static PlaybackSource _playbackSource(Object? raw) {
    return PlaybackSource.values.firstWhere(
      (source) => source.name == raw,
      orElse: () => PlaybackSource.downloaded,
    );
  }

  static PlaybackMode _playbackMode(Object? raw) {
    return PlaybackMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => PlaybackMode.auto,
    );
  }

  static AppThemeChoice _themeChoice(Object? raw) {
    return AppThemeChoice.values.firstWhere(
      (choice) => choice.name == raw,
      orElse: () => AppThemeChoice.system,
    );
  }

  static const Object _sentinel = Object();
}
