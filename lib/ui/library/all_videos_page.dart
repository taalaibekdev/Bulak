import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../state/library_controller.dart';
import '../widgets/common.dart';
import '../widgets/video_grid.dart';
import 'video_navigation.dart';

/// Полный список библиотеки — открывается с плитки «Все видео».
class AllVideosPage extends StatelessWidget {
  const AllVideosPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const AllVideosPage());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final library = context.watch<LibraryController>();
    final videos = library.videos;

    return Scaffold(
      appBar: AppBar(title: Text(strings.homeAllVideos), centerTitle: false),
      body: videos.isEmpty
          ? EmptyState(
              emoji: '🌱',
              title: strings.homeEmptyTitle,
              body: strings.homeEmptyBody,
            )
          : CustomScrollView(
              slivers: [
                VideoGridSliver(
                  videos: videos,
                  horizontalPadding: 16,
                  onTap: (video) => openVideo(context, video),
                  onFavorite: (video) {
                    library.toggleFavorite(video.id);
                    showAppSnack(
                      context,
                      video.favorite
                          ? strings.favoriteRemoved
                          : strings.favoriteAdded,
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }
}
