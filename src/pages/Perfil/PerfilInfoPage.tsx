import { useState } from 'react'
import { Button, Input, SuccessToast } from '../../components/ui'
import { useAuth } from '../../contexts/AuthContext'
import styles from './PerfilPage.module.css'

export function PerfilInfoPage() {
  const { user } = useAuth()
  const [form, setForm] = useState({
    nome: user?.nome ?? '',
    email: user?.email ?? '',
    telefone: '',
  })
  const [toast, setToast] = useState<string | null>(null)

  function handleSave() {
    setToast('Informações salvas (integração com API em seguida).')
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
        Atualize seus dados pessoais. Alterações sensíveis passam pela API.
      </p>

      <div className={styles.form}>
        <Input
          label="Nome"
          value={form.nome}
          onChange={(e) => setForm((f) => ({ ...f, nome: e.target.value }))}
        />
        <Input
          label="E-mail"
          type="email"
          value={form.email}
          onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
        />
        <Input
          label="Telefone"
          value={form.telefone}
          onChange={(e) => setForm((f) => ({ ...f, telefone: e.target.value }))}
        />
        <div className={styles.roles}>
          <span>Papéis</span>
          <strong>{user?.roles.join(' · ') ?? '—'}</strong>
        </div>
        <Button onClick={handleSave}>Salvar alterações</Button>
      </div>
    </div>
  )
}
