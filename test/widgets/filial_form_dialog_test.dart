import 'package:base_church/models/models.dart';
import 'package:base_church/widgets/form_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pastor = Pessoa(
  id: 'p1',
  nome: 'Ana Costa',
  telefone: '',
  email: '',
  status: PessoaStatus.ativo,
  tipos: [PessoaTipo.pastor],
  ministerios: [],
  dataCadastro: '2026-01-01',
  igrejaId: 'i1',
);

Pessoa _pessoa(String id, String nome, {bool ativa = true}) => Pessoa(
  id: id,
  nome: nome,
  telefone: '',
  email: '',
  status: ativa ? PessoaStatus.ativo : PessoaStatus.inativo,
  tipos: const [],
  ministerios: const [],
  dataCadastro: '2026-01-01',
  igrejaId: 'i1',
);

Future<void> _abrirDialogo<T>(
  WidgetTester tester,
  Widget dialogo,
  void Function(T?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              onResult(await showDialog<T>(context: context, builder: (_) => dialogo));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<Map<String, dynamic>?> _abrir(
  WidgetTester tester,
  void Function(Map<String, dynamic>?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              onResult(
                await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => FilialFormDialog(pessoas: const [_pastor]),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return null;
}

void main() {
  testWidgets('semCamposDeAdmin', (tester) async {
    Map<String, dynamic>? resultado;
    await _abrir(tester, (r) => resultado = r);

    expect(find.text('Nome do admin *'), findsNothing);
    expect(find.text('E-mail do admin *'), findsNothing);
    expect(find.textContaining('senha', findRichText: true), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome da filial *'),
      'Filial Norte',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Costa').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(resultado, isNotNull);
    expect(resultado!['pastorPessoaId'], 'p1');
    expect(resultado!.containsKey('adminEmail'), isFalse);
    // modo pessoa existente: o nome não vai junto (o servidor usa só o pessoaId)
    expect(resultado!.containsKey('pastorNome'), isFalse);
  });

  testWidgets('seletorDaFilialIgnoraInativosEExcluidos', (tester) async {
    await _abrirDialogo<Map<String, dynamic>>(
      tester,
      FilialFormDialog(
        pessoas: [
          _pastor,
          _pessoa('p2', 'Bia Inativa', ativa: false),
          _pessoa('p3', 'Caio Titular'),
        ],
        excluirIds: const {'p3'},
      ),
      (_) {},
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Ana Costa'), findsWidgets);
    expect(find.text('Bia Inativa'), findsNothing);
    expect(find.text('Caio Titular'), findsNothing);
  });

  testWidgets('seletorDaFilialSoComExcluidosAbreEmNovaPessoa', (tester) async {
    await _abrirDialogo<Map<String, dynamic>>(
      tester,
      FilialFormDialog(
        pessoas: [_pessoa('p2', 'Bia Inativa', ativa: false)],
      ),
      (_) {},
    );

    expect(find.widgetWithText(TextField, 'Nome do pastor *'), findsOneWidget);
  });

  testWidgets('trocarPastorIgnoraInativosEOPastorAtual', (tester) async {
    String? escolhido;
    await _abrirDialogo<String>(
      tester,
      TrocarPastorDialog(
        pessoas: [
          _pastor,
          _pessoa('p2', 'Bia Inativa', ativa: false),
          _pessoa('p3', 'Caio Titular'),
        ],
        atualId: 'p3',
      ),
      (r) => escolhido = r,
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Bia Inativa'), findsNothing);
    expect(find.text('Caio Titular'), findsNothing);
    await tester.tap(find.text('Ana Costa').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trocar'));
    await tester.pumpAndSettle();
    expect(escolhido, 'p1');
  });

  testWidgets('novaPessoaExigeEmailOuWhatsapp', (tester) async {
    Map<String, dynamic>? resultado;
    await _abrir(tester, (r) => resultado = r);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome da filial *'),
      'Filial Norte',
    );
    await tester.tap(find.text('Nova pessoa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome do pastor *'),
      'Carlos',
    );
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    // sem e-mail nem WhatsApp: o diálogo continua aberto
    expect(find.text('Nova filial'), findsOneWidget);
    expect(find.text('Informe e-mail ou WhatsApp.'), findsOneWidget);
    expect(resultado, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail'),
      'carlos@x.com',
    );
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(resultado, isNotNull);
    expect(resultado!['pastorNome'], 'Carlos');
    expect(resultado!['pastorEmail'], 'carlos@x.com');
    expect(resultado!['pastorPessoaId'], isNull);
  });
}
