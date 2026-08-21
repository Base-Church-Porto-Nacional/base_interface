import { NavLink } from 'react-router-dom'
import { cx } from '../../utils/format'
import { isNavActive, type MainNavItem } from '../../navigation/config'
import styles from './Sidebar.module.css'

interface SidebarProps {
  items: MainNavItem[]
  open: boolean
  onClose: () => void
  pathname: string
}

export function Sidebar({ items, open, onClose, pathname }: SidebarProps) {
  return (
    <>
      <button
        type="button"
        className={cx(styles.backdrop, open && styles.backdropOpen)}
        onClick={onClose}
        aria-label="Fechar menu"
        tabIndex={open ? 0 : -1}
      />
      <aside
        className={cx(styles.sidebar, open && styles.open)}
        aria-label="Navegação principal"
        aria-hidden={!open}
      >
        <div className={styles.brand}>
          <div className={styles.brandMain}>
            <span className={styles.mark}>B</span>
            <div>
              <strong>Base Church</strong>
              <span>Sistema de gestão</span>
            </div>
          </div>
          <button
            type="button"
            className={styles.close}
            onClick={onClose}
            aria-label="Fechar menu"
          >
            <span />
            <span />
          </button>
        </div>

        <p className={styles.section}>Navegação</p>
        <nav className={styles.nav}>
          {items.map((item, index) => {
            const active = isNavActive(pathname, item)
            const target = item.subnav?.[0]?.to ?? item.to
            return (
              <NavLink
                key={item.to}
                to={target}
                className={cx(styles.link, active && styles.active)}
                onClick={onClose}
                tabIndex={open ? 0 : -1}
              >
                <span className={styles.index}>
                  {String(index + 1).padStart(2, '0')}
                </span>
                <span>{item.label}</span>
              </NavLink>
            )
          })}
        </nav>

        <div className={styles.footer}>
          <span>BASE</span>
          <span>Institucional</span>
        </div>
      </aside>
    </>
  )
}
