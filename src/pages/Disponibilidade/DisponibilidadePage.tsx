import { useEffect, useState } from 'react'
import {
  Button,
  ErrorState,
  ExportButtons,
  Input,
  LoadingState,
  Modal,
  PageHeader,
  SuccessToast,
} from '../../components/ui'
import { disponibilidadeService } from '../../services/disponibilidadeService'
import type { DisponibilidadeSemanal, Indisponibilidade } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './DisponibilidadePage.module.css'

const PERIODOS = ['Manhã', 'Tarde', 'Noite']

export function DisponibilidadePage() {
  const [semanal, setSemanal] = useState<DisponibilidadeSemanal[]>([])
  const [indisponivel, setIndisponivel] = useState<Indisponibilidade[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)
  const [modalOpen, setModalOpen] = useState(false)
  const [formIndisp, setFormIndisp] = useState({
    dataInicio: '',
    dataFim: '',
    motivo: '',
  })

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const [s, i] = await Promise.all([
        disponibilidadeService.getSemanal(),
        disponibilidadeService.getIndisponibilidades(),
      ])
      setSemanal(s)
      setIndisponivel(i)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  function toggle(dia: string, periodo: string) {
    setSemanal((prev) =>
      prev.map((item) => {
        if (item.dia !== dia) return item
        const has = item.periodos.includes(periodo)
        return {
          ...item,
          periodos: has
            ? item.periodos.filter((p) => p !== periodo)
            : [...item.periodos, periodo],
        }
      }),
    )
  }

  async function save() {
    setSaving(true)
    try {
      await disponibilidadeService.updateSemanal(semanal)
      setToast('Disponibilidade salva.')
      setTimeout(() => setToast(null), 2500)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao salvar.')
    } finally {
      setSaving(false)
    }
  }

  async function addIndisponibilidade() {
    setSaving(true)
    try {
      await disponibilidadeService.createIndisponibilidade({
        dataInicio: formIndisp.dataInicio,
        dataFim: formIndisp.dataFim || formIndisp.dataInicio,
        motivo: formIndisp.motivo || null,
      })
      setModalOpen(false)
      setFormIndisp({ dataInicio: '', dataFim: '', motivo: '' })
      setToast('Indisponibilidade registrada.')
      setTimeout(() => setToast(null), 2500)
      setIndisponivel(await disponibilidadeService.getIndisponibilidades())
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao registrar.')
    } finally {
      setSaving(false)
    }
  }

  async function removeIndisp(id: string) {
    await disponibilidadeService.deleteIndisponibilidade(id)
    setIndisponivel(await disponibilidadeService.getIndisponibilidades())
  }

  if (loading) return <LoadingState />
  if (error && semanal.length === 0) {
    return <ErrorState description={error} onRetry={() => void load()} />
  }

  return (
    <div>
      <PageHeader
        description="Grade semanal e datas indisponíveis."
        actions={
          <>
            <ExportButtons recurso="disponibilidades" />
            <Button disabled={saving} onClick={() => void save()}>
              {saving ? 'Salvando…' : 'Salvar grade'}
            </Button>
          </>
        }
      />

      {toast ? (
        <div className={styles.toast}>
          <SuccessToast>✓ {toast}</SuccessToast>
        </div>
      ) : null}
      {error ? <p className={styles.error}>{error}</p> : null}

      <section className={styles.block}>
        <h2>Disponibilidade semanal</h2>
        <div className={styles.week}>
          {semanal.map((dia) => (
            <div key={dia.dia} className={styles.day}>
              <strong>{dia.dia}</strong>
              <div className={styles.periodos}>
                {PERIODOS.map((periodo) => {
                  const checked = dia.periodos.includes(periodo)
                  return (
                    <label
                      key={periodo}
                      className={checked ? styles.on : styles.off}
                    >
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={() => toggle(dia.dia, periodo)}
                      />
                      {periodo}
                    </label>
                  )
                })}
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className={styles.block}>
        <div className={styles.blockHead}>
          <h2>Datas específicas</h2>
          <Button size="sm" onClick={() => setModalOpen(true)}>
            Adicionar
          </Button>
        </div>
        {indisponivel.length === 0 ? (
          <p className={styles.muted}>Nenhuma indisponibilidade registrada.</p>
        ) : (
          <ul className={styles.dates}>
            {indisponivel.map((item) => (
              <li key={item.id}>
                <div>
                  <strong>{formatDate(item.data)}</strong>
                  {item.dataFim && item.dataFim !== item.data ? (
                    <span> → {formatDate(item.dataFim)}</span>
                  ) : null}
                  <span>
                    Indisponível{item.motivo ? ` · ${item.motivo}` : ''}
                  </span>
                </div>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => void removeIndisp(item.id)}
                >
                  Remover
                </Button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <Modal
        open={modalOpen}
        title="Nova indisponibilidade"
        onClose={() => setModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button
              disabled={saving || !formIndisp.dataInicio}
              onClick={() => void addIndisponibilidade()}
            >
              Salvar
            </Button>
          </>
        }
      >
        <div className={styles.form}>
          <Input
            label="Data início"
            type="date"
            value={formIndisp.dataInicio}
            onChange={(e) =>
              setFormIndisp({ ...formIndisp, dataInicio: e.target.value })
            }
          />
          <Input
            label="Data fim"
            type="date"
            value={formIndisp.dataFim}
            onChange={(e) =>
              setFormIndisp({ ...formIndisp, dataFim: e.target.value })
            }
          />
          <Input
            label="Motivo"
            value={formIndisp.motivo}
            onChange={(e) =>
              setFormIndisp({ ...formIndisp, motivo: e.target.value })
            }
          />
        </div>
      </Modal>
    </div>
  )
}
