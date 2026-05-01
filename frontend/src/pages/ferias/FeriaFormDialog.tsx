import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Loader2 } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import type { IFeria, IFeriaForm } from '@/types/feria'

const schema = z.object({
  codigo: z.string().min(1, 'El código es requerido').max(20, 'Máximo 20 caracteres'),
  descripcion: z.string().min(1, 'La descripción es requerida').max(255, 'Máximo 255 caracteres'),
  facturacion_publico: z.boolean(),
})

interface FeriaFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  feria?: IFeria | null
  onSubmit: (data: IFeriaForm) => Promise<void>
  isLoading: boolean
}

export function FeriaFormDialog({
  open,
  onOpenChange,
  feria,
  onSubmit,
  isLoading,
}: FeriaFormDialogProps) {
  const isEditing = !!feria

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors },
  } = useForm<IFeriaForm>({
    resolver: zodResolver(schema),
    defaultValues: {
      codigo: '',
      descripcion: '',
      facturacion_publico: false,
    },
  })

  useEffect(() => {
    if (open) {
      reset({
        codigo: feria?.codigo ?? '',
        descripcion: feria?.descripcion ?? '',
        facturacion_publico: feria?.facturacion_publico ?? false,
      })
    }
  }, [open, feria, reset])

  const facturacionPublico = watch('facturacion_publico')

  const handleFormSubmit = async (data: IFeriaForm) => {
    await onSubmit(data)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{isEditing ? 'Editar Feria' : 'Nueva Feria'}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="codigo">
              Código <span className="text-destructive">*</span>
            </Label>
            <Input
              id="codigo"
              {...register('codigo')}
              placeholder="Ej. FAG001"
              disabled={isLoading}
            />
            {errors.codigo && (
              <p className="text-xs text-destructive">{errors.codigo.message}</p>
            )}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="descripcion">
              Descripción <span className="text-destructive">*</span>
            </Label>
            <Input
              id="descripcion"
              {...register('descripcion')}
              placeholder="Ej. Feria del Agricultor de Guadalupe"
              disabled={isLoading}
            />
            {errors.descripcion && (
              <p className="text-xs text-destructive">{errors.descripcion.message}</p>
            )}
          </div>

          <div className="flex items-center justify-between rounded-lg border p-3">
            <div className="space-y-0.5">
              <Label htmlFor="facturacion_publico">Facturación a público general</Label>
              <p className="text-xs text-muted-foreground">
                Permite emitir facturas a personas sin registro
              </p>
            </div>
            <Switch
              id="facturacion_publico"
              checked={facturacionPublico}
              onCheckedChange={(checked) => setValue('facturacion_publico', checked)}
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
              {isEditing ? 'Guardar cambios' : 'Crear feria'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
