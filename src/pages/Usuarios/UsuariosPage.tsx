import { useEffect, useState } from 'react'
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
  SuccessToast,
  Table,
} from '../../components/ui'
import { papelService, usuarioService } from '../../services/usuarioService'
import { pessoaService } from '../../services/pessoaService'
import type { Papel, Pessoa, Role, Usuario } from '../../types'
import { formatDateTime } from '../../utils/format'
import styles from './UsuariosPage.module.css'

const emptyForm = {
  username: '',
  senha: '',
  email: '',
  pessoaId: '',
  ativo: true,
  papelIds: [] as string[],
}

export function UsuariosPage() {
  const [items, setItems] = useState<Usuario[]>([])
  const [papeis, setPapeis] = useState<Papel[]>([])
  const [pessoas, setPessoas] = useState<Pessoa[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<Usuario | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [toast, setToast] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const [users, roles, pess] = await Promise.all([
        usuarioService.list(),
        papelService.list(),
        pessoaService.list({ size: 500 }),
      ])
      setItems(users)
      setPapeis(roles)
      setPessoas(pess.content)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao listar usuários.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  function openCreate() {
    setEditing(null)
    setForm(emptyForm)
    setModalOpen(true)
  }

  function openEdit(user: Usuario) {
    setEditing(user)
    const selectedIds = papeis
      .filter((p) => user.roles.includes(p.nome as Role))
      .map((p) => p.id)
    setForm({
      username: user.nome,
      senha: '',
      email: user.email,
      pessoaId: user.pessoaId ?? '',
      ativo: user.status === 'ATIVO',
      papelIds: selectedIds,
    })
    setModalOpen(true)
  }

  function togglePapel(papelId: string) {
    setForm((prev) => ({
      ...prev,
      papelIds: prev.papelIds.includes(papelId)
        ? prev.papelIds.filter((id) => id !== papelId)
        : [...prev.papelIds, papelId],
    }))
  }

  async function save() {
    setSaving(true)
    try {
      const papeisNomes = papeis
        .filter((p) => form.papelIds.includes(p.id))
        .map((p) => p.nome)
      const payload = {
        username: form.username,
        email: form.email || null,
        pessoaId: form.pessoaId || null,
        ativo: form.ativo,
        papelIds: form.papelIds,
        papeis: papeisNomes,
        ...(form.senha ? { senha: form.senha } : editing ? {} : { senha: form.senha }),
      }
      if (editing) {
        await usuarioService.update(editing.id, payload)
      } else {
        if (!form.senha) throw new Error('Informe a senha do usuário.')
        await usuarioService.create({ ...payload, senha: form.senha })
      }
      setModalOpen(false)
      setToast('Usuário salvo.')
      window.setTimeout(() => setToast(null), 2500)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <LoadingState />
  if (error && items.length === 0) {
    return <ErrorState description={error} onRetry={() => void load()} />
  }

  return (
    <div>
      <PageHeader
        title="Usuários"
        description="Contas de acesso e papéis (RBAC)."
        actions={
          <>
            <ExportButtons recurso="usuarios" />
            <Button onClick={openCreate}>Novo usuário</Button>
          </>
        }
      />

      {toast ? (
        <div className={styles.toast}>
          <SuccessToast>✓ {toast}</SuccessToast>
        </div>
      ) : null}
      {error ? <p className={styles.error}>{error}</p> : null}

      {items.length === 0 ? (
        <EmptyState
          title="Nenhum usuário encontrado."
          description="Crie contas e atribua papéis."
        />
      ) : (
        <Table
          columns={[
            {
              key: 'nome',
              header: 'Usuário',
              render: (row) => <strong>{row.nome}</strong>,
            },
            {
              key: 'pessoa',
              header: 'Pessoa vinculada',
              render: (row) => {
                const pessoa = pessoas.find((p) => p.id === row.pessoaId)
                return pessoa?.nome ?? row.pessoaNome
              },
            },
            {
              key: 'email',
              header: 'E-mail',
              render: (row) => row.email || '—',
            },
            {
              key: 'roles',
              header: 'Papéis',
              render: (row) => (
                <div className={styles.roles}>
                  {row.roles.map((role) => (
                    <Badge key={role}>{role}</Badge>
                  ))}
                </div>
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
              key: 'acesso',
              header: 'Último acesso',
              render: (row) =>
                row.ultimoAcesso ? formatDateTime(row.ultimoAcesso) : '—',
            },
            {
              key: 'acoes',
              header: '',
              render: (row) => (
                <Button size="sm" variant="ghost" onClick={() => openEdit(row)}>
                  Editar
                </Button>
              ),
            },
          ]}
          data={items}
          rowKey={(row) => row.id}
        />
      )}

      <Modal
        open={modalOpen}
        title={editing ? 'Editar usuário' : 'Novo usuário'}
        onClose={() => setModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button disabled={saving || !form.username} onClick={() => void save()}>
              {saving ? 'Salvando…' : 'Salvar'}
            </Button>
          </>
        }
      >
        <div className={styles.form}>
          <Input
            label="Username"
            value={form.username}
            onChange={(e) => setForm({ ...form, username: e.target.value })}
          />
          <Input
            label={editing ? 'Nova senha (opcional)' : 'Senha'}
            type="password"
            value={form.senha}
            onChange={(e) => setForm({ ...form, senha: e.target.value })}
          />
          <Input
            label="E-mail"
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
          />
          <label className={styles.field}>
            <span>Pessoa vinculada</span>
            <select
              value={form.pessoaId}
              onChange={(e) => setForm({ ...form, pessoaId: e.target.value })}
            >
              <option value="">Nenhuma</option>
              {pessoas.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.nome}
                </option>
              ))}
            </select>
          </label>
          <fieldset className={styles.papeis}>
            <legend>Papéis</legend>
            {papeis.map((papel) => (
              <label key={papel.id} className={styles.check}>
                <input
                  type="checkbox"
                  checked={form.papelIds.includes(papel.id)}
                  onChange={() => togglePapel(papel.id)}
                />
                {papel.nome}
                {papel.descricao ? (
                  <span className={styles.hint}> — {papel.descricao}</span>
                ) : null}
              </label>
            ))}
          </fieldset>
          <label className={styles.check}>
            <input
              type="checkbox"
              checked={form.ativo}
              onChange={(e) => setForm({ ...form, ativo: e.target.checked })}
            />
            Ativo
          </label>
        </div>
      </Modal>
    </div>
  )
}
