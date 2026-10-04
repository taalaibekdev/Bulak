import 'package:bulak/core/utils/pin_code.dart';
import 'package:bulak/data/models/app_settings.dart';
import 'package:bulak/data/repositories/settings_repository.dart';
import 'package:bulak/data/storage/key_value_store.dart';
import 'package:bulak/state/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStore store;
  late SettingsController settings;

  setUp(() {
    store = InMemoryStore();
    settings = SettingsController(repository: SettingsRepository(store));
  });

  tearDown(() => settings.dispose());

  group('загрузка', () {
    test('по умолчанию лимита нет, PIN не задан, мастер не пройден', () async {
      await settings.load();
      expect(settings.isLoaded, isTrue);
      expect(settings.hasPin, isFalse);
      expect(settings.settings.dailyLimitMinutes, 0);
      expect(settings.settings.hasDailyLimit, isFalse);
      expect(settings.settings.playbackMode, PlaybackMode.auto);
      expect(settings.settings.themeChoice, AppThemeChoice.system);
      expect(settings.settings.onboardingCompleted, isFalse);
    });

    test('день сменился — счётчик обнуляется', () async {
      store = InMemoryStore({
        SettingsRepository.storageKey:
            '{"dayKey":"2000-01-01",'
            '"watchedSecondsToday":900,"dailyLimitMinutes":30}',
      });
      settings = SettingsController(repository: SettingsRepository(store));
      await settings.load();

      expect(settings.watchedSecondsToday, 0);
      expect(settings.settings.dayKey, AppSettings.dayKeyFor(DateTime.now()));
    });

    test('счётчик текущего дня сохраняется', () async {
      final today = AppSettings.dayKeyFor(DateTime.now());
      store = InMemoryStore({
        SettingsRepository.storageKey:
            '{"dayKey":"$today","watchedSecondsToday":120}',
      });
      settings = SettingsController(repository: SettingsRepository(store));
      await settings.load();

      expect(settings.watchedSecondsToday, 120);
    });
  });

  group('PIN-код', () {
    test('установка и проверка', () async {
      await settings.load();
      await settings.setPin('4821');

      expect(settings.hasPin, isTrue);
      expect(settings.verifyPin('4821'), isTrue);
      expect(settings.verifyPin('0000'), isFalse);
    });

    test('сам код не хранится в открытом виде', () async {
      await settings.load();
      await settings.setPin('4821');

      final raw = store.values[SettingsRepository.storageKey]!;
      expect(raw, isNot(contains('4821')));
      expect(raw, contains('pinHash'));
      expect(raw, contains('pinSalt'));
    });

    test('после перезапуска старый PIN продолжает работать', () async {
      await settings.load();
      await settings.setPin('4821');

      final restarted = SettingsController(
        repository: SettingsRepository(store),
      );
      await restarted.load();
      expect(restarted.verifyPin('4821'), isTrue);
      restarted.dispose();
    });

    test('новая соль делает прежний хэш недействительным', () async {
      await settings.load();
      await settings.setPin('4821');
      final firstSalt = settings.settings.pinSalt;

      await settings.setPin('4821');
      expect(settings.settings.pinSalt, isNot(firstSalt));
      expect(settings.verifyPin('4821'), isTrue);
    });
  });

  group('дневной лимит', () {
    test('без лимита просмотр не ограничен', () async {
      await settings.load();
      settings.addWatchedSeconds(3600);
      expect(settings.isLimitReached, isFalse);
      expect(settings.remainingToday, isNull);
    });

    test('лимит достигается по сумме секунд', () async {
      await settings.load();
      await settings.setDailyLimit(1); // одна минута

      settings.addWatchedSeconds(30);
      expect(settings.isLimitReached, isFalse);
      expect(settings.remainingToday, const Duration(seconds: 30));

      settings.addWatchedSeconds(30);
      expect(settings.isLimitReached, isTrue);
      expect(settings.remainingToday, Duration.zero);
    });

    test('сброс счётчика возвращает время', () async {
      await settings.load();
      await settings.setDailyLimit(1);
      settings.addWatchedSeconds(60);
      expect(settings.isLimitReached, isTrue);

      await settings.resetTodayCounter();
      expect(settings.isLimitReached, isFalse);
      expect(settings.watchedSecondsToday, 0);
    });

    test('отрицательный лимит превращается в «без ограничений»', () async {
      await settings.load();
      await settings.setDailyLimit(-5);
      expect(settings.settings.dailyLimitMinutes, 0);
    });

    test('flushWatchTime сохраняет накопленное на диск', () async {
      await settings.load();
      await settings.setDailyLimit(30);
      settings.addWatchedSeconds(5);
      await settings.flushWatchTime();

      final restarted = SettingsController(
        repository: SettingsRepository(store),
      );
      await restarted.load();
      expect(restarted.watchedSecondsToday, 5);
      restarted.dispose();
    });
  });

  group('настройки интерфейса', () {
    test('тема, язык и режим воспроизведения сохраняются', () async {
      await settings.load();
      await settings.setThemeChoice(AppThemeChoice.dark);
      await settings.setLocaleCode('en');
      await settings.setPlaybackMode(PlaybackMode.embed);

      final restarted = SettingsController(
        repository: SettingsRepository(store),
      );
      await restarted.load();
      expect(restarted.settings.themeChoice, AppThemeChoice.dark);
      expect(restarted.settings.localeCode, 'en');
      expect(restarted.settings.playbackMode, PlaybackMode.embed);
      restarted.dispose();
    });

    test('переключатели разделов и замочка', () async {
      await settings.load();
      await settings.setKidLock(false);
      await settings.setShowFavorites(false);
      await settings.setShowHistory(false);

      expect(settings.settings.kidLockEnabled, isFalse);
      expect(settings.settings.showFavorites, isFalse);
      expect(settings.settings.showHistory, isFalse);
    });

    test('мастер настройки отмечается пройденным', () async {
      await settings.load();
      await settings.completeOnboarding();
      expect(settings.settings.onboardingCompleted, isTrue);
    });
  });

  group('полный сброс', () {
    test('удаляет PIN, лимит и историю', () async {
      await settings.load();
      await settings.setPin('4821');
      await settings.setDailyLimit(45);
      settings.addWatchedSeconds(60);
      await settings.completeOnboarding();

      await settings.resetAll();
      expect(settings.hasPin, isFalse);
      expect(settings.settings.dailyLimitMinutes, 0);
      expect(settings.watchedSecondsToday, 0);
      expect(settings.settings.onboardingCompleted, isFalse);
    });
  });

  group('PinCode + AppSettings', () {
    test('normalized обнуляет счётчик только при смене дня', () {
      final today = AppSettings.dayKeyFor(DateTime.now());
      const settingsNow = AppSettings(watchedSecondsToday: 60);
      final normalized = settingsNow.normalized();
      expect(normalized.watchedSecondsToday, 0);
      expect(normalized.dayKey, today);

      final sameDay = normalized.normalized();
      expect(identical(sameDay, normalized), isTrue);
    });

    test('хэш PIN-кода проверяется через утилиту', () {
      final salt = PinCode.generateSalt();
      final hash = PinCode.hash('4821', salt);
      expect(
        PinCode.verify(code: '4821', salt: salt, expectedHash: hash),
        isTrue,
      );
    });
  });
}
