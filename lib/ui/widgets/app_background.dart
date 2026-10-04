import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Фон приложения: мягкий градиент и «пузыри».
///
/// Обычный серый фон делает интерфейс казённым, а лёгкие цветные пятна
/// создают ощущение мультика и при этом не мешают читать текст.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.blobs = true});

  final Widget child;
  final bool blobs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: base)),
        if (blobs) ...[
          Positioned(
            top: -120,
            left: -80,
            child: _Blob(
              size: 300,
              color: AppColors.sky.withValues(alpha: isDark ? 0.20 : 0.30),
            ),
          ),
          Positioned(
            top: -60,
            right: -110,
            child: _Blob(
              size: 260,
              color: AppColors.violet.withValues(alpha: isDark ? 0.18 : 0.22),
            ),
          ),
          if (isDark)
            Positioned(
              bottom: -140,
              left: -60,
              child: _Blob(
                size: 320,
                color: AppColors.blue.withValues(alpha: 0.16),
              ),
            ),
        ],
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
