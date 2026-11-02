import 'package:base_church/models/models.dart';
import 'package:base_church/services/acesso_service.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/services/dashboard_service.dart';
import 'package:base_church/services/disponibilidade_service.dart';
import 'package:base_church/services/ministerio_service.dart';
import 'package:base_church/services/pessoa_service.dart';
import 'package:base_church/services/usuario_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService.login', () {
    test('combina /auth/login e /me no usuário autenticado', () async {
      final api = await apiClientDeTeste(token: null);
      final prefs = await SharedPreferences.getInstance();
      final fake = FakeApi({
        'POST /auth/login': (_) => (
          200,
          {
            'token': 'jwt',
            'usuarioId': 'u1',
          },
        ),
        'GET /me': (r) {
          expect(r.headers['Authorization'], 'Bearer jwt');
          return (
            200,
            {
              'nome': 'Ana Costa',
              'email': 'ana@base.church',
              'papeis': ['PASTOR'],
              'permissoes': {
                'capacidades': ['PESSOAS_VER_TODAS', 'INEXISTENTE'],
                'ministeriosLiderados': ['m1'],
                'basesLideradas': [],
                'gruposLiderados': [],
                'ehVoluntario': true,
              },
              'pessoaId': 'p1',
              'igrejaId': 'i1',
              'igrejaTipo': 'MATRIZ',
              'igrejaNome': 'Base Church',
              'igrejasVisiveis': [
                {'id': 'i1', 'nome': 'Base Church', 'tipo': 'MATRIZ'},
                {
                  'id': 'i2',
                  'nome': 'Zona Sul',
                  'tipo': 'FILIAL',
                  'igrejaMatrizId': 'i1',
                },
              ],
            },
          );
        },
      });

      final user = await fake.run(
        () => AuthService(api, prefs).login('ana@base.church', 'segredo'),
      );

      expect(fake.log, ['POST /auth/login', 'GET /me']);
      expect(fake.corpo(0), {'identificador': 'ana@base.church', 'senha': 'segredo'});
      expect(fake.chamadas.first.headers.containsKey('Authorization'), isFalse);
      expect(user.id, 'u1');
      expect(user.nome, 'Ana Costa');
      expect(user.papeis, ['PASTOR']);
      expect(user.permissoes.capacidades, {Capacidade.pessoasVerTodas});
      expect(user.permissoes.ministeriosLiderados, {'m1'});
      expect(user.permissoes.ehVoluntario, isTrue);
      expect(user.igrejaTipo, IgrejaTipo.matriz);
      expect(user.igrejasVisiveis.map((i) => i.id), ['i1', 'i2']);
      expect(api.token, 'jwt');
      expect(AuthService(api, prefs).getStoredUser()?.nome, 'Ana Costa');
    });

    test('senha errada repassa a mensagem do backend', () async {
      final api = await apiClientDeTeste(token: null);
      final prefs = await SharedPreferences.getInstance();
      final fake = FakeApi({
        'POST /auth/login': (_) =>
            (401, {'message': 'Usuário ou senha inválidos'}),
      });

      await expectLater(
        fake.run(() => AuthService(api, prefs).login('ana', 'x')),
        throwsA(predicate((e) => e.toString() == 'Usuário ou senha inválidos')),
      );
    });
  });

  group('DisponibilidadeService', () {
    test('salvar substitui as janelas da pessoa pelas novas', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /disponibilidades/semanal/pessoa/p1': (_) => (
          200,
          [
            {
              'id': 'w1',
              'diaSemana': 'DOMINGO',
              'horaInicio': '00:00:00',
              'horaFim': '23:59:00',
              'disponivel': true,
            },
          ],
        ),
        'DELETE /disponibilidades/semanal/w1': (_) => (204, null),
        'POST /disponibilidades/semanal': (_) => (201, {'id': 'novo'}),
        'GET /disponibilidades/indisponibilidades/pessoa/p1': (_) => (200, []),
      });

      await fake.run(
        () => DisponibilidadeService(api).saveSemanal(
          pessoaId: 'p1',
          semanal: const [
            IndisponibilidadeSemanal(dia: DiaSemana.domingo, noite: true),
          ],
        ),
      );

      expect(fake.log.take(2), [
        'GET /disponibilidades/semanal/pessoa/p1',
        'DELETE /disponibilidades/semanal/w1',
      ]);
      final posts = [
        for (var i = 0; i < fake.chamadas.length; i++)
          if (fake.log[i] == 'POST /disponibilidades/semanal') fake.corpo(i),
      ];
      expect(posts, hasLength(7));
      expect(posts.first, {
        'pessoaId': 'p1',
        'diaSemana': 'DOMINGO',
        'horaInicio': '00:00:00',
        'horaFim': '18:00:00',
        'disponivel': true,
      });
    });

    test('ler converte janelas em períodos bloqueados', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /disponibilidades/semanal/pessoa/p1': (_) => (
          200,
          [
            {
              'id': 'w1',
              'diaSemana': 'SABADO',
              'horaInicio': '00:00:00',
              'horaFim': '12:00:00',
              'disponivel': true,
            },
          ],
        ),
        'GET /disponibilidades/indisponibilidades/pessoa/p1': (_) => (
          200,
          [
            {
              'id': 'd1',
              'pessoaId': 'p1',
              'dataInicio': '2026-12-24',
              'motivo': 'Viagem',
            },
          ],
        ),
      });

      final result = await fake.run(
        () => DisponibilidadeService(api).getByPessoa('p1'),
      );

      final sabado = result.semanal.singleWhere(
        (d) => d.dia == DiaSemana.sabado,
      );
      expect((sabado.manha, sabado.tarde, sabado.noite), (false, true, true));
      expect(result.semanal, hasLength(7));
      expect(result.datas.single.data, '2026-12-24');
    });
  });

  group('DashboardService', () {
    test('usa /dashboard e conta membros pela lista de pessoas', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /dashboard': (_) => (
          200,
          {'totalPessoas': 10, 'totalVoluntariosAtivos': 4, 'totalLideres': 2},
        ),
        'GET /pessoas': (_) => (
          200,
          [
            {
              'id': 'p1',
              'nome': 'Ana',
              'papeis': ['PASTOR'],
              'funcoes': ['MEMBRO', 'LIDER', 'PASTOR'],
            },
            {
              'id': 'p2',
              'nome': 'Bia',
              'papeis': <String>[],
              'funcoes': ['VOLUNTARIO'],
            },
            {
              'id': 'p3',
              'nome': 'Caio',
              'papeis': ['CONTADOR'],
              'funcoes': ['MEMBRO'],
            },
          ],
        ),
      });

      final stats = await fake.run(
        () => DashboardService(api, PessoaService(api)).getStats(),
      );

      expect(stats!.totalPessoas, 10);
      expect(stats.totalMembros, 2);
      expect(stats.totalVoluntarios, 4);
      expect(stats.totalLideres, 2);
      expect(stats.jornada, isNull);
      expect(stats.proximasEscalas, isNull);
    });

    test('perfil sem acesso (403) devolve null', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /dashboard': (_) => (403, {'message': 'Acesso negado'}),
      });

      final stats = await fake.run(
        () => DashboardService(api, PessoaService(api)).getStats(),
      );

      expect(stats, isNull);
    });
  });

  group('UsuarioService', () {
    final usuarioJson = {
      'id': 'u9',
      'email': 'r@base.church',
      'telefone': '63999990000',
      'igrejaId': 'filial',
      'papeis': ['SECRETARIA', 'CONTADOR'],
    };

    test('createFromPessoa não envia papéis nem consulta /papeis', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /pessoas/p9/usuario': (_) => (201, usuarioJson),
      });

      await fake.run(
        () => UsuarioService(api).createFromPessoa(
          pessoaId: 'p9',
          username: 'recepcao',
          email: 'r@base.church',
          senha: 's',
          igrejaId: 'filial',
        ),
      );

      expect(fake.log, ['POST /pessoas/p9/usuario']);
      expect(fake.corpo(0), {
        'username': 'recepcao',
        'email': 'r@base.church',
        'senha': 's',
        'igrejaId': 'filial',
      });
    });

    test('mapeia e-mail e telefone da conta', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({'GET /usuarios': (_) => (200, [usuarioJson])});

      final contas = await fake.run(() => UsuarioService(api).list());

      expect(contas.single.email, 'r@base.church');
      expect(contas.single.telefone, '63999990000');
    });

    test('alterarPapeis faz PUT /usuarios/{id}/papeis', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({'PUT /usuarios/u9/papeis': (_) => (200, usuarioJson)});

      final conta = await fake.run(
        () => UsuarioService(api).alterarPapeis('u9', ['SECRETARIA', 'CONTADOR']),
      );

      expect(fake.log, ['PUT /usuarios/u9/papeis']);
      expect(fake.corpo(0), {
        'papeis': ['SECRETARIA', 'CONTADOR'],
      });
      expect(conta.papeis, ['SECRETARIA', 'CONTADOR']);
    });

    test('listarPapeisCustomizados filtra os de sistema', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /papeis': (r) {
          expect(r.url.queryParameters['igrejaId'], 'i1');
          return (
            200,
            [
              {'id': 'a', 'nome': 'PASTOR', 'sistema': true},
              {'id': 'b', 'nome': 'CONTADOR', 'sistema': false},
            ],
          );
        },
      });

      final papeis = await fake.run(
        () => UsuarioService(api).listarPapeisCustomizados('i1'),
      );

      expect(papeis, ['CONTADOR']);
    });
    test('criarPapel faz POST /papeis com nome, contagem e igreja', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /papeis': (_) => (
          201,
          {'id': 'c1', 'nome': 'CONTADOR', 'sistema': false, 'podeLancarContagem': true},
        ),
      });

      final nome = await fake.run(
        () => UsuarioService(api).criarPapel(
          nome: 'Contador',
          podeLancarContagem: true,
          igrejaId: 'i1',
        ),
      );

      expect(fake.log, ['POST /papeis']);
      expect(fake.corpo(0), {
        'nome': 'Contador',
        'podeLancarContagem': true,
        'igrejaId': 'i1',
      });
      expect(nome, 'CONTADOR');
    });

    test('criarPapel repassa a recusa do servidor (nome reservado)', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /papeis': (_) => (400, {'message': 'Nome de papel reservado: LIDER'}),
      });

      expect(
        () => fake.run(
          () => UsuarioService(api).criarPapel(
            nome: 'LIDER',
            podeLancarContagem: false,
            igrejaId: 'i1',
          ),
        ),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'mensagem', contains('reservado')),
        ),
      );
    });
  });

  group('PessoaService', () {
    test('buscarPorNome faz GET /pessoas/busca?nome=', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /pessoas/busca': (r) {
          expect(r.url.queryParameters['nome'], 'jo');
          return (
            200,
            [
              {'id': 'p1', 'nome': 'João'},
            ],
          );
        },
      });

      final r = await fake.run(() => PessoaService(api).buscarPorNome('jo'));

      expect(r.map((e) => (e.id, e.nome)), [('p1', 'João')]);
    });

    test('tipos vêm de funcoes (papéis de sistema/customizados não viram tipo)', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /pessoas': (_) => (
          200,
          [
            {
              'id': 'p1',
              'nome': 'Ana',
              'papeis': ['SECRETARIA', 'CONTADOR'],
              'funcoes': ['LIDER', 'MEMBRO', 'SECRETARIA', 'VOLUNTARIO'],
            },
            {'id': 'p2', 'nome': 'Bia', 'papeis': <String>[], 'funcoes': <String>[]},
            {'id': 'p3', 'nome': 'Caio', 'papeis': ['LIDER']},
          ],
        ),
      });

      final page = await fake.run(() => PessoaService(api).list(size: 10));
      final porId = {for (final p in page.content) p.id: p.tipos};

      expect(porId['p1'], containsAll([PessoaTipo.lider, PessoaTipo.membro, PessoaTipo.voluntario]));
      expect(porId['p2'], [PessoaTipo.visitante]);
      expect(porId['p3'], [PessoaTipo.visitante]);
    });

    test('update faz PUT parcial só com os campos do formulário', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'PUT /pessoas/p2': (_) => (200, {'id': 'p2', 'nome': 'Ana', 'funcoes': ['MEMBRO']}),
      });

      await fake.run(
        () => PessoaService(api).update(
          'p2',
          nome: 'Ana',
          telefone: '11999',
          email: 'ana@x.com',
          whatsapp: '',
        ),
      );

      expect(fake.log, ['PUT /pessoas/p2']);
      expect(fake.corpo(0), {
        'nome': 'Ana',
        'telefone': '11999',
        'email': 'ana@x.com',
        'whatsapp': '',
      });
    });

    test('update omite campos não informados', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'PUT /pessoas/p2': (_) => (200, {'id': 'p2', 'nome': 'Ana'}),
      });

      await fake.run(() => PessoaService(api).update('p2', nome: 'Ana'));

      expect(fake.corpo(0), {'nome': 'Ana'});
    });

    test('create envia servicoId quando informado', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /pessoas': (_) => (201, {'id': 'p2', 'nome': 'Ana'}),
      });

      await fake.run(
        () => PessoaService(api).create(nome: 'Ana', servicoId: 's1'),
      );

      expect(fake.corpo(0), {'nome': 'Ana', 'servicoId': 's1'});
    });

    test('create sem servicoId não envia o campo', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /pessoas': (_) => (201, {'id': 'p2', 'nome': 'Ana'}),
      });

      await fake.run(() => PessoaService(api).create(nome: 'Ana'));

      expect((fake.corpo(0) as Map).containsKey('servicoId'), isFalse);
    });
  });
  group('MinisterioService', () {
    test('vincularPessoa faz POST /voluntarios com pessoa e serviço', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /voluntarios': (_) => (201, {'id': 'ps1', 'pessoaId': 'p5', 'servicoId': 's1a'}),
      });

      await fake.run(
        () => MinisterioService(api).vincularPessoa(pessoaId: 'p5', servicoId: 's1a'),
      );

      expect(fake.log, ['POST /voluntarios']);
      expect(fake.corpo(0), {'pessoaId': 'p5', 'servicoId': 's1a'});
    });

    test('vincularPessoa repassa o erro do servidor', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /voluntarios': (_) => (400, {'message': 'A pessoa já está vinculada a este serviço'}),
      });

      expect(
        () => fake.run(
          () => MinisterioService(api).vincularPessoa(pessoaId: 'p5', servicoId: 's1a'),
        ),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'mensagem', contains('já está vinculada')),
        ),
      );
    });
  });

  group('AcessoService', () {
    test('info faz GET /auth/token/{token} sem Bearer', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'GET /auth/token/abc': (_) =>
            (200, {'tipo': 'CONVITE', 'primeiroNome': 'Ana'}),
      });

      final info = await fake.run(() => AcessoService(api).info('abc'));

      expect(fake.log, ['GET /auth/token/abc']);
      expect(fake.chamadas.first.headers.containsKey('Authorization'), isFalse);
      expect(info.tipo, 'CONVITE');
      expect(info.primeiroNome, 'Ana');
    });

    test('410 não dispara sessão expirada', () async {
      final api = await apiClientDeTeste();
      var expirou = false;
      api.onUnauthorized = () => expirou = true;
      final fake = FakeApi({
        'GET /auth/token/x': (_) => (410, {'message': 'expirou'}),
      });

      await expectLater(
        fake.run(() => AcessoService(api).info('x')),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 410)),
      );
      expect(expirou, isFalse);
    });

    test('definirSenha faz POST /auth/definir-senha sem Bearer', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({
        'POST /auth/definir-senha': (_) => (200, {'token': 'jwt'}),
      });

      final r = await fake.run(
        () => AcessoService(api).definirSenha('abc', 'senha1234'),
      );

      expect(fake.log, ['POST /auth/definir-senha']);
      expect(fake.corpo(0), {'token': 'abc', 'senha': 'senha1234'});
      expect(fake.chamadas.first.headers.containsKey('Authorization'), isFalse);
      expect(r['token'], 'jwt');
    });

    test('esqueciSenha faz POST /auth/esqueci-senha', () async {
      final api = await apiClientDeTeste();
      final fake = FakeApi({'POST /auth/esqueci-senha': (_) => (204, null)});

      await fake.run(() => AcessoService(api).esqueciSenha('ana@base.church'));

      expect(fake.log, ['POST /auth/esqueci-senha']);
      expect(fake.corpo(0), {'identificador': 'ana@base.church'});
      expect(fake.chamadas.first.headers.containsKey('Authorization'), isFalse);
    });
  });
}
