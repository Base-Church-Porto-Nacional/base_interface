import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConteudoCulto.copyWith', () {
    test('mantém eventoId e substitui apenas os campos informados', () {
      const base = ConteudoCulto(
        eventoId: 'c1',
        textoPregacao: 'Texto',
        louvor: 'Louvor',
        pregadorPessoaId: 'p1',
        pregadorNome: 'Ana Costa',
      );

      final updated = base.copyWith(louvor: 'Novo');

      expect(updated.eventoId, 'c1');
      expect(updated.louvor, 'Novo');
      expect(updated.textoPregacao, 'Texto');
      expect(updated.pregadorPessoaId, 'p1');
      expect(updated.pregadorNome, 'Ana Costa');
    });
  });

  group('tipoEventoLabel / tipoEventoToString / tipoEventoFromString', () {
    test('rótulos em português', () {
      expect(tipoEventoLabel(TipoEvento.culto), 'Culto');
      expect(tipoEventoLabel(TipoEvento.evento), 'Evento');
      expect(tipoEventoLabel(TipoEvento.ensaio), 'Ensaio');
      expect(tipoEventoLabel(TipoEvento.reuniao), 'Reunião');
      expect(tipoEventoLabel(TipoEvento.outro), 'Outro');
    });

    test('conversão para a API e volta preserva todos os tipos', () {
      for (final tipo in TipoEvento.values) {
        expect(tipoEventoFromString(tipoEventoToString(tipo)), tipo);
      }
    });

    test('tipoEventoToString usa as siglas esperadas pela API', () {
      expect(tipoEventoToString(TipoEvento.culto), 'CULTO');
      expect(tipoEventoToString(TipoEvento.evento), 'EVENTO');
      expect(tipoEventoToString(TipoEvento.ensaio), 'ENSAIO');
      expect(tipoEventoToString(TipoEvento.reuniao), 'REUNIAO');
      expect(tipoEventoToString(TipoEvento.outro), 'OUTRO');
    });

    test('tipoEventoFromString aceita minúsculas e cai em outro para valores inválidos', () {
      expect(tipoEventoFromString('ensaio'), TipoEvento.ensaio);
      expect(tipoEventoFromString('Reuniao'), TipoEvento.reuniao);
      expect(tipoEventoFromString(''), TipoEvento.outro);
      expect(tipoEventoFromString('palestra'), TipoEvento.outro);
    });
  });
}
