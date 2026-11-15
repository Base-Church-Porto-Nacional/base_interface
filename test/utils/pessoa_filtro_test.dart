import 'package:base_church/services/pessoa_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

void main() {
  Map<String, Object?> pessoa(String id, {bool? aceitou, bool? batizado, bool? trilha}) => {
        'id': id,
        'nome': 'Pessoa $id',
        'papeis': ['MEMBRO'],
        'aceitouJesus': aceitou,
        'batizado': batizado,
        'concluiuTrilhaBase': trilha,
      };

  Future<List<String>> filtrar(String filtro) async {
    final fake = FakeApi({
      'GET /pessoas': (_) => (200, [
            pessoa('a', aceitou: true, batizado: true, trilha: true),
            pessoa('b', aceitou: true, batizado: false, trilha: false),
            pessoa('c'),
          ]),
    });
    final api = await apiClientDeTeste();
    final page = await fake.run(() => PessoaService(api).list(filtro: filtro));
    return page.content.map((p) => p.id).toList();
  }

  test('filtra pelas etapas da jornada enviadas na listagem', () async {
    expect(await filtrar('ACEITOU_JESUS'), ['a', 'b']);
    expect(await filtrar('BATIZADO'), ['a']);
    expect(await filtrar('TRILHA'), ['a']);
    expect(await filtrar('TODOS'), ['a', 'b', 'c']);
  });
}
