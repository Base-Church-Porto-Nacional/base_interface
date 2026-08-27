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
  NavItem(
    label: 'Voluntariado',
    path: '/voluntariado/voluntarios',
    permission: 'voluntarios:view',
    children: [
      NavItem(label: 'Voluntários', path: '/voluntariado/voluntarios'),
      NavItem(label: 'Líderes', path: '/voluntariado/lideres'),
      NavItem(label: 'Escalas', path: '/voluntariado/escalas'),
      NavItem(
        label: 'Ministérios',
        path: '/voluntariado/ministerios',
        permission: 'ministerios:view',
      ),
    ],
  ),
  NavItem(
    label: 'Cultos',
    path: '/cultos',
    permission: 'cronograma:view',
    children: [
      NavItem(label: 'Agenda', path: '/cultos'),
      NavItem(label: 'Gestão de culto', path: '/cultos/conteudo', permission: 'culto:view'),
    ],
  ),
  NavItem(label: 'Usuários', path: '/usuarios', permission: 'usuarios:view'),
  NavItem(
    label: 'Meu serviço',
    path: '/meu-servico',
    permission: 'meu_servico:view',
    children: [
      NavItem(label: 'Visão geral', path: '/meu-servico'),
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
