import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/contrast.dart';

void main() {
  for (final entry in {
    'light': BrandColors.light,
    'dark': BrandColors.dark,
  }.entries) {
    final b = entry.value;
    group('contraste ${entry.key}', () {
      final surfaces = {
        'background': b.background,
        'surface': b.surface,
        'surfaceRaised': b.surfaceRaised,
        'surfaceOverlay': b.surfaceOverlay,
      };
      final texts = {
        'textPrimary': b.textPrimary,
        'textSecondary': b.textSecondary,
        'textMuted': b.textMuted,
      };
      for (final t in texts.entries) {
        for (final s in surfaces.entries) {
          test('${t.key} sobre ${s.key}', () {
            expect(contrastRatio(t.value, s.value), greaterThanOrEqualTo(4.5));
          });
        }
      }
      test('onInverse sobre inverse', () {
        expect(
          contrastRatio(b.onInverse, b.inverse),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('onPrimary sobre primary', () {
        expect(
          contrastRatio(b.onPrimary, b.primary),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('estados sobre seus fundos', () {
        expect(
          contrastRatio(b.success, b.successBg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(b.warning, b.warningBg),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrastRatio(b.danger, b.dangerBg), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('lerp em 0 devolve claro e em 1 devolve escuro', () {
    expect(BrandColors.light.lerp(BrandColors.dark, 0), BrandColors.light);
    expect(BrandColors.light.lerp(BrandColors.dark, 1), BrandColors.dark);
  });
}
