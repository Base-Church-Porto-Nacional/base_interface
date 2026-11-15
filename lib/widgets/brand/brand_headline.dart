import 'dart:math' as math;

import 'package:flutter/material.dart';

class BrandHeadline extends StatelessWidget {
  const BrandHeadline(
    this.text, {
    super.key,
    required this.style,
    this.compactSize,
  });

  static const double compactBreakpoint = 600;
  static const double minSize = 12;

  final String text;
  final TextStyle style;
  final double? compactSize;

  @override
  Widget build(BuildContext context) {
    final compact =
        compactSize != null &&
        MediaQuery.sizeOf(context).width < compactBreakpoint;
    final base = compact ? style.copyWith(fontSize: compactSize) : style;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _fit(base, scaler, direction, constraints.maxWidth);
        return Text(text, style: base.copyWith(fontSize: size));
      },
    );
  }

  double _fit(
    TextStyle base,
    TextScaler scaler,
    TextDirection direction,
    double maxWidth,
  ) {
    final size = base.fontSize ?? 14;
    if (!maxWidth.isFinite) return size;
    var widest = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: base),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    if (widest <= maxWidth) return size;
    final floor = minSize * size / scaler.scale(size);
    return math.max(floor, (size * maxWidth / widest).floorToDouble());
  }
}
