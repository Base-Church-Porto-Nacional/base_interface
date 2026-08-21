import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  Badge,
  Button,
  EmptyState,
  ErrorState,
  ExportButtons,
  LoadingState,
  PageHeader,
} from '../../components/ui'
import { escalaService } from '../../services/escalaService'
import type { Escala } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './EscalasPage.module.css'

function statusTone(status: Escala['status']) {
  if (status === 'PUBLICADA') return 'success' as const
  if (status === 'RASCUNHO') return 'warning' as const
  return 'neutral' as const
}

export function EscalasPage() {
  const navigate = useNavigate()
  const [items, setItems] = useState<Escala[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      setItems(await escalaService.list())
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao listar escalas.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  if (loading) return <LoadingState />
  if (error) return <ErrorState description={error} onRetry={() => void load()} />

  return (
    <div>
      <PageHeader description="Planejamento e acompanhamento de escalas de serviço." actions={
          <>
            <ExportButtons recurso="escalas" />
            <Button onClick={() => navigate('/escalas/nova')}>Nova escala</Button>
          </>
        }
      />

      {items.length === 0 ? (
        <EmptyState
          title="Nenhuma escala encontrada."
          description="Crie uma nova escala para começar."
          actionLabel="Nova escala"
          onAction={() => navigate('/voluntariado/escalas/nova')}
        />
      ) : (
        <div className={styles.list}>
          {items.map((escala) => (
            <Link key={escala.id} to={`/voluntariado/escalas/${escala.id}`} className={styles.item}>
              <div>
                <h2>{escala.nome}</h2>
                <p>
                  {formatDate(escala.data)} · {escala.horario}
                </p>
              </div>
              <div className={styles.meta}>
                <span>
                  {escala.confirmados} confirmados · {escala.pendentes} pendentes
                </span>
                <Badge tone={statusTone(escala.status)}>{escala.status}</Badge>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
