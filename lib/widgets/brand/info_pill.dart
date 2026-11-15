import 'package:base_church/theme/app_elevation.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';

import 'glass_surface.dart';

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return GlassSurface(
      radius: 999,
      level: Elevation.e1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: brand.textSecondary),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: brand.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
