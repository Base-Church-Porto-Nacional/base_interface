import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Badge,
  Button,
  EmptyState,
  ErrorState,
  ExportButtons,
  Input,
  LoadingState,
  Modal,
  PageHeader,
  Pagination,
  SearchInput,
  SuccessToast,
  Table,
} from '../../components/ui'
import { pessoaService } from '../../services/pessoaService'
import type { Pessoa, PessoaTipo } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './PessoasPage.module.css'

const FILTERS: Array<{ value: string; label: string }> = [
  { value: 'TODOS', label: 'Todos' },
  { value: 'MEMBRO', label: 'Membros' },
  { value: 'VOLUNTARIO', label: 'Voluntários' },
  { value: 'LIDER', label: 'Líderes' },
  { value: 'VISITANTE', label: 'Visitantes' },
]

export function PessoasPage() {
  const navigate = useNavigate()
  const [items, setItems] = useState<Pessoa[]>([])
  const [totalPages, setTotalPages] = useState(1)
  const [page, setPage] = useState(0)
  const [search, setSearch] = useState('')
  const [filtro, setFiltro] = useState('TODOS')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [toast, setToast] = useState<string | null>(null)
  const [form, setForm] = useState({
    nome: '',
    telefone: '',
    email: '',
  })

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const response = await pessoaService.list({
        page,
        size: 10,
        search,
        filtro,
      })
      setItems(response.content)
      setTotalPages(response.totalPages)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao listar pessoas.')
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
  }, [page, search, filtro])

  const columns = useMemo(
    () => [
      {
        key: 'nome',
        header: 'Nome',
        render: (row: Pessoa) => <strong>{row.nome}</strong>,
      },
      {
        key: 'telefone',
        header: 'Telefone',
        render: (row: Pessoa) => row.telefone,
      },
      {
        key: 'email',
        header: 'E-mail',
        render: (row: Pessoa) => row.email,
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
        key: 'tipos',
        header: 'Tipo',
        render: (row: Pessoa) => (
          <div className={styles.tags}>
            {row.tipos.map((tipo) => (
              <Badge key={tipo}>{tipo}</Badge>
            ))}
          </div>
        ),
      },
      {
        key: 'ministerios',
        header: 'Ministérios',
        render: (row: Pessoa) =>
          row.ministerios.length ? row.ministerios.join(', ') : '—',
      },
      {
        key: 'data',
        header: 'Cadastro',
        render: (row: Pessoa) => formatDate(row.dataCadastro),
      },
    ],
    [],
  )

  async function handleCreate() {
    try {
      const created = await pessoaService.create({
        ...form,
        tipos: ['VISITANTE'] as PessoaTipo[],
      })
      setModalOpen(false)
      setForm({ nome: '', telefone: '', email: '' })
      setToast('Pessoa cadastrada com sucesso.')
      setTimeout(() => setToast(null), 3000)
      navigate(`/pessoas/${created.id}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao cadastrar.')
    }
  }

  return (
    <div>
      <PageHeader
        description="Cadastro e acompanhamento de pessoas da Base Church."
        actions={
          <>
            <ExportButtons recurso="pessoas" />
            <Button onClick={() => setModalOpen(true)}>Nova pessoa</Button>
          </>
        }
      />

      {toast ? <div className={styles.toastWrap}><SuccessToast>{toast}</SuccessToast></div> : null}

      <div className={styles.toolbar}>
        <SearchInput
          placeholder="Pesquisar pessoa…"
          value={search}
          onChange={(e) => {
            setPage(0)
            setSearch(e.target.value)
          }}
        />
        <div className={styles.filters} role="tablist" aria-label="Filtros">
          {FILTERS.map((item) => (
            <button
              key={item.value}
              type="button"
              role="tab"
              aria-selected={filtro === item.value}
              className={filtro === item.value ? styles.filterActive : styles.filter}
              onClick={() => {
                setPage(0)
                setFiltro(item.value)
              }}
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState description={error} onRetry={() => void load()} />
      ) : items.length === 0 ? (
        <EmptyState
          title="Nenhuma pessoa encontrada."
          description="Ajuste a busca ou cadastre uma nova pessoa."
          actionLabel="Nova pessoa"
          onAction={() => setModalOpen(true)}
        />
      ) : (
        <>
          <Table
            columns={columns}
            data={items}
            rowKey={(row) => row.id}
            onRowClick={(row) => navigate(`/membros/pessoa/${row.id}`)}
          />
          <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        </>
      )}

      <Modal
        open={modalOpen}
        title="Nova pessoa"
        onClose={() => setModalOpen(false)}
        footer={
          <>
            <Button variant="secondary" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={() => void handleCreate()} disabled={!form.nome}>
              Cadastrar
            </Button>
          </>
        }
      >
        <div className={styles.form}>
          <Input
            label="Nome"
            value={form.nome}
            onChange={(e) => setForm((f) => ({ ...f, nome: e.target.value }))}
          />
          <Input
            label="Telefone"
            value={form.telefone}
            onChange={(e) => setForm((f) => ({ ...f, telefone: e.target.value }))}
          />
          <Input
            label="E-mail"
            type="email"
            value={form.email}
            onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
          />
        </div>
      </Modal>
    </div>
  )
}
