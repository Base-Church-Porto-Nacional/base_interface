import { useEffect, useMemo, useState } from 'react'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  SearchInput,
  Table,
} from '../../components/ui'
import { pessoaService } from '../../services/pessoaService'
import type { Pessoa } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './LideresPage.module.css'

export function LideresPage() {
  const [items, setItems] = useState<Pessoa[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const response = await pessoaService.list({
        filtro: 'LIDER',
        search,
        size: 50,
      })
      setItems(response.content)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao listar líderes.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void load()
    }, 250)
    return () => window.clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search])

  const columns = useMemo(
    () => [
      {
        key: 'nome',
        header: 'Nome',
        render: (row: Pessoa) => <strong>{row.nome}</strong>,
      },
      {
        key: 'contato',
        header: 'Contato',
        render: (row: Pessoa) => (
          <span>
            {row.telefone || '—'}
            <br />
            <span className={styles.muted}>{row.email || '—'}</span>
          </span>
        ),
      },
      {
        key: 'ministerios',
        header: 'Ministérios',
        render: (row: Pessoa) =>
          row.ministerios.length ? row.ministerios.join(', ') : '—',
      },
      {
        key: 'status',
        header: 'Status',
        render: (row: Pessoa) => (
          <Badge tone={row.status === 'ATIVO' ? 'success' : 'neutral'}>
            {row.status}
          </Badge>
        ),
      },
      {
        key: 'cadastro',
        header: 'Desde',
        render: (row: Pessoa) => formatDate(row.dataCadastro),
      },
    ],
    [],
  )

  return (
    <div>
      <div className={styles.toolbar}>
        <SearchInput
          placeholder="Pesquisar líder…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState description={error} onRetry={() => void load()} />
      ) : items.length === 0 ? (
        <EmptyState
          title="Nenhum líder encontrado."
          description="Líderes aparecerão aqui conforme os vínculos e papéis."
        />
      ) : (
        <Table columns={columns} data={items} rowKey={(row) => row.id} />
      )}
    </div>
  )
}
