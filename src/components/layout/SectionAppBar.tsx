import { NavLink } from 'react-router-dom'
import { cx } from '../../utils/format'
import type { SubNavItem } from '../../navigation/config'
import styles from './SectionAppBar.module.css'

interface SectionAppBarProps {
  title: string
  items?: SubNavItem[]
}

export function SectionAppBar({ title, items = [] }: SectionAppBarProps) {
  if (items.length === 0) {
    return (
      <div className={styles.bar}>
        <h1 className={styles.title}>{title}</h1>
      </div>
    )
  }

  return (
    <div className={styles.bar}>
      <div className={styles.top}>
        <h1 className={styles.title}>{title}</h1>
      </div>
      <nav className={styles.tabs} aria-label={`Subnavegação de ${title}`}>
        {items.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.end}
            className={({ isActive }) => cx(styles.tab, isActive && styles.tabActive)}
          >
            {item.label}
          </NavLink>
        ))}
      </nav>
    </div>
  )
}
