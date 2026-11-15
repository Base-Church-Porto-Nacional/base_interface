import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/router/app_router.dart';
import 'package:base_church/screens/acesso/definir_senha_screen.dart';
import 'package:base_church/screens/login/login_screen.dart';
import 'package:base_church/services/acesso_service.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AcessoFalso extends AcessoService {
  _AcessoFalso(super.api);

  @override
  Future<({String tipo, String primeiroNome})> info(String token) async =>
      (tipo: 'CONVITE', primeiroNome: 'Ana');
}

Future<void> _abrir(WidgetTester tester, {String? rotaInicial}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(prefs);
  final auth = AuthProvider(AuthService(api, prefs));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AcessoService>.value(value: _AcessoFalso(api)),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp.router(
        routerConfig: createRouter(auth, rotaInicial: rotaInicial),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('linkDeConviteAbertoSemSessaoMostraDefinirSenha', (tester) async {
    // Na web, a rota do navegador é capturada no main() antes do primeiro
    // frame: a tela de carregamento reescreve a URL para "/".
    await _abrir(tester, rotaInicial: '/acesso/abc');
    expect(find.byType(DefinirSenhaScreen), findsOneWidget);
  });

  testWidgets('semRotaInicialVaiParaLogin', (tester) async {
    await _abrir(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('rotaInicialRaizUsaODashboardPadrao', (tester) async {
    await _abrir(tester, rotaInicial: '/');
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
