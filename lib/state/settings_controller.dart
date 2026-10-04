import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/pin_code.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/settings_repository.dart';

/// Настройки приложения и учёт экранного времени.
///
/// Контроллер намеренно «толстый»: он держит единственный экземпляр
/// настроек, следит за сменой суток и throttling'ом записи на диск.
class SettingsController extends ChangeNotifier {
  // Приватное поле нельзя объявить через `this._repository` в именованных
  // параметрах, поэтому присваиваем явно.
  SettingsController({required SettingsRepository repository})
    // ignore: prefer_initializing_formals
    : _repository = repository;

  final SettingsRepository _repository;

  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;
  bool _isDisposed = false;

  /// Накопленные секунды, которые ещё не записаны на диск.
  int _unsavedSeconds = 0;

  /// Сколько секунд прошло с последнего уведомления слушателей.
  int _secondsSinceNotify = 0;

  AppSettings get settings => _settings;

  bool get isLoaded => _isLoaded;

  bool get hasPin => _settings.hasPin;

  bool get isLimitReached => _settings.isLimitReached;

  Duration? get remainingToday => _settings.remainingToday;

  /// Сколько секунд просмотрено сегодня.
  int get watchedSecondsToday => _settings.watchedSecondsToday;

  Future<void> load() async {
    _settings = await _repository.load();
    _isLoaded = true;
    _notify();
  }

  // --- Родительский PIN --------------------------------------------------

  /// Проверяет введённый код.
  bool verifyPin(String code) => PinCode.verify(
    code: code,
    salt: _settings.pinSalt,
    expectedHash: _settings.pinHash,
  );

  /// Устанавливает новый PIN-код (соль генерируется заново).
  Future<void> setPin(String code) async {
    final salt = PinCode.generateSalt();
    await _apply(
      _settings.copyWith(pinSalt: salt, pinHash: PinCode.hash(code, salt)),
    );
  }

  // --- Экранное время ----------------------------------------------------

  Future<void> setDailyLimit(int minutes) =>
      _apply(_settings.copyWith(dailyLimitMinutes: minutes < 0 ? 0 : minutes));

  Future<void> resetTodayCounter() => _apply(
    _settings.copyWith(
      watchedSecondsToday: 0,
      dayKey: AppSettings.dayKeyFor(DateTime.now()),
    ),
  );

  /// Добавляет просмотренные секунды.
  ///
  /// Вызывается плеером раз в секунду. Чтобы не писать в хранилище каждую
  /// секунду, накопленные значения сбрасываются на диск раз в 30 секунд
  /// (и принудительно — при паузе или выходе через [flushWatchTime]).
  void addWatchedSeconds(int seconds) {
    if (seconds <= 0) return;
    final normalized = _settings.normalized();
    _settings = normalized.copyWith(
      watchedSecondsToday: normalized.watchedSecondsToday + seconds,
    );
    _unsavedSeconds += seconds;
    _secondsSinceNotify += seconds;

    if (_unsavedSeconds >= 30) {
      unawaited(_repository.save(_settings));
      _unsavedSeconds = 0;
    }
    // Слушателей дёргаем не чаще раза в 10 секунд — иначе интерфейс
    // перерисовывается 60 раз в минуту без пользы.
    if (_secondsSinceNotify >= 10) {
      _secondsSinceNotify = 0;
      _notify();
    }
  }

  /// Записывает накопленное время на диск (пауза, выход, сворачивание).
  Future<void> flushWatchTime() async {
    if (_unsavedSeconds == 0) return;
    _unsavedSeconds = 0;
    await _repository.save(_settings);
    _notify();
  }

  /// Проверяет, что счётчик относится к сегодняшнему дню.
  void refreshDay() {
    final normalized = _settings.normalized();
    if (!identical(normalized, _settings)) {
      _settings = normalized;
      unawaited(_repository.save(_settings));
      _notify();
    }
  }

  // --- Внешний вид и воспроизведение -------------------------------------

  Future<void> setThemeChoice(AppThemeChoice choice) =>
      _apply(_settings.copyWith(themeChoice: choice));

  /// `null` — язык как в системе.
  Future<void> setLocaleCode(String? code) =>
      _apply(_settings.copyWith(localeCode: code));

  Future<void> setPlaybackMode(PlaybackMode mode) =>
      _apply(_settings.copyWith(playbackMode: mode));

  Future<void> setKidLock(bool enabled) =>
      _apply(_settings.copyWith(kidLockEnabled: enabled));

  Future<void> setShowFavorites(bool value) =>
      _apply(_settings.copyWith(showFavorites: value));

  Future<void> setShowHistory(bool value) =>
      _apply(_settings.copyWith(showHistory: value));

  Future<void> completeOnboarding() =>
      _apply(_settings.copyWith(onboardingCompleted: true));

  // --- Сброс -------------------------------------------------------------

  /// Полное удаление настроек (используется кнопкой «Удалить все данные»).
  Future<void> resetAll() async {
    await _repository.clear();
    _settings = const AppSettings(dayKey: '', onboardingCompleted: false);
    _settings = _settings.normalized();
    _notify();
  }

  // --- Служебное ---------------------------------------------------------

  Future<void> _apply(AppSettings next) async {
    _settings = next;
    _notify();
    await _repository.save(next);
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Последний шанс сохранить накопленное время.
    if (_unsavedSeconds > 0) {
      _repository.save(_settings);
    }
    super.dispose();
  }
}
