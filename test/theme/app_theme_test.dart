import 'dart:async';

import 'package:base_church/theme/app_theme.dart';
import 'package:base_church/theme/app_typography.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/contrast.dart';

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

  for (final (nome, theme, c) in [
    ('claro', light, BrandColors.light),
    ('escuro', dark, BrandColors.dark),
  ]) {
    test('foco translucido mantem item legivel ($nome)', () {
      expect(theme.focusColor.a, lessThan(0.2));
      final fundo = Color.alphaBlend(theme.focusColor, theme.canvasColor);
      expect(contrastRatio(c.textPrimary, fundo), greaterThanOrEqualTo(4.5));
    });

    test('switch desligado com contraste de 3:1 ($nome)', () {
      final s = theme.switchTheme;
      final thumb = s.thumbColor!.resolve({})!;
      final track = s.trackColor!.resolve({})!;
      final outline = s.trackOutlineColor!.resolve({})!;
      expect(contrastRatio(thumb, track), greaterThanOrEqualTo(3));
      expect(contrastRatio(outline, c.surface), greaterThanOrEqualTo(3));
      final on = {WidgetState.selected};
      expect(s.thumbColor!.resolve(on), c.onPrimary);
      expect(s.trackColor!.resolve(on), c.primary);
    });

    test('superficies do ColorScheme vem da marca ($nome)', () {
      final cs = theme.colorScheme;
      final marca = {c.surface, c.surfaceRaised, c.surfaceOverlay};
      for (final cor in [
        cs.surfaceContainerLowest,
        cs.surfaceContainerLow,
        cs.surfaceContainer,
        cs.surfaceContainerHigh,
        cs.surfaceContainerHighest,
      ]) {
        expect(marca, contains(cor));
      }
      expect(cs.surfaceTint.a, 0);
    });

    test('botoes mostram anel de foco ($nome)', () {
      const focado = {WidgetState.focused};
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        final side = style.side!.resolve(focado)!;
        expect(side.color, c.focus);
        expect(side.width, 2);
        expect(side.strokeOffset, greaterThan(side.width));
      }
    });
  }
}
