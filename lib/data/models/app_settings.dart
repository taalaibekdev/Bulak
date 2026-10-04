/// Как оформлено приложение.
enum AppThemeChoice { system, light, dark }

/// Каким способом проигрывать видео.
///
/// * [auto] — сначала пробуем прямой поток без рекламы, при неудаче
///   автоматически переключаемся на встроенный плеер YouTube;
/// * [direct] — только прямой поток (чистая картинка, качество до 360p);
/// * [embed] — только официальный встроенный плеер YouTube.
enum PlaybackMode { auto, direct, embed }

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
