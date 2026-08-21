import { useState } from 'react'
import { Button, Input, SuccessToast } from '../../components/ui'
import styles from './PerfilPage.module.css'

export function PerfilPausaPage() {
  const [inicio, setInicio] = useState('')
  const [fim, setFim] = useState('')
  const [motivo, setMotivo] = useState('')
  const [toast, setToast] = useState<string | null>(null)
  const [ativa, setAtiva] = useState(false)

  function handlePause() {
    if (!inicio) return
    setAtiva(true)
    setToast('Pausa registrada. Você não será sugerido em escalas nesse período.')
    setTimeout(() => setToast(null), 3000)
  }

  function handleClear() {
    setAtiva(false)
    setInicio('')
    setFim('')
    setMotivo('')
    setToast('Pausa encerrada.')
    setTimeout(() => setToast(null), 2500)
  }

  return (
    <div className={styles.panel}>
      {toast ? (
        <div className={styles.toast}>
          <SuccessToast>✓ {toast}</SuccessToast>
        </div>
      ) : null}

      <p className={styles.lead}>
        Informe uma pausa temporária no voluntariado. Útil em viagens, férias ou
        períodos de indisponibilidade prolongada.
      </p>

      {ativa ? (
        <div className={styles.pauseActive}>
          <strong>Pausa ativa</strong>
          <p>
            De {inicio || '—'} até {fim || 'sem data final'}
            {motivo ? ` · ${motivo}` : ''}
          </p>
          <Button variant="secondary" onClick={handleClear}>
            Encerrar pausa
          </Button>
        </div>
      ) : (
        <div className={styles.form}>
          <Input
            label="Início"
            type="date"
            value={inicio}
            onChange={(e) => setInicio(e.target.value)}
          />
          <Input
            label="Fim (opcional)"
            type="date"
            value={fim}
            onChange={(e) => setFim(e.target.value)}
          />
          <Input
            label="Motivo"
            value={motivo}
            onChange={(e) => setMotivo(e.target.value)}
            placeholder="Ex.: viagem, estudos…"
          />
          <Button onClick={handlePause} disabled={!inicio}>
            Registrar pausa
          </Button>
        </div>
      )}
    </div>
  )
}
