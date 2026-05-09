import { useEffect, useState } from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import {
  LayoutDashboard,
  Receipt,
  Car,
  Box,
  Droplets,
  ClipboardList,
  ClipboardCheck,
  Settings,
  MapPin,
  Users,
  Package,
  UserCog,
  CreditCard,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Menu,
  X,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { usePermission } from '@/hooks/usePermission'
import { Button } from '@/components/ui/button'

interface NavItem {
  label: string
  to: string
  icon: React.ReactNode
  permission?: string
  exact?: boolean
  children?: NavItem[]
}

const navItems: NavItem[] = [
  {
    label: 'Dashboard',
    to: '/dashboard',
    icon: <LayoutDashboard className="size-4" />,
    permission: 'dashboard.ver',
  },
  {
    label: 'Facturación',
    to: '/facturacion',
    icon: <Receipt className="size-4" />,
    permission: 'facturas.ver',
  },
  {
    label: 'Parqueo',
    to: '/parqueos',
    icon: <Car className="size-4" />,
    permission: 'parqueos.ver',
  },
  {
    label: 'Tarimas',
    to: '/tarimas',
    icon: <Box className="size-4" />,
    permission: 'tarimas.ver',
  },
  {
    label: 'Sanitarios',
    to: '/sanitarios',
    icon: <Droplets className="size-4" />,
    permission: 'sanitarios.ver',
  },
  {
    label: 'Inspecciones',
    to: '/inspecciones',
    icon: <ClipboardList className="size-4" />,
    permission: 'inspecciones.ver',
  },
  {
    label: 'Configuración',
    to: '/configuracion',
    icon: <Settings className="size-4" />,
    children: [
      {
        label: 'Parámetros',
        to: '/configuracion',
        icon: <Settings className="size-4" />,
        permission: 'configuracion.editar',
        exact: true,
      },
      {
        label: 'Ferias',
        to: '/configuracion/ferias',
        icon: <MapPin className="size-4" />,
        permission: 'ferias.ver',
      },
      {
        label: 'Participantes',
        to: '/configuracion/participantes',
        icon: <Users className="size-4" />,
        permission: 'participantes.ver',
      },
      {
        label: 'Productos',
        to: '/configuracion/productos',
        icon: <Package className="size-4" />,
        permission: 'productos.ver',
      },
      {
        label: 'Items de Inspección',
        to: '/configuracion/items-diagnostico',
        icon: <ClipboardCheck className="size-4" />,
        permission: 'configuracion.ver',
      },
      {
        label: 'Métodos de pago',
        to: '/configuracion/metodos-pago',
        icon: <CreditCard className="size-4" />,
        permission: 'configuracion.ver',
      },
      {
        label: 'Usuarios y roles',
        to: '/configuracion/usuarios',
        icon: <UserCog className="size-4" />,
        permission: 'usuarios.ver',
      },
    ],
  },
]

interface NavItemLinkProps {
  item: NavItem
  collapsed?: boolean
  depth?: number
  onNavigate?: () => void
}

function NavItemLink({
  item,
  collapsed = false,
  depth = 0,
  onNavigate,
}: NavItemLinkProps) {
  const { hasPermission } = usePermission()
  const location = useLocation()
  const [open, setOpen] = useState(() =>
    item.children?.some((child) => location.pathname.startsWith(child.to)) ?? false,
  )

  if (item.permission && !hasPermission(item.permission)) {
    return null
  }

  if (item.children) {
    const visibleChildren = item.children.filter(
      (child) => !child.permission || hasPermission(child.permission),
    )
    if (visibleChildren.length === 0) return null

    return (
      <div>
        <button
          type="button"
          title={collapsed ? item.label : undefined}
          onClick={() => setOpen((prev) => !prev)}
          className={cn(
            'flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground',
            collapsed && 'justify-center px-2',
          )}
        >
          {item.icon}
          {!collapsed && <span className="flex-1 text-left">{item.label}</span>}
          {!collapsed &&
            (open ? <ChevronDown className="size-3" /> : <ChevronRight className="size-3" />)}
        </button>
        {open && (
          <div
            className={cn(
              'mt-1 space-y-1',
              collapsed ? 'flex flex-col items-center' : 'ml-4',
            )}
          >
            {visibleChildren.map((child) => (
              <NavItemLink
                key={child.to}
                item={child}
                collapsed={collapsed}
                depth={depth + 1}
                onNavigate={onNavigate}
              />
            ))}
          </div>
        )}
      </div>
    )
  }

  return (
    <NavLink
      to={item.to}
      end={item.exact}
      title={collapsed ? item.label : undefined}
      onClick={onNavigate}
      className={({ isActive }) =>
        cn(
          'flex items-center gap-2 rounded-md px-3 py-2 text-sm font-medium transition-colors',
          collapsed && 'justify-center px-2',
          depth > 0 && !collapsed && 'pl-4',
          isActive
            ? 'bg-primary text-primary-foreground'
            : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground',
        )
      }
    >
      {item.icon}
      {!collapsed && item.label}
    </NavLink>
  )
}

export function Sidebar() {
  const [mobileOpen, setMobileOpen] = useState(false)
  const [tabletCollapsed, setTabletCollapsed] = useState(false)
  const location = useLocation()

  useEffect(() => {
    setMobileOpen(false)
  }, [location.pathname])

  useEffect(() => {
    const mediaQuery = window.matchMedia('(min-width: 768px) and (max-width: 1279px)')

    const updateCollapsed = (matches: boolean) => {
      setTabletCollapsed(matches)
    }

    updateCollapsed(mediaQuery.matches)

    const handleChange = (event: MediaQueryListEvent) => {
      updateCollapsed(event.matches)
    }

    mediaQuery.addEventListener('change', handleChange)

    return () => {
      mediaQuery.removeEventListener('change', handleChange)
    }
  }, [])

  const sidebarContent = (
    <div className="flex h-full flex-col gap-1 p-3">
      <div
        className={cn(
          'mb-4 flex items-center px-3 py-2',
          tabletCollapsed ? 'justify-center md:px-2 xl:justify-between xl:px-3' : 'justify-between',
        )}
      >
        <span
          className={cn(
            'text-lg font-bold tracking-tight',
            tabletCollapsed && 'md:hidden xl:inline',
          )}
        >
          Ferias CR
        </span>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="hidden md:inline-flex xl:hidden"
          onClick={() => setTabletCollapsed((prev) => !prev)}
        >
          {tabletCollapsed ? <ChevronRight className="size-4" /> : <ChevronLeft className="size-4" />}
        </Button>
      </div>
      <nav className="flex flex-col gap-1">
        {navItems.map((item) => (
          <NavItemLink
            key={item.to}
            item={item}
            collapsed={tabletCollapsed}
            onNavigate={() => setMobileOpen(false)}
          />
        ))}
      </nav>
    </div>
  )

  return (
    <>
      {/* Mobile toggle */}
      <Button
        variant="ghost"
        size="icon"
        className="fixed left-4 top-4 z-50 md:hidden"
        onClick={() => setMobileOpen((prev) => !prev)}
      >
        {mobileOpen ? <X className="size-5" /> : <Menu className="size-5" />}
      </Button>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 md:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Mobile sidebar */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-40 w-72 max-w-[85vw] border-r bg-background transition-transform md:hidden',
          mobileOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        {sidebarContent}
      </aside>

      {/* Desktop sidebar */}
      <aside
        className={cn(
          'hidden shrink-0 border-r bg-background transition-[width] duration-200 md:block',
          tabletCollapsed ? 'md:w-20 xl:w-64' : 'md:w-64',
        )}
      >
        {sidebarContent}
      </aside>
    </>
  )
}
