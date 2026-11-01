import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Escala helpers', () {
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
          EscalaVoluntario(
            id: 'v1',
            pessoaId: 'p2',
            servicoId: 's1a',
            status: EscalaItemStatus.confirmado,
          ),
          EscalaVoluntario(
            id: 'v2',
            pessoaId: 'p3',
            servicoId: 's1a',
            status: EscalaItemStatus.recusado,
          ),
          EscalaVoluntario(
            id: 'v3',
            pessoaId: 'p4',
            servicoId: 's1a',
            status: EscalaItemStatus.pendente,
          ),
          EscalaVoluntario(
            id: 'v4',
            pessoaId: 'p5',
            servicoId: 's2a',
            status: EscalaItemStatus.pendente,
          ),
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
          EscalaVoluntario(
            id: 'v1',
            pessoaId: 'p2',
            servicoId: 's1a',
            status: EscalaItemStatus.confirmado,
          ),
          EscalaVoluntario(
            id: 'v2',
            pessoaId: 'p3',
            servicoId: 's1a',
            status: EscalaItemStatus.recusado,
          ),
          EscalaVoluntario(
            id: 'v3',
            pessoaId: 'p4',
            servicoId: 's1a',
            status: EscalaItemStatus.pendente,
          ),
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

      final updated = escala.copyWith(
        titulo: 'Novo título',
        status: EscalaStatus.emAndamento,
      );

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
        expect(
          escalaItemStatusFromString(escalaItemStatusToString(status)),
          status,
        );
      }
      expect(escalaItemStatusToString(EscalaItemStatus.pendente), 'PENDENTE');
      expect(
        escalaItemStatusToString(EscalaItemStatus.substituido),
        'SUBSTITUIDO',
      );
      expect(
        escalaItemStatusLabel(EscalaItemStatus.substituido),
        'Substituído',
      );
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
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.sugerida,
          EscalaStatus.editando,
        ),
        isTrue,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.sugerida,
          EscalaStatus.emAndamento,
        ),
        isTrue,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.sugerida,
          EscalaStatus.finalizada,
        ),
        isFalse,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.sugerida,
          EscalaStatus.sugerida,
        ),
        isFalse,
      );
    });

    test('editando volta para sugerida ou avança para em andamento', () {
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.editando,
          EscalaStatus.sugerida,
        ),
        isTrue,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.editando,
          EscalaStatus.emAndamento,
        ),
        isTrue,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.editando,
          EscalaStatus.finalizada,
        ),
        isFalse,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.editando,
          EscalaStatus.editando,
        ),
        isFalse,
      );
    });

    test('em andamento volta para editando ou fecha em finalizada', () {
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.emAndamento,
          EscalaStatus.editando,
        ),
        isTrue,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.emAndamento,
          EscalaStatus.finalizada,
        ),
        isTrue,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.emAndamento,
          EscalaStatus.sugerida,
        ),
        isFalse,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.emAndamento,
          EscalaStatus.emAndamento,
        ),
        isFalse,
      );
    });

    test('finalizada só reabre para em andamento', () {
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.finalizada,
          EscalaStatus.emAndamento,
        ),
        isTrue,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.finalizada,
          EscalaStatus.editando,
        ),
        isFalse,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.finalizada,
          EscalaStatus.sugerida,
        ),
        isFalse,
      );
      expect(
        podeTransicionarEscalaStatus(
          EscalaStatus.finalizada,
          EscalaStatus.finalizada,
        ),
        isFalse,
      );
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
