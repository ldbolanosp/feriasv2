import { useEffect } from 'react'
import { useForm, type FieldPath } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { isAxiosError } from 'axios'
import { Loader2 } from 'lucide-react'
import { z } from 'zod'
import { FormField } from '@/components/shared/FormField'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Switch } from '@/components/ui/switch'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useFerias } from '@/hooks/useFerias'
import {
  etiquetaRolUsuario,
  ROLES_USUARIO,
  type IUsuario,
  type IUsuarioFormPayload,
  type TRolUsuario,
} from '@/types/usuario'

const roleEnum = ROLES_USUARIO as unknown as [TRolUsuario, ...TRolUsuario[]]

const createSchema = (isEditing: boolean) =>
  z
    .object({
      name: z.string().min(1, 'El nombre es requerido').max(255, 'Máximo 255 caracteres'),
      email: z
        .string()
        .min(1, 'El correo electrónico es requerido')
        .email('Correo electrónico no válido')
        .max(255, 'Máximo 255 caracteres'),
      password: isEditing
        ? z.string()
        : z.string().min(8, 'La contraseña debe tener al menos 8 caracteres'),
      password_confirmation: isEditing ? z.string() : z.string(),
      role: z.enum(roleEnum, { message: 'Seleccione un rol válido' }),
      ferias: z.array(z.number()).min(1, 'Seleccione al menos una feria'),
      activo: z.boolean(),
    })
    .superRefine((values, ctx) => {
      const hasPassword = values.password.trim() !== '' || values.password_confirmation.trim() !== ''

      if (!isEditing && !hasPassword) {
        ctx.addIssue({
          code: 'custom',
          message: 'La contraseña es requerida.',
          path: ['password'],
        })
      }

      if (!isEditing || hasPassword) {
        if (values.password.trim().length < 8) {
          ctx.addIssue({
            code: 'custom',
            message: 'La contraseña debe tener al menos 8 caracteres.',
            path: ['password'],
          })
        }

        if (values.password !== values.password_confirmation) {
          ctx.addIssue({
            code: 'custom',
            message: 'La confirmación de la contraseña no coincide.',
            path: ['password_confirmation'],
          })
        }
      }
    })

type UsuarioFormValues = z.infer<ReturnType<typeof createSchema>>

const defaultValues: UsuarioFormValues = {
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
  role: 'facturador',
  ferias: [],
  activo: true,
}

function usuarioAValores(usuario: IUsuario): UsuarioFormValues {
  return {
    name: usuario.name,
    email: usuario.email,
    password: '',
    password_confirmation: '',
    role: (usuario.role as TRolUsuario | null) ?? 'facturador',
    ferias: usuario.ferias.map((feria) => feria.id),
    activo: usuario.activo,
  }
}

interface UsuarioFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  usuario?: IUsuario | null
  onSubmit: (payload: IUsuarioFormPayload) => Promise<void>
  isLoading: boolean
}

export function UsuarioFormDialog({
  open,
  onOpenChange,
  usuario,
  onSubmit,
  isLoading,
}: UsuarioFormDialogProps) {
  const isEditing = !!usuario
  const { data: feriasData, isLoading: isLoadingFerias } = useFerias({ page: 1, per_page: 100 })

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    setError,
    formState: { errors },
  } = useForm<UsuarioFormValues>({
    resolver: zodResolver(createSchema(isEditing)),
    defaultValues,
  })

  useEffect(() => {
    if (!open) {
      return
    }

    reset(usuario ? usuarioAValores(usuario) : defaultValues)
  }, [open, usuario, reset])

  const activo = watch('activo')
  const role = watch('role')
  const feriaIds = watch('ferias')

  const handleToggleFeria = (feriaId: number, checked: boolean) => {
    const current = new Set(feriaIds)

    if (checked) {
      current.add(feriaId)
    } else {
      current.delete(feriaId)
    }

    setValue('ferias', Array.from(current), { shouldValidate: true })
  }

  const handleFormSubmit = async (values: UsuarioFormValues) => {
    try {
      await onSubmit({
        name: values.name.trim(),
        email: values.email.trim(),
        activo: values.activo,
        role: values.role,
        ferias: values.ferias,
        password: values.password.trim() === '' ? undefined : values.password,
        password_confirmation:
          values.password_confirmation.trim() === '' ? undefined : values.password_confirmation,
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
          setError(field as FieldPath<UsuarioFormValues>, { message })
        }
      }
    }
  }

  const ferias = feriasData?.data ?? []

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{isEditing ? 'Editar usuario' : 'Nuevo usuario'}</DialogTitle>
          <DialogDescription>
            Defina los datos básicos, el rol principal y las ferias a las que tendrá acceso.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-5">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Nombre" error={errors.name?.message} required>
              <Input
                {...register('name')}
                placeholder="Ej. María Rodríguez"
                disabled={isLoading}
              />
            </FormField>

            <FormField label="Correo electrónico" error={errors.email?.message} required>
              <Input
                {...register('email')}
                type="email"
                placeholder="usuario@ferias.cr"
                disabled={isLoading}
              />
            </FormField>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <FormField
              label={isEditing ? 'Nueva contraseña' : 'Contraseña'}
              error={errors.password?.message}
              required={!isEditing}
            >
              <Input
                {...register('password')}
                type="password"
                placeholder={isEditing ? 'Opcional para cambiarla' : 'Mínimo 8 caracteres'}
                disabled={isLoading}
              />
            </FormField>

            <FormField
              label="Confirmación de contraseña"
              error={errors.password_confirmation?.message}
              required={!isEditing}
            >
              <Input
                {...register('password_confirmation')}
                type="password"
                placeholder="Repita la contraseña"
                disabled={isLoading}
              />
            </FormField>
          </div>

          <div className="grid gap-4 md:grid-cols-[minmax(0,240px)_1fr]">
            <FormField label="Rol" error={errors.role?.message} required>
              <Select
                value={role}
                onValueChange={(value) =>
                  setValue('role', value as TRolUsuario, { shouldValidate: true })
                }
                disabled={isLoading}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Seleccione un rol" />
                </SelectTrigger>
                <SelectContent>
                  {ROLES_USUARIO.map((rol) => (
                    <SelectItem key={rol} value={rol}>
                      {etiquetaRolUsuario(rol)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </FormField>

            <div className="flex items-center justify-between rounded-lg border p-3">
              <div className="space-y-0.5">
                <p className="text-sm font-medium">Estado del usuario</p>
                <p className="text-xs text-muted-foreground">
                  Si se desactiva, el usuario no podrá iniciar sesión.
                </p>
              </div>
              <Switch
                checked={activo}
                onCheckedChange={(checked) =>
                  setValue('activo', checked, { shouldValidate: true })
                }
                disabled={isLoading}
              />
            </div>
          </div>

          <FormField label="Ferias asignadas" error={errors.ferias?.message} required>
            <div className="rounded-xl border">
              <div className="border-b px-4 py-3">
                <div className="flex flex-wrap gap-2">
                  {feriaIds.length === 0 ? (
                    <span className="text-sm text-muted-foreground">Sin ferias seleccionadas.</span>
                  ) : (
                    feriaIds.map((feriaId) => {
                      const feria = ferias.find((item) => item.id === feriaId)

                      return (
                        <Badge key={feriaId} variant="secondary">
                          {feria ? `${feria.codigo} · ${feria.descripcion}` : `Feria #${feriaId}`}
                        </Badge>
                      )
                    })
                  )}
                </div>
              </div>

              <div className="max-h-64 space-y-2 overflow-y-auto p-4">
                {isLoadingFerias ? (
                  <p className="text-sm text-muted-foreground">Cargando ferias…</p>
                ) : ferias.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No hay ferias disponibles.</p>
                ) : (
                  ferias.map((feria) => (
                    <label
                      key={feria.id}
                      htmlFor={`usuario-feria-${feria.id}`}
                      className="flex cursor-pointer items-start gap-3 rounded-lg border p-3 transition-colors hover:bg-muted/40"
                    >
                      <input
                        id={`usuario-feria-${feria.id}`}
                        type="checkbox"
                        className="mt-1 size-4 rounded border-input"
                        checked={feriaIds.includes(feria.id)}
                        disabled={isLoading || !feria.activa}
                        onChange={(event) => handleToggleFeria(feria.id, event.target.checked)}
                      />
                      <div className="min-w-0">
                        <p className="font-medium">
                          {feria.codigo} · {feria.descripcion}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {feria.activa ? 'Feria activa' : 'Feria inactiva'}
                        </p>
                      </div>
                    </label>
                  ))
                )}
              </div>
            </div>
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
              {isEditing ? 'Guardar cambios' : 'Crear usuario'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
