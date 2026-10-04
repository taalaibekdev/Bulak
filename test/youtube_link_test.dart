import 'package:bulak/core/utils/youtube_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YouTubeLink.extractVideoId', () {
    const id = 'dQw4w9WgXcQ';

    test('принимает чистый идентификатор', () {
      expect(YouTubeLink.extractVideoId(id), id);
    });

    test('разбирает обычную ссылку watch', () {
      expect(
        YouTubeLink.extractVideoId('https://www.youtube.com/watch?v=$id'),
        id,
      );
    });

    test('разбирает ссылку с дополнительными параметрами', () {
      expect(
        YouTubeLink.extractVideoId(
          'https://www.youtube.com/watch?v=$id&list=PL123&index=4&t=42s',
        ),
        id,
      );
    });

    test('разбирает короткую ссылку youtu.be', () {
      expect(YouTubeLink.extractVideoId('https://youtu.be/$id'), id);
      expect(YouTubeLink.extractVideoId('https://youtu.be/$id?t=30'), id);
    });

    test('разбирает мобильный и музыкальный домены', () {
      expect(
        YouTubeLink.extractVideoId('https://m.youtube.com/watch?v=$id'),
        id,
      );
      expect(
        YouTubeLink.extractVideoId('https://music.youtube.com/watch?v=$id'),
        id,
      );
    });

    test('разбирает embed, shorts и live', () {
      expect(
        YouTubeLink.extractVideoId('https://www.youtube.com/embed/$id'),
        id,
      );
      expect(
        YouTubeLink.extractVideoId('https://www.youtube.com/shorts/$id'),
        id,
      );
      expect(
        YouTubeLink.extractVideoId('https://www.youtube.com/live/$id'),
        id,
      );
    });

    test('работает без схемы', () {
      expect(YouTubeLink.extractVideoId('youtube.com/watch?v=$id'), id);
      expect(YouTubeLink.extractVideoId('youtu.be/$id'), id);
    });

    test('находит ссылку внутри текста', () {
      expect(
        YouTubeLink.extractVideoId(
          'Смотри тут https://youtu.be/$id — классно!',
        ),
        id,
      );
    });

    test('не путается на мусоре', () {
      expect(YouTubeLink.extractVideoId(''), isNull);
      expect(YouTubeLink.extractVideoId('привет'), isNull);
      expect(
        YouTubeLink.extractVideoId('https://example.com/watch?v=$id'),
        isNull,
      );
      expect(YouTubeLink.extractVideoId('https://www.youtube.com/'), isNull);
    });
  });

  group('YouTubeLink.extractMany', () {
    test('достаёт несколько ссылок и убирает повторы', () {
      final ids = YouTubeLink.extractMany('''
        https://youtu.be/aaaaaaaaaaa
        https://www.youtube.com/watch?v=bbbbbbbbbbb
        https://youtu.be/aaaaaaaaaaa

      ''');
      expect(ids, ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    });

    test('пустой текст даёт пустой список', () {
      expect(YouTubeLink.extractMany('   '), isEmpty);
    });
  });

  group('YouTubeLink ссылки для плеера', () {
    test('embed использует privacy-enhanced домен и безопасные параметры', () {
      final url = YouTubeLink.embedUrl('abcdefghijk');
      expect(url, contains('youtube-nocookie.com/embed/abcdefghijk'));
      expect(url, contains('rel=0'));
      expect(url, contains('playsinline=1'));
      expect(url, contains('iv_load_policy=3'));
    });

    test('порядок превью идёт от лучшего к гарантированному', () {
      final candidates = YouTubeLink.thumbnailCandidates('abcdefghijk');
      expect(candidates.first, contains('maxresdefault'));
      expect(candidates.last, contains('hqdefault'));
    });

    test('watchUrl ведёт на обычную страницу видео', () {
      expect(
        YouTubeLink.watchUrl('abcdefghijk'),
        'https://www.youtube.com/watch?v=abcdefghijk',
      );
    });
  });
}
