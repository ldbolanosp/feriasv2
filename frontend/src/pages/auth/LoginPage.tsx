import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuthStore } from '@/stores/authStore'
import { useFeriaStore } from '@/stores/feriaStore'
import { login } from '@/services/authService'

const schema = z.object({
  email: z.string().min(1, 'El correo es requerido').email('El correo no es válido'),
  password: z.string().min(1, 'La contraseña es requerida'),
})

type FormValues = z.infer<typeof schema>

export function LoginPage() {
  const navigate = useNavigate()
  const { setUser } = useAuthStore()
  const { setFerias, setFeriaActiva } = useFeriaStore()

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) })

  async function onSubmit(values: FormValues) {
    try {
      const data = await login(values)
      setUser(data.user, data.roles, data.permisos, data.ferias)
      setFerias(data.ferias)

      if (data.ferias.length === 1) {
        setFeriaActiva(data.ferias[0])
        navigate('/dashboard')
      } else if (data.ferias.length > 1) {
        navigate('/seleccionar-feria')
      } else {
        setError('root', { message: 'Tu cuenta no tiene ferias asignadas.' })
      }
    } catch (err: unknown) {
      const status = (err as { response?: { status: number; data?: { message?: string } } })
        ?.response?.status
      const message =
        (err as { response?: { data?: { message?: string } } })?.response?.data?.message ??
        'Error al iniciar sesión.'

      if (status === 401 || status === 403) {
        setError('root', { message })
      } else {
        setError('root', { message })
      }
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/40 p-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">Ferias CR</CardTitle>
          <p className="text-sm text-muted-foreground">Ingresa tus credenciales para continuar</p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
            <div className="space-y-1.5">
              <Label htmlFor="email">Correo electrónico</Label>
              <Input
                id="email"
                type="email"
                placeholder="usuario@ferias.cr"
                autoComplete="email"
                aria-invalid={!!errors.email}
                {...register('email')}
              />
              {errors.email && (
                <p className="text-xs text-destructive">{errors.email.message}</p>
              )}
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="password">Contraseña</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                aria-invalid={!!errors.password}
                {...register('password')}
              />
              {errors.password && (
                <p className="text-xs text-destructive">{errors.password.message}</p>
              )}
            </div>

            {errors.root && (
              <p className="text-sm text-destructive">{errors.root.message}</p>
            )}

            <Button type="submit" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? 'Ingresando...' : 'Ingresar'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
