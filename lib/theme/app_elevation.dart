import 'dart:ui';

import 'package:flutter/painting.dart';

enum Elevation { e0, e1, e2, e3 }

abstract final class AppElevation {
  static List<BoxShadow> shadows(Elevation e, Brightness b) {
    if (b == Brightness.dark) {
      return switch (e) {
        Elevation.e0 || Elevation.e1 => const [],
        Elevation.e2 => const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
        Elevation.e3 => const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 48,
            offset: Offset(0, 24),
          ),
        ],
      };
    }
    return switch (e) {
      Elevation.e0 => const [],
      Elevation.e1 => const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
      Elevation.e2 => const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
      Elevation.e3 => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x2E000000),
          blurRadius: 48,
          offset: Offset(0, 24),
        ),
      ],
    };
  }

  static double highlightOpacity(Elevation e, Brightness b) {
    if (b == Brightness.light) return 0;
    return switch (e) {
      Elevation.e0 => 0,
      Elevation.e1 => 0.06,
      Elevation.e2 => 0.07,
      Elevation.e3 => 0.08,
    };
  }
}
