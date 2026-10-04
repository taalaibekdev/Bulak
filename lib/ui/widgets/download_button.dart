import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/video_item.dart';
import '../../state/download_controller.dart';
import '../../state/library_controller.dart';
import 'common.dart';

/// Кнопка «скачать / скачивается / скачано» для карточки видео.
///
/// Одно нажатие делает всё: ставит в очередь, отменяет загрузку или
/// предлагает удалить файл. Родителю не нужно искать настройки.
class DownloadButton extends StatelessWidget {
  const DownloadButton({super.key, required this.video, this.size = 44});

  final VideoItem video;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final controller = context.watch<DownloadController>();
    final library = context.watch<LibraryController>();

    // Состояние берём из библиотеки: она знает актуальную отметку о файле.
    final current = library.byId(video.id) ?? video;
    final task = controller.taskFor(video.id);

    if (task != null && task.isActive) {
      return Tooltip(
        message: strings.downloadCancelled,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => controller.cancel(video.id),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: size * 0.62,
                height: size * 0.62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: task.progress,
                      strokeWidth: 3,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                    Icon(
                      Icons.close_rounded,
                      size: size * 0.26,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (current.isDownloaded) {
      return Tooltip(
        message: strings.downloadRemove,
        child: IconButton(
          onPressed: () => _confirmRemove(context, controller, current),
          icon: const Icon(Icons.download_done_rounded),
          color: AppColors.mint,
        ),
      );
    }

    if (task?.state == DownloadState.failed) {
      return Tooltip(
        message: strings.downloadFailed,
        child: IconButton(
          onPressed: () => controller.enqueue(current),
          icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.error),
        ),
      );
    }

    return Tooltip(
      message: strings.downloadAction,
      child: IconButton(
        onPressed: () => controller.enqueue(current),
        icon: const Icon(Icons.download_rounded),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    DownloadController controller,
    VideoItem video,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.downloadRemove,
      body: strings.downloadStorageTitle,
      confirmLabel: strings.actionDelete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    await controller.removeDownload(video);
  }
}

/// Значок «скачано» для карточек и списков.
class DownloadedBadge extends StatelessWidget {
  const DownloadedBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Icon(
        Icons.download_done_rounded,
        size: 16,
        color: AppColors.mint,
      );
    }
    return PillBadge(
      label: AppStrings.of(context).downloadBadge,
      icon: Icons.download_done_rounded,
      background: AppColors.mint,
    );
  }
}
