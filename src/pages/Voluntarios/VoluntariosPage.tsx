import { useEffect, useMemo, useState } from 'react'
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
  Select,
  SuccessToast,
  Table,
} from '../../components/ui'
import { ministerioService } from '../../services/ministerioService'
import { pessoaService } from '../../services/pessoaService'
import { voluntarioService } from '../../services/voluntarioService'
import type { Ministerio, Pessoa, Servico, Voluntario } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './VoluntariosPage.module.css'

const emptyForm = {
  pessoaId: '',
  ministerioId: '',
  servicoId: '',
  cargo: '',
  dataEntrada: new Date().toISOString().slice(0, 10),
  ativo: true,
  observacoes: '',
  liderResponsavelId: '',
}

export function VoluntariosPage() {
  const [items, setItems] = useState<Voluntario[]>([])
  const [pessoas, setPessoas] = useState<Pessoa[]>([])
  const [ministerios, setMinisterios] = useState<Ministerio[]>([])
  const [servicos, setServicos] = useState<Servico[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<Voluntario | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [toast, setToast] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const [vols, pess, mins] = await Promise.all([
        voluntarioService.list(),
        pessoaService.list({ size: 500 }),
        ministerioService.list(),
      ])
      setItems(vols)
      setPessoas(pess.content)
      setMinisterios(mins)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao listar voluntários.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  useEffect(() => {
    if (!form.ministerioId) {
      setServicos([])
      return
    }
    void ministerioService.listServicos(form.ministerioId).then(setServicos)
  }, [form.ministerioId])

  const liderOptions = useMemo(
    () => [
      { value: '', label: 'Sem líder' },
      ...pessoas.map((p) => ({ value: p.id, label: p.nome })),
    ],
    [pessoas],
  )

  function openCreate() {
    setEditing(null)
    setForm(emptyForm)
    setModalOpen(true)
  }

  function openEdit(item: Voluntario) {
    setEditing(item)
    setForm({
      pessoaId: item.pessoaId,
      ministerioId: item.ministerioId,
      servicoId: item.servicoId,
      cargo: item.cargo ?? '',
      dataEntrada: item.dataEntrada ?? '',
      ativo: item.ativo,
      observacoes: item.observacoes ?? '',
      liderResponsavelId: item.liderResponsavelId ?? '',
    })
    setModalOpen(true)
  }

  async function save() {
    setSaving(true)
    try {
      const payload = {
        pessoaId: form.pessoaId,
        servicoId: form.servicoId,
        cargo: form.cargo || null,
        dataEntrada: form.dataEntrada || null,
        ativo: form.ativo,
        observacoes: form.observacoes || null,
        liderResponsavelId: form.liderResponsavelId || null,
      }
      if (editing) {
        await voluntarioService.update(editing.id, payload)
      } else {
        await voluntarioService.create(payload)
      }
      setModalOpen(false)
      setToast('Vínculo salvo.')
      window.setTimeout(() => setToast(null), 2500)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar.')
    } finally {
      setSaving(false)
    }
  }

  async function remove(id: string) {
    await voluntarioService.remove(id)
    setToast('Vínculo removido.')
    window.setTimeout(() => setToast(null), 2500)
    await load()
  }

  if (loading) return <LoadingState />
  if (error && items.length === 0) {
    return <ErrorState description={error} onRetry={() => void load()} />
  }

  return (
    <div>
      <PageHeader
        description="Vínculos pessoa ↔ serviço (cargo, entrada, líder)."
        actions={
          <>
            <ExportButtons recurso="voluntarios" />
            <Button onClick={openCreate}>Novo vínculo</Button>
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
          title="Nenhum voluntário encontrado."
          description="Crie um vínculo entre pessoa e serviço."
        />
      ) : (
        <Table
          columns={[
            {
              key: 'pessoa',
              header: 'Pessoa',
              render: (row) => <strong>{row.pessoaNome}</strong>,
            },
            {
              key: 'ministerio',
              header: 'Ministério',
              render: (row) => row.ministerioNome,
            },
            {
              key: 'servico',
              header: 'Serviço',
              render: (row) => row.servicoNome,
            },
            {
              key: 'cargo',
              header: 'Cargo',
              render: (row) => row.cargo ?? '—',
            },
            {
              key: 'entrada',
              header: 'Entrada',
              render: (row) =>
                row.dataEntrada ? formatDate(row.dataEntrada) : '—',
            },
            {
              key: 'ativo',
              header: 'Status',
              render: (row) => (
                <Badge tone={row.ativo ? 'success' : 'neutral'}>
                  {row.ativo ? 'ATIVO' : 'INATIVO'}
                </Badge>
              ),
            },
            {
              key: 'acoes',
              header: '',
              render: (row) => (
                <div className={styles.actions}>
                  <Button size="sm" variant="ghost" onClick={() => openEdit(row)}>
                    Editar
                  </Button>
                  <Button
                    size="sm"
                    variant="danger"
                    onClick={() => void remove(row.id)}
                  >
                    Remover
                  </Button>
                </div>
              ),
            },
          ]}
          data={items}
          rowKey={(row) => row.id}
        />
      )}

      <Modal
        open={modalOpen}
        title={editing ? 'Editar vínculo' : 'Novo vínculo'}
        onClose={() => setModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button
              disabled={saving || !form.pessoaId || !form.servicoId}
              onClick={() => void save()}
            >
              {saving ? 'Salvando…' : 'Salvar'}
            </Button>
          </>
        }
      >
        <div className={styles.form}>
          <Select
            label="Pessoa"
            value={form.pessoaId}
            onChange={(e) => setForm({ ...form, pessoaId: e.target.value })}
            options={[
              { value: '', label: 'Selecione' },
              ...pessoas.map((p) => ({ value: p.id, label: p.nome })),
            ]}
          />
          <Select
            label="Ministério"
            value={form.ministerioId}
            onChange={(e) =>
              setForm({
                ...form,
                ministerioId: e.target.value,
                servicoId: '',
              })
            }
            options={[
              { value: '', label: 'Selecione' },
              ...ministerios.map((m) => ({ value: m.id, label: m.nome })),
            ]}
          />
          <Select
            label="Serviço"
            value={form.servicoId}
            onChange={(e) => setForm({ ...form, servicoId: e.target.value })}
            options={[
              { value: '', label: 'Selecione' },
              ...servicos.map((s) => ({ value: s.id, label: s.nome })),
            ]}
          />
          <Input
            label="Cargo"
            placeholder="Líder / Auxiliar…"
            value={form.cargo}
            onChange={(e) => setForm({ ...form, cargo: e.target.value })}
          />
          <Input
            label="Data de entrada"
            type="date"
            value={form.dataEntrada}
            onChange={(e) => setForm({ ...form, dataEntrada: e.target.value })}
          />
          <Select
            label="Líder responsável"
            value={form.liderResponsavelId}
            onChange={(e) =>
              setForm({ ...form, liderResponsavelId: e.target.value })
            }
            options={liderOptions}
          />
          <Input
            label="Observações"
            value={form.observacoes}
            onChange={(e) => setForm({ ...form, observacoes: e.target.value })}
          />
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
