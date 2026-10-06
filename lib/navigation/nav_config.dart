import '../models/models.dart';
import '../utils/permissions.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.path,
    this.permission,
    this.children = const [],
  });

  final String label;
  final String path;
  final String? permission;
  final List<NavItem> children;
}

const mainNav = [
  NavItem(label: 'Dash', path: '/dashboard', permission: 'dashboard:view'),
  NavItem(label: 'Gestão Igreja', path: '/igrejas', permission: 'igrejas:manage'),
  NavItem(
    label: 'Membros',
    path: '/membros',
    permission: 'membros:view',
    children: [
      NavItem(label: 'Membros', path: '/membros'),
      NavItem(label: 'Pessoas', path: '/membros/pessoas', permission: 'pessoas:view'),
    ],
  ),
  NavItem(label: 'Aniversariantes', path: '/aniversariantes'),
  NavItem(
    label: 'Pequenos grupos',
    path: '/pequenos-grupos',
    permission: 'small_groups:view',
  ),
  NavItem(
    label: 'Voluntariado',
    path: '/voluntariado/voluntarios',
    permission: 'voluntarios:view',
    children: [
      NavItem(label: 'Voluntários', path: '/voluntariado/voluntarios'),
      NavItem(label: 'Escalas', path: '/voluntariado/escalas'),
      NavItem(
        label: 'Ministérios',
        path: '/voluntariado/ministerios',
        permission: 'ministerios:view',
      ),
      NavItem(
        label: 'Relatórios',
        path: '/voluntariado/relatorios',
        permission: 'relatorios:view',
      ),
    ],
  ),
  NavItem(
    label: 'Cultos',
    path: '/cultos/mes',
    permission: 'cronograma:view',
    children: [
      NavItem(label: 'Mês', path: '/cultos/mes'),
      NavItem(label: 'Categorias', path: '/cultos/categorias'),
    ],
  ),
  NavItem(label: 'Usuários', path: '/usuarios', permission: 'usuarios:view'),
  NavItem(
    label: 'Configurações',
    path: '/configuracoes/mensagem-aniversario',
    permission: 'mensagens:manage',
  ),
  NavItem(
    label: 'Meu serviço',
    path: '/meu-servico',
    permission: 'meu_servico:view',
    children: [
      NavItem(label: 'Visão geral', path: '/meu-servico'),
      NavItem(label: 'Responder escalas', path: '/meu-servico/responder'),
      NavItem(label: 'Disponibilidade', path: '/perfil/disponibilidade'),
    ],
  ),
];

List<NavItem> visibleNavItems(List<Role> roles) {
  return mainNav.where((item) {
    if (item.permission == null) return true;
    if (item.permission == 'igrejas:manage' || item.permission == 'usuarios:view') {
      return hasPermission(roles, item.permission!) ||
          hasPermission(roles, '*') ||
          roles.contains(Role.admin) ||
          roles.contains(Role.pastor);
    }
    return hasPermission(roles, item.permission!);
  }).toList();
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
];
