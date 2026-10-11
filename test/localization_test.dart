import 'package:bulak/core/l10n/app_strings.dart';
import 'package:bulak/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Кыргызский — основной язык приложения.
///
/// Тест ловит самую обидную ошибку локализации: строку, которую забыли
/// перевести. На кыргызском она молча показалась бы по-русски, и заметить
/// это можно было бы только вручную на живом устройстве.
void main() {
  const ky = AppStrings(AppStrings.defaultLocale);
  const ru = AppStrings(Locale('ru'));
  const en = AppStrings(Locale('en'));

  /// Выборка строк из разных экранов: главная, коллекции, плеер, загрузки,
  /// подготовка видео, родительский раздел, лимит времени.
  final samples = <String, String Function(AppStrings)>{
    'navHome': (s) => s.navHome,
    'navCollections': (s) => s.navCollections,
    'navFavorites': (s) => s.navFavorites,
    'navHistory': (s) => s.navHistory,
    'navParents': (s) => s.navParents,
    'actionCancel': (s) => s.actionCancel,
    'actionSave': (s) => s.actionSave,
    'actionDelete': (s) => s.actionDelete,
    'playerFullscreen': (s) => s.playerFullscreen,
    'playerNext': (s) => s.playerNext,
    'prepareTitle': (s) => s.prepareTitle,
    'prepareCancel': (s) => s.prepareCancel,
    'downloadsTitle': (s) => s.downloadsTitle,
    'downloadAction': (s) => s.downloadAction,
    'playbackSourceTitle': (s) => s.playbackSourceTitle,
    'playbackSourceDownloaded': (s) => s.playbackSourceDownloaded,
    'parentTimeLimit': (s) => s.parentTimeLimit,
    'parentSecurity': (s) => s.parentSecurity,
    'homeEmptyTitle': (s) => s.homeEmptyTitle,
    'noInternet': (s) => s.noInternet,
  };

  group('языки приложения', () {
    test('кыргызский объявлен основным', () {
      expect(AppStrings.defaultLocale.languageCode, 'ky');
      expect(AppStrings.supportedLocales.first.languageCode, 'ky');
    });

    test('поддержаны три языка', () {
      final codes = AppStrings.supportedLocales
          .map((locale) => locale.languageCode)
          .toList();

      expect(codes, containsAll(<String>['ky', 'ru', 'en']));
      expect(codes.length, 3);
    });

    test('каждая строка выборки переведена на кыргызский', () {
      final untranslated = <String>[];

      samples.forEach((name, read) {
        if (read(ky) == read(ru)) untranslated.add(name);
      });

      expect(
        untranslated,
        isEmpty,
        reason:
            'Эти строки на кыргызском совпадают с русскими — похоже, '
            'перевод забыли: ${untranslated.join(', ')}',
      );
    });

    test('английский по-прежнему отличается от русского', () {
      final same = <String>[];
      samples.forEach((name, read) {
        if (read(en) == read(ru)) same.add(name);
      });

      // Совпадения допустимы (имена собственные), но их не должно быть много.
      expect(same.length, lessThan(3), reason: 'совпали: ${same.join(', ')}');
    });

    test('незнакомый язык показывается по-русски, а не пустотой', () {
      const unknown = AppStrings(Locale('de'));

      expect(unknown.navHome, isNotEmpty);
      expect(unknown.navHome, ru.navHome);
    });

    test('название приложения одинаково на всех языках', () {
      expect(ky.appName, 'Булак');
      expect(ru.appName, 'Булак');
      expect(en.appName, 'Bulak');
    });

    test('в выборе языка каждый язык показан на своём языке', () {
      // Это не перевод, а самоназвание: «Кыргызча» должно читаться одинаково
      // при любом текущем языке интерфейса, иначе список языков путает.
      expect(ky.languageKyrgyz, 'Кыргызча');
      expect(ru.languageKyrgyz, 'Кыргызча');
      expect(en.languageKyrgyz, 'Кыргызча');
      expect(ky.languageRussian, 'Русский');
      expect(ky.languageEnglish, 'English');
    });
  });

  group('числа в кыргызском', () {
    test('после числительного существительное не меняется', () {
      // В кыргызском нет форм «1 видео / 2 видео / 5 видео»: слово всегда
      // одно и то же, поэтому склонение по русским правилам тут не годится.
      expect(ky.videosCount(1), '1 видео');
      expect(ky.videosCount(3), '3 видео');
      expect(ky.videosCount(21), '21 видео');
      expect(ky.collectionsCount(2), '2 топтом');
    });

    test('минуты пишутся одним словом для любого числа', () {
      expect(ky.minutesShort(5), '5 мүнөт');
      expect(ky.minutesShort(30), '30 мүнөт');
    });
  });

  group('форматирование на кыргызском', () {
    test('длительность', () {
      expect(Formatters.shortDuration(const Duration(minutes: 5), ky), '5 мүн');
      expect(
        Formatters.shortDuration(const Duration(hours: 1, minutes: 20), ky),
        '1 саат 20 мүн',
      );
      expect(
        Formatters.shortDuration(const Duration(seconds: 30), ky),
        '<1 мүн',
      );
    });

    test('относительные даты', () {
      final now = DateTime.now();

      expect(Formatters.relativeDate(now, ky), 'бүгүн');
      expect(
        Formatters.relativeDate(now.subtract(const Duration(days: 1)), ky),
        'кечээ',
      );
      expect(
        Formatters.relativeDate(now.subtract(const Duration(days: 3)), ky),
        '3 күн мурун',
      );
    });

    test('русский и английский не сломались', () {
      expect(Formatters.shortDuration(const Duration(minutes: 5), ru), '5 мин');
      expect(Formatters.shortDuration(const Duration(minutes: 5), en), '5 min');
      expect(Formatters.relativeDate(DateTime.now(), ru), 'сегодня');
      expect(Formatters.relativeDate(DateTime.now(), en), 'today');
    });
  });
}
