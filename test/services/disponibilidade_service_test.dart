import 'package:base_church/config/app_config.dart';
import 'package:base_church/models/models.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/disponibilidade_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late DisponibilidadeService disponibilidade;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient(await SharedPreferences.getInstance());
  });

  setUp(() {
    expect(AppConfig.useMock, isTrue, reason: 'estes testes exigem modo mock');
    disponibilidade = DisponibilidadeService(api);
  });

  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  group('getByPessoa', () {
    test('devolve a disponibilidade cadastrada', () async {
      final result = await disponibilidade.getByPessoa('p2');

      expect(result.pessoaId, 'p2');
      expect(result.semanal, hasLength(2));
      expect(result.datas, hasLength(2));
      expect(result.datas.first.motivo, 'Viagem');
    });

    test('devolve registros vazios para pessoa sem disponibilidade', () async {
      final result = await disponibilidade.getByPessoa('p9');

      expect(result.pessoaId, 'p9');
      expect(result.semanal, isEmpty);
      expect(result.datas, isEmpty);
    });
  });

  group('saveSemanal', () {
    test('substitui a grade semanal preservando as datas', () async {
      final result = await disponibilidade.saveSemanal(
        pessoaId: 'p2',
        semanal: const [
          IndisponibilidadeSemanal(dia: DiaSemana.quarta, manha: true),
          IndisponibilidadeSemanal(dia: DiaSemana.sabado, noite: true),
        ],
      );

      expect(result.semanal.map((d) => d.dia), [
        DiaSemana.quarta,
        DiaSemana.sabado,
      ]);
      expect(result.datas, hasLength(2), reason: 'as datas não são afetadas');

      final relido = await disponibilidade.getByPessoa('p2');
      expect(relido.semanal, hasLength(2));
      expect(relido.datas, hasLength(2));
    });

    test('cria o registro para quem ainda não tinha disponibilidade', () async {
      final result = await disponibilidade.saveSemanal(
        pessoaId: 'p9',
        semanal: const [IndisponibilidadeSemanal(dia: DiaSemana.sexta, tarde: true)],
      );

      expect(result.pessoaId, 'p9');
      expect(result.semanal.single.tarde, isTrue);
      expect((await disponibilidade.getByPessoa('p9')).semanal, hasLength(1));
    });
  });

  group('addData', () {
    test('adiciona uma indisponibilidade pontual', () async {
      final item = await disponibilidade.addData(
        pessoaId: 'p2',
        data: '2026-12-25',
        motivo: 'Natal',
      );

      expect(item.id, startsWith('d'));
      expect(item.pessoaId, 'p2');
      expect(item.data, '2026-12-25');
      expect(item.motivo, 'Natal');

      final relido = await disponibilidade.getByPessoa('p2');
      expect(relido.datas, hasLength(3));
      expect(relido.datas.map((d) => d.data), contains('2026-12-25'));
    });

    test('aceita indisponibilidade sem motivo', () async {
      final item = await disponibilidade.addData(pessoaId: 'p3', data: '2026-10-10');

      expect(item.motivo, isNull);
      expect((await disponibilidade.getByPessoa('p3')).datas, hasLength(2));
    });

    test('cria a disponibilidade de quem ainda não tinha registro', () async {
      await disponibilidade.addData(pessoaId: 'p9', data: '2026-10-10');

      final relido = await disponibilidade.getByPessoa('p9');
      expect(relido.pessoaId, 'p9');
      expect(relido.datas, hasLength(1));
      expect(relido.semanal, isEmpty);
    });

    test('preserva a grade semanal existente', () async {
      await disponibilidade.addData(pessoaId: 'p3', data: '2026-10-10');

      final relido = await disponibilidade.getByPessoa('p3');
      expect(relido.semanal, hasLength(1));
      expect(relido.semanal.single.dia, DiaSemana.quarta);
    });
  });

  group('removeData', () {
    test('remove a indisponibilidade pelo id', () async {
      await disponibilidade.removeData('p2', 'd1');

      final relido = await disponibilidade.getByPessoa('p2');
      expect(relido.datas.map((d) => d.id).toList(), ['d2']);
    });

    test('ignora id inexistente sem alterar a lista', () async {
      await disponibilidade.removeData('p2', 'nao-existe');

      expect((await disponibilidade.getByPessoa('p2')).datas, hasLength(2));
    });

    test('ignora pessoa sem disponibilidade sem criar registro', () async {
      await disponibilidade.removeData('p9', 'd1');

      final relido = await disponibilidade.getByPessoa('p9');
      expect(relido.datas, isEmpty);
      expect(relido.semanal, isEmpty);
    });

    test('preserva a grade semanal ao remover uma data', () async {
      await disponibilidade.removeData('p2', 'd1');

      final relido = await disponibilidade.getByPessoa('p2');
      expect(relido.semanal, hasLength(2));
    });
  });

  group('IndisponibilidadeSemanal', () {
    test('marcado é verdadeiro quando algum turno está bloqueado', () {
      expect(const IndisponibilidadeSemanal(dia: DiaSemana.domingo).marcado, isFalse);
      expect(
        const IndisponibilidadeSemanal(dia: DiaSemana.domingo, manha: true).marcado,
        isTrue,
      );
      expect(
        const IndisponibilidadeSemanal(dia: DiaSemana.domingo, tarde: true).marcado,
        isTrue,
      );
      expect(
        const IndisponibilidadeSemanal(dia: DiaSemana.domingo, noite: true).marcado,
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