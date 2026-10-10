import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/video_item.dart';
import '../../state/library_controller.dart';
import '../../state/settings_controller.dart';
import '../player/player_page.dart';
import '../player/prepare_video_page.dart';
import '../player/widgets/time_up_dialog.dart';

/// Открывает видео: проверяет лимит и, если нужно, сначала скачивает файл.
///
/// Проверки собраны в одном месте, чтобы их нельзя было случайно обойти
/// с любого экрана. Порядок такой:
///
/// 1. Если дневной лимит исчерпан — показываем добрый экран «На сегодня всё».
/// 2. Если приложение настроено играть только скачанное, а файла ещё нет —
///    открываем экран подготовки: он сам скачает видео и включит плеер.
/// 3. Иначе сразу открываем плеер.
Future<void> openVideo(BuildContext context, VideoItem video) async {
  final settings = context.read<SettingsController>();
  if (settings.isLimitReached) {
    await showTimeUpDialog(context);
    return;
  }

  final library = context.read<LibraryController>();
  final libraryVideo = library.byId(video.id) ?? video;

  if (settings.settings.requiresDownloadFirst && !libraryVideo.isDownloaded) {
    // Экран подготовки сам разберётся: скачать, показать прогресс, повторить
    // попытку после ошибки или сразу включить плеер, если файл уже готов.
    await Navigator.of(context).push(PrepareVideoPage.route(libraryVideo));
    return;
  }

  await Navigator.of(context).push(PlayerPage.route(libraryVideo));
}
