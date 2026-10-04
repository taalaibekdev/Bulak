import '../models/video_collection.dart';
import '../models/video_item.dart';
import '../storage/key_value_store.dart';

/// Содержимое библиотеки: видео и коллекции.
class LibraryData {
  const LibraryData({this.videos = const [], this.collections = const []});

  final List<VideoItem> videos;
  final List<VideoCollection> collections;
}

/// Хранение библиотеки на устройстве.
///
/// Формат — простой JSON в `shared_preferences`. Для пары тысяч ссылок этого
/// достаточно, а зависимостей и миграций получается минимум. Версия в имени
/// ключа позволяет позже поменять формат без потери данных.
class LibraryRepository {
  LibraryRepository(this._store);

  final KeyValueStore _store;

  static const String videosKey = 'bulak.videos.v1';
  static const String collectionsKey = 'bulak.collections.v1';

  Future<LibraryData> load() async {
    return LibraryData(videos: _loadVideos(), collections: _loadCollections());
  }

  List<VideoItem> _loadVideos() {
    final items = <VideoItem>[];
    final seen = <String>{};
    for (final raw in _store.readList(videosKey)) {
      final video = VideoItem.fromJson(raw);
      if (video == null) continue;
      if (!seen.add(video.id)) continue; // защита от дублей в старых данных
      items.add(video);
    }
    return items;
  }

  List<VideoCollection> _loadCollections() {
    final items = <VideoCollection>[];
    final seen = <String>{};
    for (final raw in _store.readList(collectionsKey)) {
      final collection = VideoCollection.fromJson(raw);
      if (collection == null) continue;
      if (!seen.add(collection.id)) continue;
      items.add(collection);
    }
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  Future<void> saveVideos(List<VideoItem> videos) => _store.writeJson(
    videosKey,
    videos.map((video) => video.toJson()).toList(),
  );

  Future<void> saveCollections(List<VideoCollection> collections) =>
      _store.writeJson(
        collectionsKey,
        collections.map((collection) => collection.toJson()).toList(),
      );

  Future<void> save(LibraryData data) async {
    await saveVideos(data.videos);
    await saveCollections(data.collections);
  }

  Future<void> clear() async {
    await _store.remove(videosKey);
    await _store.remove(collectionsKey);
  }
}
