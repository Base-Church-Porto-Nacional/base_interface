import 'package:base_church/widgets/competencia_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('anosCompetencia', () {
    test('cobre do ano passado até daqui a dois anos', () {
      final atual = DateTime.now().year;
      expect(anosCompetencia(atual), [atual - 1, atual, atual + 1, atual + 2]);
    });

    test('inclui o ano selecionado mesmo fora da faixa', () {
      final atual = DateTime.now().year;
      expect(anosCompetencia(atual - 5).first, atual - 5);
      expect(anosCompetencia(atual + 6).last, atual + 6);
    });
  });

  group('partesCompetencia', () {
    test('separa ano e mês', () {
      expect(partesCompetencia('2027-03'), (2027, 3));
    });

    test('cai no mês atual quando inválido', () {
      final now = DateTime.now();
      expect(partesCompetencia('xx'), (now.year, now.month));
    });
  });
}
