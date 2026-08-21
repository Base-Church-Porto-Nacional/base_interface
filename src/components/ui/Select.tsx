import type { SelectHTMLAttributes } from 'react'
import { cx } from '../../utils/format'
import styles from './Select.module.css'

interface Option {
  value: string
  label: string
}

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string
  options: Option[]
  error?: string
}

export function Select({
  label,
  options,
  error,
  className,
  id,
  ...props
}: SelectProps) {
  const selectId = id ?? props.name

  return (
    <label className={styles.field}>
      {label ? <span className={styles.label}>{label}</span> : null}
      <select
        id={selectId}
        className={cx(styles.select, error && styles.invalid, className)}
        {...props}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error ? <span className={styles.error}>{error}</span> : null}
    </label>
  )
}
