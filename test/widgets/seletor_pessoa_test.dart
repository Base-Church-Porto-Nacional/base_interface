import 'package:base_church/models/models.dart';
import 'package:base_church/widgets/seletor_pessoa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Pessoa _pessoa(String id, String nome, {String email = '', String telefone = ''}) => Pessoa(
  id: id,
  nome: nome,
  telefone: telefone,
  email: email,
  status: PessoaStatus.ativo,
  tipos: const [],
  ministerios: const [],
  dataCadastro: '2026-01-01',
  igrejaId: 'i1',
);

Future<void> _montar(
  WidgetTester tester,
  List<Pessoa> pessoas,
  void Function(String?) onChanged,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SeletorPessoa(pessoas: pessoas, label: 'Pastor *', onChanged: onChanged),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('encontraPessoaAlemDasCemPrimeiras', (tester) async {
    final pessoas = [
      for (var i = 0; i < 150; i++) _pessoa('p$i', 'Pessoa ${i.toString().padLeft(3, '0')}'),
    ];
    String? escolhido;
    await _montar(tester, pessoas, (id) => escolhido = id);

    await tester.enterText(find.widgetWithText(TextField, 'Pastor *'), 'Pessoa 149');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pessoa 149').last);
    await tester.pumpAndSettle();

    expect(escolhido, 'p149');
  });

  testWidgets('buscaIgnoraMaiusculasEAcentos', (tester) async {
    String? escolhido;
    await _montar(
      tester,
      [_pessoa('p1', 'José Antônio'), _pessoa('p2', 'Maria')],
      (id) => escolhido = id,
    );

    await tester.enterText(find.widgetWithText(TextField, 'Pastor *'), 'jose anto');
    await tester.pumpAndSettle();

    expect(find.text('Maria'), findsNothing);
    await tester.tap(find.text('José Antônio').last);
    await tester.pumpAndSettle();
    expect(escolhido, 'p1');
  });

  testWidgets('mudarOTextoDepoisDeEscolherLimpaASelecao', (tester) async {
    String? escolhido;
    await _montar(tester, [_pessoa('p1', 'Ana Costa')], (id) => escolhido = id);

    await tester.enterText(find.widgetWithText(TextField, 'Pastor *'), 'Ana');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Costa').last);
    await tester.pumpAndSettle();
    expect(escolhido, 'p1');

    await tester.enterText(find.widgetWithText(TextField, 'Pastor *'), 'Ana C');
    await tester.pumpAndSettle();
    expect(escolhido, isNull);
  });

  testWidgets('homonimosSaoDiferenciadosPeloContato', (tester) async {
    String? escolhido;
    await _montar(
      tester,
      [
        _pessoa('p1', 'João Silva', email: 'joao1@x.com'),
        _pessoa('p2', 'João Silva', email: 'joao2@x.com', telefone: '63999990000'),
      ],
      (id) => escolhido = id,
    );

    await tester.enterText(find.widgetWithText(TextField, 'Pastor *'), 'joao');
    await tester.pumpAndSettle();

    expect(find.text('joao1@x.com'), findsOneWidget);
    expect(find.text('joao2@x.com · 63999990000'), findsOneWidget);
    await tester.tap(find.text('joao2@x.com · 63999990000'));
    await tester.pumpAndSettle();
    expect(escolhido, 'p2');
  });

  testWidgets('sugestoesEmOrdemAlfabetica', (tester) async {
    await _montar(
      tester,
      [_pessoa('p1', 'Carla'), _pessoa('p2', 'Ana'), _pessoa('p3', 'Bruno')],
      (_) {},
    );

    await tester.tap(find.widgetWithText(TextField, 'Pastor *'));
    await tester.pumpAndSettle();

    final ana = tester.getTopLeft(find.text('Ana')).dy;
    final bruno = tester.getTopLeft(find.text('Bruno')).dy;
    final carla = tester.getTopLeft(find.text('Carla')).dy;
    expect(ana < bruno && bruno < carla, isTrue);
  });
}
