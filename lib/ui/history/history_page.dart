import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../state/library_controller.dart';
import '../library/video_navigation.dart';
import '../shell/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/video_card.dart';

/// История просмотра — то, что ребёнок уже смотрел.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final history = library.history;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.historyTitle,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    if (history.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _clearHistory(context, library),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(strings.actionClear),
                      ),
                  ],
                ),
              ),
            ),
            if (history.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kShellBottomInset),
                  child: EmptyState(
                    emoji: '🕰️',
                    title: strings.historyEmptyTitle,
                    body: strings.historyEmptyBody,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  kShellBottomInset,
                ),
                sliver: SliverList.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final video = history[index];
                    final percent = Formatters.percent(video.progress);
                    final subtitle = video.isFinished
                        ? strings.historyWatchedToEnd
                        : percent > 0
                        ? strings.watchedPercent(percent)
                        : Formatters.relativeDate(
                            video.lastWatchedAt ?? video.addedAt,
                            strings,
                          );
                    return VideoListTile(
                      video: video,
                      subtitle: subtitle,
                      trailing: IconButton(
                        tooltip: strings.deleteVideoTitle,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: strings.deleteVideoTitle,
                            body: strings.deleteVideoBody,
                            destructive: true,
                            icon: Icons.delete_outline_rounded,
                          );
                          if (confirmed) await library.deleteVideo(video.id);
                        },
                      ),
                      onTap: () => openVideo(context, video),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearHistory(
    BuildContext context,
    LibraryController library,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.historyClearTitle,
      body: strings.historyClearBody,
      confirmLabel: strings.actionClear,
      icon: Icons.history_toggle_off_rounded,
    );
    if (!confirmed) return;
    await library.clearHistory();
    if (!context.mounted) return;
    showAppSnack(context, strings.actionDone, icon: Icons.check_rounded);
  }
}
