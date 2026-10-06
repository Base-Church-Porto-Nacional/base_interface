import 'package:base_church/mocks/mock_data.dart';
import 'package:base_church/models/models.dart';
import 'package:base_church/utils/route_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final admin = mockUser;
  final pastorFilial = mockUserPastorFilial;
  final lider = mockUserLider;
  final membro = mockUserMembro;

  final semPapeis = const AuthUser(
    id: 'u11',
    nome: 'Sem permissões',
    email: 'sem@base.church',
    roles: [],
    igrejaId: 'i1',
    igrejaTipo: IgrejaTipo.matriz,
    igrejaNome: 'Base Church',
  );

  group('rotas públicas', () {
    test('login e acesso negado ficam abertos para qualquer usuário logado', () {
      for (final user in [admin, pastorFilial, lider, membro]) {
        expect(canAccessPath(user, '/login'), isTrue);
        expect(canAccessPath(user, '/acesso-negado'), isTrue);
      }
    });

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

  group('dashboard e perfil', () {
    test('admin, pastor e papéis com dashboard:view acessam', () {
      expect(canAccessPath(admin, '/dashboard'), isTrue);
      expect(canAccessPath(pastorFilial, '/dashboard'), isTrue);
      expect(canAccessPath(lider, '/dashboard'), isTrue);
      expect(canAccessPath(membro, '/dashboard'), isTrue);
      expect(canAccessPath(membro, '/perfil'), isTrue);
    });

    test('usuário sem papel é bloqueado no dashboard', () {
      expect(canAccessPath(semPapeis, '/dashboard'), isFalse);
      expect(canAccessPath(semPapeis, '/perfil'), isFalse);
    });
  });

  group('administração', () {
    test('apenas pastor e admin administram igrejas e usuários', () {
      expect(canAccessPath(admin, '/igrejas'), isTrue);
      expect(canAccessPath(admin, '/usuarios'), isTrue);
      expect(canAccessPath(pastorFilial, '/igrejas'), isTrue);
      expect(canAccessPath(pastorFilial, '/usuarios'), isTrue);

      for (final path in ['/igrejas', '/igrejas/i1', '/usuarios', '/usuarios/u1']) {
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

    test('nenhum papel além de pastor e admin altera pessoas', () {
      expect(canMutatePessoas(admin), isTrue);
      expect(canMutatePessoas(pastorFilial), isTrue);
      expect(canMutatePessoas(lider), isFalse);
      expect(canMutatePessoas(membro), isFalse);
      expect(canMutatePessoas(null), isFalse);
    });
  });

  group('voluntariado', () {
    test('líder acessa escalas, ministérios, relatórios e voluntários', () {
      expect(canAccessPath(lider, '/voluntariado/escalas'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/escalas/e1'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/ministerios'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/relatorios'), isTrue);
      expect(canAccessPath(lider, '/voluntariado/voluntarios'), isTrue);
    });

    test('membro não acessa as telas do voluntariado', () {
      expect(canAccessPath(membro, '/voluntariado/escalas'), isFalse);
      expect(canAccessPath(membro, '/voluntariado/ministerios'), isFalse);
      expect(canAccessPath(membro, '/voluntariado/relatorios'), isFalse);
    });

    test('membro sem escalas:view ainda abre o formulário de nova escala', () {
      expect(canAccessPath(membro, '/voluntariado/escalas/nova'), isTrue);
      expect(
        canAccessPath(membro, '/voluntariado/escalas/nova?tipo=culto'),
        isTrue,
      );
    });

    test('pastor e admin acessam a criação de escala', () {
      expect(canAccessPath(admin, '/voluntariado/escalas/nova'), isTrue);
      expect(canAccessPath(pastorFilial, '/voluntariado/escalas/nova'), isTrue);
    });

    test('criação de ministério e de usuário fica com pastor e admin', () {
      expect(canCreateMinisterio(admin), isTrue);
      expect(canCreateMinisterio(lider), isFalse);
      expect(canCreateMinisterio(null), isFalse);

      expect(canCreateUsuario(admin), isTrue);
      expect(canCreateUsuario(lider), isFalse);

      expect(canCreateBaseMinisterial(pastorFilial), isTrue);
      expect(canCreateBaseMinisterial(lider), isFalse);
    });
  });

  group('cultos e cronograma', () {
    test('todo papel com culto:view ou cronograma:view chega à raiz de cultos', () {
      for (final user in [admin, pastorFilial, lider, membro]) {
        expect(canAccessPath(user, '/cultos'), isTrue, reason: '${user.id} em /cultos');
      }
    });

    test('quem tem culto:view chega ao mês, às categorias e ao conteúdo', () {
      for (final path in ['/cultos/mes/2026-09', '/cultos/categorias/cat1', '/cultos/culto/c1', '/cultos/conteudo/c1']) {
        expect(canAccessPath(lider, path), isTrue, reason: 'líder em $path');
        expect(canAccessPath(membro, path), isTrue, reason: 'membro em $path');
        expect(canAccessPath(admin, path), isTrue, reason: 'admin em $path');
      }
    });

    test('quem não tem culto:view nem é pastor não chega às telas de culto', () {
      expect(canAccessPath(semPapeis, '/cultos'), isFalse);
      expect(canAccessPath(semPapeis, '/cultos/mes/2026-09'), isFalse);
      expect(canAccessPath(semPapeis, '/cultos/conteudo/c1'), isFalse);
    });

    test('criação de cronograma fica com pastor e admin', () {
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

    test('disponibilidade exige permissão explícita ou papel com o recurso', () {
      expect(canAccessPath(semPapeis, '/perfil/disponibilidade'), isFalse);
      expect(canAccessPath(admin, '/perfil/disponibilidade'), isTrue);
    });
  });

  group('pequenos grupos', () {
    test('pastor, admin e quem tem small_groups:view acessam pequenos grupos', () {
      expect(canAccessPath(admin, '/pequenos-grupos'), isTrue);
      expect(canAccessPath(pastorFilial, '/pequenos-grupos/g1'), isTrue);
      expect(canAccessPath(lider, '/pequenos-grupos'), isTrue);
    });

    test('voluntário e membro sem a permissão ficam de fora', () {
      expect(canAccessPath(membro, '/pequenos-grupos'), isFalse);
      expect(canAccessPath(semPapeis, '/pequenos-grupos'), isFalse);
    });
  });
}