import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';

class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.focused,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.color,
  });

  static const ringKey = ValueKey('focus-ring');
  static const double width = 2;
  static const double gap = 2;

  final bool focused;
  final Widget child;
  final BorderRadius borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    const reach = -(width + gap);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (focused)
          Positioned(
            left: reach,
            top: reach,
            right: reach,
            bottom: reach,
            child: IgnorePointer(
              child: DecoratedBox(
                key: ringKey,
                decoration: BoxDecoration(
                  borderRadius:
                      borderRadius +
                      const BorderRadius.all(Radius.circular(width + gap)),
                  border: Border.all(
                    color: color ?? context.brand.focus,
                    width: width,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
