import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
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
            onAutoDownload: settings.setAutoDownload,
            onPreferLocal: settings.setPreferLocalPlayback,
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
    required this.onAutoDownload,
    required this.onPreferLocal,
  });

  final bool autoDownload;
  final bool preferLocal;
  final ValueChanged<bool> onAutoDownload;
  final ValueChanged<bool> onPreferLocal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Container(
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
