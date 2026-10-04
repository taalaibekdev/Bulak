import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/video_collection.dart';
import '../../state/library_controller.dart';
import '../library/video_navigation.dart';
import '../widgets/common.dart';
import '../widgets/video_grid.dart';

/// Все видео одной коллекции.
class CollectionDetailPage extends StatelessWidget {
  const CollectionDetailPage({super.key, required this.collection});

  final VideoCollection collection;

  static Route<void> route(VideoCollection collection) =>
      MaterialPageRoute<void>(
        builder: (_) => CollectionDetailPage(collection: collection),
      );

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final videos = library.videosOf(collection.id);
    final colors = AppColors.collectionGradient(collection.colorIndex);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: colors.first,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 14),
              title: Text(
                collection.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    collection.emoji,
                    style: const TextStyle(fontSize: 68),
                  ),
                ),
              ),
            ),
          ),
          if (videos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                emoji: '🫧',
                title: strings.homeEmptyTitle,
                body: strings.collectionsEmptyBody,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  strings.videosCount(videos.length),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            VideoGridSliver(
              videos: videos,
              horizontalPadding: 20,
              onTap: (video) => openVideo(context, video),
              onFavorite: (video) => library.toggleFavorite(video.id),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

/// Заголовок страницы с эмодзи коллекции — используется и в других местах.
class CollectionHeader extends StatelessWidget {
  const CollectionHeader({super.key, required this.collection});

  final VideoCollection collection;

  @override
  Widget build(BuildContext context) {
    return EmojiTitle(emoji: collection.emoji, title: collection.title);
  }
}

/// Отступ снизу, чтобы контент не упирался в край.
const double kListBottomInset = 40;
