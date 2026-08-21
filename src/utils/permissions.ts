import type { Role } from '../types'

const ROLE_PERMISSIONS: Record<Role, string[]> = {
  ADMIN: ['*'],
  PASTOR: [
    'dashboard:view',
    'pessoas:*',
    'membros:*',
    'ministerios:*',
    'voluntarios:*',
    'escalas:*',
    'disponibilidade:view',
    'usuarios:view',
  ],
  LIDER: [
    'dashboard:view',
    'pessoas:view',
    'ministerios:view',
    'ministerios:manage_own',
    'voluntarios:view',
    'escalas:view',
    'escalas:manage_own',
    'disponibilidade:view',
  ],
  VOLUNTARIO: [
    'dashboard:view',
    'escalas:own',
    'disponibilidade:*',
    'pessoas:own',
  ],
  MEMBRO: ['dashboard:view', 'pessoas:own'],
}

export function hasPermission(
  roles: Role[] | undefined,
  permission: string,
): boolean {
  if (!roles?.length) return false
  return roles.some((role) => {
    const allowed = ROLE_PERMISSIONS[role] ?? []
    if (allowed.includes('*')) return true
    if (allowed.includes(permission)) return true
    const [resource] = permission.split(':')
    return allowed.includes(`${resource}:*`)
  })
}
