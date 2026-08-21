import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  Badge,
  Button,
  ErrorState,
  LoadingState,
  PageHeader,
  SuccessToast,
} from '../../components/ui'
import { useAuth } from '../../contexts/AuthContext'
import { escalaService } from '../../services/escalaService'
import type { Escala, EscalaSlotStatus } from '../../types'
import { formatDate } from '../../utils/format'
import styles from './EscalaDetailPage.module.css'

function slotTone(status: EscalaSlotStatus) {
  if (status === 'CONFIRMADO') return 'success' as const
  if (status === 'PENDENTE') return 'warning' as const
  if (status === 'RECUSADO') return 'danger' as const
  return 'neutral' as const
}

function slotLabel(status: EscalaSlotStatus) {
  if (status === 'SEM_VOLUNTARIO') return 'Sem voluntário'
  return status
}

export function EscalaDetailPage() {
  const { id } = useParams<{ id: string }>()
  const { user } = useAuth()
  const [escala, setEscala] = useState<Escala | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)
  const [acting, setActing] = useState(false)

  async function load() {
    if (!id) return
    setLoading(true)
    setError(null)
    try {
      setEscala(await escalaService.getById(id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar escala.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  const minhaDesignacao = useMemo(() => {
    if (!escala) return null
    const slots = escala.ministerios.flatMap((m) => m.slots)
    return (
      slots.find(
        (s) =>
          s.status === 'PENDENTE' &&
          s.designacaoId &&
          (s.voluntarioId === user?.pessoaId || !user?.pessoaId),
      ) ??
      slots.find((s) => s.status === 'PENDENTE' && s.designacaoId) ??
      null
    )
  }, [escala, user?.pessoaId])

  async function handleConfirm() {
    if (!id || !minhaDesignacao?.designacaoId) {
      setToast('Nenhuma designação pendente para confirmar.')
      setTimeout(() => setToast(null), 2500)
      return
    }
    setActing(true)
    try {
      await escalaService.confirmarSlot(id, minhaDesignacao.designacaoId)
      setToast('Escala confirmada.')
      setTimeout(() => setToast(null), 2500)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao confirmar.')
    } finally {
      setActing(false)
    }
  }

  async function handleRefuse() {
    if (!id || !minhaDesignacao?.designacaoId) {
      setToast('Nenhuma designação pendente para recusar.')
      setTimeout(() => setToast(null), 2500)
      return
    }
    setActing(true)
    try {
      await escalaService.recusarSlot(id, minhaDesignacao.designacaoId)
      setToast('Participação recusada.')
      setTimeout(() => setToast(null), 2500)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao recusar.')
    } finally {
      setActing(false)
    }
  }

  if (loading) return <LoadingState />
  if (error || !escala) {
    return <ErrorState description={error ?? undefined} onRetry={() => void load()} />
  }

  return (
    <div>
      <PageHeader
        title={escala.nome}
        description={`${formatDate(escala.data)} · ${escala.horario}`}
        actions={
          <Link to="/voluntariado/escalas" className={styles.back}>
            Voltar
          </Link>
        }
      />

      {toast ? (
        <div className={styles.toast}>
          <SuccessToast>✓ {toast}</SuccessToast>
        </div>
      ) : null}

      <section className={styles.confirmBox}>
        <div>
          <h2>Sua participação</h2>
          <p>
            {minhaDesignacao
              ? `Serviço: ${minhaDesignacao.servico}`
              : 'Confirme ou informe indisponibilidade quando houver designação pendente.'}
          </p>
        </div>
        <div className={styles.actions}>
          <Button
            disabled={acting || !minhaDesignacao?.designacaoId}
            onClick={() => void handleConfirm()}
          >
            Confirmar
          </Button>
          <Button
            variant="secondary"
            disabled={acting || !minhaDesignacao?.designacaoId}
            onClick={() => void handleRefuse()}
          >
            Não posso participar
          </Button>
        </div>
      </section>

      {escala.ministerios.map((ministerio) => (
        <section key={ministerio.nome} className={styles.block}>
          <h2>{ministerio.nome}</h2>
          <ul className={styles.slots}>
            {ministerio.slots.map((slot, index) => (
              <li key={`${slot.servico}-${index}`}>
                <div>
                  <strong>{slot.servico}</strong>
                  <p>
                    {slot.status === 'SEM_VOLUNTARIO'
                      ? '⚠ Sem voluntário'
                      : slot.voluntarioNome}
                  </p>
                </div>
                <Badge tone={slotTone(slot.status)}>{slotLabel(slot.status)}</Badge>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </div>
  )
}
