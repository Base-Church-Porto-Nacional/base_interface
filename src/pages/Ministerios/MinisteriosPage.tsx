import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  EmptyState,
  ErrorState,
  ExportButtons,
  LoadingState,
  PageHeader,
} from '../../components/ui'
import { ministerioService } from '../../services/ministerioService'
import type { Ministerio } from '../../types'
import styles from './MinisteriosPage.module.css'

export function MinisteriosPage() {
  const navigate = useNavigate()
  const [items, setItems] = useState<Ministerio[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      setItems(await ministerioService.list())
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao listar ministérios.')
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
      <PageHeader
        description="Estrutura de ministérios e serviços da igreja."
        actions={<ExportButtons recurso="ministerios" />}
      />

      {items.length === 0 ? (
        <EmptyState
          title="Nenhum ministério cadastrado."
          description="Cadastre ministérios pelo backend para começar."
        />
      ) : (
        <div className={styles.list}>
          <div className={styles.head}>
            <span>Ministério</span>
            <span>Líder</span>
            <span>Voluntários</span>
            <span>Serviços</span>
          </div>
          {items.map((item) => (
            <button
              key={item.id}
              type="button"
              className={styles.row}
              onClick={() => navigate(`/voluntariado/ministerios/${item.id}`)}
            >
              <strong>{item.nome}</strong>
              <span>{item.liderNome}</span>
              <span>{item.totalVoluntarios}</span>
              <span>{item.totalServicos}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
