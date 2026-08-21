import { Link } from 'react-router-dom'
import { Avatar, Button } from '../ui'
import { useAuth } from '../../contexts/AuthContext'
import styles from './Header.module.css'

interface HeaderProps {
  menuOpen: boolean
  onMenuClick: () => void
}

export function Header({ menuOpen, onMenuClick }: HeaderProps) {
  const { user, logout } = useAuth()

  return (
    <header className={styles.header}>
      <div className={styles.left}>
        <button
          type="button"
          className={styles.menu}
          onClick={onMenuClick}
          aria-label={menuOpen ? 'Fechar menu' : 'Abrir menu'}
          aria-expanded={menuOpen}
        >
          <span />
          <span />
          <span />
        </button>
        <div className={styles.brand}>
          <span className={styles.mark}>B</span>
          <div className={styles.brandText}>
            <strong>Base Church</strong>
            <span>Gestão</span>
          </div>
        </div>
      </div>
      <div className={styles.right}>
        {user ? (
          <>
            <Link to="/perfil" className={styles.user} title="Meu perfil">
              <Avatar name={user.nome} size="sm" />
              <div className={styles.meta}>
                <strong>{user.nome}</strong>
                <span>Perfil</span>
              </div>
            </Link>
            <Button variant="ghost" size="sm" onClick={() => void logout()}>
              Sair
            </Button>
          </>
        ) : null}
      </div>
    </header>
  )
}
