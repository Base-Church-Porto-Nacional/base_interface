import 'package:base_church/models/models.dart';
import 'package:base_church/services/usuario_service.dart';
import 'package:base_church/widgets/acesso_app_card.dart';
import 'package:base_church/widgets/link_acesso_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_api.dart';
import '../helpers/fixtures.dart';

Pessoa pessoa({
  String? usuarioId,
  String? acesso,
  List<PessoaTipo> tipos = const [PessoaTipo.membro],
  List<String> papeis = const [],
}) => Pessoa(
  id: 'p9',
  nome: 'Bruno',
  telefone: '',
  email: 'b@x.com',
  status: PessoaStatus.ativo,
  tipos: tipos,
  papeis: papeis,
  ministerios: const [],
  dataCadastro: '2026-01-01',
  igrejaId: 'i1',
  usuarioId: usuarioId,
  acessoStatus: acesso,
);

Future<FakeApi> abrir(
  WidgetTester tester,
  Pessoa p,
  AuthUser user, {
  Map<String, Rota> rotas = const {},
  VoidCallback? onAlterado,
}) async {
  final fake = FakeApi(rotas);
  final api = await apiClientDeTeste();
  await fake.run(() async {
    await tester.pumpWidget(
      Provider<UsuarioService>.value(
        value: UsuarioService(api),
        child: MaterialApp(
          home: Scaffold(
            body: AcessoAppCard(
              pessoa: p,
              user: user,
              onAlterado: onAlterado ?? () {},
              onPapeis: null,
            ),
          ),
        ),
      ),
    );
  });
  return fake;
}

void main() {
  testWidgets('semAcessoMostraConvidar', (tester) async {
    await abrir(tester, pessoa(), mockUser);
    expect(find.text('Sem acesso'), findsOneWidget);
    expect(find.text('Convidar'), findsOneWidget);
    expect(find.text('Redefinir senha'), findsNothing);
    expect(find.text('Desativar'), findsNothing);
  });

  testWidgets('convidadoMostraReenviar', (tester) async {
    await abrir(tester, pessoa(usuarioId: 'u9', acesso: 'CONVIDADO'), mockUser);
    expect(find.text('Convite pendente'), findsOneWidget);
    expect(find.text('Convite enviado'), findsNothing);
    expect(find.text('Reenviar convite'), findsOneWidget);
    expect(find.text('Convidar'), findsNothing);
    expect(find.text('Redefinir senha'), findsNothing);
  });

  testWidgets('ativoMostraRedefinirEDesativar', (tester) async {
    await abrir(tester, pessoa(usuarioId: 'u9', acesso: 'ATIVO'), mockUser);
    expect(find.text('Ativo'), findsOneWidget);
    expect(find.text('Redefinir senha'), findsOneWidget);
    expect(find.text('Desativar'), findsOneWidget);
    expect(find.text('Reativar'), findsNothing);
  });

  testWidgets('desativadoMostraReativar', (tester) async {
    await abrir(
      tester,
      pessoa(usuarioId: 'u9', acesso: 'DESATIVADO'),
      mockUser,
    );
    expect(find.text('Desativado'), findsOneWidget);
    expect(find.text('Reativar'), findsOneWidget);
    expect(find.text('Convidar'), findsNothing);
    expect(find.text('Desativar'), findsNothing);
  });

  testWidgets('membroNaoVeAcoes', (tester) async {
    const membro = AuthUser(
      id: 'u7',
      nome: 'Membro',
      email: 'm@x.com',
      papeis: ['MEMBRO'],
      permissoes: Permissoes(),
      igrejaId: 'i1',
      igrejaTipo: IgrejaTipo.matriz,
      igrejaNome: 'Base Church',
    );
    await abrir(tester, pessoa(usuarioId: 'u9', acesso: 'ATIVO'), membro);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('liderConvidaMasNaoRedefineNemDesativa', (tester) async {
    await abrir(tester, pessoa(), mockUserLider);
    expect(find.text('Convidar'), findsOneWidget);

    await abrir(
      tester,
      pessoa(usuarioId: 'u9', acesso: 'ATIVO'),
      mockUserLider,
    );
    expect(find.text('Redefinir senha'), findsNothing);
    expect(find.text('Desativar'), findsNothing);
  });

  testWidgets('propriaContaNaoMostraDesativarNemRedefinir', (tester) async {
    await abrir(
      tester,
      pessoa(
        usuarioId: mockUser.id,
        acesso: 'ATIVO',
        tipos: const [PessoaTipo.pastor],
      ),
      mockUser,
    );
    expect(find.text('Ativo'), findsOneWidget);
    expect(find.text('Redefinir senha'), findsNothing);
    expect(find.text('Desativar'), findsNothing);
  });

  testWidgets('secretariaNaoGereContaDePastor', (tester) async {
    await abrir(
      tester,
      pessoa(
        usuarioId: 'u9',
        acesso: 'ATIVO',
        tipos: const [PessoaTipo.pastor],
      ),
      mockUserSecretaria,
    );
    expect(find.text('Redefinir senha'), findsNothing);
    expect(find.text('Desativar'), findsNothing);

    await abrir(
      tester,
      pessoa(usuarioId: 'u9', acesso: 'DESATIVADO', papeis: const ['PASTOR']),
      mockUserSecretaria,
    );
    expect(find.text('Reativar'), findsNothing);
  });

  testWidgets('secretariaNaoGereContaDeOutraSecretaria', (tester) async {
    await abrir(
      tester,
      pessoa(usuarioId: 'u9', acesso: 'ATIVO', papeis: const ['SECRETARIA']),
      mockUserSecretaria,
    );
    expect(find.text('Redefinir senha'), findsNothing);
    expect(find.text('Desativar'), findsNothing);
  });

  testWidgets('secretariaGereContaDeMembro', (tester) async {
    await abrir(
      tester,
      pessoa(usuarioId: 'u9', acesso: 'ATIVO'),
      mockUserSecretaria,
    );
    expect(find.text('Redefinir senha'), findsOneWidget);
    expect(find.text('Desativar'), findsOneWidget);
  });

  testWidgets('pastorGereContaDeSecretaria', (tester) async {
    await abrir(
      tester,
      pessoa(usuarioId: 'u9', acesso: 'ATIVO', papeis: const ['SECRETARIA']),
      mockUser,
    );
    expect(find.text('Redefinir senha'), findsOneWidget);
    expect(find.text('Desativar'), findsOneWidget);
  });

  testWidgets('convidar chama o servidor, mostra o link e avisa onAlterado', (
    tester,
  ) async {
    var alterou = 0;
    final fake = await abrir(
      tester,
      pessoa(),
      mockUser,
      onAlterado: () => alterou++,
      rotas: {
        'POST /pessoas/p9/convite': (_) =>
            (200, {'link': 'https://app/acesso/abc', 'enviadoWhatsapp': true}),
      },
    );

    await fake.run(() async {
      await tester.tap(find.text('Convidar'));
      await tester.pumpAndSettle();
    });

    expect(fake.log, ['POST /pessoas/p9/convite']);
    expect(find.text('Enviamos pelo WhatsApp.'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(alterou, 1);
  });

  testWidgets('erro 422 do servidor aparece em SnackBar', (tester) async {
    final fake = await abrir(
      tester,
      pessoa(),
      mockUser,
      rotas: {
        'POST /pessoas/p9/convite': (_) =>
            (422, {'message': 'Cadastre e-mail ou WhatsApp antes de convidar'}),
      },
    );

    await fake.run(() async {
      await tester.tap(find.text('Convidar'));
      await tester.pumpAndSettle();
    });

    expect(
      find.text('Cadastre e-mail ou WhatsApp antes de convidar'),
      findsOneWidget,
    );
  });

  testWidgets('desativar pede confirmação e faz POST', (tester) async {
    final fake = await abrir(
      tester,
      pessoa(usuarioId: 'u9', acesso: 'ATIVO'),
      mockUser,
      rotas: {
        'POST /usuarios/u9/desativar': (_) =>
            (200, {'id': 'u9', 'status': 'DESATIVADO'}),
      },
    );

    await fake.run(() async {
      await tester.tap(find.text('Desativar'));
      await tester.pumpAndSettle();
      expect(fake.log, isEmpty);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
    });

    expect(fake.log, ['POST /usuarios/u9/desativar']);
  });

  group('LinkAcessoDialog', () {
    Future<void> abrirDialog(
      WidgetTester tester, {
      required bool whatsapp,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkAcessoDialog(
              link: 'https://app/acesso/abc',
              enviadoWhatsapp: whatsapp,
            ),
          ),
        ),
      );
    }

    testWidgets('linkNaoEnviadoMostraCopiar', (tester) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiado = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await abrirDialog(tester, whatsapp: false);
      expect(
        find.text(
          'Não foi possível enviar pelo WhatsApp. Copie o link e envie para a pessoa.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Copiar link'));
      await tester.pump();

      expect(copiado, 'https://app/acesso/abc');
      expect(find.text('Link copiado'), findsOneWidget);
    });

    testWidgets('enviado pelo WhatsApp mostra a confirmação', (tester) async {
      await abrirDialog(tester, whatsapp: true);
      expect(find.text('Enviamos pelo WhatsApp.'), findsOneWidget);
      expect(find.text('Copiar link'), findsOneWidget);
    });
  });
}
