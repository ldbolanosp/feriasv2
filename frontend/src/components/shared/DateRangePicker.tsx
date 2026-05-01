import { useEffect, useState } from 'react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { CalendarIcon } from 'lucide-react'
import type { DateRange } from 'react-day-picker'
import { Button } from '@/components/ui/button'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'

interface DateRangePickerProps {
  value: DateRange | undefined
  onChange: (range: DateRange | undefined) => void
  placeholder?: string
  className?: string
  disabled?: boolean
}

export function DateRangePicker({
  value,
  onChange,
  placeholder = 'Seleccionar rango',
  className,
  disabled,
}: DateRangePickerProps) {
  const [open, setOpen] = useState(false)
  const [numberOfMonths, setNumberOfMonths] = useState(2)

  useEffect(() => {
    const mediaQuery = window.matchMedia('(max-width: 640px)')

    const updateMonths = (matches: boolean) => {
      setNumberOfMonths(matches ? 1 : 2)
    }

    updateMonths(mediaQuery.matches)

    const handleChange = (event: MediaQueryListEvent) => {
      updateMonths(event.matches)
    }

    mediaQuery.addEventListener('change', handleChange)

    return () => {
      mediaQuery.removeEventListener('change', handleChange)
    }
  }, [])

  const displayText =
    value?.from
      ? value.to
        ? `${format(value.from, 'dd/MM/yyyy', { locale: es })} – ${format(value.to, 'dd/MM/yyyy', { locale: es })}`
        : format(value.from, 'dd/MM/yyyy', { locale: es })
      : placeholder

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          disabled={disabled}
          className={cn(
            'w-full justify-start text-left font-normal sm:w-auto',
            !value?.from && 'text-muted-foreground',
            className,
          )}
        >
          <CalendarIcon className="mr-2 size-4 shrink-0" />
          {displayText}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto max-w-[calc(100vw-1rem)] p-0" align="start">
        <Calendar
          mode="range"
          selected={value}
          onSelect={onChange}
          numberOfMonths={numberOfMonths}
          locale={es}
        />
        {value?.from && (
          <div className="flex justify-end border-t p-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                onChange(undefined)
                setOpen(false)
              }}
            >
              Limpiar
            </Button>
          </div>
        )}
      </PopoverContent>
    </Popover>
  )
}
