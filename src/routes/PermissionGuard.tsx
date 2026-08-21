import type { ReactNode } from 'react'
import { useAuth } from '../contexts/AuthContext'
import styles from './PermissionGuard.module.css'

interface PermissionGuardProps {
  permission: string
  children: ReactNode
  fallback?: ReactNode
}

export function PermissionGuard({
  permission,
  children,
  fallback,
}: PermissionGuardProps) {
  const { can } = useAuth()

  if (!can(permission)) {
    return (
      fallback ?? (
        <div className={styles.denied}>
          <h2>Acesso restrito</h2>
          <p>Você não tem permissão para visualizar este conteúdo.</p>
        </div>
      )
    )
  }

  return children
}
