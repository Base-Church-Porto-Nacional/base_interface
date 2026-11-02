import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/screens/login/login_screen.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/widgets/brand/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump.dart';

Future<AuthProvider> _montar(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthProvider(AuthService(ApiClient(prefs), prefs));
  await pumpBrand(
    t,
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const LoginScreen(),
    ),
    size: size,
    textScale: textScale,
    brightness: brightness,
  );
  await t.pump(const Duration(milliseconds: 100));
  return auth;
}

void main() {
  testWidgets('mostra selo e BEM-VINDO', (t) async {
    await _montar(t);
    expect(find.byType(BrandSeal), findsOneWidget);
    expect(find.text('BEM-VINDO'), findsOneWidget);
    expect(find.text('Entre com sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('largo usa selo 240 girando', (t) async {
    await _montar(t, size: const Size(1280, 800));
    final seal = t.widget<BrandSeal>(find.byType(BrandSeal));
    expect(seal.size, 240);
    expect(seal.spinning, isTrue);
    expect(find.text('2026 — A PARTIR DE JESUS'), findsOneWidget);
  });

  testWidgets('sem overflow com fonte 200%', (t) async {
    await _montar(t, textScale: 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('sem overflow no escuro', (t) async {
    await _montar(t, brightness: Brightness.dark, size: const Size(1280, 800));
    expect(t.takeException(), isNull);
  });

  testWidgets('Enter na senha chama login', (t) async {
    final auth = await _montar(t);
    final fake = FakeApi({
      'POST /auth/login': (_) => (401, {'message': 'Credenciais inválidas'}),
    });
    await t.enterText(find.byType(TextField).first, 'ana');
    await t.enterText(find.byType(TextField).last, 'segredo');
    var carregou = false;
    auth.addListener(() => carregou = carregou || auth.isLoading);
    await fake.run(() async {
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
    });
    expect(carregou, isTrue);
    expect(fake.log, ['POST /auth/login']);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 100));
  });
}
