import 'package:base_church/config/app_config.dart';
import 'package:base_church/models/models.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/conteudo_culto_service.dart';
import 'package:base_church/services/cronograma_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late CronogramaService cronograma;
  late ConteudoCultoService conteudos;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient(await SharedPreferences.getInstance());
  });

  setUp(() {
    expect(AppConfig.useMock, isTrue, reason: 'estes testes exigem modo mock');
    cronograma = CronogramaService(api);
    conteudos = ConteudoCultoService(api);
  });

  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  group('CronogramaService.list', () {
    test('devolve lista vazia quando a igreja não é informada', () async {
      expect(await cronograma.list(), isEmpty);
      expect(await cronograma.list(igrejaId: ''), isEmpty);
    });

    test('filtra por igreja e ordena por data', () async {
      final itens = await cronograma.list(igrejaId: 'i1');

      expect(itens.map((e) => e.id).toList(), ['c1', 'c2', 'c5', 'c3', 'c4']);
      final datas = itens.map((e) => e.data).toList();
      expect(datas, orderedEquals([...datas]..sort()));
    });

    test('respeita o filtro de igreja da filial', () async {
      final itens = await cronograma.list(igrejaId: 'i2');

      expect(itens.map((e) => e.id).toList(), ['c6']);
      expect(itens.single.igrejaId, 'i2');
    });
  });

  group('CronogramaService.getById', () {
    test('devolve o evento encontrado', () async {
      final evento = await cronograma.getById('c5');

      expect(evento.titulo, 'Encontro de jovens');
      expect(evento.tipo, TipoEvento.evento);
      expect(evento.localEvento, 'Salão');
      expect(evento.ativo, isTrue);
    });

    test('lança quando o evento não existe', () async {
      await expectLater(
        cronograma.getById('nao-existe'),
        throwsWithMessage('Evento não encontrado.'),
      );
    });
  });

  group('CronogramaService.create', () {
    const novo = CultoEvento(
      id: '',
      titulo: 'Encontro de jovens',
      tipo: TipoEvento.ensaio,
      data: '2026-08-01',
      horaInicio: '19:00',
      horaFim: '21:00',
      localEvento: 'Salão',
      descricao: 'Ensaio preparatório',
      igrejaId: 'i1',
      supervisorPessoaId: 'p1',
      supervisorNome: 'Ana Costa',
      ativo: true,
    );

    test('gera id, insere no topo e preserva os campos', () async {
      final created = await cronograma.create(novo);

      expect(created.id, startsWith('c'));
      expect(created.id, isNot('c1'));
      expect(created.titulo, novo.titulo);
      expect(created.tipo, TipoEvento.ensaio);
      expect(created.localEvento, 'Salão');
      expect(created.descricao, 'Ensaio preparatório');
      expect(created.supervisorPessoaId, 'p1');
    });

    test('o evento criado aparece na listagem da igreja', () async {
      final created = await cronograma.create(novo);

      final itens = await cronograma.list(igrejaId: 'i1');
      expect(itens.map((e) => e.id), contains(created.id));
      expect(itens.first.id, created.id, reason: '2026-08-01 é a data mais antiga');
    });

    test('mantém o evento inativo quando enviado como inativo', () async {
      final created = await cronograma.create(
        const CultoEvento(
          id: '',
          titulo: 'Evento inativo',
          tipo: TipoEvento.outro,
          data: '2026-08-01',
          horaInicio: '10:00',
          igrejaId: 'i1',
          supervisorPessoaId: 'p1',
          supervisorNome: 'Ana Costa',
          ativo: false,
        ),
      );

      expect(created.ativo, isFalse);
      expect((await cronograma.getById(created.id)).ativo, isFalse);
    });
  });

  group('ConteudoCultoService', () {
    test('getByEvento devolve o conteúdo existente', () async {
      final conteudo = await conteudos.getByEvento('c2');

      expect(conteudo.eventoId, 'c2');
      expect(conteudo.textoPregacao, contains('João 15'));
      expect(conteudo.louvor, contains('Oceanos'));
      expect(conteudo.pregadorPessoaId, 'p1');
      expect(conteudo.pregadorNome, 'Ana Costa');
    });

    test('getByEvento devolve conteúdo vazio para evento sem registro', () async {
      final conteudo = await conteudos.getByEvento('c1');

      expect(conteudo.eventoId, 'c1');
      expect(conteudo.textoPregacao, isEmpty);
      expect(conteudo.louvor, isEmpty);
      expect(conteudo.pregadorPessoaId, isNull);
    });

    test('save substitui o conteúdo existente do evento', () async {
      await conteudos.save(
        const ConteudoCulto(
          eventoId: 'c3',
          textoPregacao: 'Novo texto',
          louvor: 'Novo louvor',
          pregadorPessoaId: 'p2',
        ),
      );

      final conteudo = await conteudos.getByEvento('c3');
      expect(conteudo.textoPregacao, 'Novo texto');
      expect(conteudo.louvor, 'Novo louvor');
      expect(conteudo.pregadorPessoaId, 'p2');
    });

    test('save cria o registro quando o evento ainda não tem conteúdo', () async {
      final conteudo = await conteudos.save(
        const ConteudoCulto(
          eventoId: 'c4',
          textoPregacao: 'Primeiro registro',
          louvor: 'Hino',
        ),
      );

      expect(conteudo.eventoId, 'c4');
      expect(conteudo.textoPregacao, 'Primeiro registro');
      expect((await conteudos.getByEvento('c4')).textoPregacao, 'Primeiro registro');
    });
  });

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