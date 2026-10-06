import 'package:base_church/mocks/mock_data.dart';
import 'package:base_church/models/models.dart';
import 'package:base_church/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/support.dart';

void main() {
  late MockState snapshot;

  setUp(() => snapshot = MockState.capture());
  tearDown(() => snapshot.restore());

  group('datasDaCompetencia', () {
    test('lista todos os domingos de novembro de 2026', () {
      expect(datasDaCompetencia(DiaSemana.domingo, '2026-11'), [
        '2026-11-01',
        '2026-11-08',
        '2026-11-15',
        '2026-11-22',
        '2026-11-29',
      ]);
    });

    test('lista todos os sábados de novembro de 2026', () {
      expect(datasDaCompetencia(DiaSemana.sabado, '2026-11'), [
        '2026-11-07',
        '2026-11-14',
        '2026-11-21',
        '2026-11-28',
      ]);
    });

    test('devolve lista vazia para competência mal formatada', () {
      expect(datasDaCompetencia(DiaSemana.domingo, '2026'), isEmpty);
      expect(datasDaCompetencia(DiaSemana.domingo, 'novembro'), isEmpty);
      expect(datasDaCompetencia(DiaSemana.domingo, ''), isEmpty);
    });

    test('cai no ano e mês atuais quando os valores não são numéricos', () {
      final datas = datasDaCompetencia(DiaSemana.domingo, 'xxxx-yy');

      expect(datas, isNotEmpty);
      final primeira = DateTime.parse(datas.first);
      expect(primeira.year, DateTime.now().year);
      expect(primeira.month, DateTime.now().month);
    });
  });

  group('janelaConfiguracaoAbertaMock', () {
    test('fica aberta para datas até 8 dias à frente', () {
      final hoje = DateTime.now();

      expect(janelaConfiguracaoAbertaMock(isoDate(hoje)), isTrue);
      expect(janelaConfiguracaoAbertaMock(isoDate(hoje.add(const Duration(days: 7)))), isTrue);
    });

    test('fecha para datas a partir de 9 dias à frente', () {
      final hoje = DateTime.now();

      expect(
        janelaConfiguracaoAbertaMock(isoDate(hoje.add(const Duration(days: 9)))),
        isFalse,
      );
      expect(
        janelaConfiguracaoAbertaMock(isoDate(hoje.add(const Duration(days: 30)))),
        isFalse,
      );
    });

    test('fecha para datas passadas', () {
      final hoje = DateTime.now();

      expect(
        janelaConfiguracaoAbertaMock(isoDate(hoje.subtract(const Duration(days: 5)))),
        isTrue,
      );
    });

    test('devolve falso para data inválida', () {
      expect(janelaConfiguracaoAbertaMock('sem-data'), isFalse);
      expect(janelaConfiguracaoAbertaMock(''), isFalse);
    });
  });

  group('competenciaProximoMes', () {
    test('devolve o mês seguinte com zero à esquerda', () {
      final hoje = DateTime.now();
      final esperado =
          '${hoje.year}-${(hoje.month + 1).toString().padLeft(2, '0')}';

      expect(competenciaProximoMes(), esperado);
    });
  });

  group('gerarCultosCategoriaMock', () {
    test('cria um culto por data da semana respeitando a duração', () {
      final categoria = categoriaCultoById('cat2')!;

      final criados = gerarCultosCategoriaMock(categoria, '2026-11');

      expect(criados, hasLength(4));
      expect(criados.map((c) => c.data).toList(), [
        '2026-11-07',
        '2026-11-14',
        '2026-11-21',
        '2026-11-28',
      ]);
      expect(criados.every((c) => c.horaInicio == '19:30:00'), isTrue);
      expect(criados.every((c) => c.horaFim == '21:30:00'), isTrue);
      expect(criados.every((c) => c.status == CultoStatus.agendado), isTrue);
      expect(criados.every((c) => c.competencia == '2026-11'), isTrue);
      expect(criados.every((c) => c.ativo), isTrue);
      expect(criados.every((c) => !c.temRelatorio), isTrue);
      expect(criados.every((c) => c.categoriaCultoId == 'cat2'), isTrue);
      expect(criados.every((c) => c.categoriaCultoTitulo == 'Sábado jovem'), isTrue);
      expect(criados.every((c) => c.pregadorId == 'p2'), isTrue);
    });

    test('não duplica cultos já existentes', () {
      final categoria = categoriaCultoById('cat2')!;

      final primeira = gerarCultosCategoriaMock(categoria, '2026-11');
      final segunda = gerarCultosCategoriaMock(categoria, '2026-11');

      expect(primeira, hasLength(4));
      expect(segunda, isEmpty);
    });
  });

  group('categoriaCultoById', () {
    test('devolve a categoria encontrada', () {
      expect(categoriaCultoById('cat1')?.titulo, 'Domingo inesquecível');
    });

    test('devolve nulo quando não encontra', () {
      expect(categoriaCultoById('nao-existe'), isNull);
    });
  });

  group('pessoaById', () {
    test('devolve a pessoa encontrada', () {
      expect(pessoaById('p2')?.nome, 'João da Silva');
    });

    test('devolve nulo quando não encontra', () {
      expect(pessoaById('nao-existe'), isNull);
    });
  });

  group('mockCandidatos', () {
    test('lista apenas voluntários ativos com serviço real na igreja', () {
      final candidatos = mockCandidatos('i1');

      expect(candidatos.map((c) => c.pessoaId).toList(), [
        'p2',
        'p3',
        'p4',
        'p5',
        'p7',
      ]);
    });

    test('exclui cargos fictícios dos serviços que a pessoa serve', () {
      final candidatos = mockCandidatos('i1');

      expect(
        candidatos.every((c) => !c.servicosQueServe.contains('Coordenador')),
        isTrue,
      );
    });

    test('filtra pelo nome do serviço', () {
      final candidatos = mockCandidatos('i1', servicoNome: 'Violão');

      expect(candidatos.map((c) => c.pessoaId).toList(), ['p2', 'p3']);
    });

    test('devolve lista vazia quando ninguém serve o serviço pedido', () {
      expect(mockCandidatos('i1', servicoNome: 'Tambor'), isEmpty);
    });

    test('respeita a igreja', () {
      final candidatos = mockCandidatos('i2');

      expect(candidatos.map((c) => c.pessoaId).toList(), ['p10']);
    });

    test('sem data não analisa o dia', () {
      final candidatos = mockCandidatos('i1');

      expect(candidatos.every((c) => c.analiseDia == null), isTrue);
    });

    test('com data preenche a análise de disponibilidade', () {
      final candidatos = mockCandidatos('i1', data: '2026-08-01');

      expect(candidatos.every((c) => c.analiseDia?.data == '2026-08-01'), isTrue);
    });

    test('considera a indisponibilidade semanal registrada', () {
      // 2026-08-03 é uma segunda-feira; p2 está indisponível em toda a segunda.
      final candidatos = mockCandidatos('i1', data: '2026-08-03');
      final joao = candidatos.firstWhere((c) => c.pessoaId == 'p2');

      expect(joao.analiseDia!.disponivel, isFalse);
      expect(joao.analiseDia!.motivosIndisponibilidade, contains('Indisponibilidade semanal'));
    });

    test('considera a indisponibilidade pontual registrada', () {
      final candidatos = mockCandidatos('i1', data: '2026-08-15');
      final maria = candidatos.firstWhere((c) => c.pessoaId == 'p3');

      expect(maria.analiseDia!.disponivel, isFalse);
      expect(maria.analiseDia!.motivosIndisponibilidade, contains('Indisponibilidade pontual'));
    });
  });

  group('mockUserByLogin', () {
    test('mapeia os logins de demonstração para o papel correto', () {
      expect(mockUserByLogin('joao').roles, contains(Role.lider));
      expect(mockUserByLogin('maria').pessoaId, 'p3');
      expect(mockUserByLogin('midia').pessoaId, 'p7');
      expect(mockUserByLogin('filial').igrejaId, 'i2');
      expect(mockUserByLogin('membro').pessoaId, 'p5');
      expect(mockUserByLogin('pedro').roles, [Role.pastor]);
    });

    test('normaliza caixa e espaços', () {
      expect(mockUserByLogin('  ADMIN ').id, mockUser.id);
      expect(mockUserByLogin('JoAo').id, mockUserLider.id);
    });

    test('login desconhecido cai no usuário administrador', () {
      expect(mockUserByLogin('ninguem').id, mockUser.id);
      expect(mockUserByLogin('').id, mockUser.id);
    });
  });

  group('mockVisaoMensal', () {
    test('devolve vazio sem igreja', () {
      expect(mockVisaoMensal(), isEmpty);
    });

    test('sem cargo de liderança só vê os próprios ministérios', () {
      final visao = mockVisaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        pessoaId: 'p2',
      );

      expect(visao.map((v) => v.ministerioId).toList(), ['m1']);
    });

    test('restringe ao ministério pedido', () {
      final visao = mockVisaoMensal(
        igrejaId: 'i1',
        competencia: '2026-09',
        ministerioId: 'm3',
        administrador: true,
      );

      expect(visao.single.ministerioId, 'm3');
    });

    test('devolve vazio para pessoas que não lideram nenhum ministério', () {
      expect(
        mockVisaoMensal(igrejaId: 'i1', competencia: '2026-09', pessoaId: 'p8'),
        isEmpty,
      );
    });
  });
}