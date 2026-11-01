import 'package:base_church/models/models.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:base_church/services/dashboard_service.dart';
import 'package:base_church/services/disponibilidade_service.dart';
import 'package:base_church/services/pessoa_service.dart';
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
            'username': 'ana',
            'papeis': ['admin', 'PASTOR'],
          },
        ),
        'GET /me': (r) {
          expect(r.headers['Authorization'], 'Bearer jwt');
          return (
            200,
            {
              'nome': 'Ana Costa',
              'email': 'ana@base.church',
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
        () => AuthService(api, prefs).login('ana', 'segredo'),
      );

      expect(fake.log, ['POST /auth/login', 'GET /me']);
      expect(fake.corpo(0), {'username': 'ana', 'senha': 'segredo'});
      expect(fake.chamadas.first.headers.containsKey('Authorization'), isFalse);
      expect(user.id, 'u1');
      expect(user.nome, 'Ana Costa');
      expect(user.roles, [Role.admin, Role.pastor]);
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
              'papeis': ['MEMBRO', 'LIDER'],
            },
            {
              'id': 'p2',
              'nome': 'Bia',
              'papeis': ['VOLUNTARIO'],
            },
            {
              'id': 'p3',
              'nome': 'Caio',
              'papeis': ['MEMBRO'],
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
}
