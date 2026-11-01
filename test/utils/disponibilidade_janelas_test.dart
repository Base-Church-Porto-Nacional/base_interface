import 'package:base_church/models/models.dart';
import 'package:base_church/utils/disponibilidade_janelas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('janelasDisponiveis', () {
    test('sem nenhum bloqueio não gera janelas (sem restrição)', () {
      expect(janelasDisponiveis(const []), isEmpty);
      expect(
        janelasDisponiveis(const [
          IndisponibilidadeSemanal(dia: DiaSemana.quarta),
        ]),
        isEmpty,
      );
    });

    test('dias livres viram uma janela de dia inteiro', () {
      final janelas = janelasDisponiveis(const [
        IndisponibilidadeSemanal(
          dia: DiaSemana.quarta,
          manha: true,
          tarde: true,
          noite: true,
        ),
      ]);

      expect(janelas.where((j) => j.dia == DiaSemana.quarta), isEmpty);
      final domingo = janelas.singleWhere((j) => j.dia == DiaSemana.domingo);
      expect(domingo.horaInicio, '00:00:00');
      expect(domingo.horaFim, '23:59:00');
      expect(janelas, hasLength(6));
    });

    test(
      'períodos livres contíguos são unidos e o bloqueio parte a janela',
      () {
        final tarde = janelasDisponiveis(const [
          IndisponibilidadeSemanal(dia: DiaSemana.sabado, tarde: true),
        ]).where((j) => j.dia == DiaSemana.sabado).toList();

        expect(tarde.map((j) => (j.horaInicio, j.horaFim)), [
          ('00:00:00', '12:00:00'),
          ('18:00:00', '23:59:00'),
        ]);

        final manha = janelasDisponiveis(const [
          IndisponibilidadeSemanal(dia: DiaSemana.segunda, manha: true),
        ]).singleWhere((j) => j.dia == DiaSemana.segunda);
        expect((manha.horaInicio, manha.horaFim), ('12:00:00', '23:59:00'));
      },
    );
  });

  group('indisponibilidadesDasJanelas', () {
    test('sem janelas significa nenhum bloqueio', () {
      expect(indisponibilidadesDasJanelas(const []), isEmpty);
    });

    test('ida e volta preserva a grade marcada', () {
      const grade = [
        IndisponibilidadeSemanal(dia: DiaSemana.segunda, manha: true),
        IndisponibilidadeSemanal(
          dia: DiaSemana.quarta,
          manha: true,
          tarde: true,
          noite: true,
        ),
        IndisponibilidadeSemanal(dia: DiaSemana.sabado, tarde: true),
      ];

      final volta = indisponibilidadesDasJanelas(janelasDisponiveis(grade));

      expect(
        volta.map((d) => (d.dia, d.manha, d.tarde, d.noite)),
        grade.map((d) => (d.dia, d.manha, d.tarde, d.noite)),
      );
    });

    test('janela parcial não libera o período inteiro', () {
      final volta = indisponibilidadesDasJanelas(const [
        JanelaDisponivel(
          dia: DiaSemana.domingo,
          inicioMin: 19 * 60,
          fimMin: 21 * 60,
        ),
      ]);

      final domingo = volta.singleWhere((d) => d.dia == DiaSemana.domingo);
      expect((domingo.manha, domingo.tarde, domingo.noite), (true, true, true));
      expect(volta, hasLength(7));
    });
  });

  test('parseHoraMinutos aceita HH:mm e HH:mm:ss', () {
    expect(parseHoraMinutos('18:30'), 18 * 60 + 30);
    expect(parseHoraMinutos('06:00:00'), 360);
    expect(parseHoraMinutos('x'), isNull);
    expect(parseHoraMinutos(null), isNull);
  });
}
