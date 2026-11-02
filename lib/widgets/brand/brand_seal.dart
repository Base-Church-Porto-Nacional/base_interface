import 'package:base_church/theme/brand_assets.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandSeal extends StatefulWidget {
  const BrandSeal({
    super.key,
    this.size = 120,
    this.spinning = false,
    this.color,
  });

  final double size;
  final bool spinning;
  final Color? color;

  @override
  State<BrandSeal> createState() => _BrandSealState();
}

class _BrandSealState extends State<BrandSeal>
    with SingleTickerProviderStateMixin {
  static const double _art = 360;
  static const double _bLeft = 109.563;
  static const double _bTop = 92.032;
  static const double _bWidth = 140.882;
  static const double _bHeight = 174.964;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BrandSeal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.spinning && !MediaQuery.disableAnimationsOf(context);
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
    final size = widget.size;
    final scale = size / _art;
    final filter = ColorFilter.mode(
      widget.color ?? context.brand.textPrimary,
      BlendMode.srcIn,
    );

    Widget ring = SvgPicture.asset(
      BrandAssets.anel,
      width: size,
      height: size,
      colorFilter: filter,
    );
    if (widget.spinning) {
      ring = RotationTransition(turns: _controller, child: ring);
    }

    return Semantics(
      label: 'Base Church',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Positioned.fill(child: RepaintBoundary(child: ring)),
              Positioned(
                left: _bLeft * scale,
                top: _bTop * scale,
                width: _bWidth * scale,
                height: _bHeight * scale,
                child: SvgPicture.asset(BrandAssets.b, colorFilter: filter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
