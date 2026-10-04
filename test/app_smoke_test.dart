import 'dart:convert';

import 'package:bulak/app.dart';
import 'package:bulak/core/utils/pin_code.dart';
import 'package:bulak/data/models/app_settings.dart';
import 'package:bulak/data/repositories/library_repository.dart';
import 'package:bulak/data/repositories/settings_repository.dart';
import 'package:bulak/data/services/youtube_service.dart';
import 'package:bulak/data/storage/key_value_store.dart';
import 'package:bulak/state/library_controller.dart';
import 'package:bulak/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Сеть в тестах не нужна: подменяем источник метаданных заглушкой.
class _OfflineYoutube extends YouTubeService {
  @override
  Future<VideoMetadata?> fetchMetadata(String videoId) async => null;
}

void main() {
  late InMemoryStore store;
  late SettingsController settings;
  late LibraryController library;

  setUp(() {
    store = InMemoryStore();
    settings = SettingsController(repository: SettingsRepository(store));
    library = LibraryController(
      repository: LibraryRepository(store),
      youtube: _OfflineYoutube(),
    );
  });

  tearDown(() {
    settings.dispose();
    library.dispose();
  });

  /// Готовит сохранённые настройки до запуска приложения.
  ///
  /// Язык задаём явно: тестовое окружение по умолчанию англоязычное,
  /// а проверяем мы русский интерфейс.
  void seed({
    bool onboarding = false,
    String? pin,
    String locale = 'ru',
    int? dailyLimitMinutes,
  }) {
    final data = <String, Object?>{
      'onboardingCompleted': onboarding,
      'dayKey': AppSettings.dayKeyFor(DateTime.now()),
      'localeCode': locale,
      'dailyLimitMinutes': ?dailyLimitMinutes,
    };
    if (pin != null) {
      final salt = PinCode.generateSalt();
      data['pinSalt'] = salt;
      data['pinHash'] = PinCode.hash(pin, salt);
    }
    store.write(SettingsRepository.storageKey, jsonEncode(data));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await settings.load();
    await library.load();
    await tester.pumpWidget(
      BulakApp(
        settings: settings,
        library: library,
        youtube: _OfflineYoutube(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Нажимает цифры на клавиатуре PIN-кода.
  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(
        find
            .ancestor(of: find.text(digit), matching: find.byType(InkWell))
            .first,
      );
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('первый запуск показывает мастер настройки', (tester) async {
    seed();
    await pumpApp(tester);

    expect(find.text('Добро пожаловать в «Булак»!'), findsOneWidget);
    expect(find.text('Начать настройку'), findsOneWidget);
  });

  testWidgets('мастер настройки сохраняет PIN и ведёт к добавлению видео', (
    tester,
  ) async {
    seed();
    await pumpApp(tester);

    await tester.tap(find.text('Начать настройку'));
    await tester.pumpAndSettle();
    expect(find.text('Придумайте PIN-код'), findsOneWidget);

    // Клавиатура должна очищаться между шагами: без этого вторая четвёрка
    // цифр не принимается и пользователь застревает на подтверждении.
    await tapDigits(tester, '4821');
    expect(find.text('Повторите PIN-код'), findsOneWidget);

    await tapDigits(tester, '4821');
    expect(find.text('Добавить видео'), findsOneWidget);
    expect(settings.hasPin, isTrue);
    expect(settings.verifyPin('4821'), isTrue);
  });

  testWidgets('несовпадающий PIN возвращает к первому шагу', (tester) async {
    seed();
    await pumpApp(tester);

    await tester.tap(find.text('Начать настройку'));
    await tester.pumpAndSettle();

    await tapDigits(tester, '4821');
    await tapDigits(tester, '1111');

    expect(find.text('PIN-коды не совпали'), findsOneWidget);
    expect(find.text('Придумайте PIN-код'), findsOneWidget);
    expect(settings.hasPin, isFalse);
  });

  testWidgets('слишком простой PIN не принимается', (tester) async {
    seed();
    await pumpApp(tester);

    await tester.tap(find.text('Начать настройку'));
    await tester.pumpAndSettle();

    await tapDigits(tester, '1234');
    expect(
      find.text('Такой PIN-код слишком простой. Выберите другой.'),
      findsOneWidget,
    );
    expect(find.text('Придумайте PIN-код'), findsOneWidget);
  });

  testWidgets('после мастера видно пустую библиотеку', (tester) async {
    seed(onboarding: true);
    await pumpApp(tester);

    expect(find.text('Здесь пока пусто'), findsOneWidget);
    expect(find.text('Родителям'), findsWidgets);
    expect(find.text('Главная'), findsWidgets);
  });

  testWidgets('вкладка «Родителям» сначала просит PIN, потом открывается', (
    tester,
  ) async {
    seed(onboarding: true, pin: '4821');
    await pumpApp(tester);

    await tester.tap(find.text('Родителям').last);
    await tester.pumpAndSettle();

    expect(find.text('Родительский режим'), findsOneWidget);

    // Неверный код — показываем подсказку и не пускаем дальше.
    await tapDigits(tester, '1111');
    expect(find.text('Неверный PIN-код. Попробуйте ещё раз.'), findsOneWidget);

    // Верный код — открывается родительский экран.
    await tapDigits(tester, '4821');
    expect(find.text('Добавить видео'), findsOneWidget);
    expect(find.text('Лимит времени'), findsOneWidget);
  });

  testWidgets('без PIN вкладка «Родителям» предлагает его придумать', (
    tester,
  ) async {
    seed(onboarding: true);
    await pumpApp(tester);

    await tester.tap(find.text('Родителям').last);
    await tester.pumpAndSettle();

    expect(find.text('Придумайте PIN-код'), findsOneWidget);
  });

  testWidgets('исчерпанный лимит показывается на главной', (tester) async {
    seed(onboarding: true, dailyLimitMinutes: 15);
    await settings.load();
    settings.addWatchedSeconds(15 * 60 + 1);
    await settings.flushWatchTime();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await library.load();
    await tester.pumpWidget(
      BulakApp(
        settings: settings,
        library: library,
        youtube: _OfflineYoutube(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Лимит на сегодня уже исчерпан'), findsOneWidget);
  });
}
