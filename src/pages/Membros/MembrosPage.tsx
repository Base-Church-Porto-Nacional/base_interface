import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Badge,
  EmptyState,
  ErrorState,
  LoadingState,
  PageHeader,
  SearchInput,
  Table,
} from '../../components/ui'
import { pessoaService } from '../../services/pessoaService'
import type { Pessoa } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './MembrosPage.module.css'

export function MembrosPage() {
  const navigate = useNavigate()
  const [items, setItems] = useState<Pessoa[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const response = await pessoaService.list({
        filtro: 'MEMBRO',
        search,
        size: 50,
      })
      setItems(response.content)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao listar membros.')
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

  return (
    <div>
      <PageHeader description="Pessoas com vínculo de membro na Base Church." />

      <div className={styles.toolbar}>
        <SearchInput
          placeholder="Pesquisar membro…"
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
          title="Nenhum membro encontrado."
          description="Ajuste a busca ou revise os cadastros em Pessoas."
        />
      ) : (
        <Table
          columns={[
            {
              key: 'nome',
              header: 'Nome',
              render: (row) => <strong>{row.nome}</strong>,
            },
            {
              key: 'contato',
              header: 'Contato',
              render: (row) => (
                <span>
                  {row.telefone}
                  <br />
                  <span className={styles.muted}>{row.email}</span>
                </span>
              ),
            },
            {
              key: 'status',
              header: 'Status',
              render: (row) => (
                <Badge tone={row.status === 'ATIVO' ? 'success' : 'neutral'}>
                  {row.status}
                </Badge>
              ),
            },
            {
              key: 'ministerios',
              header: 'Ministérios',
              render: (row) =>
                row.ministerios.length ? row.ministerios.join(', ') : '—',
            },
            {
              key: 'cadastro',
              header: 'Membro desde',
              render: (row) => formatDate(row.dataCadastro),
            },
          ]}
          data={items}
          rowKey={(row) => row.id}
          onRowClick={(row) => navigate(`/membros/pessoa/${row.id}`)}
        />
      )}
    </div>
  )
}
