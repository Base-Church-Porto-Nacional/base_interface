import type { ReactNode } from 'react'
import styles from './PageHeader.module.css'

interface PageHeaderProps {
  title?: string
  description?: string
  actions?: ReactNode
}

export function PageHeader({ title, description, actions }: PageHeaderProps) {
  if (!title && !description && !actions) return null

  return (
    <header className={styles.header}>
      {(title || description) ? (
        <div>
          {title ? <h1>{title}</h1> : null}
          {description ? <p>{description}</p> : null}
        </div>
      ) : (
        <div />
      )}
      {actions ? <div className={styles.actions}>{actions}</div> : null}
    </header>
  )
}
