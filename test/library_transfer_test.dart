import 'dart:convert';

import 'package:bulak/data/models/app_settings.dart';
import 'package:bulak/data/models/video_item.dart';
import 'package:bulak/data/services/library_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

VideoItem _video(String id, {String? title, String? author, int? seconds}) =>
    VideoItem(
      id: id,
      title: title ?? 'Видео $id',
      author: author,
      durationSeconds: seconds,
      addedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('экспорт', () {
    test('собирает читаемый JSON с названиями и длительностью', () {
      final json = LibraryTransfer.encode(
        title: 'Мультики',
        videos: [
          _video('aaaaaaaaaaa', title: 'Мульт', author: 'Канал', seconds: 200),
        ],
      );

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['format'], LibraryTransfer.formatTag);
      expect(decoded['version'], LibraryTransfer.formatVersion);
      expect(decoded['title'], 'Мультики');
      expect((decoded['videos'] as List).length, 1);
      expect(decoded['videos'][0]['id'], 'aaaaaaaaaaa');
      expect(decoded['videos'][0]['duration'], 200);
    });

    test('плоский список ссылок содержит по ссылке на строку', () {
      final links = LibraryTransfer.toPlainLinks([
        _video('aaaaaaaaaaa'),
        _video('bbbbbbbbbbb'),
      ]);

      final lines = links.split('\n');
      expect(lines.length, 2);
      expect(lines.first, 'https://www.youtube.com/watch?v=aaaaaaaaaaa');
    });
  });

  group('импорт', () {
    test('читает свой формат обратно', () {
      final json = LibraryTransfer.encode(
        title: 'Мультики',
        note: 'Смотрите вместе',
        videos: [
          _video('aaaaaaaaaaa', title: 'Мульт', author: 'Канал', seconds: 200),
        ],
      );

      final payload = LibraryTransfer.decode(json)!;
      expect(payload.title, 'Мультики');
      expect(payload.note, 'Смотрите вместе');
      expect(payload.fromFile, isTrue);
      expect(payload.videos.single.id, 'aaaaaaaaaaa');
      expect(payload.videos.single.title, 'Мульт');
      expect(payload.videos.single.author, 'Канал');
      expect(payload.videos.single.durationSeconds, 200);
    });

    test('понимает просто список ссылок', () {
      final payload = LibraryTransfer.decode('''
https://youtu.be/aaaaaaaaaaa
https://www.youtube.com/watch?v=bbbbbbbbbbb
      ''')!;

      expect(payload.fromFile, isFalse);
      expect(payload.videos.map((video) => video.id), [
        'aaaaaaaaaaa',
        'bbbbbbbbbbb',
      ]);
      expect(payload.videos.first.title, isNull);
    });

    test('понимает текст сообщения со ссылками', () {
      final payload = LibraryTransfer.decode(
        'Привет! Посмотри вот это: https://youtu.be/aaaaaaaaaaa — хороший мультик',
      )!;

      expect(payload.videos.single.id, 'aaaaaaaaaaa');
    });

    test('достаёт свой JSON из текста письма', () {
      final json = LibraryTransfer.encode(
        title: 'Музыка',
        videos: [_video('aaaaaaaaaaa')],
      );
      final payload = LibraryTransfer.decode(
        'Смотри, что нашёл:\n\n$json\n\nПока!',
      )!;

      expect(payload.title, 'Музыка');
      expect(payload.videos.single.id, 'aaaaaaaaaaa');
    });

    test('понимает чужой JSON-массив', () {
      final payload = LibraryTransfer.decode(
        '[{"id": "aaaaaaaaaaa", "title": "Раз"}, '
        '{"id": "bbbbbbbbbbb"}]',
      )!;

      expect(payload.videos.length, 2);
      expect(payload.videos.first.title, 'Раз');
    });

    test('пустой и бессмысленный текст не разбирается', () {
      expect(LibraryTransfer.decode(''), isNull);
      expect(LibraryTransfer.decode('   '), isNull);
      expect(LibraryTransfer.decode('просто сообщение без ссылок'), isNull);
      expect(LibraryTransfer.decode('{"videos": []}'), isNull);
      expect(LibraryTransfer.decode('[{"id": "коротко"}]'), isNull);
    });

    test('битые записи внутри файла пропускаются', () {
      final payload = LibraryTransfer.decode(
        '{"videos": [{"id": "aaaaaaaaaaa"}, {"id": "нет"}, '
        '{"title": "без id"}]}',
      )!;

      expect(payload.videos.length, 1);
      expect(payload.videos.single.id, 'aaaaaaaaaaa');
    });

    test('ссылки на чужие сайты не попадают в подборку', () {
      final payload = LibraryTransfer.decode('''
https://youtu.be/aaaaaaaaaaa
https://example.com/watch?v=bbbbbbbbbbb
      ''')!;

      expect(payload.videos.map((video) => video.id), ['aaaaaaaaaaa']);
    });
  });

  group('VideoItem и загрузка', () {
    test('отметка о файле переживает сохранение', () {
      final video = _video('aaaaaaaaaaa').copyWith(
        localFileName: 'aaaaaaaaaaa.mp4',
        downloadedAt: DateTime(2026, 2, 3, 4, 5),
        fileSizeBytes: 12345,
        downloadQuality: '360p',
      );

      final restored = VideoItem.fromJson(video.toJson())!;
      expect(restored.isDownloaded, isTrue);
      expect(restored.localFileName, 'aaaaaaaaaaa.mp4');
      expect(restored.fileSizeBytes, 12345);
      expect(restored.downloadQuality, '360p');
      expect(restored.downloadedAt, video.downloadedAt);
    });

    test('снятие отметки очищает все поля загрузки', () {
      final video = _video('aaaaaaaaaaa').copyWith(
        localFileName: 'aaaaaaaaaaa.mp4',
        downloadedAt: DateTime(2026, 2, 3),
        fileSizeBytes: 100,
        downloadQuality: '360p',
      );

      final cleared = video.copyWith(
        localFileName: null,
        downloadedAt: null,
        fileSizeBytes: null,
        downloadQuality: null,
      );

      expect(cleared.isDownloaded, isFalse);
      expect(cleared.fileSizeBytes, isNull);
      expect(cleared.downloadQuality, isNull);
      expect(cleared.downloadedAt, isNull);
    });

    test('видео без файла не считается скачанным', () {
      expect(_video('aaaaaaaaaaa').isDownloaded, isFalse);
      expect(
        _video('aaaaaaaaaaa').copyWith(localFileName: '').isDownloaded,
        isFalse,
      );
    });
  });

  group('настройки загрузки', () {
    test(
      'по умолчанию автоскачивание выключено, локальный файл — в приоритете',
      () {
        const settings = AppSettings();
        expect(settings.autoDownload, isFalse);
        expect(settings.preferLocalPlayback, isTrue);
      },
    );

    test('настройки загрузки переживают сохранение', () {
      const settings = AppSettings(
        autoDownload: true,
        preferLocalPlayback: false,
      );

      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.autoDownload, isTrue);
      expect(restored.preferLocalPlayback, isFalse);
    });

    test('старые сохранения без новых полей читаются безопасно', () {
      final restored = AppSettings.fromJson({'dailyLimitMinutes': 30});

      expect(restored.autoDownload, isFalse);
      expect(restored.preferLocalPlayback, isTrue);
    });
  });
}
