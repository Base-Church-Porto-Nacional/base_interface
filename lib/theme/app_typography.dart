import 'package:flutter/painting.dart';

abstract final class AppTypography {
  static const String _family = 'Archivo';

  static TextStyle _expanded({
    required double size,
    required double height,
    required int weight,
    double? letterSpacing,
    List<FontFeature>? features,
  }) {
    return TextStyle(
      fontFamily: _family,
      fontSize: size,
      height: height / size,
      fontWeight: FontWeight.values[weight ~/ 100 - 1],
      fontVariations: [
        const FontVariation('wdth', 125),
        FontVariation('wght', weight.toDouble()),
      ],
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );
  }

  static TextStyle get hero =>
      _expanded(size: 36, height: 40, weight: 900, letterSpacing: -0.5);

  static TextStyle get pageTitle =>
      _expanded(size: 28, height: 32, weight: 900);

  static TextStyle get stat => _expanded(
    size: 32,
    height: 36,
    weight: 800,
    features: const [FontFeature.tabularFigures()],
  );

  static TextStyle get eyebrow =>
      _expanded(size: 12, height: 16, weight: 700, letterSpacing: 1.2);
}
