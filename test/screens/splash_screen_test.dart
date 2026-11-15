import 'package:base_church/screens/splash/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('sem animação quando movimento está desligado', (t) async {
    await pumpBrand(t, const SplashScreen(), disableAnimations: true);
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('anima quando movimento está ligado', (t) async {
    await pumpBrand(t, const SplashScreen());
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isTrue);
  });
}
