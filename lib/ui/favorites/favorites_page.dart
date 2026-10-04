import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../state/library_controller.dart';
import '../library/video_navigation.dart';
import '../shell/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/video_grid.dart';

/// Избранное: видео, которые ребёнок отметил сердечком.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final favorites = library.favorites;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text(
                  strings.favoritesTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
            if (favorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: kShellBottomInset),
                  child: EmptyState(
                    emoji: '💛',
                    title: strings.favoritesEmptyTitle,
                    body: strings.favoritesEmptyBody,
                  ),
                ),
              )
            else
              VideoGridSliver(
                videos: favorites,
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
            const SliverToBoxAdapter(
              child: SizedBox(height: kShellBottomInset),
            ),
          ],
        ),
      ),
    );
  }
}
