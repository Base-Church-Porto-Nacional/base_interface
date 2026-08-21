import { useState, type FormEvent } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { Button, Input } from '../../components/ui'
import { useAuth } from '../../contexts/AuthContext'
import styles from './LoginPage.module.css'

export function LoginPage() {
  const { login, isAuthenticated, isLoading } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [username, setUsername] = useState('admin')
  const [password, setPassword] = useState('admin123')
  const [error, setError] = useState<string | null>(null)

  const from =
    (location.state as { from?: { pathname: string } } | null)?.from?.pathname ??
    '/dashboard'

  if (isAuthenticated) {
    return <Navigate to={from} replace />
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    try {
      await login({ username, password })
      navigate(from, { replace: true })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Falha ao entrar.')
    }
  }

  return (
    <div className={styles.page}>
      <div className={styles.panel}>
        <aside className={styles.brand}>
          <div className={styles.brandTop}>
            <span className={styles.mark}>B</span>
            <div>
              <strong>Base Church</strong>
              <span>Gestão</span>
            </div>
          </div>
          <div className={styles.brandCopy}>
            <h2>Operação da igreja com clareza e ordem.</h2>
            <p>
              Pessoas, ministérios, escalas e jornada em um único sistema
              institucional.
            </p>
          </div>
        </aside>

        <div className={styles.formWrap}>
          <form className={styles.form} onSubmit={(e) => void handleSubmit(e)}>
            <div className={styles.mobileBrand}>
              <span className={styles.mark}>B</span>
              <strong>Base Church</strong>
            </div>
            <h2>Entrar</h2>
            <p className={styles.subtitle}>
              Acesse com suas credenciais institucionais.
            </p>

            <Input
              label="Usuário"
              name="username"
              autoComplete="username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
            <Input
              label="Senha"
              type="password"
              name="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />

            {error ? <p className={styles.error}>{error}</p> : null}

            <Button type="submit" fullWidth disabled={isLoading}>
              {isLoading ? 'Entrando…' : 'Entrar'}
            </Button>

            <p className={styles.hint}>
              API: <code>admin</code> / <code>admin123</code>. Com mock ativo,
              qualquer senha funciona.
            </p>
          </form>
        </div>
      </div>
    </div>
  )
}
