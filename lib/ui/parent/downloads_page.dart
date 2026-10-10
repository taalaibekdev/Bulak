import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/video_item.dart';
import '../../state/download_controller.dart';
import '../../state/library_controller.dart';
import '../../state/settings_controller.dart';
import '../library/video_navigation.dart';
import '../widgets/common.dart';
import '../widgets/video_card.dart';

/// Экран «Загрузки»: сколько занято, что скачано и как этим управлять.
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const DownloadsPage());

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DownloadController>().refreshStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final controller = context.watch<DownloadController>();
    final settings = context.watch<SettingsController>();

    final downloaded = library.downloaded;
    final usedBytes = controller.storageBytes > 0
        ? controller.storageBytes
        : library.downloadedBytes;

    return Scaffold(
      appBar: AppBar(title: Text(strings.downloadsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _StorageCard(
            used: Formatters.bytes(usedBytes),
            count: downloaded.length,
            active: controller.activeCount,
            onDownloadAll: () {
              final pending = library.videos
                  .where((video) => !video.isDownloaded)
                  .toList();
              if (pending.isEmpty) return;
              controller.enqueueAll(pending);
              showAppSnack(
                context,
                strings.downloadQueued(pending.length),
                icon: Icons.download_rounded,
              );
            },
            onDeleteAll: downloaded.isEmpty
                ? null
                : () => _confirmDeleteAll(context, controller),
          ),
          const SizedBox(height: 14),
          _SettingsCard(
            autoDownload: settings.settings.autoDownload,
            preferLocal: settings.settings.preferLocalPlayback,
            playbackSource: settings.settings.playbackSource,
            onAutoDownload: settings.setAutoDownload,
            onPreferLocal: settings.setPreferLocalPlayback,
            onPlaybackSource: settings.setPlaybackSource,
          ),
          const SizedBox(height: 14),
          _LegalNote(text: strings.downloadLegalNote),
          const SizedBox(height: 20),
          if (downloaded.isEmpty)
            EmptyState(
              emoji: '📥',
              title: strings.downloadsTitle,
              body: strings.downloadEmpty,
              compact: true,
            )
          else ...[
            SectionHeader(
              title: strings.downloadsTitle,
              icon: Icons.download_done_rounded,
            ),
            for (final video in downloaded)
              _DownloadedRow(video: video, controller: controller),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll(
    BuildContext context,
    DownloadController controller,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.downloadRemoveAll,
      body: strings.downloadLegalNote,
      confirmLabel: strings.actionDelete,
      destructive: true,
      icon: Icons.delete_sweep_rounded,
    );
    if (!confirmed) return;
    await controller.removeAllDownloads();
    if (!context.mounted) return;
    showAppSnack(context, strings.actionDone, icon: Icons.check_rounded);
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.used,
    required this.count,
    required this.active,
    required this.onDownloadAll,
    required this.onDeleteAll,
  });

  final String used;
  final int count;
  final int active;
  final VoidCallback onDownloadAll;
  final VoidCallback? onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.downloadStorageTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                used,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  strings.videosCount(count),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (active > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  strings.downloadQueued(active),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onDownloadAll,
                icon: const Icon(Icons.download_rounded),
                label: Text(strings.downloadAllAction),
              ),
              OutlinedButton.icon(
                onPressed: onDeleteAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_sweep_rounded),
                label: Text(strings.downloadRemoveAll),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.wifi_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.downloadWifiHint,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.autoDownload,
    required this.preferLocal,
    required this.playbackSource,
    required this.onAutoDownload,
    required this.onPreferLocal,
    required this.onPlaybackSource,
  });

  final bool autoDownload;
  final bool preferLocal;
  final PlaybackSource playbackSource;
  final ValueChanged<bool> onAutoDownload;
  final ValueChanged<bool> onPreferLocal;
  final ValueChanged<PlaybackSource> onPlaybackSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    // Выбор источника — главная настройка этого экрана, поэтому он сверху
    // и в виде понятных вариантов, а не переключателя «да/нет».
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.playbackSourceTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _SourceOption(
                icon: Icons.download_done_rounded,
                title: strings.playbackSourceDownloaded,
                body: strings.playbackSourceDownloadedBody,
                selected: playbackSource == PlaybackSource.downloaded,
                onTap: () => onPlaybackSource(PlaybackSource.downloaded),
              ),
              const SizedBox(height: 8),
              _SourceOption(
                icon: Icons.stream_rounded,
                title: strings.playbackSourceStream,
                body: strings.playbackSourceStreamBody,
                selected: playbackSource == PlaybackSource.stream,
                onTap: () => onPlaybackSource(PlaybackSource.stream),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: autoDownload,
                onChanged: onAutoDownload,
                title: Text(strings.downloadAutoTitle),
                subtitle: Text(strings.downloadAutoBody),
                secondary: Icon(
                  Icons.download_for_offline_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: preferLocal,
                onChanged: onPreferLocal,
                title: Text(strings.downloadPreferLocalTitle),
                subtitle: Text(strings.downloadPreferLocalBody),
                secondary: Icon(
                  Icons.offline_bolt_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Один из вариантов «откуда играть видео».
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.greenDark.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.greenDark : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.greenDark
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.greenDark,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalNote extends StatelessWidget {
  const _LegalNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sunny.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadedRow extends StatelessWidget {
  const _DownloadedRow({required this.video, required this.controller});

  final VideoItem video;
  final DownloadController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final size = video.fileSizeBytes;

    return VideoListTile(
      video: video,
      subtitle: [
        if (size != null && size > 0) Formatters.bytes(size),
        if (video.downloadQuality != null && video.downloadQuality!.isNotEmpty)
          video.downloadQuality!,
        strings.downloadPlaying,
      ].join(' · '),
      onTap: () => openVideo(context, video),
      trailing: IconButton(
        tooltip: strings.downloadRemove,
        onPressed: () => controller.removeDownload(video),
        icon: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
