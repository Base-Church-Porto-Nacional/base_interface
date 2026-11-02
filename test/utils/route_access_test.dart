import '../helpers/fixtures.dart';

import 'package:base_church/models/models.dart';
import 'package:base_church/navigation/nav_config.dart';
import 'package:base_church/utils/route_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final admin = mockUser;
  final pastorFilial = mockUserPastorFilial;
  final lider = mockUserLider;
  final membro = mockUserMembro;
  final secretaria = mockUserSecretaria;
  final voluntario = AuthUser(
    id: 'u12',
    nome: 'Vera',
    email: 'v@base.church',
    papeis: const ['VOLUNTARIO', 'MEMBRO'],
    permissoes: const Permissoes(ehVoluntario: true),
    pessoaId: 'p12',
    igrejaId: 'i1',
    igrejaTipo: IgrejaTipo.matriz,
    igrejaNome: 'Base Church',
  );

  final semPapeis = const AuthUser(
    id: 'u11',
    nome: 'Sem permissões',
    email: 'sem@base.church',
    papeis: [],
    permissoes: Permissoes(),
    igrejaId: 'i1',
    igrejaTipo: IgrejaTipo.matriz,
    igrejaNome: 'Base Church',
  );

  group('rotas públicas', () {
    test(
      'login e acesso negado ficam abertos para qualquer usuário logado',
      () {
        for (final user in [admin, pastorFilial, lider, membro]) {
          expect(canAccessPath(user, '/login'), isTrue);
          expect(canAccessPath(user, '/acesso-negado'), isTrue);
        }
      },
    );

    test('usuário sem sessão não acessa rota alguma', () {
      for (final path in [
        '/login',
        '/dashboard',
        '/perfil',
        '/acesso-negado',
        '/cultos',
      ]) {
        expect(canAccessPath(null, path), isFalse, reason: 'null em $path');
      }
    });

    test('rota desconhecida é bloqueada para todos', () {
      for (final user in [admin, pastorFilial, lider, membro]) {
        expect(canAccessPath(user, '/rota-que-nao-existe'), isFalse);
        expect(canAccessPath(user, '/'), isFalse);
      }
    });

    test('rota desconhecida é bloqueada mesmo para admin', () {
      expect(canAccessPath(admin, '/qualquer/outra/coisa'), isFalse);
    });
  });

  group('contador', () {
    test('acessa os cultos do mês e o detalhe do culto', () {
      expect(canAccessPath(mockUserContador, '/cultos/mes'), isTrue);
      expect(canAccessPath(mockUserContador, '/cultos/culto/c1'), isTrue);
      expect(canAccessPath(mockUserContador, '/dashboard'), isTrue);
    });

    test('não acessa gestão de pessoas, usuários nem configurações', () {
      expect(canAccessPath(mockUserContador, '/membros/pessoas'), isFalse);
      expect(canAccessPath(mockUserContador, '/usuarios'), isFalse);
      expect(
        canAccessPath(mockUserContador, '/configuracoes/mensagem-aniversario'),
        isFalse,
      );
    });
  });

  group('dashboard e perfil', () {
    test('qualquer usuário logado acessa dashboard e perfil', () {
      for (final u in [admin, pastorFilial, lider, membro, secretaria, semPapeis]) {
        expect(canAccessPath(u, '/dashboard'), isTrue);
        expect(canAccessPath(u, '/perfil'), isTrue);
      }
    });
  });

  group('administração', () {
    test('membroNaoAcessaUsuarios; secretaria gere contas mas não cria filial', () {
      expect(canAccessPath(membro, '/usuarios'), isFalse);
      expect(canAccessPath(secretaria, '/usuarios'), isTrue);
      expect(canAccessPath(secretaria, '/igrejas'), isTrue); // gestão
      expect(canAccessPath(admin, '/igrejas'), isTrue);
      expect(canAccessPath(admin, '/usuarios'), isTrue);
      expect(canAccessPath(pastorFilial, '/igrejas'), isTrue);
      expect(canAccessPath(pastorFilial, '/usuarios'), isTrue);

      for (final path in [
        '/igrejas',
        '/igrejas/i1',
        '/usuarios',
        '/usuarios/u1',
      ]) {
        expect(canAccessPath(lider, path), isFalse, reason: 'líder em $path');
        expect(canAccessPath(membro, path), isFalse, reason: 'membro em $path');
      }
    });

    test('apenas pastor e admin editam as mensagens de aniversário', () {
      expect(canAccessPath(admin, '/configuracoes'), isTrue);
      expect(canAccessPath(pastorFilial, '/configuracoes'), isTrue);
      expect(canAccessPath(lider, '/configuracoes'), isFalse);
      expect(canAccessPath(membro, '/configuracoes'), isFalse);

      expect(canEditMensagemAniversario(admin), isTrue);
      expect(canEditMensagemAniversario(lider), isFalse);
      expect(canEditMensagemAniversario(null), isFalse);
    });
  });

  group('membros', () {
    test('liderAcessaPessoas', () {
      expect(canAccessPath(lider, '/membros/pessoas'), isTrue);
    });

    test('líder vê qualquer ficha de pessoa', () {
      expect(canAccessPath(lider, '/membros/pessoa/p2'), isTrue);
      expect(canAccessPath(lider, '/membros/pessoa/p5'), isTrue);
    });

    test('membro só vê a própria ficha', () {
      expect(canAccessPath(membro, '/membros/pessoa/p5'), isTrue);
      expect(canAccessPath(membro, '/membros/pessoa/p2'), isFalse);
    });

    test('a lista de pessoas exige permissão de leitura', () {
      expect(canAccessPath(lider, '/membros/pessoas'), isTrue);
      expect(canAccessPath(membro, '/membros/pessoas'), isFalse);
    });

    test('só quem tem pessoasGerir altera pessoas', () {
      expect(canMutatePessoas(admin), isTrue);
      expect(canMutatePessoas(secretaria), isTrue);
      expect(canMutatePessoas(pastorFilial), isTrue);
      expect(canMutatePessoas(lider), isFalse);
      expect(canMutatePessoas(membro), isFalse);
      expect(canMutatePessoas(null), isFalse);
    });
  });

  group('voluntariado', () {
    test('líder acessa escalas, ministérios e voluntários', () {
      expect(canAccessPath(lider, '/voluntariado/escalas'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/escalas/e1'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/ministerios'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/voluntarios'), isTrue);
    });

    test('membro puro não acessa as telas do voluntariado', () {
      expect(canAccessPath(membro, '/voluntariado/escalas'), isFalse);
      expect(canAccessPath(membro, '/voluntariado/ministerios'), isFalse);
      expect(canAccessPath(membro, '/voluntariado/relatorios'), isFalse);
      expect(canAccessPath(membro, '/voluntariado/escalas/nova'), isFalse);
    });

    test('voluntário acessa voluntariado e abre o formulário de nova escala', () {
      expect(canAccessPath(voluntario, '/voluntariado/escalas'), isTrue);
      expect(canAccessPath(voluntario, '/voluntariado/ministerios'), isTrue);
      expect(canAccessPath(voluntario, '/voluntariado/escalas/nova'), isTrue);
      expect(
        canAccessPath(voluntario, '/voluntariado/escalas/nova?tipo=culto'),
        isTrue,
      );
      expect(canAccessPath(voluntario, '/voluntariado/relatorios'), isFalse);
    });

    test('relatórios exige relatoriosVer', () {
      expect(canAccessPath(secretaria, '/voluntariado/relatorios'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/relatorios'), isFalse);
    });

    test('pastor e admin acessam a criação de escala', () {
      expect(canAccessPath(admin, '/voluntariado/escalas/nova'), isTrue);
      expect(canAccessPath(pastorFilial, '/voluntariado/escalas/nova'), isTrue);
    });

    test('criação de ministério e de usuário segue as capacidades', () {
      expect(canCreateMinisterio(admin), isTrue);
      expect(canCreateMinisterio(secretaria), isTrue);
      expect(canCreateMinisterio(lider), isFalse);
      expect(canCreateMinisterio(null), isFalse);

      expect(canCreateUsuario(admin), isTrue);
      expect(canCreateUsuario(lider), isFalse);

      expect(canCreateBaseMinisterial(pastorFilial), isTrue);
      expect(canCreateBaseMinisterial(lider), isFalse);
    });
  });

  group('cultos e cronograma', () {
    test(
      'todo papel com culto:view ou cronograma:view chega à raiz de cultos',
      () {
        for (final user in [admin, pastorFilial, lider, membro]) {
          expect(
            canAccessPath(user, '/cultos'),
            isTrue,
            reason: '${user.id} em /cultos',
          );
        }
      },
    );

    test('quem tem culto:view chega ao mês, às categorias e ao conteúdo', () {
      for (final path in [
        '/cultos/mes/2026-09',
        '/cultos/categorias/cat1',
        '/cultos/culto/c1',
        '/cultos/conteudo/c1',
      ]) {
        expect(canAccessPath(lider, path), isTrue, reason: 'líder em $path');
        expect(canAccessPath(membro, path), isTrue, reason: 'membro em $path');
        expect(canAccessPath(admin, path), isTrue, reason: 'admin em $path');
      }
    });

    test('cultos são abertos a qualquer usuário logado', () {
      expect(canAccessPath(semPapeis, '/cultos'), isTrue);
      expect(canAccessPath(semPapeis, '/cultos/mes/2026-09'), isTrue);
      expect(canAccessPath(semPapeis, '/cultos/conteudo/c1'), isTrue);
    });

    test('criação de cronograma fica com a gestão', () {
      expect(canCreateCronograma(admin), isTrue);
      expect(canCreateCronograma(pastorFilial), isTrue);
      expect(canCreateCronograma(lider), isFalse);
      expect(canCreateCronograma(membro), isFalse);
      expect(canCreateCronograma(null), isFalse);
    });
  });

  group('meu serviço e disponibilidade', () {
    test('meu serviço é acessível a todos os papéis não administrativos', () {
      expect(canAccessPath(lider, '/meu-servico'), isTrue);
      expect(canAccessPath(membro, '/meu-servico'), isTrue);
    });

    test('disponibilidade é acessível a líder, voluntario e membro', () {
      expect(canAccessPath(membro, '/perfil/disponibilidade'), isTrue);
      expect(canAccessPath(lider, '/perfil/disponibilidade'), isTrue);
    });

    test('disponibilidade é aberta a qualquer usuário logado', () {
      expect(canAccessPath(semPapeis, '/perfil/disponibilidade'), isTrue);
      expect(canAccessPath(admin, '/perfil/disponibilidade'), isTrue);
    });
  });

  group('pequenos grupos', () {
    test(
      'pastor, admin e quem tem small_groups:view acessam pequenos grupos',
      () {
        expect(canAccessPath(admin, '/pequenos-grupos'), isTrue);
        expect(canAccessPath(pastorFilial, '/pequenos-grupos/g1'), isTrue);
        expect(canAccessPath(lider, '/pequenos-grupos'), isTrue);
      },
    );

    test('voluntário e membro sem a permissão ficam de fora', () {
      expect(canAccessPath(membro, '/pequenos-grupos'), isFalse);
      expect(canAccessPath(semPapeis, '/pequenos-grupos'), isFalse);
    });
  });

  group('menu (visibleNavItems)', () {
    List<String> labels(AuthUser u) => [
          for (final i in visibleNavItems(u)) ...[
            i.label,
            ...i.children.map((c) => c.label),
          ],
        ];

    test('pastor vê tudo', () {
      expect(labels(admin), containsAll([
        'Gestão Igreja', 'Usuários', 'Configurações', 'Meu serviço',
        'Pessoas', 'Voluntariado',
      ]));
    });

    test('membro vê só o básico', () {
      final l = labels(membro);
      expect(l, contains('Meu serviço'));
      for (final x in ['Gestão Igreja', 'Usuários', 'Configurações', 'Voluntariado']) {
        expect(l, isNot(contains(x)));
      }
    });

    test('líder vê Pessoas e Voluntariado mas não Usuários', () {
      final l = labels(lider);
      expect(l, containsAll(['Pessoas', 'Voluntariado']));
      expect(l, isNot(contains('Usuários')));
    });

    test('secretaria vê Usuários e Configurações', () {
      expect(labels(secretaria), containsAll(['Usuários', 'Configurações']));
    });
  });
}
