import 'package:base_church/config/app_config.dart';
import 'package:base_church/models/models.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/culto_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late CultoService cultos;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient(await SharedPreferences.getInstance());
  });

  setUp(() {
    expect(AppConfig.useMock, isTrue, reason: 'estes testes exigem modo mock');
    cultos = CultoService(api);
  });

  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  group('CultoService.list', () {
    test('sem filtros devolve todos os cultos ordenados por data', () async {
      final itens = await cultos.list();

      expect(itens, hasLength(10));
      final datas = itens.map((c) => c.data).toList();
      expect(datas, orderedEquals([...datas]..sort()));
      expect(itens.first.data, '2026-09-05');
    });

    test('filtra por igreja', () async {
      final matriz = await cultos.list(igrejaId: 'i1');
      final filial = await cultos.list(igrejaId: 'i2');

      expect(matriz, hasLength(8));
      expect(filial, hasLength(2));
      expect(filial.every((c) => c.igrejaId == 'i2'), isTrue);
    });

    test('filtra por categoria de culto', () async {
      final itens = await cultos.list(categoriaId: 'cat2');

      expect(itens, hasLength(4));
      expect(itens.every((c) => c.categoriaCultoId == 'cat2'), isTrue);
    });

    test('filtra por competência', () async {
      expect(await cultos.list(competencia: '2026-09'), hasLength(10));
      expect(await cultos.list(competencia: '2026-10'), isEmpty);
    });

    test('filtra por status', () async {
      final realizados = await cultos.list(status: CultoStatus.realizado);

      expect(realizados.map((c) => c.id).toSet(), {'culto-1', 'culto-5', 'culto-9'});
      expect(await cultos.list(status: CultoStatus.cancelado), isEmpty);
    });

    test('filtra por intervalo de datas inclusivo', () async {
      final itens = await cultos.list(inicio: '2026-09-13', fim: '2026-09-20');

      expect(itens.map((c) => c.id).toSet(), {'culto-2', 'culto-3', 'culto-7', 'culto-10'});
      final datas = itens.map((c) => c.data).toList();
      expect(datas, orderedEquals([...datas]..sort()));
    });

    test('filtra por ativo', () async {
      expect(await cultos.list(ativo: true), hasLength(10));
      expect(await cultos.list(ativo: false), isEmpty);
    });

    test('combina filtros de igreja e categoria', () async {
      final itens = await cultos.list(igrejaId: 'i2', categoriaId: 'cat3');

      expect(itens.map((c) => c.id).toList(), ['culto-9', 'culto-10']);
      expect(await cultos.list(igrejaId: 'i2', categoriaId: 'cat1'), isEmpty);
    });
  });

  group('CultoService.getById', () {
    test('devolve o culto encontrado', () async {
      final culto = await cultos.getById('culto-3');

      expect(culto.categoriaCultoTitulo, 'Domingo inesquecível');
      expect(culto.status, CultoStatus.agendado);
      expect(culto.temRelatorio, isFalse);
    });

    test('lança quando o culto não existe', () async {
      await expectLater(
        cultos.getById('nao-existe'),
        throwsWithMessage('Culto não encontrado.'),
      );
    });
  });

  group('CultoService.create', () {
    Culto novo({String data = '2026-10-04', String categoria = 'cat1'}) => Culto(
      id: '',
      igrejaId: 'i1',
      categoriaCultoId: categoria,
      categoriaCultoTitulo: 'Domingo inesquecível',
      titulo: 'Culto novo',
      tema: 'Tema novo',
      data: data,
      horaInicio: '20:00',
      horaFim: '21:30',
      pregadorId: 'p1',
      pregadorNome: 'Ana Costa',
      status: CultoStatus.agendado,
      competencia: '2026-10',
      ativo: true,
      janelaConfiguracaoAberta: false,
      temRelatorio: true,
    );

    test('gera id e força agendado, ativo e sem relatório', () async {
      final created = await cultos.create(novo());

      expect(created.id, startsWith('culto-'));
      expect(created.status, CultoStatus.agendado);
      expect(created.ativo, isTrue);
      expect(created.temRelatorio, isFalse);
      expect(created.titulo, 'Culto novo');
      expect(created.tema, 'Tema novo');
      expect(created.pregadorNome, 'Ana Costa');
    });

    test('recusa categoria e data duplicadas', () async {
      await expectLater(
        cultos.create(novo(data: '2026-09-06', categoria: 'cat1')),
        throwsWithMessage('Já existe um culto desta categoria nesta data.'),
      );
    });

    test('permite a mesma data em categorias diferentes', () async {
      final created = await cultos.create(novo(data: '2026-09-06', categoria: 'cat2'));

      expect(created.categoriaCultoId, 'cat2');
    });

    test('o culto criado aparece na listagem da competência', () async {
      final created = await cultos.create(novo());

      final itens = await cultos.list(competencia: '2026-10');
      expect(itens.map((c) => c.id), [created.id]);
    });
  });

  group('CultoService.update', () {
    test('altera os campos editáveis e preserva os imutáveis', () async {
      final original = await cultos.getById('culto-3');

      final updated = await cultos.update(
        original.copyWith(
          titulo: 'Culto atualizado',
          tema: 'Novo tema',
          horaInicio: '19:00:00',
          status: CultoStatus.aberto,
          ativo: false,
        ),
      );

      expect(updated.titulo, 'Culto atualizado');
      expect(updated.tema, 'Novo tema');
      expect(updated.horaInicio, '19:00:00');
      expect(updated.status, CultoStatus.aberto);
      expect(updated.ativo, isFalse);
      expect(updated.competencia, original.competencia);
      expect(updated.categoriaCultoId, original.categoriaCultoId);
      expect(updated.categoriaCultoTitulo, original.categoriaCultoTitulo);
      expect(updated.escalaId, original.escalaId);
      expect(updated.temRelatorio, original.temRelatorio);
    });

    test('mantém o nome do pregador quando o novo não é informado', () async {
      final original = await cultos.getById('culto-3');

      final semNome = Culto(
        id: original.id,
        igrejaId: original.igrejaId,
        categoriaCultoId: original.categoriaCultoId,
        categoriaCultoTitulo: original.categoriaCultoTitulo,
        titulo: 'Sem pregador informado',
        data: original.data,
        horaInicio: original.horaInicio,
        status: original.status,
        competencia: original.competencia,
        ativo: original.ativo,
        janelaConfiguracaoAberta: original.janelaConfiguracaoAberta,
        temRelatorio: original.temRelatorio,
      );

      final updated = await cultos.update(semNome);
      expect(updated.pregadorNome, 'Ana Costa');
    });

    test('lança quando o culto não existe', () async {
      await expectLater(
        cultos.update(
          Culto(
            id: 'nao-existe',
            igrejaId: 'i1',
            categoriaCultoId: 'cat1',
            categoriaCultoTitulo: 'x',
            titulo: 'x',
            data: '2026-09-06',
            horaInicio: '20:00:00',
            status: CultoStatus.agendado,
            competencia: '2026-09',
            ativo: true,
            janelaConfiguracaoAberta: true,
            temRelatorio: false,
          ),
        ),
        throwsWithMessage('Culto não encontrado.'),
      );
    });
  });

  group('CultoService.delete', () {
    test('remove o culto sem relatório', () async {
      await cultos.delete('culto-3');

      await expectLater(
        cultos.getById('culto-3'),
        throwsWithMessage('Culto não encontrado.'),
      );
      expect(await cultos.list(competencia: '2026-09'), hasLength(9));
    });

    test('recusa excluir culto que já possui relatório', () async {
      await expectLater(
        cultos.delete('culto-1'),
        throwsWithMessage('Não é possível excluir um culto que já possui relatório'),
      );
      expect(await cultos.getById('culto-1'), isNotNull);
    });

    test('lança quando o culto não existe', () async {
      await expectLater(
        cultos.delete('nao-existe'),
        throwsWithMessage('Culto não encontrado.'),
      );
    });
  });

  group('CultoService conteúdo', () {
    test('getConteudo devolve o conteúdo cadastrado', () async {
      final conteudo = await cultos.getConteudo('culto-2');

      expect(conteudo.cultoId, 'culto-2');
      expect(conteudo.textoPregacao, contains('Mateus 11:28'));
      expect(conteudo.pregadorId, 'p1');
    });

    test('getConteudo devolve registro vazio quando não há conteúdo', () async {
      final conteudo = await cultos.getConteudo('culto-3');

      expect(conteudo.cultoId, 'culto-3');
      expect(conteudo.textoPregacao, isNull);
      expect(conteudo.louvor, isNull);
      expect(conteudo.pregadorId, isNull);
    });

    test('saveConteudo cria o registro quando não existe', () async {
      final salvo = await cultos.saveConteudo('culto-3', louvor: 'Hino novo');

      expect(salvo.cultoId, 'culto-3');
      expect(salvo.louvor, 'Hino novo');
      expect(salvo.textoPregacao, isNull);
    });

    test('saveConteudo mescla apenas os campos enviados', () async {
      await cultos.saveConteudo('culto-3', louvor: 'Hino novo');
      final salvo = await cultos.saveConteudo('culto-3', tema: 'Tema novo');

      expect(salvo.louvor, 'Hino novo');
      expect(salvo.tema, 'Tema novo');
      expect((await cultos.getConteudo('culto-3')).louvor, 'Hino novo');
    });

    test('saveConteudo resolve o nome do pregador pela pessoa', () async {
      final salvo = await cultos.saveConteudo('culto-2', pregadorPessoaId: 'p2');

      expect(salvo.pregadorId, 'p2');
      expect(salvo.pregadorNome, 'João da Silva');
      expect(salvo.textoPregacao, 'Mateus 11:28 — Vinde a mim.');
    });
  });

  group('CultoService relatório', () {
    test('getRelatorio devolve relatório existente', () async {
      final relatorio = await cultos.getRelatorio('culto-1');

      expect(relatorio.adultos, 19);
      expect(relatorio.criancas, 2);
      expect(relatorio.totalPresentes, 21);
    });

    test('getRelatorio devolve relatório zerado quando não existe', () async {
      final relatorio = await cultos.getRelatorio('culto-3');

      expect(relatorio.cultoId, 'culto-3');
      expect(relatorio.totalPresentes, 0);
      expect(relatorio.totalVeiculos, 0);
      expect(relatorio.observacoes, isNull);
    });

    test('saveRelatorio marca o culto como realizado e com relatório', () async {
      await cultos.saveRelatorio(
        const CultoRelatorio(
          cultoId: 'culto-3',
          adultos: 30,
          criancas: 10,
          conversoes: 2,
          carros: 5,
          motos: 3,
          observacoes: 'Bom culto',
        ),
      );

      final culto = await cultos.getById('culto-3');
      expect(culto.status, CultoStatus.realizado);
      expect(culto.temRelatorio, isTrue);

      final relatorio = await cultos.getRelatorio('culto-3');
      expect(relatorio.adultos, 30);
      expect(relatorio.totalPresentes, 40);
      expect(relatorio.totalVeiculos, 8);
    });

    test('saveRelatorio substitui o relatório já existente', () async {
      await cultos.saveRelatorio(const CultoRelatorio(cultoId: 'culto-1', adultos: 1));
      await cultos.saveRelatorio(const CultoRelatorio(cultoId: 'culto-1', adultos: 99));

      expect((await cultos.getRelatorio('culto-1')).adultos, 99);
    });
  });

  group('CultoService automação de calendário', () {
    test('gerarMes cria os cultos da competência para as categorias ativas', () async {
      final mensagem = await cultos.gerarMes('2026-11', igrejaId: 'i1');

      expect(
        mensagem,
        matches(RegExp(r'^Cultos de 2026-11 gerados: \d+ criados, 0 já existentes\.$')),
      );

      final gerados = await cultos.list(competencia: '2026-11');
      expect(gerados, isNotEmpty);
      expect(gerados.every((c) => c.igrejaId == 'i1'), isTrue);
      expect(gerados.every((c) => c.status == CultoStatus.agendado), isTrue);
      expect(gerados.every((c) => c.horaFim == '21:30:00'), isTrue);
    });

    test('gerarMes é idempotente: a segunda chamada não duplica', () async {
      await cultos.gerarMes('2026-11', igrejaId: 'i1');
      final antes = (await cultos.list(competencia: '2026-11')).length;

      final mensagem = await cultos.gerarMes('2026-11', igrejaId: 'i1');

      expect(mensagem, matches(RegExp(r'gerados: 0 criados, \d+ já existentes\.')));
      expect((await cultos.list(competencia: '2026-11')).length, antes);
    });

    test('gerarMes respeita o filtro de igreja', () async {
      await cultos.gerarMes('2026-11', igrejaId: 'i2');

      final filial = await cultos.list(competencia: '2026-11');
      expect(filial, isNotEmpty);
      expect(filial.every((c) => c.igrejaId == 'i2'), isTrue);
      expect(await cultos.list(igrejaId: 'i1', competencia: '2026-11'), isEmpty);
    });

    test('gerarProximoMes usa a competência corrente', () async {
      final agora = DateTime.now();
      final esperado =
          '${agora.year}-${(agora.month + 1).toString().padLeft(2, '0')}';

      final mensagem = await cultos.gerarProximoMes(igrejaId: 'i1');

      expect(mensagem, contains(esperado));
    });
  });

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
      const relatorio = CultoRelatorio(cultoId: 'c1', adultos: 40, criancas: 12);
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