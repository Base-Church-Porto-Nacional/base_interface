import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cultoStatus conversions', () {
    test('round-trip com a API para todos os status', () {
      for (final status in CultoStatus.values) {
        expect(cultoStatusFromApi(cultoStatusApiToString(status)), status);
      }
    });

    test('siglas e rótulos esperados', () {
      expect(cultoStatusApiToString(CultoStatus.agendado), 'AGENDADO');
      expect(cultoStatusApiToString(CultoStatus.aberto), 'ABERTO');
      expect(cultoStatusApiToString(CultoStatus.realizado), 'REALIZADO');
      expect(cultoStatusApiToString(CultoStatus.cancelado), 'CANCELADO');

      expect(cultoStatusLabel(CultoStatus.agendado), 'Agendado');
      expect(cultoStatusLabel(CultoStatus.realizado), 'Realizado');
      expect(cultoStatusLabel(CultoStatus.cancelado), 'Cancelado');
    });

    test('aceita minúsculas e cai em agendado para valores inválidos', () {
      expect(cultoStatusFromApi('realizado'), CultoStatus.realizado);
      expect(cultoStatusFromApi(''), CultoStatus.agendado);
      expect(cultoStatusFromApi('adiado'), CultoStatus.agendado);
    });
  });

  group('diaSemana conversions', () {
    test('round-trip para a API de todos os dias', () {
      for (final dia in DiaSemana.values) {
        expect(diaSemanaFromApi(diaSemanaApiToString(dia)), dia);
      }
    });

    test('rótulos em português', () {
      expect(diaSemanaLabel(DiaSemana.domingo), 'Domingo');
      expect(diaSemanaLabel(DiaSemana.terca), 'Terça');
      expect(diaSemanaLabel(DiaSemana.sabado), 'Sábado');
    });

    test('diaSemanaFromApi e diaSemanaFromString caem em domingo', () {
      expect(diaSemanaFromApi('QUARTA'), DiaSemana.quarta);
      expect(diaSemanaFromApi('quarta'), DiaSemana.quarta);
      expect(diaSemanaFromApi('sábado'), DiaSemana.domingo);
      expect(diaSemanaFromString('SABADO'), DiaSemana.sabado);
      expect(diaSemanaFromString('terca'), DiaSemana.terca);
      expect(diaSemanaFromString('xyz'), DiaSemana.domingo);
    });
  });

  group('Culto.copyWith', () {
    test('preserva identidade e categoria, altera o informado', () {
      const base = Culto(
        id: 'culto-1',
        igrejaId: 'i1',
        categoriaCultoId: 'cat1',
        categoriaCultoTitulo: 'Domingo inesquecível',
        titulo: 'Culto de domingo',
        tema: 'Tema A',
        data: '2026-09-06',
        horaInicio: '20:00:00',
        horaFim: '21:30:00',
        pregadorId: 'p1',
        status: CultoStatus.aberto,
        competencia: '2026-09',
        escalaId: 'e1',
        ativo: true,
        janelaConfiguracaoAberta: true,
        temRelatorio: true,
      );

      final updated = base.copyWith(status: CultoStatus.realizado);

      expect(updated.id, 'culto-1');
      expect(updated.igrejaId, 'i1');
      expect(updated.categoriaCultoId, 'cat1');
      expect(updated.escalaId, 'e1');
      expect(updated.status, CultoStatus.realizado);
      expect(updated.tema, 'Tema A');
    });
  });

  group('CultoRelatorio', () {
    test('totalPresentes soma adultos e crianças', () {
      const relatorio = CultoRelatorio(
        cultoId: 'c1',
        adultos: 40,
        criancas: 12,
      );
      expect(relatorio.totalPresentes, 52);
    });

    test('totalVeiculos soma carros, motos e bicicletas', () {
      const relatorio = CultoRelatorio(
        cultoId: 'c1',
        carros: 10,
        motos: 4,
        bicicletas: 0,
      );
      expect(relatorio.totalVeiculos, 14);
    });

    test('copyWith preserva o cultoId e o que não foi informado', () {
      const base = CultoRelatorio(
        cultoId: 'c1',
        adultos: 10,
        criancas: 5,
        observacoes: 'Original',
      );

      final updated = base.copyWith(adultos: 20);

      expect(updated.cultoId, 'c1');
      expect(updated.adultos, 20);
      expect(updated.criancas, 5);
      expect(updated.observacoes, 'Original');
    });
  });
}
