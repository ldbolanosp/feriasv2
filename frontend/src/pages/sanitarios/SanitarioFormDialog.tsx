import { useEffect, useMemo, useState } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { isAxiosError } from 'axios'
import { Loader2 } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { ComboboxSearch } from '@/components/shared/ComboboxSearch'
import { FormField } from '@/components/shared/FormField'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Switch } from '@/components/ui/switch'
import { Textarea } from '@/components/ui/textarea'
import { useParticipantesPorFeria } from '@/hooks/useParticipantes'
import type { ISanitarioFormPayload } from '@/types/sanitario'

const schema = z.object({
  es_publico: z.boolean(),
  participante_id: z.number().nullable(),
  cantidad: z.number().int('La cantidad debe ser entera.').min(1, 'La cantidad mínima es 1.'),
  observaciones: z.string(),
})

type SanitarioFormValues = z.infer<typeof schema>

interface SanitarioFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  precioActual: number
  onSubmit: (payload: ISanitarioFormPayload) => Promise<void>
  isLoading: boolean
}

const defaultValues: SanitarioFormValues = {
  es_publico: true,
  participante_id: null,
  cantidad: 1,
  observaciones: '',
}

function formatMoney(value: number): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(value)
}

export function SanitarioFormDialog({
  open,
  onOpenChange,
  precioActual,
  onSubmit,
  isLoading,
}: SanitarioFormDialogProps) {
  const [participanteSearch, setParticipanteSearch] = useState('')
  const { data: participantes = [], isFetching: isFetchingParticipantes } =
    useParticipantesPorFeria(participanteSearch)

  const {
    register,
    handleSubmit,
    watch,
    reset,
    setValue,
    setError,
    clearErrors,
    formState: { errors },
  } = useForm<SanitarioFormValues>({
    resolver: zodResolver(schema),
    defaultValues,
  })

  useEffect(() => {
    if (!open) {
      return
    }

    reset(defaultValues)
    setParticipanteSearch('')
  }, [open, reset])

  const esPublico = watch('es_publico')
  const participanteId = watch('participante_id')
  const cantidad = watch('cantidad')
  const total = (Number.isFinite(cantidad) ? cantidad : 0) * precioActual

  const participanteOptions = useMemo(
    () =>
      participantes.map((participante) => ({
        value: participante.id,
        label: `${participante.nombre} · ${participante.numero_identificacion}`,
      })),
    [participantes],
  )

  const handleFormSubmit = async (values: SanitarioFormValues) => {
    clearErrors('participante_id')

    if (!values.es_publico && values.participante_id === null) {
      setError('participante_id', { message: 'Debe seleccionar un participante o marcar uso público.' })
      return
    }

    try {
      await onSubmit({
        participante_id: values.es_publico ? null : values.participante_id,
        cantidad: values.cantidad,
        observaciones: values.observaciones.trim() === '' ? null : values.observaciones.trim(),
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
          setError(field as keyof SanitarioFormValues, { message })
        }
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>Facturar sanitario</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
          <div className="flex items-center justify-between rounded-lg border p-3">
            <div className="space-y-0.5">
              <p className="text-sm font-medium">Uso público</p>
              <p className="text-xs text-muted-foreground">
                Desactive esta opción si desea vincular el cobro a un participante.
              </p>
            </div>
            <Switch
              checked={esPublico}
              onCheckedChange={(checked) => {
                setValue('es_publico', checked, { shouldValidate: true })
                if (checked) {
                  setValue('participante_id', null, { shouldValidate: true })
                }
              }}
              disabled={isLoading}
            />
          </div>

          {!esPublico && (
            <FormField label="Participante" error={errors.participante_id?.message} required>
              <ComboboxSearch
                options={participanteOptions}
                value={participanteId}
                onSelect={(value) => setValue('participante_id', value as number | null, { shouldValidate: true })}
                onSearch={setParticipanteSearch}
                placeholder="Buscar participante..."
                isLoading={isFetchingParticipantes}
                className="w-full"
              />
            </FormField>
          )}

          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Cantidad" error={errors.cantidad?.message} required>
              <Input
                {...register('cantidad', { valueAsNumber: true })}
                type="number"
                min={1}
                step={1}
                disabled={isLoading}
              />
            </FormField>

            <FormField label="Precio unitario">
              <Input value={formatMoney(precioActual)} readOnly disabled />
            </FormField>
          </div>

          <FormField label="Total">
            <Input value={formatMoney(total)} readOnly disabled />
          </FormField>

          <FormField label="Observaciones" error={errors.observaciones?.message}>
            <Textarea
              {...register('observaciones')}
              rows={3}
              placeholder="Notas opcionales para el ticket"
              disabled={isLoading}
            />
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
              Facturar
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
