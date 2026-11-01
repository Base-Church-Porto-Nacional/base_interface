import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoriaCulto.copyWith', () {
    test('mantém id e igreja e altera os campos informados', () {
      const base = CategoriaCulto(
        id: 'cat1',
        igrejaId: 'i1',
        titulo: 'Domingo inesquecível',
        descricao: 'Culto oficial',
        diaSemana: DiaSemana.domingo,
        horaInicio: '20:00:00',
        duracaoMinutos: 90,
        pregadorPadraoId: 'p1',
        pregadorPadraoNome: 'Ana Costa',
        ativo: true,
      );

      final updated = base.copyWith(ativo: false, duracaoMinutos: 60);

      expect(updated.id, 'cat1');
      expect(updated.igrejaId, 'i1');
      expect(updated.titulo, 'Domingo inesquecível');
      expect(updated.descricao, 'Culto oficial');
      expect(updated.ativo, isFalse);
      expect(updated.duracaoMinutos, 60);
    });
  });
}
