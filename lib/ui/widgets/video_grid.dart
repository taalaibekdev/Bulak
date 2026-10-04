import 'package:flutter/material.dart';

import '../../data/models/video_item.dart';
import 'video_card.dart';

/// Сколько колонок помещается на экране.
int videoGridColumns(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1280) return 5;
  if (width >= 980) return 4;
  if (width >= 680) return 3;
  return 2;
}

/// Сетка карточек видео в виде sliver — чтобы её можно было вставлять в
/// общий прокручиваемый экран рядом с заголовками и баннерами.
class VideoGridSliver extends StatelessWidget {
  const VideoGridSliver({
    super.key,
    required this.videos,
    required this.onTap,
    this.onFavorite,
    this.horizontalPadding = 16,
    this.spacing = 14,
  });

  final List<VideoItem> videos;
  final void Function(VideoItem video) onTap;
  final void Function(VideoItem video)? onFavorite;
  final double horizontalPadding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final columns = videoGridColumns(context);
    final width = MediaQuery.sizeOf(context).width;
    final tileWidth =
        (width - horizontalPadding * 2 - spacing * (columns - 1)) / columns;
    final imageHeight = tileWidth * 9 / 16;

    // Высоту текстовой части считаем из реального масштаба шрифта,
    // иначе при крупном системном шрифте заголовок обрезается.
    final scaler = MediaQuery.textScalerOf(context);
    final textHeight =
        scaler.scale(15) * 1.25 * 2 + scaler.scale(13) * 1.4 + 20;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: spacing + 6,
          crossAxisSpacing: spacing,
          mainAxisExtent: imageHeight + 12 + textHeight,
        ),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return VideoGridCard(
            video: video,
            onTap: () => onTap(video),
            onFavorite: onFavorite == null ? null : () => onFavorite!(video),
          );
        },
      ),
    );
  }
}

/// Горизонтальная лента крупных карточек — блок «Продолжить просмотр».
class VideoCarousel extends StatelessWidget {
  const VideoCarousel({
    super.key,
    required this.videos,
    required this.onTap,
    this.height = 210,
    this.horizontalPadding = 16,
  });

  final List<VideoItem> videos;
  final void Function(VideoItem video) onTap;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 680 ? 300.0 : 258.0;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: videos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final video = videos[index];
          return SizedBox(
            width: cardWidth,
            child: VideoGridCard(
              video: video,
              highlight: true,
              showFavoriteButton: false,
              onTap: () => onTap(video),
            ),
          );
        },
      ),
    );
  }
}
