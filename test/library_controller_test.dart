import 'package:bulak/data/models/video_item.dart';
import 'package:bulak/data/repositories/library_repository.dart';
import 'package:bulak/data/services/youtube_service.dart';
import 'package:bulak/data/storage/key_value_store.dart';
import 'package:bulak/state/library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Заглушка вместо сети: возвращает предсказуемые названия.
class _FakeMetadata implements VideoMetadataSource {
  _FakeMetadata({this.failFor = const {}});

  final Set<String> failFor;

  @override
  Future<VideoMetadata?> fetchMetadata(String videoId) async {
    if (failFor.contains(videoId)) return null;
    return VideoMetadata(
      id: videoId,
      title: 'Название $videoId',
      author: 'Канал $videoId',
      duration: const Duration(minutes: 3, seconds: 20),
    );
  }
}

void main() {
  late InMemoryStore store;
  late LibraryController library;

  LibraryController buildController({Set<String> failFor = const {}}) {
    return LibraryController(
      repository: LibraryRepository(store),
      youtube: _FakeMetadata(failFor: failFor),
    );
  }

  setUp(() async {
    store = InMemoryStore();
    library = buildController();
    await library.load();
  });

  tearDown(() => library.dispose());

  group('добавление видео', () {
    test('пустая библиотека при загрузке', () {
      expect(library.isLoaded, isTrue);
      expect(library.videos, isEmpty);
      expect(library.collections, isEmpty);
    });

    test('addVideos создаёт карточки с метаданными', () async {
      final result = await library.addVideos([
        const VideoDraft(
          id: 'aaaaaaaaaaa',
          title: 'Название aaaaaaaaaaa',
          author: 'Канал',
          duration: Duration(minutes: 3, seconds: 20),
        ),
      ]);

      expect(result.added, 1);
      expect(library.videoCount, 1);
      final video = library.byId('aaaaaaaaaaa')!;
      expect(video.title, 'Название aaaaaaaaaaa');
      expect(video.durationSeconds, 200);
    });

    test('повторная ссылка не добавляется второй раз', () async {
      const draft = VideoDraft(id: 'aaaaaaaaaaa', title: 'Видео');
      await library.addVideos([draft]);
      final second = await library.addVideos([draft]);

      expect(second.added, 0);
      expect(second.duplicates, 1);
      expect(library.videoCount, 1);
    });

    test('видео без названия получает запасную подпись', () async {
      await library.addVideos([
        const VideoDraft(id: 'bbbbbbbbbbb', title: '  '),
      ]);
      expect(library.byId('bbbbbbbbbbb')!.title, contains('bbbbbbbbbbb'));
    });

    test('видео попадает сразу в выбранную коллекцию', () async {
      final collection = await library.createCollection(title: 'Мультики');
      await library.addVideos([
        const VideoDraft(id: 'ccccccccccc', title: 'Мульт'),
      ], collectionId: collection.id);
      expect(library.countOf(collection.id), 1);
      expect(library.videosOf(collection.id).single.id, 'ccccccccccc');
    });

    test('библиотека сохраняется между запусками', () async {
      await library.addVideos([
        const VideoDraft(id: 'ddddddddddd', title: 'Сохраняемое'),
      ]);

      final restarted = buildController();
      await restarted.load();
      expect(restarted.videoCount, 1);
      expect(restarted.byId('ddddddddddd')!.title, 'Сохраняемое');
      restarted.dispose();
    });
  });

  group('разбор вставленных ссылок', () {
    test('находит новые, повторные и некорректные', () async {
      await library.addVideos([
        const VideoDraft(id: 'aaaaaaaaaaa', title: 'Уже есть'),
      ]);

      final summary = library.parseLinks('''
        https://youtu.be/aaaaaaaaaaa
        https://youtu.be/bbbbbbbbbbb
        https://example.com/что-то
      ''');

      expect(summary.validIds, ['bbbbbbbbbbb']);
      expect(summary.duplicates, 1);
      expect(summary.invalid, 0);
    });

    test('непонятный текст помечается как некорректный', () {
      final summary = library.parseLinks('просто текст без ссылки');
      expect(summary.validIds, isEmpty);
      expect(summary.invalid, 1);
    });

    test('метаданные приходят от источника', () async {
      final metadata = await library.fetchMetadata('eeeeeeeeeee');
      expect(metadata?.title, 'Название eeeeeeeeeee');
    });

    test('сбой источника не мешает добавить видео вручную', () async {
      final offline = buildController(failFor: {'fffffffffff'});
      await offline.load();

      final metadata = await offline.fetchMetadata('fffffffffff');
      expect(metadata, isNull);

      final result = await offline.addVideos([
        VideoDraft.fallback('fffffffffff'),
      ]);
      expect(result.added, 1);
      offline.dispose();
    });
  });

  group('изменение видео', () {
    setUp(() async {
      await library.addVideos([
        const VideoDraft(id: 'aaaaaaaaaaa', title: 'Первое'),
        const VideoDraft(id: 'bbbbbbbbbbb', title: 'Второе'),
      ]);
    });

    test('переименование', () async {
      await library.renameVideo('aaaaaaaaaaa', 'Новое имя');
      expect(library.byId('aaaaaaaaaaa')!.title, 'Новое имя');
    });

    test('пустое имя не затирает прежнее', () async {
      await library.renameVideo('aaaaaaaaaaa', '   ');
      expect(library.byId('aaaaaaaaaaa')!.title, 'Первое');
    });

    test('избранное переключается', () async {
      await library.toggleFavorite('aaaaaaaaaaa');
      expect(library.favorites.map((v) => v.id), ['aaaaaaaaaaa']);
      await library.toggleFavorite('aaaaaaaaaaa');
      expect(library.favorites, isEmpty);
    });

    test('перенос в коллекцию и обратно', () async {
      final collection = await library.createCollection(title: 'Папка');
      await library.moveVideo('aaaaaaaaaaa', collection.id);
      expect(library.byId('aaaaaaaaaaa')!.collectionId, collection.id);

      await library.moveVideo('aaaaaaaaaaa', null);
      expect(library.byId('aaaaaaaaaaa')!.collectionId, isNull);
    });

    test('удаление убирает видео из всех списков', () async {
      await library.toggleFavorite('aaaaaaaaaaa');
      await library.deleteVideo('aaaaaaaaaaa');
      expect(library.byId('aaaaaaaaaaa'), isNull);
      expect(library.favorites, isEmpty);
      expect(library.videoCount, 1);
    });
  });

  group('прогресс и история', () {
    setUp(() async {
      await library.addVideos([
        const VideoDraft(
          id: 'aaaaaaaaaaa',
          title: 'Длинное',
          duration: Duration(minutes: 10),
        ),
        const VideoDraft(id: 'bbbbbbbbbbb', title: 'Второе'),
      ]);
    });

    test('прогресс не откатывается назад', () async {
      await library.recordProgress('aaaaaaaaaaa', positionSeconds: 120);
      await library.recordProgress('aaaaaaaaaaa', positionSeconds: 40);
      expect(library.byId('aaaaaaaaaaa')!.watchedSeconds, 120);
    });

    test('начатое видео попадает в «продолжить»', () async {
      await library.recordProgress('aaaaaaaaaaa', positionSeconds: 60);
      expect(library.inProgress.map((v) => v.id), contains('aaaaaaaaaaa'));
    });

    test('почти досмотренное считается законченным', () async {
      await library.recordProgress('aaaaaaaaaaa', positionSeconds: 595);
      expect(library.byId('aaaaaaaaaaa')!.isFinished, isTrue);
      expect(library.inProgress, isEmpty);
    });

    test('markFinished выставляет прогресс на всю длительность', () async {
      await library.markFinished('aaaaaaaaaaa');
      final video = library.byId('aaaaaaaaaaa')!;
      expect(video.watchedSeconds, video.durationSeconds);
    });

    test('история сортируется по времени просмотра', () async {
      await library.recordProgress('aaaaaaaaaaa', positionSeconds: 30);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await library.recordProgress('bbbbbbbbbbb', positionSeconds: 30);
      expect(library.history.first.id, 'bbbbbbbbbbb');
    });

    test('очистка истории сохраняет видео в библиотеке', () async {
      await library.recordProgress('aaaaaaaaaaa', positionSeconds: 30);
      await library.clearHistory();
      expect(library.history, isEmpty);
      expect(library.videoCount, 2);
      expect(library.byId('aaaaaaaaaaa')!.watchedSeconds, 0);
    });
  });

  group('коллекции', () {
    test('создание, изменение и удаление', () async {
      final collection = await library.createCollection(
        title: 'Учёба',
        emoji: '📚',
        colorIndex: 2,
      );
      expect(library.collections.single.title, 'Учёба');
      expect(library.collections.single.emoji, '📚');

      await library.updateCollection(collection.copyWith(title: 'Уроки'));
      expect(library.collections.single.title, 'Уроки');

      await library.deleteCollection(collection.id);
      expect(library.collections, isEmpty);
    });

    test('удаление коллекции не удаляет видео', () async {
      final collection = await library.createCollection(title: 'Папка');
      await library.addVideos([
        const VideoDraft(id: 'aaaaaaaaaaa', title: 'Видео'),
      ], collectionId: collection.id);

      await library.deleteCollection(collection.id);
      expect(library.videoCount, 1);
      expect(library.byId('aaaaaaaaaaa')!.collectionId, isNull);
    });

    test('пустое название заменяется на «Коллекция»', () async {
      final collection = await library.createCollection(title: '   ');
      expect(collection.title, 'Коллекция');
    });

    test('перестановка сохраняет порядок', () async {
      await library.createCollection(title: 'Первая');
      await library.createCollection(title: 'Вторая');
      await library.createCollection(title: 'Третья');

      await library.reorderCollections(2, 0);
      expect(library.collections.map((c) => c.title), [
        'Третья',
        'Первая',
        'Вторая',
      ]);
      expect(library.collections.map((c) => c.sortOrder), [0, 1, 2]);
    });
  });

  group('следующее видео', () {
    test('идёт по кругу внутри коллекции', () async {
      final collection = await library.createCollection(title: 'Папка');
      await library.addVideos([
        const VideoDraft(id: 'aaaaaaaaaaa', title: '1'),
        const VideoDraft(id: 'bbbbbbbbbbb', title: '2'),
      ], collectionId: collection.id);

      final first = library.videosOf(collection.id).last;
      final next = library.nextAfter(first);
      expect(next, isNotNull);
      expect(next!.id, isNot(first.id));
    });

    test('единственное видео не имеет следующего', () async {
      await library.addVideos([
        const VideoDraft(id: 'aaaaaaaaaaa', title: '1'),
      ]);
      expect(library.nextAfter(library.videos.first), isNull);
    });
  });

  group('полный сброс', () {
    test('удаляет видео и коллекции', () async {
      final collection = await library.createCollection(title: 'Папка');
      await library.addVideos([
        const VideoDraft(id: 'aaaaaaaaaaa', title: 'Видео'),
      ], collectionId: collection.id);

      await library.resetAll();
      expect(library.videos, isEmpty);
      expect(library.collections, isEmpty);

      final restarted = buildController();
      await restarted.load();
      expect(restarted.videos, isEmpty);
      restarted.dispose();
    });
  });

  group('VideoItem', () {
    test('переживает сериализацию', () {
      final video = VideoItem(
        id: 'aaaaaaaaaaa',
        title: 'Проверка',
        author: 'Канал',
        durationSeconds: 300,
        collectionId: 'col',
        favorite: true,
        addedAt: DateTime(2025, 1, 2, 3, 4),
        watchedSeconds: 42,
        lastWatchedAt: DateTime(2025, 1, 3, 5, 6),
      );

      final restored = VideoItem.fromJson(video.toJson())!;
      expect(restored.id, video.id);
      expect(restored.title, video.title);
      expect(restored.author, video.author);
      expect(restored.durationSeconds, video.durationSeconds);
      expect(restored.collectionId, video.collectionId);
      expect(restored.favorite, isTrue);
      expect(restored.watchedSeconds, 42);
      expect(restored.addedAt, video.addedAt);
      expect(restored.lastWatchedAt, video.lastWatchedAt);
    });

    test('битые данные не роняют приложение', () {
      expect(VideoItem.fromJson(null), isNull);
      expect(VideoItem.fromJson('строка'), isNull);
      expect(VideoItem.fromJson({'title': 'без id'}), isNull);
    });

    test('progress считается от длительности', () {
      final video = VideoItem(
        id: 'aaaaaaaaaaa',
        title: 'Видео',
        addedAt: DateTime.now(),
        durationSeconds: 100,
        watchedSeconds: 25,
      );
      expect(video.progress, 0.25);
      expect(video.isFinished, isFalse);
    });

    test('без длительности прогресс нулевой', () {
      final video = VideoItem(
        id: 'aaaaaaaaaaa',
        title: 'Видео',
        addedAt: DateTime.now(),
        watchedSeconds: 50,
      );
      expect(video.progress, 0);
    });
  });
}
