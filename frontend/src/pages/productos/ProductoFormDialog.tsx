import { useEffect } from 'react'
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
import { Switch } from '@/components/ui/switch'
import { FormField } from '@/components/shared/FormField'
import type { IProducto, IProductoFormPayload } from '@/types/producto'

const schema = z.object({
  codigo: z.string().min(1, 'El código es requerido').max(20, 'Máximo 20 caracteres'),
  descripcion: z
    .string()
    .min(1, 'La descripción es requerida')
    .max(255, 'Máximo 255 caracteres'),
  activo: z.boolean(),
})

type ProductoFormValues = z.infer<typeof schema>

interface ProductoFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  producto?: IProducto | null
  onSubmit: (payload: IProductoFormPayload) => Promise<void>
  isLoading: boolean
}

const defaultValues: ProductoFormValues = {
  codigo: '',
  descripcion: '',
  activo: true,
}

export function ProductoFormDialog({
  open,
  onOpenChange,
  producto,
  onSubmit,
  isLoading,
}: ProductoFormDialogProps) {
  const isEditing = !!producto

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    setError,
    formState: { errors },
  } = useForm<ProductoFormValues>({
    resolver: zodResolver(schema),
    defaultValues,
  })

  useEffect(() => {
    if (!open) {
      return
    }

    reset({
      codigo: producto?.codigo ?? '',
      descripcion: producto?.descripcion ?? '',
      activo: producto?.activo ?? true,
    })
  }, [open, producto, reset])

  const activo = watch('activo')

  const handleFormSubmit = async (values: ProductoFormValues) => {
    try {
      await onSubmit({
        codigo: values.codigo.trim(),
        descripcion: values.descripcion.trim(),
        activo: values.activo,
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
          setError(field as keyof ProductoFormValues, { message })
        }
      }
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{isEditing ? 'Editar producto' : 'Nuevo producto'}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
          <FormField label="Código" error={errors.codigo?.message} required>
            <Input
              {...register('codigo')}
              placeholder="Ej. PROD-001"
              disabled={isLoading}
            />
          </FormField>

          <FormField label="Descripción" error={errors.descripcion?.message} required>
            <Input
              {...register('descripcion')}
              placeholder="Ej. Tomate cherry"
              disabled={isLoading}
            />
          </FormField>

          <div className="flex items-center justify-between rounded-lg border p-3">
            <div className="space-y-0.5">
              <p className="text-sm font-medium">Estado del producto</p>
              <p className="text-xs text-muted-foreground">
                Los productos inactivos no deberían usarse en operaciones nuevas.
              </p>
            </div>
            <Switch
              checked={activo}
              onCheckedChange={(checked) => setValue('activo', checked)}
              disabled={isLoading}
            />
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
              {isEditing ? 'Guardar cambios' : 'Crear producto'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
