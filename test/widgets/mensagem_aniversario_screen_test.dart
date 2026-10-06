import 'package:base_church/config/app_config.dart';
import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/providers/igreja_context.dart';
import 'package:base_church/screens/configuracoes/mensagem_aniversario_screen.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/services/igreja_service.dart';
import 'package:base_church/services/mensagem_aniversario_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = ApiClient(prefs);
  });

  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  // Os serviços mock usam Future.delayed real, que não avança no relógio falso
  // do testWidgets: qualquer await de serviço fora daqui trava o teste.
  Future<void> pumpScreen(WidgetTester tester, {String login = 'admin'}) async {
    expect(AppConfig.useMock, isTrue, reason: 'este teste exige modo mock');

    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late AuthProvider auth;
    late IgrejaContext igrejaCtx;
    await tester.runAsync(() async {
      auth = AuthProvider(AuthService(api, prefs));
      await auth.login(login, 'senha');
      igrejaCtx = IgrejaContext(IgrejaService(api), prefs);
      await igrejaCtx.syncUser(auth.user);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<IgrejaContext>.value(value: igrejaCtx),
          Provider<MensagemAniversarioService>.value(
            value: MensagemAniversarioService(api),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MensagemAniversarioScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final Finder campo = find.byType(TextField);

  String textoDoCampo(WidgetTester tester) =>
      tester.widget<TextField>(campo).controller?.text ?? '';

  Future<void> tocar(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('MensagemAniversarioScreen', () {
    testWidgets('carrega a mensagem da igreja no campo de edição', (tester) async {
      await pumpScreen(tester);

      expect(textoDoCampo(tester), contains('[Nome]'));
      expect(textoDoCampo(tester), contains('Feliz aniversário'));
    });

    testWidgets('mostra a pré-visualização com o nome de exemplo', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Pré-visualização'), findsOneWidget);
      expect(
        find.textContaining('Feliz aniversário, Gustavo! 🎉'),
        findsOneWidget,
      );
    });

    testWidgets('o chip insere o placeholder no campo', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(campo, '');
      await tester.pump();
      await tocar(tester, find.widgetWithText(ActionChip, '[Nome]'));

      expect(textoDoCampo(tester), '[Nome]');
      expect(find.text('Gustavo'), findsOneWidget);
    });

    testWidgets('o chip insere o placeholder na posição do cursor', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(campo, 'Parabéns, ');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      editable.controller.selection = const TextSelection.collapsed(offset: 10);
      await tester.pump();
      await tocar(tester, find.widgetWithText(ActionChip, '[Nome]'));

      expect(textoDoCampo(tester), 'Parabéns, [Nome]');
    });

    testWidgets('o chip de [Nome Completo] insere a chave completa', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(campo, '');
      await tester.pump();
      await tocar(tester, find.widgetWithText(ActionChip, '[Nome Completo]'));

      expect(textoDoCampo(tester), '[Nome Completo]');
      expect(find.text('Gustavo Antunes'), findsOneWidget);
    });

    testWidgets('avisa quando a mensagem não usa [Nome]', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(campo, 'Parabéns!');
      await tester.pump();

      expect(find.text('A mensagem não usa [Nome]'), findsOneWidget);
    });

    testWidgets('não avisa quando a mensagem usa [Nome]', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(campo, 'Parabéns, [Nome]!');
      await tester.pump();

      expect(find.text('A mensagem não usa [Nome]'), findsNothing);
    });

    testWidgets('salva a mensagem e confirma com SnackBar', (tester) async {
      await pumpScreen(tester);

      const texto = 'Feliz aniversário, [Nome]! Deus te ama.';
      await tester.enterText(campo, texto);
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, 'Salvar mensagem'));

      expect(find.text('Mensagem padrão salva.'), findsOneWidget);
      expect(textoDoCampo(tester), texto);

      final salvo = await tester.runAsync(
        () => MensagemAniversarioService(api).get(igrejaId: 'i1'),
      );
      expect(salvo?.mensagem, texto);
    });

    testWidgets('descartar volta ao texto salvo', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(campo, 'Rascunho');
      await tester.pump();
      await tocar(tester, find.widgetWithText(TextButton, 'Descartar alterações'));

      expect(textoDoCampo(tester), contains('[Nome]'));
      expect(textoDoCampo(tester), isNot(contains('Rascunho')));
    });

    testWidgets('recusa salvar mensagem vazia', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(campo, '   ');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, 'Salvar mensagem'));

      expect(find.text('Informe a mensagem padrão.'), findsOneWidget);
      expect(find.text('Mensagem padrão salva.'), findsNothing);
    });

    testWidgets('sem permissão, o campo é somente leitura', (tester) async {
      await pumpScreen(tester, login: 'joao');

      expect(tester.widget<TextField>(campo).readOnly, isTrue);
      expect(find.text('Somente leitura para o seu papel'), findsOneWidget);
      expect(find.text('Salvar mensagem'), findsNothing);
      expect(
        tester.widget<ActionChip>(find.widgetWithText(ActionChip, '[Nome]')).onPressed,
        isNull,
      );
    });
  });
}