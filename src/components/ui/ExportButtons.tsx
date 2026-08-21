import { useState } from 'react'
import { Button } from './Button'
import { exportService } from '../../services/exportService'
import type { ExportFormato, ExportRecurso } from '../../types'
import styles from './ExportButtons.module.css'

interface ExportButtonsProps {
  recurso: ExportRecurso
}

const FORMATOS: { formato: ExportFormato; label: string }[] = [
  { formato: 'txt', label: 'TXT' },
  { formato: 'md', label: 'MD' },
  { formato: 'xlsx', label: 'Excel' },
]

export function ExportButtons({ recurso }: ExportButtonsProps) {
  const [loading, setLoading] = useState<ExportFormato | null>(null)
  const [error, setError] = useState<string | null>(null)

  async function handleExport(formato: ExportFormato) {
    setLoading(formato)
    setError(null)
    try {
      await exportService.download(recurso, formato)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Falha ao exportar.')
    } finally {
      setLoading(null)
    }
  }

  return (
    <div className={styles.wrap}>
      <div className={styles.group}>
        {FORMATOS.map(({ formato, label }) => (
          <Button
            key={formato}
            variant="secondary"
            size="sm"
            disabled={loading !== null}
            onClick={() => void handleExport(formato)}
          >
            {loading === formato ? '…' : `Exportar ${label}`}
          </Button>
        ))}
      </div>
      {error ? <p className={styles.error}>{error}</p> : null}
    </div>
  )
}
