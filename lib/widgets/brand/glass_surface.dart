import 'dart:math' as math;
import 'dart:ui';

import 'package:base_church/theme/app_elevation.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 16,
    this.level = Elevation.e2,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final Elevation level;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final solid = MediaQuery.highContrastOf(context);
    final borderRadius = BorderRadius.circular(radius);

    final content = Padding(padding: padding, child: child);
    final Widget face = solid
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: context.brand.surfaceOverlay,
              borderRadius: borderRadius,
              border: Border.all(color: context.brand.borderStrong),
            ),
            child: content,
          )
        : BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: CustomPaint(
              painter: _GlassFacePainter(
                radius: radius,
                dark: brightness == Brightness.dark,
              ),
              child: content,
            ),
          );

    return CustomPaint(
      painter: _OuterShadowPainter(
        radius: radius,
        shadows: AppElevation.shadows(level, brightness),
      ),
      child: ClipRRect(borderRadius: borderRadius, child: face),
    );
  }
}

class _OuterShadowPainter extends CustomPainter {
  _OuterShadowPainter({required this.radius, required this.shadows});

  final double radius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final reach = shadows.fold<double>(
      0,
      (m, s) =>
          math.max(m, s.blurRadius * 2 + s.offset.distance + s.spreadRadius),
    );
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect((Offset.zero & size).inflate(reach)),
      Path()..addRRect(shape),
    );
    canvas.save();
    canvas.clipPath(outside);
    for (final s in shadows) {
      canvas.drawRRect(
        shape.shift(s.offset).inflate(s.spreadRadius),
        s.toPaint(),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) =>
      old.radius != radius || old.shadows != shadows;
}

class _GlassFacePainter extends CustomPainter {
  _GlassFacePainter({required this.radius, required this.dark});

  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final inner = outer.deflate(1);

    final fill = dark ? const Color(0x8C141414) : const Color(0xB3FFFFFF);
    canvas.drawRRect(outer, Paint()..color = fill);

    final glowRect = Rect.fromLTWH(0, 0, size.width, size.height / 3);
    canvas.save();
    canvas.clipRRect(outer);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(dark ? 0x0FFFFFFF : 0x4DFFFFFF),
            const Color(0x00FFFFFF),
          ],
        ).createShader(glowRect),
    );
    canvas.restore();

    final top = dark ? const Color(0x24FFFFFF) : const Color(0xCCFFFFFF);
    final bottom = dark ? const Color(0x0AFFFFFF) : const Color(0x33FFFFFF);
    canvas.drawDRRect(
      outer,
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassFacePainter old) =>
      old.radius != radius || old.dark != dark;
}
