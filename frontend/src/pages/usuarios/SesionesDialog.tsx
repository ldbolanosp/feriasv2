import { Laptop, Loader2, LogOut, ShieldCheck, Smartphone, Tablet, XCircle } from 'lucide-react'
import { EmptyState } from '@/components/shared/EmptyState'
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
import { Separator } from '@/components/ui/separator'
import {
  useCerrarSesionUsuario,
  useCerrarTodasLasSesionesUsuario,
  useUsuarioSesiones,
} from '@/hooks/useUsuarios'
import type { IUsuario } from '@/types/usuario'

interface SesionesDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  usuario: IUsuario | null
}

function formatDateTime(value: string): string {
  return new Intl.DateTimeFormat('es-CR', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function SessionDeviceIcon({ device }: { device: string }) {
  if (device === 'Móvil') {
    return <Smartphone className="size-4" />
  }

  if (device === 'Tablet') {
    return <Tablet className="size-4" />
  }

  return <Laptop className="size-4" />
}

export function SesionesDialog({ open, onOpenChange, usuario }: SesionesDialogProps) {
  const usuarioId = usuario?.id ?? null

  const { data: sesiones = [], isLoading, isFetching } = useUsuarioSesiones(usuarioId, open)
  const cerrarSesion = useCerrarSesionUsuario()
  const cerrarTodas = useCerrarTodasLasSesionesUsuario()

  const isBusy = cerrarSesion.isPending || cerrarTodas.isPending

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>Sesiones activas</DialogTitle>
          <DialogDescription>
            {usuario
              ? `Administre las sesiones abiertas de ${usuario.name}.`
              : 'Seleccione un usuario para ver sus sesiones.'}
          </DialogDescription>
        </DialogHeader>

        {!usuario ? (
          <EmptyState
            title="No hay usuario seleccionado"
            description="Cierre este panel e inténtelo nuevamente."
            className="py-10"
          />
        ) : isLoading ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 className="size-7 animate-spin text-muted-foreground" />
          </div>
        ) : sesiones.length === 0 ? (
          <EmptyState
            icon={ShieldCheck}
            title="Sin sesiones activas"
            description="Este usuario no tiene sesiones registradas en este momento."
            className="py-10"
          />
        ) : (
          <div className="space-y-4">
            <div className="flex items-center justify-between rounded-xl border bg-muted/20 px-4 py-3">
              <div>
                <p className="font-medium">{sesiones.length} sesiones registradas</p>
                <p className="text-sm text-muted-foreground">
                  {isFetching ? 'Actualizando listado…' : 'Puede cerrar sesiones individuales o todas.'}
                </p>
              </div>
              <Button
                variant="outline"
                onClick={() => cerrarTodas.mutate(usuario.id)}
                disabled={isBusy}
              >
                {cerrarTodas.isPending ? (
                  <Loader2 className="size-4 animate-spin" />
                ) : (
                  <XCircle className="size-4" />
                )}
                Cerrar todas
              </Button>
            </div>

            <div className="rounded-xl border">
              {sesiones.map((sesion, index) => (
                <div key={sesion.id}>
                  {index > 0 && <Separator />}
                  <div className="flex flex-col gap-4 p-4 md:flex-row md:items-center md:justify-between">
                    <div className="space-y-2">
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge variant="outline" className="gap-1">
                          <SessionDeviceIcon device={sesion.device} />
                          {sesion.browser}
                        </Badge>
                        <Badge variant="secondary">{sesion.platform}</Badge>
                        <Badge variant="secondary">{sesion.device}</Badge>
                        {sesion.is_current && <Badge>Actual</Badge>}
                      </div>

                      <div className="space-y-1 text-sm text-muted-foreground">
                        <p>IP: {sesion.ip_address ?? 'No disponible'}</p>
                        <p>Última actividad: {formatDateTime(sesion.last_activity)}</p>
                        <p className="break-all">
                          User agent: {sesion.user_agent ?? 'No disponible'}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 md:self-start">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() =>
                          cerrarSesion.mutate({ userId: usuario.id, sessionId: sesion.id })
                        }
                        disabled={isBusy}
                      >
                        {cerrarSesion.isPending ? (
                          <Loader2 className="size-4 animate-spin" />
                        ) : (
                          <LogOut className="size-4" />
                        )}
                        Cerrar sesión
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <DialogFooter>
          <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
            Cerrar
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
