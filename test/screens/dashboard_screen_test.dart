import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/providers/igreja_context.dart';
import 'package:base_church/screens/dashboard/dashboard_screen.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/services/dashboard_service.dart';
import 'package:base_church/services/export_service.dart';
import 'package:base_church/services/igreja_service.dart';
import 'package:base_church/services/pessoa_service.dart';
import 'package:base_church/widgets/brand/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/fixtures.dart';
import '../helpers/pump.dart';

Future<void> _montar(
  WidgetTester t,
  Map<String, Rota> rotas, {
  Size size = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(prefs);
  final pessoas = PessoaService(api);
  final dashboard = DashboardService(api, pessoas);
  final auth = AuthProvider(AuthService(api, prefs))..user = mockUser;
  final ctx = IgrejaContext(IgrejaService(api), prefs)
    ..igrejas = [mockIgrejaMatriz, mockIgrejaFilial]
    ..selectedIgrejaId = 'i1';
  final fake = FakeApi(rotas);
  await fake.run(() async {
    await pumpBrand(
      t,
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<IgrejaContext>.value(value: ctx),
          Provider<DashboardService>.value(value: dashboard),
          Provider<ExportService>.value(
            value: ExportService(pessoas, dashboard),
          ),
        ],
        child: const DashboardScreen(),
      ),
      size: size,
    );
    await t.pumpAndSettle();
  });
}

final _rotasOk = <String, Rota>{
  'GET /dashboard': (_) => (
    200,
    {'totalPessoas': 10, 'totalVoluntariosAtivos': 4, 'totalLideres': 2},
  ),
  'GET /pessoas': (_) => (
    200,
    [
      {
        'id': 'p1',
        'nome': 'Ana',
        'papeis': ['MEMBRO'],
      },
    ],
  ),
};

void main() {
  testWidgets('mostra os quatro indicadores e o nome da igreja', (t) async {
    await _montar(t, _rotasOk);
    expect(find.byType(StatTile), findsNWidgets(4));
    expect(find.text(mockIgrejaMatriz.nome.toUpperCase()), findsOneWidget);
    expect(find.textContaining('ANA'), findsOneWidget);
  });

  testWidgets('em 1280px os indicadores ficam na mesma linha', (t) async {
    await _montar(t, _rotasOk, size: const Size(1280, 800));
    final tops = [
      for (final e in find.byType(StatTile).evaluate())
        t.getTopLeft(find.byWidget(e.widget)).dy,
    ];
    expect(tops.toSet().length, 1);
  });

  testWidgets('em 390px os indicadores ficam em duas colunas', (t) async {
    await _montar(t, _rotasOk);
    final tops = [
      for (final e in find.byType(StatTile).evaluate())
        t.getTopLeft(find.byWidget(e.widget)).dy,
    ];
    expect(tops.toSet().length, 2);
  });

  testWidgets('403 mostra a tela de boas-vindas com a saudação', (t) async {
    await _montar(t, {
      'GET /dashboard': (_) => (403, {'message': 'x'}),
    });
    expect(find.byType(StatTile), findsNothing);
    expect(find.textContaining('ANA'), findsOneWidget);
  });
}
