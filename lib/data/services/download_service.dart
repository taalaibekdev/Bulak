import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/video_item.dart';
import 'youtube_service.dart';

/// Итог одной попытки скачать видео.
class DownloadResult {
  const DownloadResult._({
    required this.success,
    this.fileName,
    this.sizeBytes = 0,
    this.quality,
    this.cancelled = false,
  });

  const DownloadResult.success({
    required String fileName,
    required int sizeBytes,
    required String quality,
  }) : this._(
         success: true,
         fileName: fileName,
         sizeBytes: sizeBytes,
         quality: quality,
       );

  const DownloadResult.failure({bool cancelled = false})
    : this._(success: false, cancelled: cancelled);

  final bool success;
  final String? fileName;
  final int sizeBytes;
  final String? quality;
  final bool cancelled;
}

/// Хранение скачанных видео на устройстве.
///
/// Файлы лежат в каталоге поддержки приложения — он не попадает в резервные
/// копии и не виден другим приложениям. Имена файлов — это идентификатор
/// видео плюс расширение, поэтому путь нельзя «подделать» данными из ссылки.
class DownloadService {
  DownloadService({
    required VideoDownloadSource source,
    Future<Directory> Function()? directoryProvider,
  }) : _source = source,
       _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final VideoDownloadSource _source;
  final Future<Directory> Function() _directoryProvider;

  /// Подкаталог внутри каталога поддержки приложения.
  static const String folderName = 'media';

  /// Допустимые контейнеры. Всё остальное считаем mp4.
  static const Set<String> _allowedExtensions = {'mp4', 'webm', '3gpp', 'mkv'};

  /// Идентификатор видео безопасен как имя файла: только буквы, цифры, `-`, `_`.
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  Directory? _cachedDirectory;

  /// Каталог со скачанными файлами. Создаётся при первом обращении.
  Future<Directory> mediaDirectory() async {
    final cached = _cachedDirectory;
    if (cached != null) return cached;

    final base = await _directoryProvider();
    final directory = Directory(p.join(base.path, folderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _cachedDirectory = directory;
    return directory;
  }

  /// Имя файла для видео: `<идентификатор>.<расширение>`.
  static String fileNameFor(String videoId, String extension) =>
      '$videoId.${_normalizeExtension(extension)}';

  static String _normalizeExtension(String extension) {
    final clean = extension.toLowerCase().replaceAll('.', '');
    return _allowedExtensions.contains(clean) ? clean : 'mp4';
  }

  /// Файл по имени внутри каталога загрузок.
  Future<File> fileForName(String fileName) async {
    final directory = await mediaDirectory();
    return File(p.join(directory.path, p.basename(fileName)));
  }

  /// Файл видео, если оно действительно скачано и файл на месте.
  ///
  /// Если родитель удалил файл вручную, вернём `null` — приложение
  /// не должно показывать «скачано» там, где играть нечего.
  Future<File?> localFileFor(VideoItem video) async {
    final name = video.localFileName;
    if (name == null || name.isEmpty) return null;
    final file = await fileForName(name);
    return await file.exists() ? file : null;
  }

  /// Сведения о потоке: размер, формат, качество.
  Future<DownloadInfo?> info(String videoId) =>
      _source.fetchDownloadInfo(videoId);

  /// Скачивает видео целиком.
  ///
  /// Возвращает результат с именем файла и его размером. При отмене или
  /// ошибке недописанный файл удаляется.
  Future<DownloadResult> download(
    VideoItem video, {
    required void Function(int received, int total) onProgress,
    bool Function()? isCancelled,
  }) async {
    if (!_safeId.hasMatch(video.id)) {
      return const DownloadResult.failure();
    }

    final info = await _source.fetchDownloadInfo(video.id);
    if (info == null) return const DownloadResult.failure();

    final fileName = fileNameFor(video.id, info.extension);
    final file = await fileForName(fileName);

    // Если раньше файл был в другом контейнере, убираем старый.
    await _deleteSiblings(video.id, keep: fileName);

    final ok = await _source.downloadToFile(
      video.id,
      file,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );

    if (!ok) {
      // Недописанный файл удаляем здесь, а не только в источнике: сервис —
      // владелец каталога, и «полувидео» не должно пережить неудачу.
      await delete(fileName);
      return DownloadResult.failure(cancelled: isCancelled?.call() ?? false);
    }

    return DownloadResult.success(
      fileName: fileName,
      sizeBytes: await file.length(),
      quality: info.quality,
    );
  }

  /// Удаляет файл загрузки. Отсутствие файла ошибкой не считается.
  Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    try {
      final file = await fileForName(fileName);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Файла нет или он занят — для интерфейса это не ошибка.
    }
  }

  /// Сколько места занимают скачанные видео.
  Future<int> usedBytes() async {
    try {
      final directory = await mediaDirectory();
      var total = 0;
      await for (final entity in directory.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Удаляет все скачанные файлы. Возвращает, сколько освободилось байт.
  Future<int> deleteAll() async {
    final before = await usedBytes();
    try {
      final directory = await mediaDirectory();
      await for (final entity in directory.list()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {
            // Отдельный файл могли удалить параллельно — не мешаем остальным.
          }
        }
      }
    } catch (_) {
      // Каталога нет — значит и удалять нечего.
    }
    return before;
  }

  /// Список имён файлов, реально лежащих в каталоге загрузок.
  ///
  /// Нужен, чтобы почистить библиотеку от записей о файлах, которых больше нет.
  Future<Set<String>> existingFileNames() async {
    try {
      final directory = await mediaDirectory();
      final names = <String>{};
      await for (final entity in directory.list()) {
        if (entity is File) names.add(p.basename(entity.path));
      }
      return names;
    } catch (_) {
      return const {};
    }
  }

  Future<void> _deleteSiblings(String videoId, {required String keep}) async {
    try {
      final directory = await mediaDirectory();
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name == keep) continue;
        if (name.startsWith('$videoId.')) {
          try {
            await entity.delete();
          } catch (_) {
            // Не критично: файл всё равно будет перезаписан или удалён позже.
          }
        }
      }
    } catch (_) {
      // Каталога ещё нет — создастся при записи файла.
    }
  }
}
