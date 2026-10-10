import 'package:bulak/core/app_config.dart';
import 'package:bulak/data/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('источник воспроизведения', () {
    test('по умолчанию выбран режим «только скачанное»', () {
      const settings = AppSettings();

      // Сохранённая настройка по умолчанию одинакова в любой сборке…
      expect(settings.playbackSource, PlaybackSource.downloaded);
      // …а вот играть ли с обязательным скачиванием, зависит от того,
      // доступно ли скачивание в этой сборке вообще.
      expect(settings.requiresDownloadFirst, AppConfig.downloadsEnabled);
    });

    test('режим потока отключает обязательное скачивание', () {
      const settings = AppSettings(playbackSource: PlaybackSource.stream);

      expect(settings.requiresDownloadFirst, isFalse);
    });

    test('выбор источника переживает сохранение', () {
      const settings = AppSettings(playbackSource: PlaybackSource.stream);
      final restored = AppSettings.fromJson(settings.toJson());

      expect(restored.playbackSource, PlaybackSource.stream);
    });

    test('старое сохранение без поля читается как «только скачанное»', () {
      final restored = AppSettings.fromJson({'dailyLimitMinutes': 30});

      expect(restored.playbackSource, PlaybackSource.downloaded);
    });

    test('неизвестное значение не ломает настройки', () {
      final restored = AppSettings.fromJson({'playbackSource': 'нет такого'});

      expect(restored.playbackSource, PlaybackSource.downloaded);
    });

    test('в сборке без скачивания источник принудительно потоковый', () {
      // В магазинных сборках скачивание выключено флагом
      // BULAK_DISABLE_DOWNLOADS, поэтому «только скачанное» там
      // означало бы «не играет вообще ничего».
      const settings = AppSettings(playbackSource: PlaybackSource.downloaded);

      // Один и тот же тест прогоняется в двух конфигурациях: обычно и с
      // --dart-define=BULAK_DISABLE_DOWNLOADS=true (магазинная сборка).
      // В магазинной сборке скачивания нет, поэтому «только скачанное»
      // означало бы «не играет вообще ничего» — режим обязан стать потоковым.
      if (AppConfig.downloadsEnabled) {
        expect(settings.effectivePlaybackSource, PlaybackSource.downloaded);
        expect(settings.requiresDownloadFirst, isTrue);
      } else {
        expect(settings.effectivePlaybackSource, PlaybackSource.stream);
        expect(settings.requiresDownloadFirst, isFalse);
      }
    });
  });
}
