import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/video_item.dart';
import 'common.dart';
import 'thumbnail_image.dart';

/// Карточка видео для сетки на главной.
class VideoGridCard extends StatelessWidget {
  const VideoGridCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onFavorite,
    this.onLongPress,
    this.showFavoriteButton = true,
    this.highlight = false,
  });

  final VideoItem video;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onLongPress;
  final bool showFavoriteButton;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final duration = Formatters.duration(video.duration);

    return BouncyTap(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: video.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (highlight ? AppColors.blue : Colors.black)
                              .withValues(alpha: highlight ? 0.28 : 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ThumbnailImage(
                    videoId: video.id,
                    overlay: Stack(
                      children: [
                        // Кнопка «смотреть» в центре — понятная даже малышу.
                        Center(
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        if (duration.isNotEmpty)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: PillBadge(label: duration),
                          ),
                        if (video.isInProgress)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _ProgressStrip(value: video.progress),
                          ),
                        if (video.isFinished)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: PillBadge(
                              label: strings.historyWatchedToEnd,
                              icon: Icons.check_rounded,
                              background: AppColors.mint,
                            ),
                          ),
                        // Значок «скачано»: родитель сразу видит, что видео
                        // сыграет без интернета.
                        if (video.isDownloaded && !video.isFinished)
                          Positioned(
                            left: 8,
                            top: 6,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.42),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.download_done_rounded,
                                size: 17,
                                color: AppColors.mint,
                              ),
                            ),
                          ),
                        if (showFavoriteButton && onFavorite != null)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: _FavoriteButton(
                              isFavorite: video.favorite,
                              onPressed: onFavorite!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(height: 1.25),
          ),
          if (video.author != null) ...[
            const SizedBox(height: 2),
            Text(
              video.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Строка видео — для истории, избранного и списков родителя.
class VideoListTile extends StatelessWidget {
  const VideoListTile({
    super.key,
    required this.video,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.onFavorite,
    this.leadingWidth = 124,
  });

  final VideoItem video;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onFavorite;
  final double leadingWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = Formatters.duration(video.duration);

    return BouncyTap(
      onTap: onTap,
      semanticLabel: video.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: leadingWidth,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ThumbnailImage(
                  videoId: video.id,
                  borderRadius: 14,
                  overlay: Stack(
                    children: [
                      if (duration.isNotEmpty)
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: PillBadge(label: duration),
                        ),
                      if (video.isInProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _ProgressStrip(value: video.progress),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ??
                        (video.author ??
                            Formatters.relativeDate(
                              video.lastWatchedAt ?? video.addedAt,
                              AppStrings.of(context),
                            )),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ] else if (onFavorite != null)
              IconButton(
                onPressed: onFavorite,
                tooltip: AppStrings.of(context).favoritesTitle,
                icon: Icon(
                  video.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: video.favorite
                      ? AppColors.coral
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Полоска просмотра внизу превью.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      color: Colors.black.withValues(alpha: 0.35),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.02, 1.0),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: AppColors.coral),
        ),
      ),
    );
  }
}

/// Сердечко «в избранное» на карточке.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey(isFavorite),
              size: 21,
              color: isFavorite ? AppColors.coral : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
