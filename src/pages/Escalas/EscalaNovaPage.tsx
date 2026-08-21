import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Button,
  ErrorState,
  Input,
  LoadingState,
  PageHeader,
  Select,
} from '../../components/ui'
import { escalaService } from '../../services/escalaService'
import { ministerioService } from '../../services/ministerioService'
import type { Ministerio, Servico } from '../../types'
import styles from './EscalaNovaPage.module.css'

type Step = 1 | 2 | 3 | 4

export function EscalaNovaPage() {
  const navigate = useNavigate()
  const [step, setStep] = useState<Step>(1)
  const [ministerios, setMinisterios] = useState<Ministerio[]>([])
  const [servicos, setServicos] = useState<Servico[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [sugestaoMsg, setSugestaoMsg] = useState<string | null>(null)

  const [form, setForm] = useState({
    nome: 'Culto de Domingo',
    data: '',
    horario: '18:00',
    ministerioId: '',
  })
  const [quantidades, setQuantidades] = useState<Record<string, number>>({})

  useEffect(() => {
    async function load() {
      try {
        const list = await ministerioService.list()
        setMinisterios(list)
        setForm((prev) => ({
          ...prev,
          ministerioId: list[0]?.id ?? '',
        }))
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Erro ao carregar dados.')
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [])

  useEffect(() => {
    async function loadServicos() {
      if (!form.ministerioId) return
      const list = await ministerioService.listServicos(form.ministerioId)
      setServicos(list)
      const initial: Record<string, number> = {}
      list.forEach((s) => {
        initial[s.id] = s.nome === 'Vocal' ? 2 : 1
      })
      setQuantidades(initial)
    }
    void loadServicos()
  }, [form.ministerioId])

  async function handleGerarSugestao() {
    setSugestaoMsg('Gerando sugestão… (integração com algoritmo do backend)')
    setSaving(true)
    try {
      const draft = await escalaService.create({
        nome: form.nome,
        data: form.data,
        horario: form.horario,
        ministerioIds: [form.ministerioId],
        servicos: Object.entries(quantidades).map(([servicoId, quantidade]) => ({
          servicoId,
          quantidade,
        })),
      })
      await escalaService.gerarSugestao(draft.id)
      setSugestaoMsg('Sugestão preparada. Revise e publique a escala.')
      setStep(3)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao gerar sugestão.')
    } finally {
      setSaving(false)
    }
  }

  async function handlePublicar(event: FormEvent) {
    event.preventDefault()
    setSaving(true)
    try {
      const created = await escalaService.create({
        nome: form.nome,
        data: form.data,
        horario: form.horario,
        ministerioIds: [form.ministerioId],
        servicos: Object.entries(quantidades).map(([servicoId, quantidade]) => ({
          servicoId,
          quantidade,
        })),
      })
      await escalaService.publicar(created.id)
      navigate(`/voluntariado/escalas/${created.id}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao publicar.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <LoadingState />
  if (error) return <ErrorState description={error} />

  return (
    <div>
      <PageHeader
        title="Nova escala"
        description="Fluxo de criação com sugestão automática do backend."
      />

      <ol className={styles.steps}>
        <li data-active={step === 1}>1. Dados</li>
        <li data-active={step === 2}>2. Serviços</li>
        <li data-active={step === 3}>3. Revisar</li>
        <li data-active={step === 4}>4. Publicar</li>
      </ol>

      {step === 1 ? (
        <form
          className={styles.form}
          onSubmit={(e) => {
            e.preventDefault()
            setStep(2)
          }}
        >
          <Input
            label="Nome"
            value={form.nome}
            onChange={(e) => setForm((f) => ({ ...f, nome: e.target.value }))}
            required
          />
          <Input
            label="Data"
            type="date"
            value={form.data}
            onChange={(e) => setForm((f) => ({ ...f, data: e.target.value }))}
            required
          />
          <Input
            label="Horário"
            type="time"
            value={form.horario}
            onChange={(e) => setForm((f) => ({ ...f, horario: e.target.value }))}
            required
          />
          <Select
            label="Ministério"
            value={form.ministerioId}
            onChange={(e) =>
              setForm((f) => ({ ...f, ministerioId: e.target.value }))
            }
            options={ministerios.map((m) => ({ value: m.id, label: m.nome }))}
          />
          <Button type="submit">Continuar</Button>
        </form>
      ) : null}

      {step === 2 ? (
        <div className={styles.form}>
          <h2>Serviços necessários</h2>
          {servicos.map((servico) => (
            <label key={servico.id} className={styles.qty}>
              <span>{servico.nome}</span>
              <input
                type="number"
                min={0}
                max={10}
                value={quantidades[servico.id] ?? 0}
                onChange={(e) =>
                  setQuantidades((prev) => ({
                    ...prev,
                    [servico.id]: Number(e.target.value),
                  }))
                }
              />
            </label>
          ))}
          <div className={styles.row}>
            <Button variant="secondary" onClick={() => setStep(1)}>
              Voltar
            </Button>
            <Button disabled={saving} onClick={() => void handleGerarSugestao()}>
              Gerar sugestão
            </Button>
          </div>
          {sugestaoMsg ? <p className={styles.hint}>{sugestaoMsg}</p> : null}
        </div>
      ) : null}

      {step === 3 ? (
        <div className={styles.form}>
          <h2>Revisar</h2>
          <dl className={styles.review}>
            <div>
              <dt>Nome</dt>
              <dd>{form.nome}</dd>
            </div>
            <div>
              <dt>Data</dt>
              <dd>{form.data}</dd>
            </div>
            <div>
              <dt>Horário</dt>
              <dd>{form.horario}</dd>
            </div>
          </dl>
          <p className={styles.hint}>
            A distribuição de voluntários virá do algoritmo do backend.
          </p>
          <div className={styles.row}>
            <Button variant="secondary" onClick={() => setStep(2)}>
              Voltar
            </Button>
            <Button onClick={() => setStep(4)}>Continuar</Button>
          </div>
        </div>
      ) : null}

      {step === 4 ? (
        <form className={styles.form} onSubmit={(e) => void handlePublicar(e)}>
          <h2>Publicar escala</h2>
          <p className={styles.hint}>
            Ao publicar, os voluntários poderão confirmar participação.
          </p>
          <div className={styles.row}>
            <Button variant="secondary" onClick={() => setStep(3)}>
              Voltar
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? 'Publicando…' : 'Publicar escala'}
            </Button>
          </div>
        </form>
      ) : null}
    </div>
  )
}
