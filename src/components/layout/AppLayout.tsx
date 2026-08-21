import { useEffect, useMemo, useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../../contexts/AuthContext'
import { MAIN_NAV } from '../../navigation/config'
import { Header } from './Header'
import { SectionChrome } from './SectionChrome'
import { Sidebar } from './Sidebar'
import styles from './AppLayout.module.css'

export function AppLayout() {
  const { can, hasRole } = useAuth()
  const { pathname } = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  useEffect(() => {
    document.body.style.overflow = sidebarOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [sidebarOpen])

  useEffect(() => {
    if (!sidebarOpen) return
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setSidebarOpen(false)
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [sidebarOpen])

  const items = useMemo(() => {
    return MAIN_NAV.filter((item) => {
      if (!item.permission) return true
      if (can(item.permission)) return true
      if (item.to === '/voluntariado' && (can('escalas:view') || can('escalas:own') || can('ministerios:view'))) {
        return true
      }
      if (item.to === '/membros' && (hasRole('ADMIN', 'PASTOR') || can('pessoas:view') || can('pessoas:*'))) {
        return true
      }
      return false
    })
  }, [can, hasRole])

  return (
    <div className={styles.shell}>
      <Sidebar
        items={items}
        open={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
        pathname={pathname}
      />
      <div className={styles.main}>
        <Header
          menuOpen={sidebarOpen}
          onMenuClick={() => setSidebarOpen((open) => !open)}
        />
        <main className={styles.content}>
          <SectionChrome />
          <Outlet />
        </main>
      </div>
    </div>
  )
}
