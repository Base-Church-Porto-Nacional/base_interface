import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndisponibilidadeSemanal', () {
    test('marcado é verdadeiro quando algum turno está bloqueado', () {
      expect(
        const IndisponibilidadeSemanal(dia: DiaSemana.domingo).marcado,
        isFalse,
      );
      expect(
        const IndisponibilidadeSemanal(
          dia: DiaSemana.domingo,
          manha: true,
        ).marcado,
        isTrue,
      );
      expect(
        const IndisponibilidadeSemanal(
          dia: DiaSemana.domingo,
          tarde: true,
        ).marcado,
        isTrue,
      );
      expect(
        const IndisponibilidadeSemanal(
          dia: DiaSemana.domingo,
          noite: true,
        ).marcado,
        isTrue,
      );
    });

    test('copyWith mantém o dia e alterna os turnos', () {
      const base = IndisponibilidadeSemanal(
        dia: DiaSemana.segunda,
        manha: true,
        tarde: true,
        noite: true,
      );

      final updated = base.copyWith(manha: false, tarde: false, noite: false);

      expect(updated.dia, DiaSemana.segunda);
      expect(updated.marcado, isFalse);
    });
  });
}
