import 'package:base_church/models/models.dart';
import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/screens/igrejas/igreja_detail_screen.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/services/igreja_service.dart';
import 'package:base_church/services/pessoa_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

class _IgrejaServiceFake extends IgrejaService {
  _IgrejaServiceFake(super.api);
  @override
  Future<Igreja> getById(String id) async => mockIgrejaFilial;
}

Future<void> _abrir(WidgetTester tester, AuthUser user) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(prefs);
  final auth = AuthProvider(AuthService(api, prefs))..user = user;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<IgrejaService>.value(value: _IgrejaServiceFake(api)),
        Provider<PessoaService>.value(value: PessoaService(api)),
      ],
      child: MaterialApp(
        home: Scaffold(body: IgrejaDetailScreen(key: UniqueKey(), igrejaId: 'i2')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AuthUser _user({
  required IgrejaTipo tipo,
  Set<Capacidade> caps = const {},
  String? pessoaId,
}) => AuthUser(
  id: 'u',
  nome: 'U',
  email: 'u@x.com',
  papeis: const [],
  permissoes: Permissoes(capacidades: caps),
  igrejaId: tipo == IgrejaTipo.matriz ? 'i1' : 'i2',
  igrejaTipo: tipo,
  igrejaNome: 'X',
  pessoaId: pessoaId,
);

void main() {
  testWidgets('trocarPastorSoParaQuemPode', (tester) async {
    // matriz com filialCriar: vê
    await _abrir(tester, _user(tipo: IgrejaTipo.matriz, caps: {Capacidade.filialCriar}));
    expect(find.text('Trocar pastor'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);

    // pastor titular da filial (pessoaId == pastorPessoaId): vê
    await _abrir(tester, _user(tipo: IgrejaTipo.filial, pessoaId: 'p8'));
    expect(find.text('Trocar pastor'), findsOneWidget);

    // matriz sem filialCriar: não vê
    await _abrir(tester, _user(tipo: IgrejaTipo.matriz));
    expect(find.text('Trocar pastor'), findsNothing);

    // outro usuário da filial: não vê
    await _abrir(tester, _user(tipo: IgrejaTipo.filial, pessoaId: 'p9'));
    expect(find.text('Trocar pastor'), findsNothing);
  });
}
