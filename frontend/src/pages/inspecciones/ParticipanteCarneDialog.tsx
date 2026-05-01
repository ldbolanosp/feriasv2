import { useEffect } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { isAxiosError } from 'axios'
import { Loader2 } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
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
import type { IParticipante } from '@/types/participante'

const schema = z
  .object({
    numero_carne: z.string().max(50, 'Máximo 50 caracteres'),
    fecha_emision_carne: z.string(),
    fecha_vencimiento_carne: z.string(),
  })
  .superRefine((data, ctx) => {
    if (data.fecha_emision_carne && data.fecha_vencimiento_carne) {
      const emision = new Date(`${data.fecha_emision_carne}T12:00:00`)
      const vencimiento = new Date(`${data.fecha_vencimiento_carne}T12:00:00`)

      if (vencimiento <= emision) {
        ctx.addIssue({
          code: 'custom',
          message: 'La fecha de vencimiento debe ser posterior a la fecha de emisión.',
          path: ['fecha_vencimiento_carne'],
        })
      }
    }
  })

type ParticipanteCarneFormValues = z.infer<typeof schema>

interface ParticipanteCarneDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  participante: IParticipante | null
  onSubmit: (payload: {
    numero_carne: string | null
    fecha_emision_carne: string | null
    fecha_vencimiento_carne: string | null
  }) => Promise<void>
  isLoading: boolean
}

export function ParticipanteCarneDialog({
  open,
  onOpenChange,
  participante,
  onSubmit,
  isLoading,
}: ParticipanteCarneDialogProps) {
  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors },
  } = useForm<ParticipanteCarneFormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      numero_carne: '',
      fecha_emision_carne: '',
      fecha_vencimiento_carne: '',
    },
  })

  useEffect(() => {
    if (!open) {
      return
    }

    reset({
      numero_carne: participante?.numero_carne ?? '',
      fecha_emision_carne: participante?.fecha_emision_carne ?? '',
      fecha_vencimiento_carne: participante?.fecha_vencimiento_carne ?? '',
    })
  }, [open, participante, reset])

  const handleFormSubmit = async (values: ParticipanteCarneFormValues) => {
    try {
      await onSubmit({
        numero_carne: values.numero_carne.trim() === '' ? null : values.numero_carne.trim(),
        fecha_emision_carne:
          values.fecha_emision_carne === '' ? null : values.fecha_emision_carne,
        fecha_vencimiento_carne:
          values.fecha_vencimiento_carne === '' ? null : values.fecha_vencimiento_carne,
      })
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
          setError(field as keyof ParticipanteCarneFormValues, { message })
        }
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Actualizar carné</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
          <div className="rounded-lg border border-border/70 bg-muted/30 px-4 py-3">
            <p className="text-sm font-medium">{participante?.nombre}</p>
            <p className="text-xs text-muted-foreground">
              {participante?.numero_identificacion ?? 'Sin identificación'}
            </p>
          </div>

          <FormField label="Número de carné" error={errors.numero_carne?.message}>
            <Input
              {...register('numero_carne')}
              placeholder="Ej. CAR-2026-015"
              disabled={isLoading}
            />
          </FormField>

          <div className="grid gap-4 sm:grid-cols-2">
            <FormField label="Fecha de emisión" error={errors.fecha_emision_carne?.message}>
              <Input
                type="date"
                {...register('fecha_emision_carne')}
                disabled={isLoading}
              />
            </FormField>

            <FormField label="Fecha de vencimiento" error={errors.fecha_vencimiento_carne?.message}>
              <Input
                type="date"
                {...register('fecha_vencimiento_carne')}
                disabled={isLoading}
              />
            </FormField>
          </div>

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
              Guardar carné
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
