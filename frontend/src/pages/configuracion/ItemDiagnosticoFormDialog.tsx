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
import type { IItemDiagnostico, IItemDiagnosticoFormPayload } from '@/types/itemDiagnostico'

const schema = z.object({
  nombre: z.string().min(1, 'El nombre es requerido').max(255, 'Máximo 255 caracteres'),
})

type ItemDiagnosticoFormValues = z.infer<typeof schema>

interface ItemDiagnosticoFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  item?: IItemDiagnostico | null
  onSubmit: (payload: IItemDiagnosticoFormPayload) => Promise<void>
  isLoading: boolean
}

export function ItemDiagnosticoFormDialog({
  open,
  onOpenChange,
  item,
  onSubmit,
  isLoading,
}: ItemDiagnosticoFormDialogProps) {
  const isEditing = !!item
  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors },
  } = useForm<ItemDiagnosticoFormValues>({
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
      nombre: item?.nombre ?? '',
    })
  }, [item, open, reset])

  const handleFormSubmit = async (values: ItemDiagnosticoFormValues) => {
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
          setError(field as keyof ItemDiagnosticoFormValues, { message })
        }
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {isEditing ? 'Editar item de inspección' : 'Nuevo item de inspección'}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
          <FormField label="Nombre" error={errors.nombre?.message} required>
            <Input
              {...register('nombre')}
              placeholder="Ej. Uso correcto del carné"
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
              {isEditing ? 'Guardar cambios' : 'Crear item'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
