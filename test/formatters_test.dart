import 'package:bulak/core/l10n/app_strings.dart';
import 'package:bulak/core/utils/formatters.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.duration', () {
    test('форматирует минуты и секунды', () {
      expect(
        Formatters.duration(const Duration(minutes: 2, seconds: 5)),
        '2:05',
      );
      expect(Formatters.duration(const Duration(seconds: 9)), '0:09');
      expect(
        Formatters.duration(const Duration(minutes: 12, seconds: 40)),
        '12:40',
      );
    });

    test('добавляет часы для длинных видео', () {
      expect(
        Formatters.duration(const Duration(hours: 1, minutes: 2, seconds: 33)),
        '1:02:33',
      );
    });

    test('пустая и нулевая длительность дают пустую строку', () {
      expect(Formatters.duration(null), '');
      expect(Formatters.duration(Duration.zero), '');
    });
  });

  group('Formatters.percent', () {
    test('округляет и ограничивает диапазон', () {
      expect(Formatters.percent(0), 0);
      expect(Formatters.percent(0.5), 50);
      expect(Formatters.percent(1), 100);
      expect(Formatters.percent(1.4), 100);
      expect(Formatters.percent(-1), 0);
    });
  });

  group('Formatters.relativeDate', () {
    const strings = AppStrings(Locale('ru'));

    test('сегодня и вчера словами', () {
      expect(Formatters.relativeDate(DateTime.now(), strings), 'сегодня');
      expect(
        Formatters.relativeDate(
          DateTime.now().subtract(const Duration(days: 1)),
          strings,
        ),
        'вчера',
      );
    });

    test('давние даты — в числовом виде', () {
      final old = DateTime(2024, 3, 7);
      expect(Formatters.relativeDate(old, strings), '07.03.2024');
    });
  });

  group('AppStrings', () {
    test('русский язык по умолчанию', () {
      const strings = AppStrings(Locale('ru'));
      expect(strings.appName, 'Булак');
      expect(strings.navHome, 'Главная');
    });

    test('английский язык переключается по локали', () {
      const strings = AppStrings(Locale('en'));
      expect(strings.appName, 'Bulak');
      expect(strings.navHome, 'Home');
    });

    test('счётчик видео согласуется с числом', () {
      const ru = AppStrings(Locale('ru'));
      const en = AppStrings(Locale('en'));
      expect(ru.videosCount(1), '1 видео');
      expect(ru.videosCount(5), '5 видео');
      expect(en.videosCount(1), '1 video');
      expect(en.videosCount(5), '5 videos');
    });

    test('русские формы множественного числа', () {
      expect(AppStrings.plural(1, 'минута', 'минуты', 'минут'), 'минута');
      expect(AppStrings.plural(3, 'минута', 'минуты', 'минут'), 'минуты');
      expect(AppStrings.plural(11, 'минута', 'минуты', 'минут'), 'минут');
      expect(AppStrings.plural(22, 'минута', 'минуты', 'минут'), 'минуты');
    });
  });
}
