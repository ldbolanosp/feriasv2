import { useNavigate, useLocation } from 'react-router-dom'
import { ChevronDown, LogOut, KeyRound } from 'lucide-react'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { useAuthStore } from '@/stores/authStore'
import { useFeriaStore } from '@/stores/feriaStore'
import { logout } from '@/services/authService'

const pageTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/facturacion': 'Facturación',
  '/parqueos': 'Parqueo',
  '/tarimas': 'Tarimas',
  '/sanitarios': 'Sanitarios',
  '/configuracion': 'Configuración',
  '/configuracion/ferias': 'Ferias',
  '/configuracion/participantes': 'Participantes',
  '/configuracion/productos': 'Productos',
  '/configuracion/metodos-pago': 'Métodos de pago',
  '/configuracion/usuarios': 'Usuarios y roles',
}

function getPageTitle(pathname: string): string {
  const match = Object.entries(pageTitles)
    .filter(([path]) => pathname.startsWith(path))
    .sort(([leftPath], [rightPath]) => rightPath.length - leftPath.length)[0]

  return match?.[1] ?? 'Ferias CR'
}

export function TopBar() {
  const navigate = useNavigate()
  const location = useLocation()
  const { user, roles, clearAuth } = useAuthStore()
  const { feriaActiva, clearFeria } = useFeriaStore()

  const initials = user?.name
    ? user.name
        .split(' ')
        .slice(0, 2)
        .map((n) => n[0])
        .join('')
        .toUpperCase()
    : '?'

  async function handleLogout() {
    try {
      await logout()
    } finally {
      clearAuth()
      clearFeria()
      navigate('/login')
    }
  }

  return (
    <header className="flex h-16 shrink-0 items-center gap-3 border-b bg-background/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-background/80">
      <h1 className="flex-1 pl-12 text-sm font-semibold tracking-tight md:pl-0 md:text-lg">
        {getPageTitle(location.pathname)}
      </h1>

      <div className="flex min-w-0 items-center gap-2 sm:gap-3">
        {feriaActiva && (
          <Button
            variant="outline"
            size="sm"
            className="min-w-0 max-w-[52vw] gap-1.5 sm:max-w-none"
            onClick={() => navigate('/seleccionar-feria')}
          >
            <Badge variant="secondary" className="pointer-events-none">
              {feriaActiva.codigo}
            </Badge>
            <span className="hidden truncate text-xs text-muted-foreground sm:inline">
              {feriaActiva.descripcion}
            </span>
            <ChevronDown className="size-3 text-muted-foreground" />
          </Button>
        )}

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="relative size-9 rounded-full p-0">
              <Avatar className="size-9">
                <AvatarFallback className="text-xs">{initials}</AvatarFallback>
              </Avatar>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>
              <p className="font-medium">{user?.name}</p>
              <p className="text-xs text-muted-foreground">{roles[0] ?? ''}</p>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => navigate('/perfil/password')}>
              <KeyRound className="mr-2 size-4" />
              Cambiar contraseña
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              onClick={handleLogout}
              className="text-destructive focus:text-destructive"
            >
              <LogOut className="mr-2 size-4" />
              Cerrar sesión
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  )
}
