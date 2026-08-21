export interface SubNavItem {
  to: string
  label: string
  end?: boolean
}

export interface MainNavItem {
  to: string
  label: string
  match: string[]
  permission?: string
  subnav?: SubNavItem[]
}

export const MAIN_NAV: MainNavItem[] = [
  {
    to: '/dashboard',
    label: 'Dash',
    match: ['/dashboard'],
    permission: 'dashboard:view',
  },
  {
    to: '/membros',
    label: 'Membros',
    match: ['/membros'],
    permission: 'membros:view',
    subnav: [
      { to: '/membros', label: 'Membros', end: true },
      { to: '/membros/pessoas', label: 'Pessoas' },
    ],
  },
  {
    to: '/voluntariado',
    label: 'Voluntariado',
    match: ['/voluntariado'],
    permission: 'voluntarios:view',
    subnav: [
      { to: '/voluntariado/voluntarios', label: 'Voluntários' },
      { to: '/voluntariado/lideres', label: 'Líderes' },
      { to: '/voluntariado/escalas', label: 'Escalas' },
      { to: '/voluntariado/ministerios', label: 'Ministérios' },
    ],
  },
  {
    to: '/usuarios',
    label: 'Usuários',
    match: ['/usuarios'],
    permission: 'usuarios:view',
  },
  {
    to: '/cronograma',
    label: 'Cronograma',
    match: ['/cronograma'],
    subnav: [
      { to: '/cronograma/cultos', label: 'Cultos' },
      { to: '/cronograma/eventos', label: 'Eventos' },
    ],
  },
]

export const PROFILE_TABS: SubNavItem[] = [
  { to: '/perfil', label: 'Informações', end: true },
  { to: '/perfil/disponibilidade', label: 'Disponibilidade' },
  { to: '/perfil/pausa', label: 'Pausa' },
]

export function findSection(pathname: string): MainNavItem | undefined {
  return MAIN_NAV.find((item) =>
    item.match.some((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`)),
  )
}

export function isNavActive(pathname: string, item: MainNavItem): boolean {
  return item.match.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  )
}
