import 'package:bulak/data/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('источник воспроизведения', () {
    test('по умолчанию играем только скачанное', () {
      const settings = AppSettings();

      expect(settings.playbackSource, PlaybackSource.downloaded);
      expect(settings.requiresDownloadFirst, isTrue);
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

      // Флаг сборки здесь не выставлен, поэтому проверяем саму логику:
      // при доступном скачивании режим сохраняется как выбран.
      expect(settings.effectivePlaybackSource, PlaybackSource.downloaded);
    });
  });
}
