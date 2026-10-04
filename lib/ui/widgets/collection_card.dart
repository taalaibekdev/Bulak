import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/video_collection.dart';
import 'common.dart';

/// Плитка коллекции: крупный эмодзи на градиенте и число видео.
class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.videoCount,
    required this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final VideoCollection collection;
  final int videoCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.collectionGradient(collection.colorIndex);
    final theme = Theme.of(context);

    return BouncyTap(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: collection.title,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.34),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(collection.emoji, style: const TextStyle(fontSize: 34)),
                const Spacer(),
                ?trailing,
              ],
            ),
            const Spacer(),
            Text(
              collection.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.of(context).videosCount(videoCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Плитка «все видео без коллекции».
class AllVideosCard extends StatelessWidget {
  const AllVideosCard({
    super.key,
    required this.videoCount,
    required this.onTap,
    this.label,
  });

  final int videoCount;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return BouncyTap(
      onTap: onTap,
      semanticLabel: label ?? strings.homeAllVideos,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const Spacer(),
            Text(
              label ?? strings.homeAllVideos,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              strings.videosCount(videoCount),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
