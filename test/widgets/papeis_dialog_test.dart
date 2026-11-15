import 'package:base_church/widgets/form_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester, {
    required Future<List<String>> Function(String nome, bool contagem)? onCriarPapel,
    bool podeCustom = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PapeisDialog(
            pessoaNome: 'Bruno',
            atuais: const [],
            customizados: const [],
            podeGestao: false,
            podeCustom: podeCustom,
            onCriarPapel: onCriarPapel,
          ),
        ),
      ),
    );
  }

  testWidgets('cria papel com contagem e passa a listá-lo', (tester) async {
    String? nomeEnviado;
    bool? contagemEnviada;
    await abrir(tester, onCriarPapel: (nome, contagem) async {
      nomeEnviado = nome;
      contagemEnviada = contagem;
      return ['CONTADOR'];
    });

    await tester.enterText(find.byKey(const Key('novoPapelNome')), 'Contador');
    await tester.tap(find.text('Pode lançar contagem do culto'));
    await tester.tap(find.text('Criar papel'));
    await tester.pumpAndSettle();

    expect(nomeEnviado, 'Contador');
    expect(contagemEnviada, isTrue);
    expect(find.widgetWithText(CheckboxListTile, 'Contador'), findsOneWidget);
  });

  testWidgets('mostra o erro do servidor ao criar papel', (tester) async {
    await abrir(tester, onCriarPapel: (_, _) async => throw Exception('Nome de papel reservado: LIDER'));

    await tester.enterText(find.byKey(const Key('novoPapelNome')), 'LIDER');
    await tester.tap(find.text('Criar papel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('reservado'), findsOneWidget);
  });

  testWidgets('sem papeisCustomGerir não mostra o formulário', (tester) async {
    await abrir(tester, podeCustom: false, onCriarPapel: (_, _) async => []);

    expect(find.text('Criar papel'), findsNothing);
  });
}
