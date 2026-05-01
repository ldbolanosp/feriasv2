import { useEffect, useRef } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { isAxiosError } from 'axios'
import { Loader2 } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { FormField } from '@/components/shared/FormField'
import type { IParqueoFormPayload } from '@/types/parqueo'

const schema = z.object({
  placa: z.string().min(1, 'La placa es obligatoria.').max(20, 'Máximo 20 caracteres.'),
})

type ParqueoFormValues = z.infer<typeof schema>

interface ParqueoRegistroDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  tarifaActual: number
  onSubmit: (payload: IParqueoFormPayload) => Promise<void>
  isLoading: boolean
}

const defaultValues: ParqueoFormValues = {
  placa: '',
}

function formatMoney(value: number): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(value)
}

export function ParqueoRegistroDialog({
  open,
  onOpenChange,
  tarifaActual,
  onSubmit,
  isLoading,
}: ParqueoRegistroDialogProps) {
  const inputRef = useRef<HTMLInputElement | null>(null)

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    setError,
    formState: { errors },
  } = useForm<ParqueoFormValues>({
    resolver: zodResolver(schema),
    defaultValues,
  })

  useEffect(() => {
    if (!open) {
      return
    }

    reset(defaultValues)

    window.setTimeout(() => {
      inputRef.current?.focus()
      inputRef.current?.select()
    }, 10)
  }, [open, reset])

  const placaField = register('placa')

  const handleFormSubmit = async (values: ParqueoFormValues) => {
    try {
      await onSubmit({
        placa: values.placa.trim().toUpperCase(),
      })

      reset(defaultValues)
    } catch (error) {
      if (!isAxiosError(error) || error.response?.status !== 422) {
        throw error
      }

      const apiErrors = error.response.data?.errors as Record<string, string[]> | undefined

      if (!apiErrors) {
        return
      }

      for (const [field, messages] of Object.entries(apiErrors)) {
        const message = messages[0]

        if (message) {
          setError(field as keyof ParqueoFormValues, { message })
        }
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Registrar parqueo</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
          <FormField label="Placa" error={errors.placa?.message} required>
            <Input
              {...placaField}
              ref={(element) => {
                placaField.ref(element)
                inputRef.current = element
              }}
              autoFocus
              autoCapitalize="characters"
              autoCorrect="off"
              spellCheck={false}
              placeholder="Ej. ABC123"
              disabled={isLoading}
              onChange={(event) => {
                const uppercaseValue = event.target.value.toUpperCase()
                setValue('placa', uppercaseValue, { shouldValidate: true, shouldDirty: true })
              }}
            />
          </FormField>

          <FormField label="Tarifa vigente">
            <Input value={formatMoney(tarifaActual)} disabled readOnly />
          </FormField>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isLoading}
            >
              Cancelar
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading && <Loader2 className="size-4 animate-spin" />}
              Registrar
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
