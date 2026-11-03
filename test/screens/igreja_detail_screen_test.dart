import 'package:base_church/models/models.dart';
import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/providers/igreja_context.dart';
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

const _novoPastor = Pessoa(
  id: 'p1',
  nome: 'Ana Costa',
  telefone: '',
  email: '',
  status: PessoaStatus.ativo,
  tipos: [],
  ministerios: [],
  dataCadastro: '2026-01-01',
  igrejaId: 'i2',
);

class _IgrejaServiceFake extends IgrejaService {
  _IgrejaServiceFake(super.api, {this.anteriorMantevePastor = false, this.falharListagem = false});

  final bool anteriorMantevePastor;
  final bool falharListagem;
  int listagens = 0;

  @override
  Future<Igreja> getById(String id) async => mockIgrejaFilial;

  @override
  Future<List<Igreja>> listVisiveis(AuthUser user) async {
    listagens++;
    if (falharListagem && listagens > 1) throw Exception('sem rede');
    return mockIgrejas;
  }

  @override
  Future<PastorTrocado> trocarPastor(String igrejaId, String pessoaId) async => (
    igreja: const Igreja(
      id: 'i2',
      nome: 'Base Church — Zona Sul',
      tipo: IgrejaTipo.filial,
      igrejaMatrizId: 'i1',
      pastorPessoaId: 'p1',
      pastorNome: 'Ana Costa',
      ativo: true,
    ),
    convite: null,
    anteriorMantevePastor: anteriorMantevePastor,
  );
}

class _PessoaServiceFake extends PessoaService {
  _PessoaServiceFake(super.api);

  @override
  Future<List<Pessoa>> listarTodas({String? igrejaId}) async => const [_novoPastor];
}

class _AuthServiceFake extends AuthService {
  _AuthServiceFake(super.api, super.prefs);

  int recargas = 0;

  @override
  Future<AuthUser?> recarregarMe() async {
    recargas++;
    return null;
  }
}

class _Tela {
  _Tela(this.igrejas, this.auth);
  final _IgrejaServiceFake igrejas;
  final _AuthServiceFake auth;
}

Future<_Tela> _abrir(
  WidgetTester tester,
  AuthUser user, {
  bool anteriorMantevePastor = false,
  bool falharListagem = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(prefs);
  final authService = _AuthServiceFake(api, prefs);
  final auth = AuthProvider(authService)..user = user;
  final igrejas = _IgrejaServiceFake(
    api,
    anteriorMantevePastor: anteriorMantevePastor,
    falharListagem: falharListagem,
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<IgrejaService>.value(value: igrejas),
        Provider<PessoaService>.value(value: _PessoaServiceFake(api)),
        ChangeNotifierProvider<IgrejaContext>(create: (_) => IgrejaContext(igrejas, prefs)),
      ],
      child: MaterialApp(
        home: Scaffold(body: IgrejaDetailScreen(key: UniqueKey(), igrejaId: 'i2')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Tela(igrejas, authService);
}

Future<void> _trocarPara(WidgetTester tester, String nome) async {
  await tester.tap(find.text('Trocar pastor'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Novo pastor *'), nome);
  await tester.pumpAndSettle();
  await tester.tap(find.text(nome).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Trocar'));
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

    // pastor titular da filial (pessoaId == pastorPessoaId) que ainda é PASTOR: vê
    await _abrir(
      tester,
      _user(tipo: IgrejaTipo.filial, pessoaId: 'p8', caps: {Capacidade.papeisGestaoAtribuir}),
    );
    expect(find.text('Trocar pastor'), findsOneWidget);

    // titular cujo PASTOR foi removido: não vê (o servidor responderia 403)
    await _abrir(tester, _user(tipo: IgrejaTipo.filial, pessoaId: 'p8'));
    expect(find.text('Trocar pastor'), findsNothing);

    // matriz sem filialCriar: não vê
    await _abrir(tester, _user(tipo: IgrejaTipo.matriz));
    expect(find.text('Trocar pastor'), findsNothing);

    // outro usuário da filial: não vê
    await _abrir(tester, _user(tipo: IgrejaTipo.filial, pessoaId: 'p9'));
    expect(find.text('Trocar pastor'), findsNothing);
  });

  testWidgets('avisaQuandoOPastorAnteriorMantemOPapel', (tester) async {
    final tela = await _abrir(
      tester,
      _user(tipo: IgrejaTipo.matriz, pessoaId: 'px', caps: {Capacidade.filialCriar}),
      anteriorMantevePastor: true,
    );
    final antes = tela.igrejas.listagens;

    await _trocarPara(tester, 'Ana Costa');

    expect(
      find.text('O pastor anterior mantém o papel PASTOR até você removê-lo em Papéis.'),
      findsOneWidget,
    );
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(tela.igrejas.listagens, greaterThan(antes));
    // quem trocou não era o titular: as permissões dele não mudaram
    expect(tela.auth.recargas, 0);
    expect(find.text('Você não é mais o pastor desta igreja.'), findsNothing);
  });

  testWidgets('semAvisoQuandoOAnteriorPerdeuOPapel', (tester) async {
    await _abrir(
      tester,
      _user(tipo: IgrejaTipo.matriz, pessoaId: 'px', caps: {Capacidade.filialCriar}),
    );

    await _trocarPara(tester, 'Ana Costa');

    expect(find.textContaining('mantém o papel PASTOR'), findsNothing);
  });

  testWidgets('titularQueSeTrocaEhAvisadoERecarregaMe', (tester) async {
    final tela = await _abrir(
      tester,
      _user(tipo: IgrejaTipo.filial, pessoaId: 'p8', caps: {Capacidade.papeisGestaoAtribuir}),
    );

    await _trocarPara(tester, 'Ana Costa');

    expect(find.text('Você não é mais o pastor desta igreja.'), findsOneWidget);
    expect(tela.auth.recargas, 1);
  });

  testWidgets('titularQueMantemPastorRecebeUmAvisoSo', (tester) async {
    final tela = await _abrir(
      tester,
      _user(tipo: IgrejaTipo.filial, pessoaId: 'p8', caps: {Capacidade.papeisGestaoAtribuir}),
      anteriorMantevePastor: true,
    );

    await _trocarPara(tester, 'Ana Costa');

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text(
        'Você deixou de ser o pastor titular, mas mantém o papel PASTOR até ele ser removido em Papéis.',
      ),
      findsOneWidget,
    );
    expect(tela.auth.recargas, 1);
  });

  testWidgets('falhaAoRecarregarAListaNaoEscondeOAvisoDoTitular', (tester) async {
    final tela = await _abrir(
      tester,
      _user(tipo: IgrejaTipo.filial, pessoaId: 'p8', caps: {Capacidade.papeisGestaoAtribuir}),
      falharListagem: true,
    );

    await _trocarPara(tester, 'Ana Costa');

    expect(find.text('Você não é mais o pastor desta igreja.'), findsOneWidget);
    expect(tela.auth.recargas, 1);
  });
}
