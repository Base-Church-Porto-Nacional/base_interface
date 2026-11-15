import 'dart:math' as math;

import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.animated = false,
  });

  final Widget child;
  final bool animated;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AmbientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.animated && !MediaQuery.disableAnimationsOf(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      painter: _LightPainter(
        dark: context.isDark,
        background: context.brand.background,
        phase: _controller,
      ),
      child: const SizedBox.expand(),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: RepaintBoundary(child: painter)),
        widget.child,
      ],
    );
  }
}

class _Blob {
  const _Blob(this.x, this.y, this.radius, this.light, this.dark, this.phase);

  final double x;
  final double y;
  final double radius;
  final double light;
  final double dark;
  final double phase;
}

class _LightPainter extends CustomPainter {
  _LightPainter({
    required this.dark,
    required this.background,
    required this.phase,
  }) : super(repaint: phase);

  final bool dark;
  final Color background;
  final Animation<double> phase;

  static const _blobs = [
    _Blob(0.15, 0.05, 0.70, 0.50, 0.10, 0),
    _Blob(0.95, 0.40, 0.60, 0.40, 0.06, 2.1),
    _Blob(0.30, 1.00, 0.75, 0.60, 0.08, 4.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final base = math.max(size.width, size.height * 0.6);
    final t = phase.value * 2 * math.pi;
    for (final b in _blobs) {
      final center = Offset(
        size.width * b.x + math.sin(t + b.phase) * size.width * 0.06,
        size.height * b.y + math.cos(t + b.phase) * size.height * 0.04,
      );
      final radius = base * b.radius;
      final color = dark
          ? Color.fromRGBO(255, 255, 255, b.dark)
          : Color.fromRGBO(212, 212, 212, b.light);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_LightPainter old) =>
      old.dark != dark || old.background != background;
}
