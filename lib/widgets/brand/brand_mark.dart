import 'package:base_church/theme/brand_assets.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  static const double aspect = 140.882 / 174.964;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.brand.textPrimary;
    return Semantics(
      label: 'Base Church',
      image: true,
      child: ExcludeSemantics(
        child: SvgPicture.asset(
          BrandAssets.b,
          height: size,
          width: size * aspect,
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        ),
      ),
    );
  }
}
