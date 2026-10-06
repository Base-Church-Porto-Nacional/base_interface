import 'package:base_church/config/app_config.dart';
import 'package:base_church/models/models.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/escala_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/support.dart';

const _semana = Escala(
  id: 'draft',
  titulo: 'Escala nova',
  competencia: '2026-12',
  tipo: EscalaTipo.culto,
  igrejaId: 'i1',
  supervisorPessoaId: 'p1',
  supervisorNome: 'Ana Costa',
  ativo: false,
  dataEvento: '2026-12-06',
  horaInicio: '18:00:00',
  horaFim: '20:00:00',
  servicos: [
    EscalaServico(
      id: 'x1',
      servicoId: 's1a',
      servicoNome: 'Vocal',
      quantidadeNecessaria: 2,
    ),
    EscalaServico(
      id: 'x2',
      servicoId: 's2b',
      servicoNome: 'Som',
      quantidadeNecessaria: 1,
    ),
  ],
);

const _vazio = Escala(
  id: 'draft',
  titulo: 'Escala sem serviços',
  competencia: '2026-12',
  tipo: EscalaTipo.culto,
  igrejaId: 'i1',
  supervisorPessoaId: 'p1',
  supervisorNome: 'Ana Costa',
  ativo: false,
  dataEvento: '2026-12-06',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient api;
  late EscalaService escalas;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient(await SharedPreferences.getInstance());
  });

  setUp(() {
    expect(AppConfig.useMock, isTrue, reason: 'estes testes exigem modo mock');
    escalas = EscalaService(api);
  });

  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  group('EscalaService.list', () {
    test('devolve vazio quando a igreja não é informada', () async {
      expect(await escalas.list(), isEmpty);
      expect(await escalas.list(igrejaId: ''), isEmpty);
    });

    test('filtra por igreja', () async {
      final matriz = await escalas.list(igrejaId: 'i1');
      final filial = await escalas.list(igrejaId: 'i2');

      expect(matriz, hasLength(7));
      expect(filial, isNotEmpty);
      expect(filial.every((e) => e.igrejaId == 'i2'), isTrue);
    });

    test('filtra por competência', () async {
      final itens = await escalas.list(igrejaId: 'i1', competencia: '2026-09');

      expect(itens.map((e) => e.id).toSet(), {
        'e-culto-set-lancado',
        'e-culto-set',
        'e-louvor-set',
      });
    });

    test('filtra por pessoa, reduzindo a escala às designações dela', () async {
      final itens = await escalas.list(igrejaId: 'i1', pessoaId: 'p3');

      expect(itens.map((e) => e.id).toSet(), {
        'e-culto',
        'e-louvor',
        'e-culto-set-lancado',
        'e-louvor-set',
      });
      for (final escala in itens) {
        expect(escala.voluntarios, isNotEmpty);
        expect(escala.voluntarios.every((v) => v.pessoaId == 'p3'), isTrue);
      }
    });

    test('descarta escalas sem designação para a pessoa filtrada', () async {
      final itens = await escalas.list(igrejaId: 'i1', pessoaId: 'p6');

      expect(itens, isEmpty);
    });
  });

  group('EscalaService.getById', () {
    test('devolve a escala com serviços e designações', () async {
      final escala = await escalas.getById('e-louvor');

      expect(escala.titulo, 'Louvor — agosto');
      expect(escala.status, EscalaStatus.editando);
      expect(escala.ministerioId, 'm1');
      expect(escala.servicos, hasLength(2));
      expect(escala.voluntarios, hasLength(2));
    });

    test('lança quando a escala não existe', () async {
      await expectLater(
        escalas.getById('nao-existe'),
        throwsWithMessage('Escala não encontrada.'),
      );
    });
  });

  group('EscalaService.create', () {
    test('gera id e força status editando e ativo', () async {
      final created = await escalas.create(_semana);

      expect(created.id, startsWith('e'));
      expect(created.status, EscalaStatus.editando);
      expect(created.ativo, isTrue);
      expect(created.titulo, 'Escala nova');
      expect(created.competencia, '2026-12');
      expect(created.dataEvento, '2026-12-06');
    });

    test('gera sugestões automáticas para preencher as vagas', () async {
      final created = await escalas.create(_semana);

      expect(created.voluntarios.map((v) => v.pessoaId).toList(), ['p2', 'p3', 'p4']);
      expect(
        created.voluntarios.map((v) => v.servicoNome).toList(),
        ['Vocal', 'Vocal', 'Som'],
      );
      expect(
        created.voluntarios.every((v) => v.status == EscalaItemStatus.pendente),
        isTrue,
      );
      expect(created.voluntarios.every((v) => v.data == '2026-12-06'), isTrue);
    });

    test('não repete a mesma pessoa em vagas diferentes', () async {
      final created = await escalas.create(
        const Escala(
          id: 'draft',
          titulo: 'Vocal 4 vagas',
          competencia: '2026-12',
          tipo: EscalaTipo.culto,
          igrejaId: 'i1',
          supervisorPessoaId: 'p1',
          supervisorNome: 'Ana Costa',
          ativo: false,
          dataEvento: '2026-12-06',
          servicos: [
            EscalaServico(
              id: 'x1',
              servicoId: 's1a',
              servicoNome: 'Vocal',
              quantidadeNecessaria: 4,
            ),
          ],
        ),
      );

      final ids = created.voluntarios.map((v) => v.pessoaId).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, hasLength(2), reason: 'só p2 e p3 servem ao serviço Vocal');
    });

    test('a escala criada entra no topo da listagem', () async {
      final created = await escalas.create(_semana);

      final itens = await escalas.list(igrejaId: 'i1');
      expect(itens.first.id, created.id);
    });

    test('escala sem serviços não recebe sugestões', () async {
      final created = await escalas.create(_vazio);

      expect(created.voluntarios, isEmpty);
    });
  });

  group('EscalaService.update', () {
    test('altera os campos e mantém o id da rota', () async {
      final original = await escalas.getById('e-louvor');

      await escalas.update(
        original.id,
        Escala(
          id: original.id,
          titulo: 'Louvor — setembro',
          descricao: 'Atualizada',
          competencia: '2026-09',
          tipo: EscalaTipo.ministerio,
          igrejaId: 'i1',
          ministerioId: 'm1',
          ministerioNome: 'Louvor',
          supervisorPessoaId: 'p2',
          supervisorNome: 'João da Silva',
          status: EscalaStatus.sugerida,
          dataEvento: '2026-09-06',
          horaInicio: '19:00:00',
          horaFim: '21:00:00',
          ativo: true,
        ),
      );

      final atualizada = await escalas.getById('e-louvor');
      expect(atualizada.id, 'e-louvor');
      expect(atualizada.titulo, 'Louvor — setembro');
      expect(atualizada.descricao, 'Atualizada');
      expect(atualizada.competencia, '2026-09');
      expect(atualizada.supervisorPessoaId, 'p2');
      expect(atualizada.status, EscalaStatus.sugerida);
    });

    test('lança quando a escala não existe', () async {
      await expectLater(
        escalas.update('nao-existe', _semana),
        throwsWithMessage('Escala não encontrada.'),
      );
    });
  });

  group('EscalaService.delete', () {
    test('remove a escala da listagem', () async {
      await escalas.delete('e-louvor');

      final itens = await escalas.list(igrejaId: 'i1');
      expect(itens.map((e) => e.id), isNot(contains('e-louvor')));
      expect(itens, hasLength(6));
    });

    test('não lança ao remover id inexistente', () async {
      await expectLater(escalas.delete('nao-existe'), completes);
    });
  });

  group('EscalaService.updateStatus', () {
    test('sugerida → em andamento registra a data de lançamento', () async {
      final updated = await escalas.updateStatus('e-culto-set', EscalaStatus.emAndamento);

      expect(updated.status, EscalaStatus.emAndamento);
      expect(updated.dataLancamento, isNotNull);
      expect(updated.dataFinalizacao, isNull);
    });

    test('em andamento → finalizada registra a data de finalização', () async {
      final updated = await escalas.updateStatus(
        'e-culto-set-lancado',
        EscalaStatus.finalizada,
      );

      expect(updated.status, EscalaStatus.finalizada);
      expect(updated.dataLancamento, '2026-09-01T10:10:00');
      expect(updated.dataFinalizacao, isNotNull);
    });

    test('editando → em andamento é permitido', () async {
      final updated = await escalas.updateStatus('e-louvor', EscalaStatus.emAndamento);

      expect(updated.status, EscalaStatus.emAndamento);
      expect(updated.dataLancamento, isNotNull);
    });

    test('recusa transição não permitida', () async {
      await expectLater(
        escalas.updateStatus('e-culto-set', EscalaStatus.finalizada),
        throwsWithMessage('Transição Sugerida → Finalizada não permitida.'),
      );
    });

    test('recusa manter o status finalizada', () async {
      await expectLater(
        escalas.updateStatus('e-culto', EscalaStatus.finalizada),
        throwsWithMessage('Transição Finalizada → Finalizada não permitida.'),
      );
    });

    test('reabrir uma escala finalizada mantém a data de finalização anterior', () async {
      final original = await escalas.getById('e-culto');
      expect(original.status, EscalaStatus.finalizada);

      final updated = await escalas.updateStatus('e-culto', EscalaStatus.emAndamento);

      expect(updated.status, EscalaStatus.emAndamento);
      expect(updated.dataFinalizacao, original.dataFinalizacao);
    });

    test('lança quando a escala não existe', () async {
      await expectLater(
        escalas.updateStatus('nao-existe', EscalaStatus.emAndamento),
        throwsWithMessage('Escala não encontrada.'),
      );
    });
  });

  group('EscalaService serviços da escala', () {
    test('addServico adiciona serviço à escala', () async {
      final servico = await escalas.addServico(
        'e-louvor',
        servicoId: 's2a',
        servicoNome: 'Projeção',
        quantidadeNecessaria: 2,
      );

      expect(servico.id, startsWith('sv'));
      expect(servico.escalaId, 'e-louvor');
      expect(servico.quantidadeNecessaria, 2);

      final atualizada = await escalas.getById('e-louvor');
      expect(atualizada.servicos, hasLength(3));
      expect(
        atualizada.servicos.map((s) => s.servicoNome),
        containsAll(['Vocal', 'Violão', 'Projeção']),
      );
    });

    test('addServico usa quantidade 1 por padrão', () async {
      final servico = await escalas.addServico(
        'e-louvor',
        servicoId: 's2b',
        servicoNome: 'Som',
      );

      expect(servico.quantidadeNecessaria, 1);
    });

    test('updateServico altera a quantidade sem perder os demais campos', () async {
      final servico = await escalas.updateServico(
        'e-louvor',
        'sl1',
        quantidadeNecessaria: 4,
      );

      expect(servico.id, 'sl1');
      expect(servico.quantidadeNecessaria, 4);
      expect(servico.servicoNome, 'Vocal');

      final atualizada = await escalas.getById('e-louvor');
      expect(atualizada.servicos.firstWhere((s) => s.id == 'sl2').quantidadeNecessaria, 1);
    });

    test('removeServico retira o serviço da escala', () async {
      await escalas.removeServico('e-louvor', 'sl1');

      final atualizada = await escalas.getById('e-louvor');
      expect(atualizada.servicos.map((s) => s.id).toList(), ['sl2']);
    });

    test('lança quando a escala não existe', () async {
      await expectLater(
        escalas.addServico('nao-existe', servicoId: 's1a', servicoNome: 'Vocal'),
        throwsWithMessage('Escala não encontrada.'),
      );
      await expectLater(
        escalas.updateServico('nao-existe', 'sl1', quantidadeNecessaria: 2),
        throwsWithMessage('Escala não encontrada.'),
      );
      await expectLater(
        escalas.removeServico('nao-existe', 'sl1'),
        throwsWithMessage('Escala não encontrada.'),
      );
    });
  });

  group('EscalaService designações', () {
    test('addVoluntario resolve pessoa e serviço e inicia como pendente', () async {
      final designacao = await escalas.addVoluntario(
        'e-louvor',
        pessoaId: 'p4',
        servicoId: 's1b',
        observacoes: 'Traz o violão',
      );

      expect(designacao.id, startsWith('v'));
      expect(designacao.escalaId, 'e-louvor');
      expect(designacao.pessoaId, 'p4');
      expect(designacao.pessoaNome, 'Bruno Santos');
      expect(designacao.servicoNome, 'Violão');
      expect(designacao.status, EscalaItemStatus.pendente);
      expect(designacao.confirmadoPeloVoluntario, isFalse);
      expect(designacao.observacoes, 'Traz o violão');
    });

    test('addVoluntario deixa o nome do serviço nulo quando é desconhecido', () async {
      final designacao = await escalas.addVoluntario(
        'e-louvor',
        pessoaId: 'p4',
        servicoId: 'servico-desconhecido',
      );

      expect(designacao.servicoNome, isNull);
    });

    test('addVoluntario aceita nome do serviço explícito', () async {
      final designacao = await escalas.addVoluntario(
        'e-louvor',
        pessoaId: 'p4',
        servicoId: 's9',
        servicoNome: 'Teclado',
      );

      expect(designacao.servicoNome, 'Teclado');
    });

    test('a designação adicionada aparece na escala', () async {
      final designacao = await escalas.addVoluntario(
        'e-louvor',
        pessoaId: 'p4',
        servicoId: 's1b',
      );

      final atualizada = await escalas.getById('e-louvor');
      expect(atualizada.voluntarios, hasLength(3));
      expect(atualizada.voluntarios.map((v) => v.id), contains(designacao.id));
    });

    test('updateVoluntario altera os campos informados', () async {
      await escalas.updateVoluntario(
        'e-louvor',
        'vl1',
        pessoaNome: 'Maria alterada',
        observacoes: 'Troca de teclado',
      );

      final atualizada = await escalas.getById('e-louvor');
      final designacao = atualizada.voluntarios.firstWhere((v) => v.id == 'vl1');
      expect(designacao.pessoaNome, 'Maria alterada');
      expect(designacao.observacoes, 'Troca de teclado');
      expect(designacao.pessoaId, 'p3');
      expect(designacao.status, EscalaItemStatus.pendente);
    });

    test('updateVoluntario lança para designação inexistente', () async {
      await expectLater(
        escalas.updateVoluntario('e-louvor', 'nao-existe', pessoaNome: 'X'),
        throwsWithMessage('Designação não encontrada.'),
      );
    });

    test('updateVoluntarioStatus confirma a designação', () async {
      final updated = await escalas.updateVoluntarioStatus(
        'e-louvor',
        'vl1',
        status: EscalaItemStatus.confirmado,
        confirmadoPeloVoluntario: true,
      );

      expect(updated.status, EscalaItemStatus.confirmado);
      expect(updated.confirmadoPeloVoluntario, isTrue);
      expect(updated.aprovadoPeloVoluntario, isTrue);
    });

    test('updateVoluntarioStatus substitui por outro voluntário', () async {
      await escalas.updateVoluntarioStatus(
        'e-louvor',
        'vl1',
        status: EscalaItemStatus.substituido,
      );

      final atualizada = await escalas.getById('e-louvor');
      expect(
        atualizada.voluntarios.firstWhere((v) => v.id == 'vl1').status,
        EscalaItemStatus.substituido,
      );
    });

    test('removeVoluntario retira a designação', () async {
      await escalas.removeVoluntario('e-louvor', 'vl1');

      final atualizada = await escalas.getById('e-louvor');
      expect(atualizada.voluntarios.map((v) => v.id).toList(), ['vl2']);
    });

    test('ignora designação inexistente sem lançar', () async {
      await expectLater(escalas.removeVoluntario('e-louvor', 'nao-existe'), completes);

      final atualizada = await escalas.getById('e-louvor');
      expect(atualizada.voluntarios, hasLength(2));
    });

    test('removeVoluntario lança quando a escala não existe', () async {
      await expectLater(
        escalas.removeVoluntario('nao-existe', 'vl1'),
        throwsWithMessage('Escala não encontrada.'),
      );
    });

    test('addVoluntario lança quando a escala não existe', () async {
      await expectLater(
        escalas.addVoluntario('nao-existe', pessoaId: 'p4', servicoId: 's1b'),
        throwsWithMessage('Escala não encontrada.'),
      );
    });
  });

  group('EscalaService.responderDesignacao', () {
    test('recusa resposta quando a escala ainda não foi lançada', () async {
      await expectLater(
        escalas.responderDesignacao(
          'e-louvor',
          'vl1',
          status: EscalaItemStatus.confirmado,
        ),
        throwsWithMessage('A escala precisa estar lançada para o voluntário responder.'),
      );
    });

    test('voluntário confirma a própria designação', () async {
      final updated = await escalas.responderDesignacao(
        'e-culto-set-lancado',
        'sla-v1',
        status: EscalaItemStatus.confirmado,
        pessoaId: 'p3',
      );

      expect(updated.status, EscalaItemStatus.confirmado);
      expect(updated.confirmadoPeloVoluntario, isTrue);
      expect(updated.aprovadoPeloVoluntario, isTrue);
    });

    test('recusa exige motivo', () async {
      await expectLater(
        escalas.responderDesignacao(
          'e-culto-set-lancado',
          'sla-v1',
          status: EscalaItemStatus.recusado,
          pessoaId: 'p3',
        ),
        throwsWithMessage('Informe o motivo da recusa.'),
      );
    });

    test('recusa com motivo em branco também é bloqueada', () async {
      await expectLater(
        escalas.responderDesignacao(
          'e-culto-set-lancado',
          'sla-v1',
          status: EscalaItemStatus.recusado,
          observacoes: '   ',
          pessoaId: 'p3',
        ),
        throwsWithMessage('Informe o motivo da recusa.'),
      );
    });

    test('recusa com motivo é registrada', () async {
      final updated = await escalas.responderDesignacao(
        'e-culto-set-lancado',
        'sla-v1',
        status: EscalaItemStatus.recusado,
        observacoes: 'Fora da cidade',
        pessoaId: 'p3',
      );

      expect(updated.status, EscalaItemStatus.recusado);
      expect(updated.observacoes, 'Fora da cidade');
      expect(updated.confirmadoPeloVoluntario, isTrue);
    });

    test('não permite responder designação de outra pessoa', () async {
      await expectLater(
        escalas.responderDesignacao(
          'e-culto-set-lancado',
          'sla-v1',
          status: EscalaItemStatus.confirmado,
          pessoaId: 'p4',
        ),
        throwsWithMessage('Você só pode responder à sua própria designação.'),
      );
    });

    test('sem pessoa informada a resposta é aceita', () async {
      final updated = await escalas.responderDesignacao(
        'e-culto-set-lancado',
        'sla-v1',
        status: EscalaItemStatus.confirmado,
      );

      expect(updated.status, EscalaItemStatus.confirmado);
    });

    test('lança para designação inexistente', () async {
      await expectLater(
        escalas.responderDesignacao(
          'e-culto-set-lancado',
          'nao-existe',
          status: EscalaItemStatus.confirmado,
          pessoaId: 'p3',
        ),
        throwsWithMessage('Designação não encontrada.'),
      );
    });
  });

  group('EscalaService.candidatos', () {
    test('lista os voluntários da igreja que servem a algum serviço', () async {
      final candidatos = await escalas.candidatos('e-louvor');

      expect(candidatos.map((c) => c.pessoaId).toList(), ['p2', 'p3', 'p4', 'p5', 'p7']);
      expect(candidatos.every((c) => c.servicosQueServe.isNotEmpty), isTrue);
      expect(candidatos.every((c) => c.analiseDia == null), isTrue);
    });

    test('filtra por serviço', () async {
      final candidatos = await escalas.candidatos('e-louvor', servicoId: 's1b');

      expect(candidatos.map((c) => c.pessoaId).toList(), ['p2', 'p3']);
      expect(candidatos.every((c) => c.servicosQueServe.contains('Violão')), isTrue);
    });

    test('com data analisa a disponibilidade e detecta conflitos', () async {
      final candidatos = await escalas.candidatos(
        'e-louvor',
        data: '2026-09-06',
      );

      expect(candidatos, isNotEmpty);
      for (final candidato in candidatos) {
        expect(candidato.analiseDia?.data, '2026-09-06');
      }

      final comConflito = candidatos.firstWhere((c) => c.pessoaId == 'p2');
      expect(comConflito.analiseDia!.disponivel, isFalse);
      expect(
        comConflito.analiseDia!.motivosIndisponibilidade,
        contains('Conflito com outra escala no mesmo dia/horário'),
      );
      expect(comConflito.analiseDia!.conflitos, isNotEmpty);
      expect(comConflito.analiseDia!.conflitos.first.escalaTitulo, isNotEmpty);

      final semConflito = candidatos.firstWhere((c) => c.pessoaId == 'p5');
      expect(semConflito.analiseDia!.disponivel, isTrue);
      expect(semConflito.analiseDia!.conflitos, isEmpty);
    });

    test('considera indisponível quem já tem designação na mesma data', () async {
      final candidatos = await escalas.candidatos('e-louvor', data: '2026-09-06');

      final sobrepostos = candidatos
          .where((c) => c.analiseDia!.disponivel == false)
          .map((c) => c.pessoaId)
          .toSet();
      expect(sobrepostos, {'p2', 'p3', 'p7'});
    });

    test('respeita a igreja da escala', () async {
      final candidatos = await escalas.candidatos('e-zs');

      expect(candidatos.map((c) => c.pessoaId).toList(), ['p10']);
    });

    test('lança quando a escala não existe', () async {
      await expectLater(
        escalas.candidatos('nao-existe'),
        throwsWithMessage('Escala não encontrada.'),
      );
    });
  });

  group('EscalaService.gerarSugestoes', () {
    test('COMPLETA quando todas as vagas são preenchidas', () async {
      final created = await escalas.create(
        const Escala(
          id: 'draft',
          titulo: 'Só violão',
          competencia: '2026-12',
          tipo: EscalaTipo.culto,
          igrejaId: 'i1',
          supervisorPessoaId: 'p1',
          supervisorNome: 'Ana Costa',
          ativo: false,
          dataEvento: '2026-12-06',
          servicos: [
            EscalaServico(
              id: 'x1',
              servicoId: 's1b',
              servicoNome: 'Violão',
              quantidadeNecessaria: 1,
            ),
          ],
        ),
      );

      final resultado = await escalas.gerarSugestoes(created.id);

      expect(resultado.escalaId, created.id);
      expect(resultado.status, 'COMPLETA');
      expect(resultado.sugestoes, isNotEmpty);
      expect(resultado.message, contains('1 de 1 vagas preenchidas'));
    });

    test('PARCIAL quando sobram vagas', () async {
      final resultado = await escalas.gerarSugestoes('e-culto-set');

      expect(resultado.status, 'PARCIAL');
      expect(resultado.message, contains('3 de 5 vagas preenchidas'));
      expect(resultado.sugestoes.map((s) => s.pessoaId).toSet(), {'p2', 'p7', 'p4'});
      expect(
        resultado.sugestoes.where((s) => s.motivo == 'Disponível e de menor carga no mês'),
        hasLength(3),
      );
    });

    test('pessoas com conflito na data do evento ficam de fora da sugestão', () async {
      final antes = await escalas.getById('e-culto-set');

      await escalas.gerarSugestoes('e-culto-set');

      final depois = await escalas.getById('e-culto-set');
      final novos = depois.voluntarios
          .where((v) => !antes.voluntarios.any((a) => a.id == v.id))
          .toList();
      expect(novos.map((v) => v.pessoaId).toList(), ['p4']);
    });

    test('SEM_SERVICOS quando a escala não tem vagas', () async {
      final created = await escalas.create(_vazio);

      final resultado = await escalas.gerarSugestoes(created.id);

      expect(resultado.status, 'SEM_SERVICOS');
      expect(resultado.sugestoes, isEmpty);
    });

    test('SEM_DISPONIVEL quando não há candidatos para o serviço', () async {
      final created = await escalas.create(
        const Escala(
          id: 'draft',
          titulo: 'Violão na filial',
          competencia: '2026-12',
          tipo: EscalaTipo.culto,
          igrejaId: 'i2',
          supervisorPessoaId: 'p8',
          supervisorNome: 'Pedro Alves',
          ativo: false,
          dataEvento: '2026-12-06',
          servicos: [
            EscalaServico(
              id: 'x1',
              servicoId: 's1b',
              servicoNome: 'Violão',
              quantidadeNecessaria: 1,
            ),
          ],
        ),
      );

      final resultado = await escalas.gerarSugestoes(created.id);

      expect(resultado.status, 'SEM_DISPONIVEL');
    });

    test('persiste as sugestões geradas na escala', () async {
      final resultado = await escalas.gerarSugestoes('e-culto-set');
      final atualizada = await escalas.getById('e-culto-set');

      expect(atualizada.voluntarios, hasLength(resultado.sugestoes.length));
      expect(atualizada.voluntarios.map((v) => v.id).toSet(), {
        'se1',
        'se2',
        ...resultado.sugestoes.map((_) => atualizada.voluntarios.last.id),
      });
    });

    test('lança quando a escala não existe', () async {
      await expectLater(
        escalas.gerarSugestoes('nao-existe'),
        throwsWithMessage('Escala não encontrada.'),
      );
    });
  });

  group('EscalaService.visaoMensal', () {
    test('devolve vazio quando a igreja não é informada', () async {
      expect(await escalas.visaoMensal(), isEmpty);
    });

    test('administrador vê todos os ministérios da igreja', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        administrador: true,
      );

      expect(visao.map((v) => v.ministerioId).toSet(), {'m1', 'm2', 'm3', 'm4', 'm6', 'm7'});
      expect(visao.every((v) => v.competencia == '2026-09'), isTrue);
      expect(visao.every((v) => v.igrejaId == 'i1'), isTrue);
    });

    test('cruza a escala mensal do ministério com os cultos', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        ministerioId: 'm1',
        administrador: true,
      );

      expect(visao, hasLength(1));
      final louvor = visao.single;
      expect(louvor.ministerioNome, 'Louvor');
      expect(louvor.escalaId, 'e-louvor-set');
      expect(louvor.escalaStatus, EscalaStatus.sugerida);
      expect(louvor.itens, hasLength(8));
      expect(louvor.itens.every((i) => i.isCulto), isTrue);

      final datas = louvor.itens.map((i) => i.data).toList();
      expect(datas, orderedEquals([...datas]..sort()));
    });

    test('mostra as vagas em aberto e os designados por culto', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        ministerioId: 'm1',
        administrador: true,
      );

      final item = visao.single.itens.firstWhere((i) => i.data == '2026-09-06');
      final vocal = item.servicos.firstWhere((s) => s.servicoNome == 'Vocal');

      expect(vocal.quantidadeNecessaria, 2);
      expect(vocal.designados, hasLength(1));
      expect(vocal.designados.single.pessoaNome, 'Maria Oliveira');
      expect(vocal.designados.single.status, EscalaItemStatus.pendente);
      expect(vocal.vagasEmAberto, 1);

      final violao = item.servicos.firstWhere((s) => s.servicoNome == 'Violão');
      expect(violao.designados, isEmpty);
      expect(violao.vagasEmAberto, 1);
    });

    test('culto sem designações mostra todas as vagas em aberto', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        ministerioId: 'm1',
        administrador: true,
      );

      final item = visao.single.itens.firstWhere((i) => i.data == '2026-09-13');
      expect(item.servicos.every((s) => s.designados.isEmpty), isTrue);
      expect(item.servicos.every((s) => s.vagasEmAberto > 0), isTrue);
    });

    test('ministério sem escala mensal não tem escala vinculada', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        ministerioId: 'm2',
        administrador: true,
      );

      expect(visao, hasLength(1));
      expect(visao.single.escalaId, isNull);
      expect(visao.single.escalaStatus, isNull);
    });

    test('líder vê apenas o próprio ministério', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        pessoaId: 'p2',
      );

      expect(visao, hasLength(1));
      expect(visao.single.ministerioId, 'm1');
    });

    test('pessoa sem cargo de liderança não vê nada', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        pessoaId: 'p8',
      );

      expect(visao, isEmpty);
    });

    test('competência sem cultos devolve ministérios sem itens', () async {
      final visao = await escalas.visaoMensal(
        igrejaId: 'i1',
        competencia: '2027-01',
        administrador: true,
      );

      expect(visao, isNotEmpty);
      expect(visao.every((v) => v.itens.isEmpty), isTrue);
    });
  });

  group('EscalaService.automatizarProximoMes', () {
    test('devolve a mensagem de resumo', () async {
      expect(
        await escalas.automatizarProximoMes(),
        contains('Escalas recomendadas geradas automaticamente'),
      );
    });
  });

  group('Escala helpers', () {
    test('geraAuto é verdadeiro apenas para escalas sugeridas', () async {
      expect((await escalas.getById('e-culto-set')).geraAuto(), isTrue);
      expect((await escalas.getById('e-louvor')).geraAuto(), isFalse);
    });

    test('preenchidosDoServico ignora as recusas', () {
      const escala = Escala(
        id: 'e1',
        titulo: 't',
        competencia: '2026-12',
        tipo: EscalaTipo.culto,
        igrejaId: 'i1',
        supervisorPessoaId: 'p1',
        supervisorNome: 'Ana Costa',
        ativo: true,
        voluntarios: [
          EscalaVoluntario(id: 'v1', pessoaId: 'p2', servicoId: 's1a', status: EscalaItemStatus.confirmado),
          EscalaVoluntario(id: 'v2', pessoaId: 'p3', servicoId: 's1a', status: EscalaItemStatus.recusado),
          EscalaVoluntario(id: 'v3', pessoaId: 'p4', servicoId: 's1a', status: EscalaItemStatus.pendente),
          EscalaVoluntario(id: 'v4', pessoaId: 'p5', servicoId: 's2a', status: EscalaItemStatus.pendente),
        ],
      );

      expect(escala.preenchidosDoServico('s1a'), 2);
      expect(escala.preenchidosDoServico('s2a'), 1);
      expect(escala.preenchidosDoServico('inexistente'), 0);
      expect(escala.preenchidosDoServico(null), 0);
    });

    test('voluntariosDoServico lista apenas os não recusados', () {
      const escala = Escala(
        id: 'e1',
        titulo: 't',
        competencia: '2026-12',
        tipo: EscalaTipo.culto,
        igrejaId: 'i1',
        supervisorPessoaId: 'p1',
        supervisorNome: 'Ana Costa',
        ativo: true,
        voluntarios: [
          EscalaVoluntario(id: 'v1', pessoaId: 'p2', servicoId: 's1a', status: EscalaItemStatus.confirmado),
          EscalaVoluntario(id: 'v2', pessoaId: 'p3', servicoId: 's1a', status: EscalaItemStatus.recusado),
          EscalaVoluntario(id: 'v3', pessoaId: 'p4', servicoId: 's1a', status: EscalaItemStatus.pendente),
        ],
      );

      expect(escala.voluntariosDoServico('s1a').map((v) => v.id).toList(), [
        'v1',
        'v3',
      ]);
    });

    test('copyWith preserva id e igreja, que não são editáveis', () {
      const escala = Escala(
        id: 'e1',
        titulo: 'Título',
        descricao: 'Descrição',
        competencia: '2026-12',
        tipo: EscalaTipo.ministerio,
        igrejaId: 'i1',
        ministerioId: 'm1',
        ministerioNome: 'Louvor',
        supervisorPessoaId: 'p1',
        supervisorNome: 'Ana Costa',
        status: EscalaStatus.editando,
        ativo: true,
      );

      final updated = escala.copyWith(titulo: 'Novo título', status: EscalaStatus.emAndamento);

      expect(updated.id, 'e1');
      expect(updated.igrejaId, 'i1');
      expect(updated.titulo, 'Novo título');
      expect(updated.status, EscalaStatus.emAndamento);
      expect(updated.ministerioId, 'm1');
    });
  });

  group('Escala enum conversions', () {
    test('round-trip de tipo e status', () {
      for (final tipo in EscalaTipo.values) {
        expect(escalaTipoFromString(escalaTipoToString(tipo)), tipo);
      }
      for (final status in EscalaStatus.values) {
        expect(escalaStatusFromString(escalaStatusToString(status)), status);
      }
    });

    test('siglas e rótulos de tipo', () {
      expect(escalaTipoToString(EscalaTipo.supervisor), 'SUPERVISOR');
      expect(escalaTipoToString(EscalaTipo.pregador), 'PREGADOR');
      expect(escalaTipoToString(EscalaTipo.culto), 'CULTO');
      expect(escalaTipoToString(EscalaTipo.ministerio), 'MINISTERIO');

      expect(escalaTipoLabel(EscalaTipo.supervisor), 'Supervisor');
      expect(escalaTipoLabel(EscalaTipo.culto), 'Culto');
      expect(escalaTipoLabel(EscalaTipo.ministerio), 'Ministério');
    });

    test('tipo desconhecido cai em ministério', () {
      expect(escalaTipoFromString('OUTRO'), EscalaTipo.ministerio);
      expect(escalaTipoFromString(''), EscalaTipo.ministerio);
      expect(escalaTipoFromString('culto'), EscalaTipo.culto);
    });

    test('siglas e rótulos de status', () {
      expect(escalaStatusToString(EscalaStatus.emAndamento), 'EM_ANDAMENTO');
      expect(escalaStatusLabel(EscalaStatus.sugerida), 'Sugerida');
      expect(escalaStatusLabel(EscalaStatus.emAndamento), 'Em andamento');
      expect(escalaStatusLabel(EscalaStatus.finalizada), 'Finalizada');
    });

    test('status desconhecido cai em editando', () {
      expect(escalaStatusFromString('CANCELADA'), EscalaStatus.editando);
      expect(escalaStatusFromString('editando'), EscalaStatus.editando);
    });

    test('round-trip e rótulos do status da designação', () {
      for (final status in EscalaItemStatus.values) {
        expect(escalaItemStatusFromString(escalaItemStatusToString(status)), status);
      }
      expect(escalaItemStatusToString(EscalaItemStatus.pendente), 'PENDENTE');
      expect(escalaItemStatusToString(EscalaItemStatus.substituido), 'SUBSTITUIDO');
      expect(escalaItemStatusLabel(EscalaItemStatus.substituido), 'Substituído');
    });

    test('aceita a variante acentuada de substituído', () {
      expect(
        escalaItemStatusFromString('SUBSTITUÍDO'),
        EscalaItemStatus.substituido,
      );
      expect(escalaItemStatusFromString('qualquer'), EscalaItemStatus.pendente);
    });
  });

  group('podeTransicionarEscalaStatus', () {
    test('sugerida só avança para editando ou em andamento', () {
      expect(podeTransicionarEscalaStatus(EscalaStatus.sugerida, EscalaStatus.editando), isTrue);
      expect(podeTransicionarEscalaStatus(EscalaStatus.sugerida, EscalaStatus.emAndamento), isTrue);
      expect(podeTransicionarEscalaStatus(EscalaStatus.sugerida, EscalaStatus.finalizada), isFalse);
      expect(podeTransicionarEscalaStatus(EscalaStatus.sugerida, EscalaStatus.sugerida), isFalse);
    });

    test('editando volta para sugerida ou avança para em andamento', () {
      expect(podeTransicionarEscalaStatus(EscalaStatus.editando, EscalaStatus.sugerida), isTrue);
      expect(podeTransicionarEscalaStatus(EscalaStatus.editando, EscalaStatus.emAndamento), isTrue);
      expect(podeTransicionarEscalaStatus(EscalaStatus.editando, EscalaStatus.finalizada), isFalse);
      expect(podeTransicionarEscalaStatus(EscalaStatus.editando, EscalaStatus.editando), isFalse);
    });

    test('em andamento volta para editando ou fecha em finalizada', () {
      expect(podeTransicionarEscalaStatus(EscalaStatus.emAndamento, EscalaStatus.editando), isTrue);
      expect(podeTransicionarEscalaStatus(EscalaStatus.emAndamento, EscalaStatus.finalizada), isTrue);
      expect(podeTransicionarEscalaStatus(EscalaStatus.emAndamento, EscalaStatus.sugerida), isFalse);
      expect(podeTransicionarEscalaStatus(EscalaStatus.emAndamento, EscalaStatus.emAndamento), isFalse);
    });

    test('finalizada só reabre para em andamento', () {
      expect(podeTransicionarEscalaStatus(EscalaStatus.finalizada, EscalaStatus.emAndamento), isTrue);
      expect(podeTransicionarEscalaStatus(EscalaStatus.finalizada, EscalaStatus.editando), isFalse);
      expect(podeTransicionarEscalaStatus(EscalaStatus.finalizada, EscalaStatus.sugerida), isFalse);
      expect(podeTransicionarEscalaStatus(EscalaStatus.finalizada, EscalaStatus.finalizada), isFalse);
    });
  });

  group('EscalaVoluntario.aprovadoPeloVoluntario', () {
    test('exige confirmação do voluntário e status confirmado', () {
      const base = EscalaVoluntario(id: 'v1', pessoaId: 'p2');
      expect(base.aprovadoPeloVoluntario, isFalse);

      final confirmado = EscalaVoluntario(
        id: 'v1',
        pessoaId: 'p2',
        status: EscalaItemStatus.confirmado,
        confirmadoPeloVoluntario: true,
      );
      expect(confirmado.aprovadoPeloVoluntario, isTrue);

      final pendente = EscalaVoluntario(
        id: 'v1',
        pessoaId: 'p2',
        status: EscalaItemStatus.pendente,
        confirmadoPeloVoluntario: true,
      );
      expect(pendente.aprovadoPeloVoluntario, isFalse);

      final semConfirmacao = EscalaVoluntario(
        id: 'v1',
        pessoaId: 'p2',
        status: EscalaItemStatus.confirmado,
      );
      expect(semConfirmacao.aprovadoPeloVoluntario, isFalse);
    });
  });

  group('ServicoVisaoMensal.vagasEmAberto', () {
    test('subtrai os designados do total', () {
      final servico = ServicoVisaoMensal(
        servicoId: 's1a',
        servicoNome: 'Vocal',
        quantidadeNecessaria: 3,
        designados: const [DesignadoVisao(designacaoId: 'd1', pessoaNome: 'A')],
      );

      expect(servico.vagasEmAberto, 2);
    });

    test('nunca fica negativo quando há mais designados que vagas', () {
      final servico = ServicoVisaoMensal(
        servicoNome: 'Vocal',
        quantidadeNecessaria: 1,
        designados: const [
          DesignadoVisao(designacaoId: 'd1', pessoaNome: 'A'),
          DesignadoVisao(designacaoId: 'd2', pessoaNome: 'B'),
        ],
      );

      expect(servico.vagasEmAberto, 0);
    });
  });
}