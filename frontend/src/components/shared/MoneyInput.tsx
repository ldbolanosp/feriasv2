import { useState } from 'react'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'

interface MoneyInputProps {
  value: number | null
  onChange: (value: number | null) => void
  className?: string
  disabled?: boolean
  placeholder?: string
}

function formatCRC(value: number): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(value)
}

function parseRaw(raw: string): number | null {
  const cleaned = raw.replace(/[^0-9.]/g, '')
  const parsed = parseFloat(cleaned)
  return isNaN(parsed) ? null : parsed
}

export function MoneyInput({ value, onChange, className, disabled, placeholder }: MoneyInputProps) {
  const [inputValue, setInputValue] = useState(value != null ? String(value) : '')
  const [focused, setFocused] = useState(false)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value
    setInputValue(raw)
    onChange(parseRaw(raw))
  }

  const handleBlur = () => {
    setFocused(false)
    if (value != null) {
      setInputValue(String(value))
    }
  }

  const displayValue = focused
    ? inputValue
    : value != null
      ? formatCRC(value)
      : ''

  return (
    <div className={cn('relative', className)}>
      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground pointer-events-none">
        ₡
      </span>
      <Input
        type="text"
        value={displayValue}
        onChange={handleChange}
        onFocus={() => {
          setFocused(true)
          setInputValue(value != null ? String(value) : '')
        }}
        onBlur={handleBlur}
        className="pl-7"
        disabled={disabled}
        placeholder={placeholder ?? '0.00'}
        inputMode="decimal"
      />
    </div>
  )
}
