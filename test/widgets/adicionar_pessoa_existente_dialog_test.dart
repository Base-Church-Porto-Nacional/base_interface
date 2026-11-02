import 'package:base_church/models/models.dart';
import 'package:base_church/widgets/form_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  final louvor = mockMinisterios.first;

  Future<void> abrir(
    WidgetTester tester, {
    required Future<List<PessoaResumo>> Function(String) buscar,
    required Future<void> Function(String pessoaId, String servicoId) vincular,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdicionarPessoaExistenteDialog(
            ministerio: louvor,
            buscar: buscar,
            vincular: vincular,
          ),
        ),
      ),
    );
  }

  testWidgets('busca por nome (≥2), escolhe pessoa e serviço real e vincula', (tester) async {
    final termos = <String>[];
    (String, String)? vinculado;
    await abrir(
      tester,
      buscar: (t) async {
        termos.add(t);
        return const [PessoaResumo(id: 'p5', nome: 'Fernanda Dias')];
      },
      vincular: (p, s) async => vinculado = (p, s),
    );

    await tester.enterText(find.byKey(const Key('buscaPessoaExistente')), 'f');
    await tester.pump(const Duration(milliseconds: 400));
    expect(termos, isEmpty);

    await tester.enterText(find.byKey(const Key('buscaPessoaExistente')), 'fer');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(termos, ['fer']);

    await tester.tap(find.text('Fernanda Dias'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('servicoPessoaExistente')));
    await tester.pumpAndSettle();
    expect(find.text('Coordenador'), findsNothing);
    await tester.tap(find.text('Violão').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(vinculado, ('p5', 's1b'));
  });

  testWidgets('mostra o erro do servidor ao vincular', (tester) async {
    await abrir(
      tester,
      buscar: (_) async => const [PessoaResumo(id: 'p5', nome: 'Fernanda Dias')],
      vincular: (_, _) async => throw Exception('A pessoa já está vinculada a este serviço'),
    );

    await tester.enterText(find.byKey(const Key('buscaPessoaExistente')), 'fer');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fernanda Dias'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('servicoPessoaExistente')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vocal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('já está vinculada'), findsOneWidget);
  });
}
