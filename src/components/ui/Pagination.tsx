import { Button } from './Button'
import styles from './Pagination.module.css'

interface PaginationProps {
  page: number
  totalPages: number
  onChange: (page: number) => void
}

export function Pagination({ page, totalPages, onChange }: PaginationProps) {
  if (totalPages <= 1) return null

  return (
    <div className={styles.wrap}>
      <Button
        variant="secondary"
        size="sm"
        disabled={page <= 0}
        onClick={() => onChange(page - 1)}
      >
        Anterior
      </Button>
      <span className={styles.info}>
        Página {page + 1} de {totalPages}
      </span>
      <Button
        variant="secondary"
        size="sm"
        disabled={page >= totalPages - 1}
        onClick={() => onChange(page + 1)}
      >
        Próxima
      </Button>
    </div>
  )
}
