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
import { Textarea } from '@/components/ui/textarea'
import { useParticipantesPorFeria } from '@/hooks/useParticipantes'
import type { ITarimaFormPayload } from '@/types/tarima'

const schema = z.object({
  participante_id: z.number().nullable(),
  numero_tarima: z.string(),
  cantidad: z.number().int('La cantidad debe ser entera.').min(1, 'La cantidad mínima es 1.'),
  observaciones: z.string(),
})

type TarimaFormValues = z.infer<typeof schema>

interface TarimaFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  precioActual: number
  onSubmit: (payload: ITarimaFormPayload) => Promise<void>
  isLoading: boolean
}

const defaultValues: TarimaFormValues = {
  participante_id: null,
  numero_tarima: '',
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

export function TarimaFormDialog({
  open,
  onOpenChange,
  precioActual,
  onSubmit,
  isLoading,
}: TarimaFormDialogProps) {
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
  } = useForm<TarimaFormValues>({
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

  const handleFormSubmit = async (values: TarimaFormValues) => {
    clearErrors('participante_id')

    if (values.participante_id === null) {
      setError('participante_id', { message: 'Debe seleccionar un participante.' })
      return
    }

    try {
      await onSubmit({
        participante_id: values.participante_id,
        numero_tarima: values.numero_tarima.trim() === '' ? null : values.numero_tarima.trim(),
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
          setError(field as keyof TarimaFormValues, { message })
        }
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>Facturar tarima</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
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

            <FormField label="Número de tarima" error={errors.numero_tarima?.message}>
              <Input
                {...register('numero_tarima')}
                placeholder="Ej. B-12"
                disabled={isLoading}
              />
            </FormField>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Precio unitario">
              <Input value={formatMoney(precioActual)} readOnly disabled />
            </FormField>

            <FormField label="Total">
              <Input value={formatMoney(total)} readOnly disabled />
            </FormField>
          </div>

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
