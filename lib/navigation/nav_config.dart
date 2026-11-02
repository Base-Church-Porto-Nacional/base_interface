import '../models/models.dart';
import '../utils/permissions.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.path,
    this.visivel,
    this.children = const [],
  });

  final String label;
  final String path;

  /// Regra de visibilidade no menu; null = todos.
  final bool Function(AuthUser user)? visivel;
  final List<NavItem> children;
}

bool _verGestaoIgreja(AuthUser u) =>
    u.permissoes.tem(Capacidade.filialCriar) || isGestao(u);

bool _verPessoas(AuthUser u) => isGestao(u) || u.permissoes.lideraAlgo;

bool _verVoluntariado(AuthUser u) =>
    _verPessoas(u) ||
    u.permissoes.ehVoluntario ||
    u.permissoes.tem(Capacidade.escalasGerir);

final mainNav = [
  NavItem(label: 'Dash', path: '/dashboard'),
  NavItem(label: 'Gestão Igreja', path: '/igrejas', visivel: _verGestaoIgreja),
  NavItem(
    label: 'Membros',
    path: '/membros',
    visivel: _verPessoas,
    children: [
      NavItem(label: 'Membros', path: '/membros'),
      NavItem(label: 'Pessoas', path: '/membros/pessoas', visivel: _verPessoas),
    ],
  ),
  NavItem(label: 'Aniversariantes', path: '/aniversariantes'),
  NavItem(
    label: 'Pequenos grupos',
    path: '/pequenos-grupos',
    visivel: _verPessoas,
  ),
  NavItem(
    label: 'Voluntariado',
    path: '/voluntariado/voluntarios',
    visivel: _verVoluntariado,
    children: [
      NavItem(label: 'Voluntários', path: '/voluntariado/voluntarios'),
      NavItem(label: 'Escalas', path: '/voluntariado/escalas'),
      NavItem(
        label: 'Ministérios',
        path: '/voluntariado/ministerios',
        visivel: _verVoluntariado,
      ),
      NavItem(
        label: 'Relatórios',
        path: '/voluntariado/relatorios',
        visivel: (u) => u.permissoes.tem(Capacidade.relatoriosVer),
      ),
    ],
  ),
  NavItem(
    label: 'Cultos',
    path: '/cultos/mes',
    children: [
      NavItem(label: 'Mês', path: '/cultos/mes'),
      NavItem(label: 'Categorias', path: '/cultos/categorias'),
    ],
  ),
  NavItem(
    label: 'Configurações',
    path: '/configuracoes/mensagem-aniversario',
    visivel: (u) => u.permissoes.tem(Capacidade.configurar),
  ),
  NavItem(
    label: 'Meu serviço',
    path: '/meu-servico',
    children: [
      NavItem(label: 'Visão geral', path: '/meu-servico'),
      NavItem(label: 'Responder escalas', path: '/meu-servico/responder'),
      NavItem(label: 'Disponibilidade', path: '/perfil/disponibilidade'),
    ],
  ),
];

List<NavItem> visibleNavItems(AuthUser? user) {
  if (user == null) return const [];
  return mainNav.where((item) => item.visivel?.call(user) ?? true).toList();
}

const pessoaFiltros = [
  ('TODOS', 'Todos'),
  ('VISITANTE', 'Visitantes'),
  ('MEMBRO', 'Membros'),
  ('BATIZADO', 'Batizados'),
  ('ACEITOU_JESUS', 'Aceitaram Jesus'),
  ('TRILHA', 'Trilha da Base'),
  ('VOLUNTARIO', 'Voluntários'),
  ('LIDER', 'Líderes'),
  ('PASTOR', 'Pastores'),
  ('COM_ACESSO', 'Com acesso'),
];
