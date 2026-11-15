import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/screens/acesso/definir_senha_screen.dart';
import 'package:base_church/services/acesso_service.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AcessoFalso extends AcessoService {
  _AcessoFalso(super.api, {this.erro, this.tipo = 'CONVITE'});

  final ApiException? erro;
  final String tipo;
  int definirChamadas = 0;

  @override
  Future<({String tipo, String primeiroNome})> info(String token) async {
    if (erro != null) throw erro!;
    return (tipo: tipo, primeiroNome: 'Ana');
  }

  @override
  Future<Map<String, dynamic>> definirSenha(String token, String senha) async {
    definirChamadas++;
    throw ApiException('falhou');
  }
}

Future<_AcessoFalso> _abrir(
  WidgetTester tester, {
  ApiException? erro,
  String tipo = 'CONVITE',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(prefs);
  final acesso = _AcessoFalso(api, erro: erro, tipo: tipo);
  final authService = AuthService(api, prefs);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AcessoService>.value(value: acesso),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
      ],
      child: const MaterialApp(home: DefinirSenhaScreen(token: 'abc')),
    ),
  );
  await tester.pumpAndSettle();
  return acesso;
}

void main() {
  testWidgets('linkExpiradoMostraMensagemSemFormulario', (tester) async {
    await _abrir(tester, erro: ApiException('x', status: 410));

    expect(
      find.text('Este link expirou ou já foi usado. Peça um novo convite.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('convite mostra saudação e subtítulo', (tester) async {
    await _abrir(tester);

    expect(find.text('Olá, Ana'), findsOneWidget);
    expect(find.text('Crie sua senha'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('redefinição mostra subtítulo próprio', (tester) async {
    await _abrir(tester, tipo: 'REDEFINICAO');

    expect(find.text('Crie uma nova senha'), findsOneWidget);
  });

  testWidgets('senhasDiferentesNaoEnviam', (tester) async {
    final acesso = await _abrir(tester);

    await tester.enterText(find.byType(TextField).at(0), 'senha1234');
    await tester.enterText(find.byType(TextField).at(1), 'outra1234');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(acesso.definirChamadas, 0);
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
  });

  testWidgets('senha curta não envia', (tester) async {
    final acesso = await _abrir(tester);

    await tester.enterText(find.byType(TextField).at(0), 'curta');
    await tester.enterText(find.byType(TextField).at(1), 'curta');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(acesso.definirChamadas, 0);
    expect(
      find.text('A senha deve ter ao menos 8 caracteres.'),
      findsOneWidget,
    );
  });
}
