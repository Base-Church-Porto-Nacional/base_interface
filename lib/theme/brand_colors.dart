import 'package:flutter/material.dart';

import 'app_tokens.dart';

@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.inverse,
    required this.onInverse,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.onPrimary,
    required this.focus,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color inverse;
  final Color onInverse;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color onPrimary;
  final Color focus;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;

  static const BrandColors light = BrandColors(
    background: AppTokens.n100,
    surface: AppTokens.white,
    surfaceRaised: AppTokens.n50,
    surfaceOverlay: AppTokens.white,
    inverse: AppTokens.black,
    onInverse: AppTokens.white,
    textPrimary: AppTokens.n950,
    textSecondary: Color(0xFF525252),
    textMuted: AppTokens.n500,
    border: AppTokens.n200,
    borderStrong: AppTokens.n300,
    primary: AppTokens.black,
    onPrimary: AppTokens.white,
    focus: AppTokens.black,
    success: Color(0xFF167A45),
    successBg: Color(0xFFE7F4EC),
    warning: Color(0xFF8A6500),
    warningBg: Color(0xFFFFF6DB),
    danger: Color(0xFFB42318),
    dangerBg: Color(0xFFFCE8E6),
  );

  static const BrandColors dark = BrandColors(
    background: AppTokens.black,
    surface: AppTokens.n900,
    surfaceRaised: AppTokens.n850,
    surfaceOverlay: AppTokens.n800,
    inverse: AppTokens.black,
    onInverse: AppTokens.white,
    textPrimary: AppTokens.n50,
    textSecondary: AppTokens.n400,
    textMuted: AppTokens.n450,
    border: AppTokens.n750,
    borderStrong: AppTokens.n700,
    primary: AppTokens.white,
    onPrimary: AppTokens.black,
    focus: AppTokens.white,
    success: Color(0xFF4ADE80),
    successBg: Color(0xFF0F2A1A),
    warning: Color(0xFFFACC15),
    warningBg: Color(0xFF2A2205),
    danger: Color(0xFFF87171),
    dangerBg: Color(0xFF2D0F0D),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandColors &&
          background == other.background &&
          surface == other.surface &&
          surfaceRaised == other.surfaceRaised &&
          surfaceOverlay == other.surfaceOverlay &&
          inverse == other.inverse &&
          onInverse == other.onInverse &&
          textPrimary == other.textPrimary &&
          textSecondary == other.textSecondary &&
          textMuted == other.textMuted &&
          border == other.border &&
          borderStrong == other.borderStrong &&
          primary == other.primary &&
          onPrimary == other.onPrimary &&
          focus == other.focus &&
          success == other.success &&
          successBg == other.successBg &&
          warning == other.warning &&
          warningBg == other.warningBg &&
          danger == other.danger &&
          dangerBg == other.dangerBg;

  @override
  int get hashCode => Object.hashAll([
    background,
    surface,
    surfaceRaised,
    surfaceOverlay,
    inverse,
    onInverse,
    textPrimary,
    textSecondary,
    textMuted,
    border,
    borderStrong,
    primary,
    onPrimary,
    focus,
    success,
    successBg,
    warning,
    warningBg,
    danger,
    dangerBg,
  ]);

  @override
  BrandColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? inverse,
    Color? onInverse,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
    Color? primary,
    Color? onPrimary,
    Color? focus,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? danger,
    Color? dangerBg,
  }) {
    return BrandColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      inverse: inverse ?? this.inverse,
      onInverse: onInverse ?? this.onInverse,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      focus: focus ?? this.focus,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BrandColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceOverlay: l(surfaceOverlay, other.surfaceOverlay),
      inverse: l(inverse, other.inverse),
      onInverse: l(onInverse, other.onInverse),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      focus: l(focus, other.focus),
      success: l(success, other.success),
      successBg: l(successBg, other.successBg),
      warning: l(warning, other.warning),
      warningBg: l(warningBg, other.warningBg),
      danger: l(danger, other.danger),
      dangerBg: l(dangerBg, other.dangerBg),
    );
  }
}

extension BrandContext on BuildContext {
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
