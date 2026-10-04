import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/youtube_link.dart';

/// Превью видео с «терпеливой» загрузкой.
///
/// YouTube отдаёт `maxresdefault.jpg` не для всех роликов, поэтому пробуем
/// несколько адресов по очереди, а если не вышло ни одного — показываем
/// симпатичную заглушку, а не серый прямоугольник.
class ThumbnailImage extends StatefulWidget {
  const ThumbnailImage({
    super.key,
    required this.videoId,
    this.overlay,
    this.borderRadius = 20,
    this.semanticLabel,
  });

  final String videoId;

  /// Что положить поверх картинки (значок длительности, сердечко и т.п.).
  final Widget? overlay;

  final double borderRadius;
  final String? semanticLabel;

  @override
  State<ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<ThumbnailImage> {
  late List<String> _candidates = YouTubeLink.thumbnailCandidates(
    widget.videoId,
  );
  int _index = 0;

  @override
  void didUpdateWidget(ThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _candidates = YouTubeLink.thumbnailCandidates(widget.videoId);
      _index = 0;
    }
  }

  void _nextCandidate() {
    if (_index >= _candidates.length - 1) return;
    // Нельзя менять состояние прямо во время сборки — переносим на кадр.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _index++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: _buildImage(),
          ),
          if (widget.overlay != null) widget.overlay!,
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_index >= _candidates.length) return _Fallback(videoId: widget.videoId);

    return CachedNetworkImage(
      imageUrl: _candidates[_index],
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (context, url) => const _Shimmer(),
      errorWidget: (context, url, error) {
        _nextCandidate();
        return const _Shimmer();
      },
    );
  }
}

/// Мягкое «дыхание» вместо спиннера — не пугает малышей.
class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            Color.alphaBlend(Colors.white.withValues(alpha: 0.35), base),
            base,
          ],
        ),
      ),
    );
  }
}

/// Заглушка, если превью не загрузилось совсем.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 54,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
