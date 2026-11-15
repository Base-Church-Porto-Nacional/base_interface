import 'package:base_church/models/models.dart';
import 'package:base_church/widgets/lista_presenca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Pessoa _pessoa(String id, String nome) => Pessoa(
  id: id,
  nome: nome,
  telefone: '',
  email: '',
  status: PessoaStatus.ativo,
  tipos: const [],
  ministerios: const [],
  dataCadastro: '2026-01-01',
  igrejaId: 'i1',
);

List<Pessoa> _muitas(int n) => [
  for (var i = 0; i < n; i++) _pessoa('p$i', 'Pessoa ${i.toString().padLeft(3, '0')}'),
];

Future<Set<String>> _montar(
  WidgetTester tester,
  List<Pessoa> pessoas, {
  Set<String> marcados = const {},
}) async {
  var atual = {...marcados};
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => ListaPresenca(
              pessoas: pessoas,
              marcados: atual,
              onChanged: (novos) => setState(() => atual = novos),
            ),
          ),
        ),
      ),
    ),
  );
  return atual;
}

void main() {
  testWidgets('listaPequenaMostraTodos', (tester) async {
    await _montar(tester, _muitas(5));

    for (var i = 0; i < 5; i++) {
      expect(find.text('Pessoa 00$i'), findsOneWidget);
    }
    expect(find.text('0 presentes'), findsOneWidget);
  });

  testWidgets('listaGrandePedeBuscaEMostraSoMarcados', (tester) async {
    await _montar(tester, _muitas(50), marcados: {'p7'});

    expect(find.text('Pessoa 007'), findsOneWidget);
    expect(find.text('Pessoa 010'), findsNothing);
    expect(find.textContaining('Digite o nome'), findsOneWidget);
    expect(find.text('1 presente'), findsOneWidget);
  });

  testWidgets('buscaEncontraEMarca', (tester) async {
    await _montar(tester, _muitas(50));

    await tester.enterText(find.widgetWithText(TextField, 'Buscar pessoa'), 'pessoa 049');
    await tester.pumpAndSettle();
    expect(find.text('Pessoa 048'), findsNothing);
    await tester.tap(find.text('Pessoa 049'));
    await tester.pumpAndSettle();

    expect(find.text('1 presente'), findsOneWidget);
    // marcado continua visível depois de limpar a busca
    await tester.enterText(find.widgetWithText(TextField, 'Buscar pessoa'), '');
    await tester.pumpAndSettle();
    expect(find.text('Pessoa 049'), findsOneWidget);
  });

  testWidgets('desmarcarTiraDaContagem', (tester) async {
    await _montar(tester, _muitas(3), marcados: {'p1'});

    await tester.tap(find.text('Pessoa 001'));
    await tester.pumpAndSettle();

    expect(find.text('0 presentes'), findsOneWidget);
  });
}
