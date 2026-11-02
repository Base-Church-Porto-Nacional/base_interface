import 'package:flutter/material.dart';

import '../../theme/brand_colors.dart';
import '../../widgets/brand/brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onInverse = context.brand.onInverse;
    return Scaffold(
      body: SpotlightBlock(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrandSeal(size: 120, spinning: true, color: onInverse),
              const SizedBox(height: 32),
              SizedBox(
                width: 160,
                height: 2,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  value: MediaQuery.disableAnimationsOf(context) ? 0.4 : null,
                  color: onInverse,
                  backgroundColor: onInverse.withValues(alpha: 0.16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
