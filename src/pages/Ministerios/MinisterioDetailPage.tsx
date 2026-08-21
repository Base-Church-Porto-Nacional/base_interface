import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  Badge,
  ErrorState,
  LoadingState,
  PageHeader,
} from '../../components/ui'
import { ministerioService } from '../../services/ministerioService'
import type { Ministerio, Servico } from '../../types'
import styles from './MinisterioDetailPage.module.css'

export function MinisterioDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [ministerio, setMinisterio] = useState<Ministerio | null>(null)
  const [servicos, setServicos] = useState<Servico[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function load() {
    if (!id) return
    setLoading(true)
    setError(null)
    try {
      const [m, s] = await Promise.all([
        ministerioService.getById(id),
        ministerioService.listServicos(id),
      ])
      setMinisterio(m)
      setServicos(s)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar ministério.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  if (loading) return <LoadingState />
  if (error || !ministerio) {
    return <ErrorState description={error ?? undefined} onRetry={() => void load()} />
  }

  return (
    <div>
      <PageHeader
        title={ministerio.nome}
        description="Detalhes do ministério, líder e serviços."
        actions={
          <Link to="/voluntariado/ministerios" className={styles.back}>
            Voltar
          </Link>
        }
      />

      <section className={styles.summary}>
        <div>
          <span>Líder</span>
          <strong>{ministerio.liderNome}</strong>
        </div>
        <div>
          <span>Voluntários</span>
          <strong>{ministerio.totalVoluntarios}</strong>
        </div>
        <div>
          <span>Serviços</span>
          <strong>{ministerio.totalServicos}</strong>
        </div>
      </section>

      <section className={styles.block}>
        <h2>Serviços</h2>
        {servicos.length === 0 ? (
          <p className={styles.muted}>Nenhum serviço cadastrado.</p>
        ) : (
          <ul className={styles.servicos}>
            {servicos.map((servico) => (
              <li key={servico.id}>
                <div>
                  <strong>{servico.nome}</strong>
                  <p>{servico.totalVoluntarios} voluntários</p>
                </div>
                <Badge tone={servico.ativo ? 'success' : 'neutral'}>
                  {servico.ativo ? 'Ativo' : 'Inativo'}
                </Badge>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  )
}
