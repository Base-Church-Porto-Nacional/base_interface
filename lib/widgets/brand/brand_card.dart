import 'package:base_church/theme/app_elevation.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';

import 'focus_ring.dart';

class BrandCard extends StatefulWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<BrandCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final brightness = Theme.of(context).brightness;
    final interactive = widget.onTap != null;
    final lifted = interactive && _hovered && !_pressed;
    final level = lifted ? Elevation.e2 : Elevation.e1;
    final dy = !interactive
        ? 0.0
        : _pressed
        ? 1.0
        : _hovered
        ? -2.0
        : 0.0;
    final radius = BorderRadius.circular(8);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (interactive) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onFocusChange: (v) => setState(() => _focused = v),
          child: content,
        ),
      );
    }

    final visual = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, dy, 0),
      decoration: BoxDecoration(
        color: lifted && brightness == Brightness.dark
            ? brand.surfaceRaised
            : brand.surface,
        borderRadius: radius,
        border: Border.all(color: brand.border),
        boxShadow: AppElevation.shadows(level, brightness),
      ),
      foregroundDecoration: _TopHighlight(
        AppElevation.highlightOpacity(level, brightness),
        radius.topLeft.x,
      ),
      child: content,
    );

    if (!interactive) return visual;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusRing(focused: _focused, borderRadius: radius, child: visual),
    );
  }
}

class _TopHighlight extends Decoration {
  const _TopHighlight(this.opacity, this.inset);

  final double opacity;
  final double inset;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TopHighlightPainter(opacity, inset);

  @override
  bool operator ==(Object other) =>
      other is _TopHighlight &&
      other.opacity == opacity &&
      other.inset == inset;

  @override
  int get hashCode => Object.hash(opacity, inset);
}

class _TopHighlightPainter extends BoxPainter {
  _TopHighlightPainter(this.opacity, this.inset);

  final double opacity;
  final double inset;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (opacity == 0 || size == null) return;
    final y = offset.dy + 0.5;
    canvas.drawLine(
      Offset(offset.dx + inset, y),
      Offset(offset.dx + size.width - inset, y),
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity)
        ..strokeWidth = 1,
    );
  }
}
