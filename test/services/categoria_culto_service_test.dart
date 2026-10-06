import 'package:base_church/config/app_config.dart';
import 'package:base_church/models/models.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/categoria_culto_service.dart';
import 'package:base_church/services/culto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late CategoriaCultoService categorias;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient(await SharedPreferences.getInstance());
  });

  setUp(() {
    expect(AppConfig.useMock, isTrue, reason: 'estes testes exigem modo mock');
    categorias = CategoriaCultoService(api);
  });

  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  group('CategoriaCultoService.list', () {
    test('sem filtros devolve todas as categorias ordenadas por título', () async {
      final itens = await categorias.list();

      expect(itens.map((c) => c.id).toList(), ['cat3', 'cat1', 'cat2']);
    });

    test('filtra por igreja', () async {
      final matriz = await categorias.list(igrejaId: 'i1');
      final filial = await categorias.list(igrejaId: 'i2');

      expect(matriz.map((c) => c.id).toSet(), {'cat1', 'cat2'});
      expect(filial.map((c) => c.id).toList(), ['cat3']);
    });

    test('filtra por ativo', () async {
      expect(await categorias.list(ativo: true), hasLength(3));
      expect(await categorias.list(ativo: false), isEmpty);
    });

    test('filtra por igreja e ativo juntos', () async {
      expect(await categorias.list(igrejaId: 'i1', ativo: false), isEmpty);
      expect(await categorias.list(igrejaId: 'i2', ativo: true), hasLength(1));
    });
  });

  group('CategoriaCultoService.getById', () {
    test('devolve a categoria encontrada', () async {
      final categoria = await categorias.getById('cat2');

      expect(categoria.titulo, 'Sábado jovem');
      expect(categoria.diaSemana, DiaSemana.sabado);
      expect(categoria.duracaoMinutos, 120);
      expect(categoria.ativo, isTrue);
    });

    test('lança quando a categoria não existe', () async {
      await expectLater(
        categorias.getById('nao-existe'),
        throwsWithMessage('Categoria não encontrada.'),
      );
    });
  });

  group('CategoriaCultoService.create', () {
    CategoriaCulto nova({String titulo = 'Culto Jovem Extra', String igreja = 'i1'}) =>
        CategoriaCulto(
          id: '',
          igrejaId: igreja,
          titulo: titulo,
          descricao: 'Nova categoria',
          diaSemana: DiaSemana.quarta,
          horaInicio: '19:00:00',
          duracaoMinutos: 60,
          pregadorPadraoId: 'p1',
          pregadorPadraoNome: 'Ana Costa',
          ativo: false,
        );

    test('gera id, normaliza o título e força ativo', () async {
      final created = await categorias.create(nova(titulo: '  Culto Jovem Extra  '));

      expect(created.id, startsWith('cat-'));
      expect(created.titulo, 'Culto Jovem Extra');
      expect(created.ativo, isTrue);
      expect(created.diaSemana, DiaSemana.quarta);
      expect(created.duracaoMinutos, 60);
    });

    test('recusa título duplicado na mesma igreja ignorando caixa e espaços', () async {
      await expectLater(
        categorias.create(nova(titulo: '  domingo inesquecível ')),
        throwsWithMessage('Título já existe nesta igreja.'),
      );
    });

    test('aceita o mesmo título em outra igreja', () async {
      final created = await categorias.create(
        nova(titulo: 'Domingo inesquecível', igreja: 'i2'),
      );

      expect(created.titulo, 'Domingo inesquecível');
    });

    test('a categoria criada entra na listagem da igreja', () async {
      final created = await categorias.create(nova());

      final itens = await categorias.list(igrejaId: 'i1');
      expect(itens.map((c) => c.id), contains(created.id));
      expect(itens.first.id, created.id, reason: 'insert no topo');
    });
  });

  group('CategoriaCultoService.update', () {
    test('altera os campos e mantém o id', () async {
      final original = await categorias.getById('cat3');
      final updated = await categorias.update(
        CategoriaCulto(
          id: original.id,
          igrejaId: 'i1',
          titulo: '  Domingo Zona Sul Novo  ',
          descricao: 'Alterada',
          diaSemana: DiaSemana.segunda,
          horaInicio: '18:30:00',
          duracaoMinutos: 75,
          pregadorPadraoId: 'p2',
          pregadorPadraoNome: 'João da Silva',
          ativo: false,
        ),
      );

      expect(updated.id, 'cat3');
      expect(updated.igrejaId, 'i1');
      expect(updated.titulo, 'Domingo Zona Sul Novo');
      expect(updated.descricao, 'Alterada');
      expect(updated.diaSemana, DiaSemana.segunda);
      expect(updated.duracaoMinutos, 75);
      expect(updated.ativo, isFalse);
    });

    test('lança quando a categoria não existe', () async {
      await expectLater(
        categorias.update(
          const CategoriaCulto(
            id: 'nao-existe',
            igrejaId: 'i1',
            titulo: 'X',
            diaSemana: DiaSemana.domingo,
            horaInicio: '20:00:00',
            duracaoMinutos: 60,
            ativo: true,
          ),
        ),
        throwsWithMessage('Categoria não encontrada.'),
      );
    });
  });

  group('CategoriaCultoService.delete', () {
    test('desativa a categoria quando ela já tem cultos vinculados', () async {
      await categorias.delete('cat1');

      final categoria = await categorias.getById('cat1');
      expect(categoria.ativo, isFalse);
      expect(await categorias.list(ativo: false), hasLength(1));
      expect(await categorias.list(ativo: true), hasLength(2));
    });

    test('remove definitivamente a categoria sem cultos', () async {
      final created = await categorias.create(
        const CategoriaCulto(
          id: '',
          igrejaId: 'i1',
          titulo: 'Categoria Descartável',
          diaSemana: DiaSemana.sabado,
          horaInicio: '10:00:00',
          duracaoMinutos: 30,
          ativo: true,
        ),
      );

      await categorias.delete(created.id);

      await expectLater(
        categorias.getById(created.id),
        throwsWithMessage('Categoria não encontrada.'),
      );
    });
  });

  group('CategoriaCultoService.gerarCultos', () {
    test('cria um culto por dia da semana na competência', () async {
      final mensagem = await categorias.gerarCultos('cat2', competencia: '2026-11');

      expect(mensagem, 'Cultos de Sábado jovem em 2026-11: 4 criados.');

      final cultos = await CultoService(api).list(
        competencia: '2026-11',
        categoriaId: 'cat2',
      );

      expect(cultos, hasLength(4));
      expect(cultos.map((c) => c.data).toList(), [
        '2026-11-07',
        '2026-11-14',
        '2026-11-21',
        '2026-11-28',
      ]);
    });

    test('os cultos gerados usam hora de início e duração da categoria', () async {
      await categorias.gerarCultos('cat1', competencia: '2026-11');

      final cultos = await CultoService(api).list(competencia: '2026-11');

      expect(cultos, hasLength(5));
      expect(cultos.every((c) => c.categoriaCultoId == 'cat1'), isTrue);
      expect(cultos.every((c) => c.horaInicio == '20:00:00'), isTrue);
      expect(cultos.every((c) => c.horaFim == '21:30:00'), isTrue);
      expect(cultos.every((c) => c.status == CultoStatus.agendado), isTrue);
      expect(cultos.every((c) => c.temRelatorio == false), isTrue);
    });

    test('sem competência informada usa a competência corrente', () async {
      final agora = DateTime.now();
      final esperado =
          '${agora.year}-${(agora.month + 1).toString().padLeft(2, '0')}';

      final mensagem = await categorias.gerarCultos('cat2');

      expect(mensagem, startsWith('Cultos de Sábado jovem em $esperado'));
      expect(mensagem, endsWith('criados.'));
    });

    test('lança quando a categoria não existe', () async {
      await expectLater(
        categorias.gerarCultos('nao-existe', competencia: '2026-11'),
        throwsWithMessage('Categoria não encontrada.'),
      );
    });
  });

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