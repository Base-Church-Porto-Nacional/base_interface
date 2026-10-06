import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/acesso/acesso_negado_screen.dart';
import '../screens/aniversarios/aniversariantes_screen.dart';
import '../screens/aniversarios/aniversario_envios_screen.dart';
import '../screens/cronograma/cronograma_screen.dart';
import '../screens/culto/categorias_culto_screen.dart';
import '../screens/culto/conteudo_culto_screen.dart';
import '../screens/culto/culto_detail_screen.dart';
import '../screens/culto/cultos_mes_screen.dart';
import '../screens/configuracoes/mensagem_aniversario_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/disponibilidade/disponibilidade_screen.dart';
import '../screens/escalas/escala_detail_screen.dart';
import '../screens/escalas/escala_edit_screen.dart';
import '../screens/escalas/escala_form_screen.dart';
import '../screens/escalas/escalas_screen.dart';
import '../screens/escalas/visao_mensal_screen.dart';
import '../screens/igrejas/igreja_detail_screen.dart';
import '../screens/igrejas/igrejas_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/membros/membros_screen.dart';
import '../screens/meu_servico/meu_servico_screen.dart';
import '../screens/meu_servico/responder_escalas_screen.dart';
import '../screens/ministerios/ministerio_detail_screen.dart';
import '../screens/ministerios/ministerios_screen.dart';
import '../screens/pessoas/pessoa_detail_screen.dart';
import '../screens/pessoas/pessoas_screen.dart';
import '../screens/pequenos_grupos/small_group_detail_screen.dart';
import '../screens/pequenos_grupos/small_groups_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/usuarios/usuarios_screen.dart';
import '../screens/voluntariado/relatorios_screen.dart';
import '../screens/voluntariado/voluntarios_screen.dart';
import '../utils/route_access.dart';
import '../widgets/placeholder_screen.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final path = state.uri.path;
      final onLogin = path == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/dashboard';
      if (loggedIn && !canAccessPath(auth.user, path)) return '/acesso-negado';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/acesso-negado',
            builder: (_, _) => const AcessoNegadoScreen(),
          ),
          GoRoute(
            path: '/igrejas',
            builder: (_, _) => const IgrejasScreen(),
          ),
          GoRoute(
            path: '/igrejas/:id',
            builder: (_, state) => IgrejaDetailScreen(
              igrejaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/membros',
            builder: (_, _) => const MembrosScreen(),
          ),
          GoRoute(
            path: '/membros/pessoas',
            builder: (_, _) => const PessoasScreen(),
          ),
          GoRoute(
            path: '/membros/pessoa/:id',
            builder: (_, state) => PessoaDetailScreen(
              pessoaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/pequenos-grupos',
            builder: (_, _) => const SmallGroupsScreen(),
          ),
          GoRoute(
            path: '/pequenos-grupos/:id',
            builder: (_, state) => SmallGroupDetailScreen(
              groupId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/voluntariado/ministerios',
            builder: (_, _) => const MinisteriosScreen(),
          ),
          GoRoute(
            path: '/voluntariado/ministerios/:id',
            builder: (_, state) => MinisterioDetailScreen(
              ministerioId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/voluntariado/relatorios',
            builder: (_, _) => const RelatoriosScreen(),
          ),
          GoRoute(
            path: '/voluntariado/voluntarios',
            builder: (_, _) => const VoluntariosScreen(),
          ),
          GoRoute(
            path: '/voluntariado/escalas/nova',
            builder: (_, state) => EscalaFormScreen(
              competencia: state.uri.queryParameters['competencia'],
            ),
          ),
          GoRoute(
            path: '/voluntariado/escalas/:id/editar',
            builder: (_, state) => EscalaEditScreen(
              escalaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/voluntariado/escalas/visao-mensal',
            builder: (_, state) => VisaoMensalScreen(
              competencia: state.uri.queryParameters['competencia'],
            ),
          ),
          GoRoute(
            path: '/voluntariado/escalas/:id',
            builder: (_, state) => EscalaDetailScreen(
              escalaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/voluntariado/escalas',
            builder: (_, _) => const EscalasScreen(),
          ),
          GoRoute(
            path: '/cultos/culto/:id',
            builder: (_, state) => CultoDetailScreen(
              cultoId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/cultos/mes',
            builder: (_, state) => CultosMesScreen(
              competencia: state.uri.queryParameters['competencia'],
            ),
          ),
          GoRoute(
            path: '/cultos/categorias',
            builder: (_, _) => const CategoriasCultoScreen(),
          ),
          GoRoute(
            path: '/cultos/conteudo',
            builder: (_, state) => ConteudoCultoScreen(
              eventoId: state.uri.queryParameters['eventoId'],
            ),
          ),
          GoRoute(
            path: '/cultos',
            builder: (_, _) => const CronogramaScreen(),
          ),
          GoRoute(
            path: '/usuarios',
            builder: (_, _) => const UsuariosScreen(),
          ),
          GoRoute(
            path: '/meu-servico',
            builder: (_, _) => const MeuServicoScreen(),
          ),
          GoRoute(
            path: '/meu-servico/responder',
            builder: (_, _) => const ResponderEscalasScreen(),
          ),
          GoRoute(
            path: '/perfil/disponibilidade',
            builder: (_, _) => const DisponibilidadeScreen(),
          ),
          GoRoute(
            path: '/aniversariantes/envios',
            builder: (_, _) => const AniversarioEnviosScreen(),
          ),
          GoRoute(
            path: '/aniversariantes',
            builder: (_, _) => const AniversariantesScreen(),
          ),
          GoRoute(
            path: '/configuracoes/mensagem-aniversario',
            builder: (_, _) => const MensagemAniversarioScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (_, _) => const PlaceholderScreen(
              title: 'Perfil',
              description: 'Informações da conta.',
            ),
          ),
        ],
      ),
    ],
  );
}
