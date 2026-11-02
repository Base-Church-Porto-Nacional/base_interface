import 'dart:async';

import 'package:base_church/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

T _quiet<T>(T Function() body) => runZoned(
  body,
  zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
);

ThemeData? _light;
ThemeData? _dark;

ThemeData _theme(Brightness brightness) {
  GoogleFonts.config.allowRuntimeFetching = false;
  if (brightness == Brightness.dark) {
    final theme = _dark ?? _quiet<ThemeData>(() => AppTheme.dark);
    _dark = theme;
    return theme;
  }
  final theme = _light ?? _quiet<ThemeData>(() => AppTheme.light);
  _light = theme;
  return theme;
}

Future<void> pumpBrand(
  WidgetTester t,
  Widget w, {
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
  bool highContrast = false,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          highContrast: highContrast,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(body: w),
    ),
  );
}
