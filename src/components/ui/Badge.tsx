import type { ReactNode } from 'react'
import { cx } from '../../utils/format'
import styles from './Badge.module.css'

type Tone = 'neutral' | 'success' | 'warning' | 'danger' | 'info'

interface BadgeProps {
  children: ReactNode
  tone?: Tone
  className?: string
}

export function Badge({ children, tone = 'neutral', className }: BadgeProps) {
  return (
    <span className={cx(styles.badge, styles[tone], className)}>{children}</span>
  )
}
