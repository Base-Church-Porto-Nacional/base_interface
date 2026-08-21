import { cx } from '../../utils/format'
import styles from './Avatar.module.css'

interface AvatarProps {
  name: string
  src?: string
  size?: 'sm' | 'md'
}

function initials(name: string): string {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('')
}

export function Avatar({ name, src, size = 'md' }: AvatarProps) {
  if (src) {
    return (
      <img
        src={src}
        alt={name}
        className={cx(styles.avatar, styles[size])}
      />
    )
  }

  return (
    <span className={cx(styles.avatar, styles.fallback, styles[size])} aria-hidden>
      {initials(name)}
    </span>
  )
}
