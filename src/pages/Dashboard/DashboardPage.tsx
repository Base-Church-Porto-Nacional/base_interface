import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  ErrorState,
  LoadingState,
  PageHeader,
} from '../../components/ui'
import { dashboardService } from '../../services/dashboardService'
import type { DashboardStats } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './DashboardPage.module.css'

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      setStats(await dashboardService.getStats())
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar dashboard.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  if (loading) return <LoadingState />
  if (error || !stats) {
    return <ErrorState description={error ?? undefined} onRetry={() => void load()} />
  }

  const indicators = [
    { label: 'Pessoas', value: stats.totalPessoas },
    { label: 'Membros', value: stats.totalMembros },
    { label: 'Voluntários', value: stats.totalVoluntarios },
    { label: 'Líderes', value: stats.totalLideres },
  ]

  const jornada = [
    { label: 'Novos visitantes', value: stats.jornada.novosVisitantes },
    { label: 'Aceitaram Jesus', value: stats.jornada.aceitaramJesus },
    { label: 'Batizados', value: stats.jornada.batizados },
    { label: 'Trilha da Base', value: stats.jornada.trilhaBase },
    { label: 'Novos membros', value: stats.jornada.novosMembros },
  ]

  return (
    <div>
      <PageHeader
        title="Dashboard"
        description="Visão operacional para líderes, pastores e administradores."
      />

      <section className={styles.hero} aria-label="Indicadores">
        <div className={styles.heroTop}>
          <p>Resumo institucional</p>
          <span>
            {stats.escalasPendentes} pendências · {stats.visitantesRecentes}{' '}
            visitantes recentes
          </span>
        </div>
        <div className={styles.metrics}>
          {indicators.map((item) => (
            <div key={item.label} className={styles.metric}>
              <span>{item.label}</span>
              <strong>{item.value}</strong>
            </div>
          ))}
        </div>
      </section>

      <div className={styles.grid}>
        <section className={styles.panel}>
          <div className={styles.panelHeader}>
            <h2>Próximas escalas</h2>
            <Link to="/voluntariado/escalas">Ver todas</Link>
          </div>
          {stats.proximasEscalas.length === 0 ? (
            <p className={styles.empty}>Nenhuma escala próxima.</p>
          ) : (
            <div className={styles.tableLike}>
              <div className={styles.rowHead}>
                <span>Data</span>
                <span>Horário</span>
                <span>Ministério</span>
                <span>Voluntários</span>
                <span>Confirmados</span>
                <span>Pendentes</span>
              </div>
              {stats.proximasEscalas.map((escala) => (
                <Link
                  key={`${escala.id}-${escala.ministerio}`}
                  to={`/voluntariado/escalas/${escala.id}`}
                  className={styles.row}
                >
                  <span>{formatDate(escala.data)}</span>
                  <span>{escala.horario}</span>
                  <span>{escala.ministerio}</span>
                  <span>{escala.totalVoluntarios}</span>
                  <span className={styles.ok}>{escala.confirmados}</span>
                  <span className={styles.warn}>{escala.pendentes}</span>
                </Link>
              ))}
            </div>
          )}
        </section>

        <section className={styles.panel}>
          <div className={styles.panelHeader}>
            <h2>Jornada</h2>
          </div>
          <ul className={styles.jornada}>
            {jornada.map((item) => (
              <li key={item.label}>
                <span>{item.label}</span>
                <strong>{item.value}</strong>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  )
}
