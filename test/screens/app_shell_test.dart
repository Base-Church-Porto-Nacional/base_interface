import 'package:base_church/models/models.dart';
import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/providers/igreja_context.dart';
import 'package:base_church/screens/shell/app_shell.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/services/igreja_service.dart';
import 'package:base_church/widgets/brand/brand.dart';
import 'package:base_church/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Size size = const Size(390, 844),
  double textScale = 1,
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
    size: size,
    textScale: textScale,
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
    await _montar(t, size: const Size(800, 600));
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
    expect(find.text('conteudo'), findsOneWidget);
  });

  for (final (nome, size, scale) in [
    ('360 com texto 200%', const Size(360, 800), 2.0),
    ('375 com texto 200%', const Size(375, 800), 2.0),
    ('320 com texto 100%', const Size(320, 640), 1.0),
  ]) {
    testWidgets('app bar cabe em $nome e Sair continua alcancavel', (t) async {
      await _montar(t, size: size, textScale: scale);
      expect(t.takeException(), isNull);
      expect(find.text('Sair'), findsNothing);
      await t.tap(find.byTooltip('Perfil'));
      await t.pumpAndSettle();
      expect(find.text('Sair'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });
  }

  testWidgets('alvos de toque da app bar com 48', (t) async {
    await _montar(t, size: const Size(800, 600));
    expect(
      t.getSize(find.widgetWithText(TextButton, 'Sair')).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      t.getSize(find.byType(DropdownButton<String>)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('seletor de igreja alarga no desktop', (t) async {
    await _montar(t, size: const Size(1280, 800));
    expect(
      t.getSize(find.byType(DropdownButton<String>)).width,
      greaterThan(200),
    );
    expect(
      t.getRect(find.widgetWithText(TextButton, 'Sair')).right,
      greaterThan(1280 - 16),
    );
  });

  testWidgets('luz ambiente passa por baixo da app bar', (t) async {
    await _montar(t);
    expect(
      find.ancestor(
        of: find.byType(GlassSurface),
        matching: find.byType(AmbientBackground),
      ),
      findsOneWidget,
    );
    final scaffold = t.widget<Scaffold>(
      find
          .ancestor(
            of: find.byType(GlassSurface),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    expect(scaffold.backgroundColor, Colors.transparent);
  });

  testWidgets('item ativo do drawer anuncia selecionado', (t) async {
    await _montar(t);
    await _abrirDrawer(t);
    final item = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Dash'),
    );
    expect(t.getSemantics(item), isSemantics(isButton: true, isSelected: true));
  });

  testWidgets('item do drawer mostra anel de foco', (t) async {
    await _montar(t);
    await _abrirDrawer(t);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    final ring = find.descendant(
      of: find.byType(Drawer),
      matching: find.byWidgetPredicate((w) => w is FocusRing && w.focused),
    );
    expect(ring, findsOneWidget);
    expect(t.widget<FocusRing>(ring).color, BrandColors.light.onInverse);
  });
}
