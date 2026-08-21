import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  Badge,
  Button,
  ErrorState,
  Input,
  LoadingState,
  Modal,
  PageHeader,
  SuccessToast,
} from '../../components/ui'
import { useAuth } from '../../contexts/AuthContext'
import { pessoaService } from '../../services/pessoaService'
import type { ApiJornada } from '../../types/api'
import type { Pessoa, PessoaHistorico } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './PessoaDetailPage.module.css'

type Tab = 'perfil' | 'jornada' | 'historico'

const emptyHistorico = {
  descricao: '',
  autorNome: '',
  autorCargo: '',
  dataRegistro: new Date().toISOString().slice(0, 10),
}

export function PessoaDetailPage() {
  const { id } = useParams<{ id: string }>()
  const { user } = useAuth()
  const [tab, setTab] = useState<Tab>('perfil')
  const [pessoa, setPessoa] = useState<Pessoa | null>(null)
  const [jornada, setJornada] = useState<ApiJornada | null>(null)
  const [historico, setHistorico] = useState<PessoaHistorico[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editingHistorico, setEditingHistorico] = useState<PessoaHistorico | null>(
    null,
  )
  const [formHistorico, setFormHistorico] = useState(emptyHistorico)

  async function load() {
    if (!id) return
    setLoading(true)
    setError(null)
    try {
      const [p, j, h] = await Promise.all([
        pessoaService.getById(id),
        pessoaService.getJornada(id).catch(() => null),
        pessoaService.listHistorico(id).catch(() => []),
      ])
      setPessoa(p)
      setJornada(j)
      setHistorico(h)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar pessoa.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  function showToast(message: string) {
    setToast(message)
    window.setTimeout(() => setToast(null), 2500)
  }

  async function handleDeactivate() {
    if (!id || !pessoa) return
    await pessoaService.deactivate(id)
    showToast('Pessoa desativada.')
    await load()
  }

  async function saveJornada() {
    if (!id || !jornada) return
    setSaving(true)
    try {
      const updated = await pessoaService.updateJornada(id, {
        aceitouJesus: jornada.aceitouJesus,
        dataAceitouJesus: jornada.dataAceitouJesus,
        batizado: jornada.batizado,
        dataBatismo: jornada.dataBatismo,
        concluiuTrilhaBase: jornada.concluiuTrilhaBase,
        dataConclusaoTrilhaBase: jornada.dataConclusaoTrilhaBase,
        membro: jornada.membro,
        dataMembro: jornada.dataMembro,
      })
      setJornada(updated)
      showToast('Jornada atualizada.')
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar jornada.')
    } finally {
      setSaving(false)
    }
  }

  function openHistorico(item?: PessoaHistorico) {
    if (item) {
      setEditingHistorico(item)
      setFormHistorico({
        descricao: item.descricao,
        autorNome: item.autorNome,
        autorCargo: item.autorCargo ?? '',
        dataRegistro: item.dataRegistro,
      })
    } else {
      setEditingHistorico(null)
      setFormHistorico({
        ...emptyHistorico,
        autorNome: user?.nome ?? '',
      })
    }
    setModalOpen(true)
  }

  async function saveHistorico() {
    if (!id) return
    setSaving(true)
    try {
      const payload = {
        descricao: formHistorico.descricao,
        autorNome: formHistorico.autorNome,
        autorCargo: formHistorico.autorCargo || null,
        dataRegistro: formHistorico.dataRegistro,
      }
      if (editingHistorico) {
        await pessoaService.updateHistorico(id, editingHistorico.id, payload)
      } else {
        await pessoaService.createHistorico(id, payload)
      }
      setModalOpen(false)
      showToast('Histórico salvo.')
      setHistorico(await pessoaService.listHistorico(id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar histórico.')
    } finally {
      setSaving(false)
    }
  }

  async function removeHistorico(historicoId: string) {
    if (!id) return
    await pessoaService.deleteHistorico(id, historicoId)
    showToast('Registro removido.')
    setHistorico(await pessoaService.listHistorico(id))
  }

  if (loading) return <LoadingState />
  if (error && !pessoa) {
    return <ErrorState description={error} onRetry={() => void load()} />
  }
  if (!pessoa) return null

  const timeline = pessoa.jornada ?? []

  return (
    <div>
      <PageHeader
        title={pessoa.nome}
        description="Perfil, jornada e histórico pastoral."
        actions={
          <>
            <Link to="/pessoas" className={styles.backLink}>
              Voltar
            </Link>
            {pessoa.status === 'ATIVO' ? (
              <Button variant="danger" onClick={() => void handleDeactivate()}>
                Desativar
              </Button>
            ) : null}
          </>
        }
      />

      {toast ? (
        <div className={styles.toast}>
          <SuccessToast>✓ {toast}</SuccessToast>
        </div>
      ) : null}
      {error ? <p className={styles.errorMsg}>{error}</p> : null}

      <div className={styles.types}>
        {pessoa.tipos.map((tipo) => (
          <Badge key={tipo}>{tipo}</Badge>
        ))}
        <Badge tone={pessoa.status === 'ATIVO' ? 'success' : 'neutral'}>
          {pessoa.status}
        </Badge>
      </div>

      <div className={styles.tabs} role="tablist">
        {(
          [
            ['perfil', 'Perfil'],
            ['jornada', 'Jornada'],
            ['historico', 'Histórico'],
          ] as const
        ).map(([key, label]) => (
          <button
            key={key}
            type="button"
            role="tab"
            aria-selected={tab === key}
            className={tab === key ? styles.tabActive : styles.tab}
            onClick={() => setTab(key)}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'perfil' ? (
        <div className={styles.sections}>
          <section className={styles.section}>
            <h2>Informações pessoais</h2>
            <dl className={styles.dl}>
              <div>
                <dt>Telefone</dt>
                <dd>{pessoa.telefone || '—'}</dd>
              </div>
              <div>
                <dt>E-mail</dt>
                <dd>{pessoa.email || '—'}</dd>
              </div>
              <div>
                <dt>Nascimento</dt>
                <dd>
                  {pessoa.nascimento ? formatDate(pessoa.nascimento) : '—'}
                </dd>
              </div>
              <div>
                <dt>Cadastro</dt>
                <dd>{formatDate(pessoa.dataCadastro)}</dd>
              </div>
            </dl>
          </section>

          <section className={styles.section}>
            <h2>Ministérios</h2>
            {pessoa.ministerios.length === 0 ? (
              <p className={styles.muted}>Sem ministérios vinculados.</p>
            ) : (
              <ul className={styles.list}>
                {pessoa.ministerios.map((nome) => (
                  <li key={nome}>{nome}</li>
                ))}
              </ul>
            )}
          </section>
        </div>
      ) : null}

      {tab === 'jornada' ? (
        <div className={styles.sections}>
          <section className={styles.section}>
            <h2>Timeline</h2>
            {timeline.length === 0 ? (
              <p className={styles.muted}>Nenhuma etapa registrada.</p>
            ) : (
              <ol className={styles.timeline}>
                {timeline.map((etapa) => (
                  <li key={etapa.id} data-status={etapa.status}>
                    <span className={styles.dot} aria-hidden />
                    <div>
                      <strong>{etapa.titulo}</strong>
                      <p>
                        {etapa.status === 'CONCLUIDO' && '✓ '}
                        {etapa.status === 'ATUAL' && '● '}
                        {etapa.status === 'PENDENTE' && '○ '}
                        {etapa.data ? formatDate(etapa.data) : 'Sem data'}
                      </p>
                      {etapa.observacoes ? (
                        <p className={styles.muted}>{etapa.observacoes}</p>
                      ) : null}
                    </div>
                  </li>
                ))}
              </ol>
            )}
          </section>

          {jornada ? (
            <section className={styles.section}>
              <h2>Atualizar marcos</h2>
              <div className={styles.formGrid}>
                {(
                  [
                    ['aceitouJesus', 'dataAceitouJesus', 'Aceitou Jesus'],
                    ['batizado', 'dataBatismo', 'Batizado'],
                    [
                      'concluiuTrilhaBase',
                      'dataConclusaoTrilhaBase',
                      'Trilha da Base',
                    ],
                    ['membro', 'dataMembro', 'Membro'],
                  ] as const
                ).map(([flag, dateKey, label]) => (
                  <label key={flag} className={styles.checkRow}>
                    <input
                      type="checkbox"
                      checked={Boolean(jornada[flag])}
                      onChange={(e) =>
                        setJornada({
                          ...jornada,
                          [flag]: e.target.checked,
                          [dateKey]: e.target.checked
                            ? jornada[dateKey] ??
                              new Date().toISOString().slice(0, 10)
                            : null,
                        })
                      }
                    />
                    <span>{label}</span>
                    <input
                      type="date"
                      value={jornada[dateKey] ?? ''}
                      disabled={!jornada[flag]}
                      onChange={(e) =>
                        setJornada({
                          ...jornada,
                          [dateKey]: e.target.value || null,
                        })
                      }
                    />
                  </label>
                ))}
              </div>
              <Button disabled={saving} onClick={() => void saveJornada()}>
                {saving ? 'Salvando…' : 'Salvar jornada'}
              </Button>
            </section>
          ) : (
            <p className={styles.muted}>Jornada ainda não iniciada na API.</p>
          )}
        </div>
      ) : null}

      {tab === 'historico' ? (
        <section className={styles.section}>
          <div className={styles.sectionHead}>
            <h2>Histórico</h2>
            <Button size="sm" onClick={() => openHistorico()}>
              Novo registro
            </Button>
          </div>
          {historico.length === 0 ? (
            <p className={styles.muted}>Nenhum registro de histórico.</p>
          ) : (
            <ul className={styles.historicoList}>
              {historico.map((item) => (
                <li key={item.id}>
                  <div>
                    <strong>{formatDate(item.dataRegistro)}</strong>
                    <p>{item.descricao}</p>
                    <span className={styles.muted}>
                      {item.autorNome}
                      {item.autorCargo ? ` · ${item.autorCargo}` : ''}
                    </span>
                  </div>
                  <div className={styles.rowActions}>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => openHistorico(item)}
                    >
                      Editar
                    </Button>
                    <Button
                      size="sm"
                      variant="danger"
                      onClick={() => void removeHistorico(item.id)}
                    >
                      Excluir
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      ) : null}

      <Modal
        open={modalOpen}
        title={editingHistorico ? 'Editar histórico' : 'Novo histórico'}
        onClose={() => setModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button disabled={saving} onClick={() => void saveHistorico()}>
              {saving ? 'Salvando…' : 'Salvar'}
            </Button>
          </>
        }
      >
        <div className={styles.formGrid}>
          <Input
            label="Descrição"
            value={formHistorico.descricao}
            onChange={(e) =>
              setFormHistorico({ ...formHistorico, descricao: e.target.value })
            }
          />
          <Input
            label="Autor"
            value={formHistorico.autorNome}
            onChange={(e) =>
              setFormHistorico({ ...formHistorico, autorNome: e.target.value })
            }
          />
          <Input
            label="Cargo"
            value={formHistorico.autorCargo}
            onChange={(e) =>
              setFormHistorico({ ...formHistorico, autorCargo: e.target.value })
            }
          />
          <Input
            label="Data"
            type="date"
            value={formHistorico.dataRegistro}
            onChange={(e) =>
              setFormHistorico({
                ...formHistorico,
                dataRegistro: e.target.value,
              })
            }
          />
        </div>
      </Modal>
    </div>
  )
}
