import type { ExportFormato, ExportRecurso } from '../types'
import { api } from './api'
import { delay, isMockEnabled } from '../mocks/data'

const EXT: Record<ExportFormato, string> = {
  txt: 'txt',
  md: 'md',
  xlsx: 'xlsx',
}

export const exportService = {
  async download(recurso: ExportRecurso, formato: ExportFormato): Promise<void> {
    if (isMockEnabled()) {
      const content =
        formato === 'md'
          ? `# Exportação mock — ${recurso}\n\nDados de demonstração.`
          : `Exportacao mock — ${recurso}`
      const blob = new Blob([content], {
        type: formato === 'xlsx' ? 'application/octet-stream' : 'text/plain',
      })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `${recurso}.${EXT[formato]}`
      document.body.appendChild(a)
      a.click()
      a.remove()
      URL.revokeObjectURL(url)
      return delay(undefined)
    }

    await api.download(
      `/export/${recurso}?formato=${formato}`,
      `${recurso}.${EXT[formato]}`,
    )
  },
}
