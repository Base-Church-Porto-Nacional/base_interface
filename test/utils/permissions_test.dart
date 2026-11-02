import '../helpers/fixtures.dart';

import 'package:base_church/models/models.dart';
import 'package:base_church/utils/permissions.dart';
import 'package:base_church/utils/route_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final louvor = mockMinisterios.firstWhere((m) => m.id == 'm1');
  final midia = mockMinisterios.firstWhere((m) => m.id == 'm2');
  final infantil = mockMinisterios.firstWhere((m) => m.id == 'm3');
  final ministerios = mockMinisterios;
  final ada = mockBasesMinisteriais.firstWhere((b) => b.id == 'b1');

  group('Permissoes', () {
    test('fromJson converte SCREAMING_SNAKE e ignora capacidade desconhecida', () {
      final p = Permissoes.fromJson({
        'capacidades': ['PESSOAS_VER_TODAS', 'CULTO_CONTAGEM', 'VOA_AVIAO'],
        'ministeriosLiderados': ['m1'],
        'basesLideradas': ['b1'],
        'gruposLiderados': ['g1'],
        'ehVoluntario': true,
      });
      expect(p.capacidades, {
        Capacidade.pessoasVerTodas,
        Capacidade.cultoContagem,
      });
      expect(p.ministeriosLiderados, {'m1'});
      expect(p.basesLideradas, {'b1'});
      expect(p.gruposLiderados, {'g1'});
      expect(p.ehVoluntario, isTrue);
      expect(p.tem(Capacidade.cultoContagem), isTrue);
      expect(p.tem(Capacidade.exportar), isFalse);
      expect(p.lideraAlgo, isTrue);
    });

    test('todas as 14 capacidades do backend são reconhecidas', () {
      const nomes = [
        'CONFIGURAR', 'CONTAS_GERIR', 'CULTO_CONTAGEM', 'CULTO_CONTEUDO_EDITAR',
        'DADOS_PASTORAIS_EDITAR', 'ESCALAS_GERIR', 'EXPORTAR', 'FILIAL_CRIAR',
        'MINISTERIOS_GERIR', 'PAPEIS_CUSTOM_GERIR', 'PAPEIS_GESTAO_ATRIBUIR',
        'PESSOAS_GERIR', 'PESSOAS_VER_TODAS', 'RELATORIOS_VER',
      ];
      final p = Permissoes.fromJson({'capacidades': nomes});
      expect(p.capacidades, Capacidade.values.toSet());
      expect(Capacidade.values.length, 14);
    });

    test('json ausente ou vazio vira permissões vazias', () {
      expect(Permissoes.fromJson(null).capacidades, isEmpty);
      expect(Permissoes.fromJson(const {}).lideraAlgo, isFalse);
    });

    test('AuthUser faz round-trip de papeis e permissoes', () {
      final u = AuthUser.fromJson(mockUserLider.toJson());
      expect(u.papeis, mockUserLider.papeis);
      expect(u.permissoes.ministeriosLiderados, {'m1'});
      expect(u.permissoes.ehVoluntario, isTrue);
      final p = AuthUser.fromJson(mockUser.toJson());
      expect(p.permissoes.capacidades, Capacidade.values.toSet());
    });

    test('sessão persistida no formato antigo não quebra e fica sem permissões', () {
      final u = AuthUser.fromJson({
        'id': 'u1',
        'nome': 'Ana',
        'email': 'a@b.c',
        'roles': ['ADMIN', 'PASTOR'],
        'igrejaId': 'i1',
        'igrejaTipo': 'MATRIZ',
        'igrejaNome': 'Base',
      });
      expect(u.permissoes.capacidades, isEmpty);
      expect(u.papeis, isEmpty);
      expect(u.permissoesAusentes, isTrue);
      expect(AuthUser.fromJson(mockUser.toJson()).permissoesAusentes, isFalse);
    });
  });

  group('isGestao', () {
    test('pastor e secretaria são gestão; líder, contador e membro não', () {
      expect(isGestao(mockUser), isTrue);
      expect(isGestao(mockUserSecretaria), isTrue);
      expect(isGestao(mockUserLider), isFalse);
      expect(isGestao(mockUserContador), isFalse);
      expect(isGestao(mockUserMembro), isFalse);
      expect(isGestao(null), isFalse);
    });
  });

  group('regras por perfil', () {
    test('secretariaNaoEditaTextoCulto', () {
      expect(podeEditarTextoCulto(mockUserSecretaria), isFalse);
      expect(
        podeEditarTextoCulto(mockUserSecretaria, pregadorPessoaId: 'p1'),
        isFalse,
      );
      expect(podeEditarTextoCulto(mockUser), isTrue);
    });

    test('secretariaCriaEscalaPregador', () {
      for (final tipo in EscalaTipo.values) {
        expect(
          podeCriarTipoEscala(
            user: mockUserSecretaria,
            tipo: tipo,
            ministerios: ministerios,
            escalas: const [],
            competencia: '2026-09',
            igrejaId: 'i1',
          ),
          isTrue,
          reason: escalaTipoLabel(tipo),
        );
      }
    });

    test('liderGerenciaSoMinisterioLiderado', () {
      expect(podeGerenciarMinisterio(mockUserLider, louvor), isTrue);
      expect(podeGerenciarMinisterio(mockUserLider, midia), isFalse);
      expect(podeGerenciarMinisterio(mockUserLider, infantil), isFalse);
      expect(podeGerenciarMinisterio(mockUserSecretaria, infantil), isTrue);
    });

    test('contadorLancaContagem', () {
      expect(podeLancarContagem(mockUserContador), isTrue);
      expect(podeLancarContagem(mockUserSecretaria), isTrue);
      expect(podeLancarContagem(mockUserLider), isFalse);
      expect(isGestao(mockUserContador), isFalse);
    });

    test('canCreateUsuario exige contasGerir; podeEnviarAniversarios exige configurar', () {
      expect(canCreateUsuario(mockUser), isTrue);
      expect(canCreateUsuario(mockUserLider), isFalse);
      expect(podeEnviarAniversarios(mockUserSecretaria), isTrue);
      expect(podeEnviarAniversarios(mockUserLider), isFalse);
      expect(podeEnviarAniversarios(null), isFalse);
    });

    test('líder sem papel não gerencia grupo alheio (remove regra qualquer LIDER)', () {
      const meu = SmallGroup(
        id: 'g1', nome: 'G1', igrejaId: 'i1', diaSemana: DiaSemana.sexta,
        liderPessoaId: 'p9', liderNome: 'X', ativo: true, nota: 0,
      );
      const outro = SmallGroup(
        id: 'g2', nome: 'G2', igrejaId: 'i1', diaSemana: DiaSemana.sexta,
        liderPessoaId: 'p9', liderNome: 'X', ativo: true, nota: 0,
        ministerioId: 'm1',
      );
      const lideraG1 = AuthUser(
        id: 'u20', nome: 'L', email: 'l@b.c', papeis: [],
        permissoes: Permissoes(gruposLiderados: {'g1'}),
        igrejaId: 'i1', igrejaTipo: IgrejaTipo.matriz, igrejaNome: 'B',
      );
      expect(podeGerenciarSmallGroup(lideraG1, meu), isTrue);
      expect(podeGerenciarSmallGroup(lideraG1, outro), isFalse);
      expect(podeGerenciarSmallGroup(mockUserLider, outro), isTrue); // ministério m1
      expect(podeGerenciarSmallGroup(mockUserLider, meu), isFalse);
      expect(podeGerenciarSmallGroup(mockUserSecretaria, meu), isTrue);
      expect(podeGerenciarSmallGroup(mockUserMembro, meu), isFalse);
    });
  });

  group('podeLancarContagem', () {
    test('pastor, admin e contador lançam a contagem', () {
      expect(podeLancarContagem(mockUser), isTrue);
      expect(podeLancarContagem(mockUserPastorFilial), isTrue);
      expect(podeLancarContagem(mockUserContador), isTrue);
    });

    test('nega para líder, membro e usuário nulo', () {
      expect(podeLancarContagem(mockUserLider), isFalse);
      expect(podeLancarContagem(mockUserMembro), isFalse);
      expect(podeLancarContagem(null), isFalse);
    });

    test('contador não ganha gestão do culto', () {
      expect(isGestao(mockUserContador), isFalse);
    });
  });

  group('pertenceAoMinisterioTipo', () {
    test('reconhece o líder e o coordenador do ministério do tipo', () {
      expect(
        pertenceAoMinisterioTipo(
          mockUserLider,
          ministerios,
          MinisterioTipo.musica,
        ),
        isTrue,
      );
      expect(
        pertenceAoMinisterioTipo(
          mockUserCoordenador,
          ministerios,
          MinisterioTipo.musica,
        ),
        isTrue,
      );
      expect(
        pertenceAoMinisterioTipo(
          mockUserMidia,
          ministerios,
          MinisterioTipo.midia,
        ),
        isTrue,
      );
    });

    test('nega para quem não é do tipo', () {
      expect(
        pertenceAoMinisterioTipo(
          mockUserMidia,
          ministerios,
          MinisterioTipo.musica,
        ),
        isFalse,
      );
      expect(
        pertenceAoMinisterioTipo(
          mockUserLider,
          ministerios,
          MinisterioTipo.midia,
        ),
        isFalse,
      );
      expect(
        pertenceAoMinisterioTipo(
          mockUserMembro,
          ministerios,
          MinisterioTipo.musica,
        ),
        isFalse,
      );
    });

    test('nega para usuário sem pessoa associada', () {
      const semPessoa = AuthUser(
        id: 'u9',
        nome: 'Sem pessoa',
        email: 'sem@base.church',
        papeis: ['LIDER'],
        permissoes: Permissoes(),
        igrejaId: 'i1',
        igrejaTipo: IgrejaTipo.matriz,
        igrejaNome: 'Base Church',
      );

      expect(
        pertenceAoMinisterioTipo(semPessoa, ministerios, MinisterioTipo.musica),
        isFalse,
      );
      expect(
        pertenceAoMinisterioTipo(null, ministerios, MinisterioTipo.musica),
        isFalse,
      );
    });
  });

  group('podeCriarTipoEscala', () {
    test('pastor e admin criam qualquer tipo', () {
      for (final tipo in EscalaTipo.values) {
        expect(
          podeCriarTipoEscala(
            user: mockUser,
            tipo: tipo,
            ministerios: ministerios,
            escalas: const [],
            competencia: '2026-09',
            igrejaId: 'i1',
          ),
          isTrue,
          reason: 'admin deveria criar ${escalaTipoLabel(tipo)}',
        );
      }
    });

    test('líder do ministério cria apenas escala do próprio ministério', () {
      final comMinisterio = podeCriarTipoEscala(
        user: mockUserLider,
        tipo: EscalaTipo.ministerio,
        ministerios: ministerios,
        escalas: const [],
        competencia: '2026-09',
        igrejaId: 'i1',
      );
      final semSupervisao = podeCriarTipoEscala(
        user: mockUserLider,
        tipo: EscalaTipo.culto,
        ministerios: ministerios,
        escalas: const [],
        competencia: '2026-09',
        igrejaId: 'i1',
      );

      expect(comMinisterio, isTrue);
      expect(semSupervisao, isFalse);
    });

    test('supervisor do mês cria escala de culto e de ministério', () {
      final escalas = [
        Escala(
          id: 'e-sup-set',
          titulo: 'Supervisores — setembro',
          competencia: '2026-09',
          tipo: EscalaTipo.supervisor,
          igrejaId: 'i1',
          supervisorPessoaId: 'p2',
          supervisorNome: 'João da Silva',
          ativo: true,
        ),
      ];

      bool criar(EscalaTipo tipo) => podeCriarTipoEscala(
        user: mockUserLider,
        tipo: tipo,
        ministerios: ministerios,
        escalas: escalas,
        competencia: '2026-09',
        igrejaId: 'i1',
      );

      expect(criar(EscalaTipo.culto), isTrue);
      expect(criar(EscalaTipo.ministerio), isTrue);
    });

    test('ninguem sem papel cria escala de supervisor ou pregador', () {
      final escalas = [
        Escala(
          id: 'e-sup-set',
          titulo: 'Supervisores — setembro',
          competencia: '2026-09',
          tipo: EscalaTipo.supervisor,
          igrejaId: 'i1',
          supervisorPessoaId: 'p2',
          supervisorNome: 'João da Silva',
          ativo: true,
        ),
      ];

      for (final tipo in [EscalaTipo.supervisor, EscalaTipo.pregador]) {
        expect(
          podeCriarTipoEscala(
            user: mockUserLider,
            tipo: tipo,
            ministerios: ministerios,
            escalas: escalas,
            competencia: '2026-09',
            igrejaId: 'i1',
          ),
          isFalse,
        );
      }
    });

    test('supisão de outra competência ou igreja não autoriza', () {
      final escalas = [
        Escala(
          id: 'e-sup-ago',
          titulo: 'Supervisores — agosto',
          competencia: '2026-08',
          tipo: EscalaTipo.supervisor,
          igrejaId: 'i1',
          supervisorPessoaId: 'p2',
          supervisorNome: 'João da Silva',
          ativo: true,
        ),
      ];

      expect(
        podeCriarTipoEscala(
          user: mockUserLider,
          tipo: EscalaTipo.culto,
          ministerios: ministerios,
          escalas: escalas,
          competencia: '2026-09',
          igrejaId: 'i1',
        ),
        isFalse,
      );
      expect(
        podeCriarTipoEscala(
          user: mockUserLider,
          tipo: EscalaTipo.culto,
          ministerios: ministerios,
          escalas: escalas,
          competencia: '2026-08',
          igrejaId: 'i2',
        ),
        isFalse,
      );
    });

    test('usuário nulo nunca cria escala', () {
      expect(
        podeCriarTipoEscala(
          user: null,
          tipo: EscalaTipo.culto,
          ministerios: ministerios,
          escalas: const [],
          competencia: '2026-09',
          igrejaId: 'i1',
        ),
        isFalse,
      );
    });
  });

  group('isSupervisorNoMes', () {
    final escalaSupervisor = Escala(
      id: 'e-sup-ago',
      titulo: 'Supervisores — agosto',
      competencia: '2026-08',
      tipo: EscalaTipo.supervisor,
      igrejaId: 'i1',
      supervisorPessoaId: 'p1',
      supervisorNome: 'Ana Costa',
      ativo: true,
      voluntarios: const [
        EscalaVoluntario(
          id: 'v1',
          pessoaId: 'p3',
          pessoaNome: 'Maria Oliveira',
        ),
      ],
    );

    test('pastor e admin são supervisores sem escala cadastrada', () {
      expect(
        isSupervisorNoMes(
          user: mockUser,
          escalas: const [],
          competencia: '2026-09',
          igrejaId: 'i1',
        ),
        isTrue,
      );
    });

    test('reconhece o supervisor da escala do mês', () {
      expect(
        isSupervisorNoMes(
          user: mockUser,
          escalas: [escalaSupervisor],
          competencia: '2026-08',
          igrejaId: 'i1',
        ),
        isTrue,
      );
    });

    test('reconhece o voluntário designado como supervisor', () {
      expect(
        isSupervisorNoMes(
          user: mockUserCoordenador,
          escalas: [escalaSupervisor],
          competencia: '2026-08',
          igrejaId: 'i1',
        ),
        isTrue,
      );
    });

    test('nega para quem não participa da escala do mês', () {
      expect(
        isSupervisorNoMes(
          user: mockUserMembro,
          escalas: [escalaSupervisor],
          competencia: '2026-08',
          igrejaId: 'i1',
        ),
        isFalse,
      );
    });

    test('nega para usuário sem pessoa associada', () {
      const semPessoa = AuthUser(
        id: 'u9',
        nome: 'Sem pessoa',
        email: 'sem@base.church',
        papeis: ['LIDER'],
        permissoes: Permissoes(),
        igrejaId: 'i1',
        igrejaTipo: IgrejaTipo.matriz,
        igrejaNome: 'Base Church',
      );

      expect(
        isSupervisorNoMes(
          user: semPessoa,
          escalas: [escalaSupervisor],
          competencia: '2026-08',
          igrejaId: 'i1',
        ),
        isFalse,
      );
    });
  });

  group('podeEditarTextoCulto', () {
    test('pastor e admin podem sempre', () {
      expect(podeEditarTextoCulto(mockUser), isTrue);
      expect(podeEditarTextoCulto(mockUserPastorFilial), isTrue);
    });

    test('o pregador designado pode editar o próprio texto', () {
      expect(
        podeEditarTextoCulto(mockUserLider, pregadorPessoaId: 'p2'),
        isTrue,
      );
    });

    test('outro líder não pode editar o texto alheio', () {
      expect(
        podeEditarTextoCulto(mockUserLider, pregadorPessoaId: 'p3'),
        isFalse,
      );
      expect(podeEditarTextoCulto(mockUserLider), isFalse);
    });

    test('usuário nulo nunca edita', () {
      expect(podeEditarTextoCulto(null, pregadorPessoaId: 'p2'), isFalse);
    });
  });

  group('podeEditarLouvor', () {
    test('pastor e admin podem sempre', () {
      expect(podeEditarLouvor(mockUser, ministerios), isTrue);
      expect(podeEditarLouvor(mockUserPastorFilial, ministerios), isTrue);
    });

    test('líder e coordenador do ministério de música podem', () {
      expect(podeEditarLouvor(mockUserLider, ministerios), isTrue);
      expect(podeEditarLouvor(mockUserCoordenador, ministerios), isTrue);
    });

    test('quem não é do ministerio de música não pode', () {
      expect(podeEditarLouvor(mockUserMidia, ministerios), isFalse);
      expect(podeEditarLouvor(mockUserMembro, ministerios), isFalse);
      expect(podeEditarLouvor(null, ministerios), isFalse);
    });
  });

  group('podeVerConteudoMidia', () {
    test('pastor e admin podem sempre', () {
      expect(podeVerConteudoMidia(mockUser, ministerios), isTrue);
    });

    test('quem lidera o ministério de mídia pode', () {
      expect(podeVerConteudoMidia(mockUserMidia, ministerios), isTrue);
    });

    test('os demais não podem', () {
      expect(podeVerConteudoMidia(mockUserLider, ministerios), isFalse);
      expect(podeVerConteudoMidia(null, ministerios), isFalse);
    });
  });

  group('soLeituraConteudoCulto', () {
    test('quem pode editar texto ou louvor não fica somente leitura', () {
      expect(soLeituraConteudoCulto(mockUser, ministerios), isFalse);
      expect(soLeituraConteudoCulto(mockUserLider, ministerios), isFalse);
    });

    test('somente o Bioinformatics fica em modo leitura', () {
      expect(soLeituraConteudoCulto(mockUserMidia, ministerios), isTrue);
    });

    test('quem não pode ver mídia nem editar não acessa o modo leitura', () {
      expect(soLeituraConteudoCulto(mockUserMembro, ministerios), isFalse);
    });
  });

  group('podeGerenciarMinisterio', () {
    test('pastor e admin administram qualquer ministério', () {
      expect(podeGerenciarMinisterio(mockUser, midia), isTrue);
      expect(podeGerenciarMinisterio(mockUser, infantil), isTrue);
    });

    test('líder e coordenador administram o próprio ministério', () {
      expect(podeGerenciarMinisterio(mockUserLider, louvor), isTrue);
      expect(podeGerenciarMinisterio(mockUserCoordenador, louvor), isTrue);
      expect(podeGerenciarMinisterio(mockUserMidia, midia), isTrue);
    });

    test('não administra ministério de outro', () {
      expect(podeGerenciarMinisterio(mockUserMidia, louvor), isFalse);
      expect(podeGerenciarMinisterio(mockUserLider, midia), isFalse);
      expect(podeGerenciarMinisterio(mockUserMembro, louvor), isFalse);
    });

    test('cai para a base ministerial quando não lidera o ministério', () {
      // Maria (p3) é coordenadora do Louvor e da base Adoração, mas não do ministryo de mídia.
      expect(podeGerenciarMinisterio(mockUserCoordenador, midia), isFalse);
      expect(
        podeGerenciarMinisterio(mockUserCoordenador, midia, base: ada),
        isTrue,
      );
    });

    test('base ministerial de outra base não autoriza', () {
      // Fernanda (p5) coordena a base Serviço (b2), não a Adoração (b1).
      expect(
        podeGerenciarMinisterio(mockUserMembro, midia, base: ada),
        isFalse,
      );
    });

    test('usuário nulo não administra', () {
      expect(podeGerenciarMinisterio(null, louvor), isFalse);
      expect(podeGerenciarMinisterio(null, louvor, base: ada), isFalse);
    });
  });

  group('podeGerenciarBaseMinisterial', () {
    test('pastor e admin administram qualquer base', () {
      expect(podeGerenciarBaseMinisterial(mockUser, ada), isTrue);
    });

    test('lider e coordenador da base administram a própria base', () {
      // Adoração (b1): líder p2 (João) e coordenadora p3 (Maria).
      expect(podeGerenciarBaseMinisterial(mockUserLider, ada), isTrue);
      expect(podeGerenciarBaseMinisterial(mockUserCoordenador, ada), isTrue);
      // Carlos (p7) lidera a base Missão (b3), não a Adoração.
      expect(podeGerenciarBaseMinisterial(mockUserMidia, ada), isFalse);
      expect(podeGerenciarBaseMinisterial(mockUserMembro, ada), isFalse);
      expect(podeGerenciarBaseMinisterial(null, ada), isFalse);
    });
  });
}
