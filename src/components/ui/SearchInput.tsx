import type { InputHTMLAttributes } from 'react'
import { cx } from '../../utils/format'
import styles from './SearchInput.module.css'

interface SearchInputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: string
}

export function SearchInput({ className, label = 'Pesquisar', ...props }: SearchInputProps) {
  return (
    <label className={styles.wrap}>
      <span className={styles.srOnly}>{label}</span>
      <svg
        className={styles.icon}
        width="16"
        height="16"
        viewBox="0 0 16 16"
        fill="none"
        aria-hidden
      >
        <path
          d="M7 12A5 5 0 1 0 7 2a5 5 0 0 0 0 10Zm4.5-.5L14 14"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
      </svg>
      <input type="search" className={cx(styles.input, className)} {...props} />
    </label>
  )
}
