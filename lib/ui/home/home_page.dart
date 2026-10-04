import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video_collection.dart';
import '../../state/library_controller.dart';
import '../../state/settings_controller.dart';
import '../collections/collection_detail_page.dart';
import '../library/video_navigation.dart';
import '../shell/app_shell.dart';
import '../widgets/brand_mark.dart';
import '../widgets/common.dart';
import '../widgets/video_grid.dart';

/// Главный экран ребёнка: приветствие, «Продолжить», коллекции и библиотека.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final settings = context.watch<SettingsController>().settings;

    final videos = library.videos;
    final inProgress = library.inProgress;
    final collections = library.collections;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                onParentTap: () => AppShell.of(context)?.openParents(),
              ),
            ),
            if (settings.hasDailyLimit)
              SliverToBoxAdapter(
                child: _TimeLimitBanner(
                  remaining: settings.remainingToday,
                  isReached: settings.isLimitReached,
                ),
              ),
            if (videos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kShellBottomInset),
                  child: EmptyState(
                    emoji: '🌱',
                    title: strings.homeEmptyTitle,
                    body: strings.homeEmptyBody,
                    action: FilledButton.icon(
                      onPressed: () => AppShell.of(context)?.openParents(),
                      icon: const Icon(Icons.lock_open_rounded),
                      label: Text(strings.parentAddVideo),
                    ),
                  ),
                ),
              )
            else ...[
              if (inProgress.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: strings.homeContinueWatching,
                      icon: Icons.play_circle_fill_rounded,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: VideoCarousel(
                    videos: inProgress,
                    onTap: (video) => openVideo(context, video),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 26)),
              ],
              if (collections.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: strings.collectionsTitle,
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CollectionsStrip(
                    collections: collections,
                    countOf: library.countOf,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 26)),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: strings.homeAllVideos,
                    icon: Icons.video_library_rounded,
                  ),
                ),
              ),
              VideoGridSliver(
                videos: videos,
                horizontalPadding: 20,
                onTap: (video) => openVideo(context, video),
                onFavorite: (video) {
                  library.toggleFavorite(video.id);
                  showAppSnack(
                    context,
                    video.favorite
                        ? strings.favoriteRemoved
                        : strings.favoriteAdded,
                    icon: video.favorite
                        ? Icons.favorite_border_rounded
                        : Icons.favorite_rounded,
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: kShellBottomInset),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onParentTap});

  final VoidCallback onParentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 46),
              const SizedBox(width: 12),
              Text(
                strings.appName,
                style: AppTheme.brandStyle(
                  size: Formatters.adaptive(context, 28),
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              RoundIconButton(
                icon: Icons.lock_outline_rounded,
                tooltip: strings.navParents,
                onPressed: onParentTap,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            Formatters.greeting(strings),
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: Formatters.adaptive(context, 30),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.homeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Горизонтальная лента коллекций на главной.
class _CollectionsStrip extends StatelessWidget {
  const _CollectionsStrip({required this.collections, required this.countOf});

  final List<VideoCollection> collections;
  final int Function(String) countOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: collections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final collection = collections[index];
          final colors = AppColors.collectionGradient(collection.colorIndex);
          return SizedBox(
            width: 190,
            child: BouncyTap(
              semanticLabel: collection.title,
              onTap: () =>
                  Navigator.of(context)
                      .push(CollectionDetailPage.route(collection)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                    const Spacer(),
                    Text(
                      collection.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.videosCount(countOf(collection.id)),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Полоска-напоминание о дневном лимите времени.
class _TimeLimitBanner extends StatelessWidget {
  const _TimeLimitBanner({required this.remaining, required this.isReached});

  final Duration? remaining;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    final seconds = remaining?.inSeconds ?? 0;
    final minutes = seconds <= 0 ? 0 : ((seconds + 59) ~/ 60);
    final label = isReached
        ? strings.timeLimitExhausted
        : strings.minutesLeft(minutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (isReached ? theme.colorScheme.error : AppColors.mint)
              .withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              isReached ? Icons.nightlight_round : Icons.timer_outlined,
              color: isReached ? theme.colorScheme.error : AppColors.mint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isReached ? theme.colorScheme.error : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
