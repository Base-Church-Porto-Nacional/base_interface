import 'dart:async';

import 'package:base_church/theme/app_theme.dart';
import 'package:base_church/theme/app_typography.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

T _quiet<T>(T Function() body) => runZoned(
  body,
  zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final light = _quiet(() => AppTheme.light);
  final dark = _quiet(() => AppTheme.dark);

  test('extensao de marca nos dois temas', () {
    expect(light.extension<BrandColors>(), BrandColors.light);
    expect(dark.extension<BrandColors>(), BrandColors.dark);
  });

  test('brilho e primaria', () {
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.primary, const Color(0xFFFFFFFF));
    expect(light.colorScheme.primary, const Color(0xFF000000));
  });

  test('canvas e menus em superficie overlay', () {
    expect(light.canvasColor, BrandColors.light.surfaceOverlay);
    expect(dark.canvasColor, BrandColors.dark.surfaceOverlay);
    expect(light.popupMenuTheme.color, BrandColors.light.surfaceOverlay);
    expect(dark.popupMenuTheme.color, BrandColors.dark.surfaceOverlay);
  });

  test('tipografia de marca', () {
    expect(AppTypography.hero.fontFamily, 'Archivo');
    expect(AppTypography.hero.fontSize, 36);
    expect(AppTypography.eyebrow.letterSpacing, 1.2);
  });
}
