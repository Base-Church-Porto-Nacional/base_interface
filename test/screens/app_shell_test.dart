import 'package:base_church/models/models.dart';
import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/providers/igreja_context.dart';
import 'package:base_church/screens/shell/app_shell.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/services/igreja_service.dart';
import 'package:base_church/widgets/brand/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump.dart';

Future<void> _montar(
  WidgetTester t, {
  String? nomeIgreja,
  Brightness brightness = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(prefs);
  final auth = AuthProvider(AuthService(api, prefs));
  final igreja = nomeIgreja == null
      ? mockIgrejaMatriz
      : Igreja(
          id: 'i1',
          nome: nomeIgreja,
          tipo: IgrejaTipo.matriz,
          pastorPessoaId: 'p1',
          pastorNome: 'Ana Costa',
          adminUsuarioId: 'u1',
          adminNome: 'Ana Costa',
          ativo: true,
        );
  auth.user = mockUser;
  final ctx = IgrejaContext(IgrejaService(api), prefs)
    ..igrejas = [igreja, mockIgrejaFilial]
    ..selectedIgrejaId = 'i1';
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const Text('conteudo'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await pumpBrand(
    t,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<IgrejaContext>.value(value: ctx),
      ],
      child: Router(
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
        backButtonDispatcher: RootBackButtonDispatcher(),
      ),
    ),
    brightness: brightness,
  );
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> _abrirDrawer(WidgetTester t) async {
  final state = t.state<ScaffoldState>(find.byType(Scaffold).last);
  state.openDrawer();
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('drawer mostra selo e igreja', (t) async {
    await _montar(t);
    await _abrirDrawer(t);
    expect(find.byType(BrandSeal), findsOneWidget);
    expect(find.text('Base Church'), findsWidgets);
    expect(find.text('MATRIZ'), findsOneWidget);
  });

  testWidgets('nome de igreja longo nao estoura', (t) async {
    await _montar(t, nomeIgreja: 'Igreja ' * 11 + 'Base');
    await _abrirDrawer(t);
    expect(t.takeException(), isNull);
  });

  testWidgets('tema escuro sem excecao', (t) async {
    await _montar(t, brightness: Brightness.dark);
    await _abrirDrawer(t);
    expect(t.takeException(), isNull);
  });

  testWidgets('app bar tem marca, avatar e Sair', (t) async {
    await _montar(t);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
    expect(find.text('conteudo'), findsOneWidget);
  });
}
