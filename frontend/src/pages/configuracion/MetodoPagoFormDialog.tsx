import { useEffect } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { isAxiosError } from 'axios'
import { Loader2 } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { FormField } from '@/components/shared/FormField'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import type { IMetodoPago, IMetodoPagoFormPayload } from '@/types/metodoPago'

const schema = z.object({
  nombre: z.string().min(1, 'El nombre es requerido').max(255, 'Máximo 255 caracteres'),
})

type MetodoPagoFormValues = z.infer<typeof schema>

interface MetodoPagoFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  metodoPago?: IMetodoPago | null
  onSubmit: (payload: IMetodoPagoFormPayload) => Promise<void>
  isLoading: boolean
}

export function MetodoPagoFormDialog({
  open,
  onOpenChange,
  metodoPago,
  onSubmit,
  isLoading,
}: MetodoPagoFormDialogProps) {
  const isEditing = !!metodoPago
  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors },
  } = useForm<MetodoPagoFormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      nombre: '',
    },
  })

  useEffect(() => {
    if (!open) {
      return
    }

    reset({
      nombre: metodoPago?.nombre ?? '',
    })
  }, [metodoPago, open, reset])

  const handleFormSubmit = async (values: MetodoPagoFormValues) => {
    try {
      await onSubmit({
        nombre: values.nombre.trim(),
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
          setError(field as keyof MetodoPagoFormValues, { message })
        }
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {isEditing ? 'Editar método de pago' : 'Nuevo método de pago'}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
          <FormField label="Nombre" error={errors.nombre?.message} required>
            <Input
              {...register('nombre')}
              placeholder="Ej. Transferencia"
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
              {isEditing ? 'Guardar cambios' : 'Crear método'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
