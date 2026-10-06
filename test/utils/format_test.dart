import 'package:base_church/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDate', () {
    test('converte data ISO para o formato brasileiro', () {
      expect(formatDate('2026-09-06'), '06/09/2026');
      expect(formatDate('2026-01-01'), '01/01/2026');
      expect(formatDate('2026-12-31'), '31/12/2026');
    });

    test('devolve o valor original quando a data é inválida', () {
      expect(formatDate('sem-data'), 'sem-data');
      expect(formatDate(''), '');
    });
  });

  group('formatDateShort', () {
    test('mostra apenas dia e mês', () {
      expect(formatDateShort('2026-09-06'), '06/09');
    });

    test('devolve o valor original quando a data é inválida', () {
      expect(formatDateShort('06/09/2026'), '06/09/2026');
    });
  });

  group('formatCompetencia', () {
    test('converte a competência em mês por extenso', () {
      expect(formatCompetencia('2026-01'), 'Janeiro 2026');
      expect(formatCompetencia('2026-09'), 'Setembro 2026');
      expect(formatCompetencia('2026-12'), 'Dezembro 2026');
    });

    test('devolve o valor original quando não há mês', () {
      expect(formatCompetencia('2026'), '2026');
      expect(formatCompetencia(''), '');
    });

    test('limita meses fora do intervalo ao primeiro e ao último', () {
      expect(formatCompetencia('2026-00'), 'Janeiro 2026');
      expect(formatCompetencia('2026-13'), 'Dezembro 2026');
      expect(formatCompetencia('2026-99'), 'Dezembro 2026');
    });

    test('usa janeiro quando o mês não é numérico', () {
      expect(formatCompetencia('2026-xx'), 'Janeiro 2026');
    });
  });

  group('competenciaFrom', () {
    test('formata a competência com mês preenchido com zero', () {
      expect(competenciaFrom(DateTime(2026, 1, 5)), '2026-01');
      expect(competenciaFrom(DateTime(2026, 9, 30)), '2026-09');
      expect(competenciaFrom(DateTime(2026, 12, 31)), '2026-12');
    });

    test('ignora o dia', () {
      expect(competenciaFrom(DateTime(2026, 5, 1)), competenciaFrom(DateTime(2026, 5, 31)));
    });
  });

  group('isoDate', () {
    test('formata a data em ISO sem horário', () {
      expect(isoDate(DateTime(2026, 9, 6)), '2026-09-06');
      expect(isoDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(isoDate(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('sundaysInMonth', () {
    test('lista os domingos do mês', () {
      expect(sundaysInMonth(2026, 11).map(isoDate), [
        '2026-11-01',
        '2026-11-08',
        '2026-11-15',
        '2026-11-22',
        '2026-11-29',
      ]);
    });

    test('inclui o dia 1 quando o mês começa no domingo', () {
      expect(sundaysInMonth(2026, 2).map(isoDate), [
        '2026-02-01',
        '2026-02-08',
        '2026-02-15',
        '2026-02-22',
      ]);
    });

    test('todos os dias devolvidos são domingos', () {
      for (final data in sundaysInMonth(2026, 12)) {
        expect(data.weekday, DateTime.sunday);
        expect(data.month, 12);
      }
    });
  });

  group('formatHora', () {
    test('corta os segundos', () {
      expect(formatHora('18:00:00'), '18:00');
      expect(formatHora('18:30:59'), '18:30');
    });

    test('mantém valores que já não têm segundos', () {
      expect(formatHora('18:00'), '18:00');
    });

    test('devolve vazio para nulo ou string vazia', () {
      expect(formatHora(null), '');
      expect(formatHora(''), '');
    });
  });

  group('normalizeHoraApi', () {
    test('acrescenta os segundos quando faltam', () {
      expect(normalizeHoraApi('18:00'), '18:00:00');
      expect(normalizeHoraApi('07:05'), '07:05:00');
    });

    test('preserva valores que já têm segundos', () {
      expect(normalizeHoraApi('18:00:00'), '18:00:00');
    });

    test('remove espaços antes de processar', () {
      expect(normalizeHoraApi('  19:30  '), '19:30:00');
    });

    test('devolve vazio sem alterar', () {
      expect(normalizeHoraApi(''), '');
      expect(normalizeHoraApi('   '), '');
    });

    test('preserva formatos inesperados', () {
      expect(normalizeHoraApi('depois'), 'depois');
    });
  });

  group('mesesPt', () {
    test('tem os doze meses em português', () {
      expect(mesesPt, hasLength(12));
      expect(mesesPt.first, 'Janeiro');
      expect(mesesPt.last, 'Dezembro');
      expect(mesesPt[2], 'Março');
    });
  });
}