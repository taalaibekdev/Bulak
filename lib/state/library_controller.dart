import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../core/utils/youtube_link.dart';
import '../data/models/video_collection.dart';
import '../data/models/video_item.dart';
import '../data/repositories/library_repository.dart';
import '../data/services/youtube_service.dart';

/// Заготовка видео для добавления в библиотеку.
class VideoDraft {
  const VideoDraft({
    required this.id,
    required this.title,
    this.author,
    this.duration,
  });

  final String id;
  final String title;
  final String? author;
  final Duration? duration;

  factory VideoDraft.fromMetadata(VideoMetadata metadata) => VideoDraft(
    id: metadata.id,
    title: metadata.title,
    author: metadata.author,
    duration: metadata.duration,
  );

  factory VideoDraft.fallback(String id) =>
      VideoDraft(id: id, title: VideoMetadata.fallbackTitle(id));
}

/// Что получилось из попытки добавить ссылки.
class AddVideosResult {
  const AddVideosResult({
    this.added = 0,
    this.duplicates = 0,
    this.invalid = 0,
    this.limitReached = false,
  });

  final int added;
  final int duplicates;
  final int invalid;
  final bool limitReached;

  bool get hasChanges => added > 0;
}

/// Библиотека ребёнка: видео, коллекции, избранное и история просмотра.
///
/// История не хранится отдельно — ею становится дата последнего просмотра
/// у самого видео. Так удаление видео автоматически чистит и историю, и
/// не бывает «висячих» записей.
class LibraryController extends ChangeNotifier {
  // Приватные поля нельзя объявить через `this._repository` в именованных
  // параметрах, поэтому присваиваем явно.
  LibraryController({
    required LibraryRepository repository,
    required VideoMetadataSource youtube,
  }) : // ignore: prefer_initializing_formals
       _repository = repository,
       // ignore: prefer_initializing_formals
       _youtube = youtube;

  final LibraryRepository _repository;
  final VideoMetadataSource _youtube;

  final List<VideoItem> _videos = [];
  final List<VideoCollection> _collections = [];

  bool _isLoaded = false;
  bool _isDisposed = false;

  bool get isLoaded => _isLoaded;

  /// Все видео, новые сверху.
  List<VideoItem> get videos {
    final list = [..._videos];
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return List.unmodifiable(list);
  }

  List<VideoCollection> get collections => List.unmodifiable(_collections);

  /// Коллекция по идентификатору (или `null`, если видео без коллекции).
  VideoCollection? collectionById(String? id) {
    if (id == null) return null;
    for (final collection in _collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  bool get isEmpty => _videos.isEmpty;

  int get videoCount => _videos.length;

  VideoItem? byId(String id) {
    for (final video in _videos) {
      if (video.id == id) return video;
    }
    return null;
  }

  bool contains(String id) => byId(id) != null;

  List<VideoItem> videosOf(String? collectionId) {
    final list =
        _videos.where((video) => video.collectionId == collectionId).toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return List.unmodifiable(list);
  }

  int countOf(String collectionId) =>
      _videos.where((video) => video.collectionId == collectionId).length;

  /// Избранное: свежие сверху.
  List<VideoItem> get favorites {
    final list = _videos.where((video) => video.favorite).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return List.unmodifiable(list);
  }

  /// История: то, что смотрели, последние — сверху.
  List<VideoItem> get history {
    final list = _videos.where((video) => video.lastWatchedAt != null).toList()
      ..sort((a, b) => b.lastWatchedAt!.compareTo(a.lastWatchedAt!));
    return List.unmodifiable(list);
  }

  /// Незаконченные видео — блок «Продолжить» на главной.
  List<VideoItem> get inProgress {
    final list = _videos.where((video) => video.isInProgress).toList()
      ..sort((a, b) {
        final aDate = a.lastWatchedAt ?? a.addedAt;
        final bDate = b.lastWatchedAt ?? b.addedAt;
        return bDate.compareTo(aDate);
      });
    return List.unmodifiable(list.take(12).toList());
  }

  /// Видео, рекомендованное к показу после текущего: следующее в той же
  /// коллекции, иначе — следующее в библиотеке. Порядок всегда предсказуем,
  /// никаких «рекомендаций» из сети.
  VideoItem? nextAfter(VideoItem current) {
    final pool = current.collectionId == null
        ? videos
        : videosOf(current.collectionId);
    if (pool.length < 2) return null;
    final index = pool.indexWhere((video) => video.id == current.id);
    if (index == -1) return pool.first;
    return pool[(index + 1) % pool.length];
  }

  // --- Загрузка ----------------------------------------------------------

  Future<void> load() async {
    final data = await _repository.load();
    _videos
      ..clear()
      ..addAll(data.videos);
    _collections
      ..clear()
      ..addAll(data.collections);
    _isLoaded = true;
    _notify();
  }

  // --- Добавление видео --------------------------------------------------

  /// Разбирает вставленный родителем текст: сколько ссылок, какие повторные.
  LinkParseSummary parseLinks(String rawText) {
    final ids = YouTubeLink.extractMany(rawText);
    final fresh = <String>[];
    var duplicates = 0;
    for (final id in ids) {
      if (contains(id)) {
        duplicates++;
      } else if (!fresh.contains(id)) {
        fresh.add(id);
      }
    }
    final trimmed = rawText.trim();
    final invalid = ids.isEmpty && trimmed.isNotEmpty ? 1 : 0;
    return LinkParseSummary(
      validIds: fresh,
      duplicates: duplicates,
      invalid: invalid,
    );
  }

  /// Догружает метаданные для ссылки (название, автор, длительность).
  Future<VideoMetadata?> fetchMetadata(String videoId) =>
      _youtube.fetchMetadata(videoId);

  /// Добавляет подготовленные видео в библиотеку.
  Future<AddVideosResult> addVideos(
    List<VideoDraft> drafts, {
    String? collectionId,
  }) async {
    var added = 0;
    var duplicates = 0;
    var limitReached = false;

    for (final draft in drafts) {
      if (contains(draft.id)) {
        duplicates++;
        continue;
      }
      if (_videos.length >= AppConfig.maxVideos) {
        limitReached = true;
        break;
      }
      _videos.add(
        VideoItem(
          id: draft.id,
          title: draft.title.trim().isEmpty
              ? VideoMetadata.fallbackTitle(draft.id)
              : draft.title.trim(),
          author: draft.author,
          durationSeconds: draft.duration?.inSeconds,
          collectionId: collectionId,
          addedAt: DateTime.now(),
        ),
      );
      added++;
    }

    if (added > 0) {
      await _repository.saveVideos(videos);
      _notify();
    }

    return AddVideosResult(
      added: added,
      duplicates: duplicates,
      limitReached: limitReached,
    );
  }

  // --- Изменение видео ---------------------------------------------------

  Future<void> updateVideo(VideoItem video) async {
    final index = _videos.indexWhere((item) => item.id == video.id);
    if (index == -1) return;
    _videos[index] = video;
    await _repository.saveVideos(videos);
    _notify();
  }

  Future<void> renameVideo(String id, String title) async {
    final video = byId(id);
    if (video == null) return;
    final clean = title.trim();
    await updateVideo(
      video.copyWith(title: clean.isEmpty ? video.title : clean),
    );
  }

  Future<void> moveVideo(String id, String? collectionId) async {
    final video = byId(id);
    if (video == null) return;
    await updateVideo(video.copyWith(collectionId: collectionId));
  }

  Future<void> toggleFavorite(String id) async {
    final video = byId(id);
    if (video == null) return;
    await updateVideo(video.copyWith(favorite: !video.favorite));
  }

  Future<void> deleteVideo(String id) async {
    _videos.removeWhere((video) => video.id == id);
    await _repository.saveVideos(videos);
    _notify();
  }

  /// Сохраняет позицию просмотра: вызывается плеером при паузе, выходе и
  /// раз в несколько секунд во время просмотра.
  Future<void> recordProgress(String id, {required int positionSeconds}) async {
    final index = _videos.indexWhere((video) => video.id == id);
    if (index == -1) return;
    final video = _videos[index];
    // Прогресс не должен «откатываться» назад: ребёнок может перемотать
    // в начало, но полоска «продолжить» останется на максимуме.
    final progress = positionSeconds > video.watchedSeconds
        ? positionSeconds
        : video.watchedSeconds;
    _videos[index] = video.copyWith(
      watchedSeconds: progress,
      lastWatchedAt: DateTime.now(),
    );
    await _repository.saveVideos(videos);
    _notify();
  }

  Future<void> markFinished(String id) async {
    final video = byId(id);
    if (video == null) return;
    await updateVideo(
      video.copyWith(
        watchedSeconds: video.durationSeconds ?? video.watchedSeconds,
        lastWatchedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearHistory() async {
    var changed = false;
    for (var i = 0; i < _videos.length; i++) {
      final video = _videos[i];
      if (video.lastWatchedAt == null && video.watchedSeconds == 0) continue;
      _videos[i] = video.copyWith(watchedSeconds: 0, lastWatchedAt: null);
      changed = true;
    }
    if (!changed) return;
    await _repository.saveVideos(videos);
    _notify();
  }

  // --- Коллекции ---------------------------------------------------------

  Future<VideoCollection> createCollection({
    required String title,
    String emoji = '🎬',
    int colorIndex = 0,
  }) async {
    final collection = VideoCollection(
      id: _newCollectionId(),
      title: title.trim().isEmpty ? 'Коллекция' : title.trim(),
      emoji: emoji,
      colorIndex: colorIndex,
      sortOrder: _collections.length,
      createdAt: DateTime.now(),
    );
    _collections.add(collection);
    await _repository.saveCollections(collections);
    _notify();
    return collection;
  }

  Future<void> updateCollection(VideoCollection collection) async {
    final index = _collections.indexWhere((item) => item.id == collection.id);
    if (index == -1) return;
    _collections[index] = collection;
    await _repository.saveCollections(collections);
    _notify();
  }

  /// Удаляет коллекцию. Видео не теряются — они становятся «без коллекции».
  Future<void> deleteCollection(String id) async {
    _collections.removeWhere((collection) => collection.id == id);
    for (var i = 0; i < _videos.length; i++) {
      if (_videos[i].collectionId == id) {
        _videos[i] = _videos[i].copyWith(collectionId: null);
      }
    }
    await _repository.saveCollections(collections);
    await _repository.saveVideos(videos);
    _notify();
  }

  Future<void> reorderCollections(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _collections.length) return;
    final target = newIndex.clamp(0, _collections.length - 1);
    final item = _collections.removeAt(oldIndex);
    _collections.insert(target, item);
    for (var i = 0; i < _collections.length; i++) {
      _collections[i] = _collections[i].copyWith(sortOrder: i);
    }
    await _repository.saveCollections(collections);
    _notify();
  }

  // --- Сброс -------------------------------------------------------------

  Future<void> resetAll() async {
    _videos.clear();
    _collections.clear();
    await _repository.clear();
    _notify();
  }

  // --- Служебное ---------------------------------------------------------

  String _newCollectionId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = DateTime.now().millisecond.toRadixString(36);
    var id = 'c$now$random';
    var counter = 0;
    while (_collections.any((collection) => collection.id == id)) {
      counter++;
      id = 'c$now$random$counter';
    }
    return id;
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Результат разбора вставленного текста со ссылками.
class LinkParseSummary {
  const LinkParseSummary({
    required this.validIds,
    required this.duplicates,
    required this.invalid,
  });

  /// Новые идентификаторы, которых ещё нет в библиотеке.
  final List<String> validIds;

  /// Сколько ссылок уже было в библиотеке.
  final int duplicates;

  /// Сколько строк не удалось разобрать.
  final int invalid;

  bool get isEmpty => validIds.isEmpty;
}
