import 'package:base_church/models/models.dart';
import 'package:base_church/services/pessoa_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

void main() {
  Map<String, Object?> jornada({
    bool aceitou = false,
    bool batizado = false,
    bool trilha = false,
    bool membro = false,
  }) => {
        'id': 'j1',
        'pessoaId': 'p1',
        'aceitouJesus': aceitou,
        'dataAceitouJesus': aceitou ? '2026-01-10' : null,
        'batizado': batizado,
        'dataBatismo': batizado ? '2026-03-02' : null,
        'concluiuTrilhaBase': trilha,
        'dataConclusaoTrilhaBase': null,
        'membro': membro,
        'dataMembro': null,
      };

  Future<List<JornadaEtapa>> carregar(
    Map<String, Object?> principal,
    List<Object?> etapas,
  ) async {
    final fake = FakeApi({
      'GET /pessoas/p1/jornada': (_) => (200, principal),
      'GET /pessoas/p1/jornada/etapas': (_) => (200, etapas),
    });
    final api = await apiClientDeTeste();
    return fake.run(() => PessoaService(api).jornada('p1'));
  }

  test('monta as quatro etapas principais com a primeira pendente como atual', () async {
    final etapas = await carregar(jornada(aceitou: true, batizado: true), []);

    expect(etapas.map((e) => e.titulo), [
      'Aceitou Jesus',
      'Batismo',
      'Trilha da Base',
      'Membro',
    ]);
    expect(etapas.map((e) => e.status), [
      JornadaEtapaStatus.concluido,
      JornadaEtapaStatus.concluido,
      JornadaEtapaStatus.atual,
      JornadaEtapaStatus.pendente,
    ]);
    expect(etapas[0].data, '2026-01-10');
    expect(etapas[1].data, '2026-03-02');
    expect(etapas[2].data, isNull);
  });

  test('acrescenta as etapas extras registradas para a pessoa', () async {
    final etapas = await carregar(
      jornada(aceitou: true, batizado: true, trilha: true, membro: true),
      [
        {
          'id': 'r1',
          'etapaNome': 'Escola de líderes',
          'concluida': true,
          'dataConclusao': '2026-05-01',
        },
        {'id': 'r2', 'etapaNome': 'Encontro', 'concluida': false},
      ],
    );

    expect(etapas, hasLength(6));
    expect(etapas[4].titulo, 'Escola de líderes');
    expect(etapas[4].status, JornadaEtapaStatus.concluido);
    expect(etapas[4].data, '2026-05-01');
    expect(etapas[5].titulo, 'Encontro');
    expect(etapas[5].status, JornadaEtapaStatus.atual);
  });
}
