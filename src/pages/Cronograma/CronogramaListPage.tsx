import { EmptyState } from '../../components/ui'
import styles from './CronogramaPage.module.css'

interface CronogramaListPageProps {
  kind: 'cultos' | 'eventos'
}

export function CronogramaListPage({ kind }: CronogramaListPageProps) {
  const isCulto = kind === 'cultos'

  return (
    <div className={styles.wrap}>
      <EmptyState
        title={isCulto ? 'Nenhum culto cadastrado.' : 'Nenhum evento cadastrado.'}
        description={
          isCulto
            ? 'O calendário de cultos será integrado à API de cronograma.'
            : 'Eventos especiais da igreja aparecerão nesta lista.'
        }
      />
    </div>
  )
}
