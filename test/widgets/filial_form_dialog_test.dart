import 'package:base_church/services/igreja_service.dart';
import 'package:base_church/widgets/form_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

import 'package:base_church/models/models.dart';

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

void main() {
  testWidgets('novaFilialNaoPedeUsuarioDoAdmin', (tester) async {
    Map<String, dynamic>? resultado;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                resultado = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => FilialFormDialog(pessoas: const [_pastor]),
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

    expect(find.text('Usuário do admin *'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome da filial *'),
      'Filial Norte',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Costa').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome do admin *'),
      'Carlos',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail do admin *'),
      'carlos@x.com',
    );
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(resultado, isNotNull);
    expect(resultado!['adminEmail'], 'carlos@x.com');
    expect(resultado!.containsKey('adminUsername'), isFalse);
  });

  test('createFilialNaoEnviaAdminUsername', () async {
    final fake = FakeApi({
      'POST /igrejas/i1/filiais': (_) =>
          (201, {'id': 'i9', 'nome': 'Filial Norte', 'tipo': 'FILIAL'}),
    });
    final api = await apiClientDeTeste();
    await fake.run(
      () => IgrejaService(api).createFilial(
        matrizId: 'i1',
        nome: 'Filial Norte',
        pastorPessoaId: 'p1',
        pastorNome: 'Ana',
        adminNome: 'Carlos',
        adminEmail: 'carlos@x.com',
      ),
    );

    final corpo = fake.corpo(0) as Map<String, dynamic>;
    expect(corpo.containsKey('adminUsername'), isFalse);
    expect(corpo['adminEmail'], 'carlos@x.com');
  });
}
