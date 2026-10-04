import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Логотип приложения, нарисованный кодом.
///
/// Векторный знак всегда резкий на любом экране и не требует картинки
/// в ассетах, поэтому его можно ставить в шапку без опаски.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: CustomPaint(painter: _BrandMarkPainter(), size: Size.square(size)),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 100;

    // Капля-родник: мягкий блик в левом верхнем углу.
    final gloss = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(32 * unit, 28 * unit), 18 * unit, gloss);

    // Треугольник «играть» — оптически сдвинут вправо, иначе кажется смещённым.
    final center = Offset(53 * unit, size.height / 2);
    final width = 30 * unit;
    final height = 36 * unit;

    final triangle = <Offset>[
      Offset(center.dx - width / 2, center.dy - height / 2),
      Offset(center.dx + width / 2, center.dy),
      Offset(center.dx - width / 2, center.dy + height / 2),
    ];

    final rounded = _roundedPolygon(triangle, radius: 9 * unit);

    canvas.drawPath(
      rounded,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * unit),
    );

    canvas.drawPath(rounded, Paint()..color = Colors.white);
  }

  /// Строит многоугольник со скруглёнными углами.
  ///
  /// Работает для любого числа точек: у каждого угла отступаем по обеим
  /// сторонам на радиус и соединяем квадратичной кривой через вершину.
  static Path _roundedPolygon(List<Offset> points, {required double radius}) {
    final path = Path();
    if (points.length < 3) return path;

    for (var i = 0; i < points.length; i++) {
      final previous = points[(i - 1 + points.length) % points.length];
      final current = points[i];
      final next = points[(i + 1) % points.length];

      final toPrevious = previous - current;
      final toNext = next - current;
      final previousLength = toPrevious.distance;
      final nextLength = toNext.distance;
      if (previousLength == 0 || nextLength == 0) continue;

      final corner = radius
          .clamp(0.0, previousLength / 2)
          .clamp(0.0, nextLength / 2);
      final start = current + toPrevious / previousLength * corner;
      final end = current + toNext / nextLength * corner;

      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => false;
}
