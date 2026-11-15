import 'dart:ui' as ui;

import 'package:base_church/theme/brand_assets.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';

class SpotlightBlock extends StatelessWidget {
  const SpotlightBlock({super.key, required this.child, this.borderRadius});

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    Widget block = CustomPaint(
      painter: _SpotlightPainter(brand.inverse),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(BrandAssets.grain),
            repeat: ImageRepeat.repeat,
            opacity: 0.03,
            filterQuality: FilterQuality.none,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: brand.onInverse),
          child: IconTheme.merge(
            data: IconThemeData(color: brand.onInverse),
            child: child,
          ),
        ),
      ),
    );
    if (borderRadius != null) {
      block = ClipRRect(borderRadius: borderRadius!, child: block);
    }
    return block;
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.base);

  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, 0),
          size.width * 1.2,
          [const Color(0xFF2A2A2A), base],
        ),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.base != base;
}
