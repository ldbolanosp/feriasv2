import { useState } from 'react'
import type { ColumnDef, SortingState } from '@tanstack/react-table'
import { MoreHorizontal, Plus } from 'lucide-react'
import { PageHeader } from '@/components/shared/PageHeader'
import { DataTable } from '@/components/shared/DataTable'
import { FilterBar } from '@/components/shared/FilterBar'
import { SearchInput } from '@/components/shared/SearchInput'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { usePermission } from '@/hooks/usePermission'
import {
  useCreateUsuario,
  useDeleteUsuario,
  useToggleUsuario,
  useUpdateUsuario,
  useUsuarios,
} from '@/hooks/useUsuarios'
import {
  etiquetaRolUsuario,
  ROLES_USUARIO,
  type IUsuario,
  type IUsuarioFormPayload,
  type TRolUsuario,
} from '@/types/usuario'
import { SesionesDialog } from './SesionesDialog'
import { UsuarioFormDialog } from './UsuarioFormDialog'

type EstadoFiltro = 'todos' | 'activos' | 'inactivos'
type RolFiltro = 'todos' | TRolUsuario

function roleBadgeVariant(role: string | null): 'default' | 'secondary' | 'outline' {
  if (role === 'administrador') {
    return 'default'
  }

  if (role === 'supervisor') {
    return 'secondary'
  }

  return 'outline'
}

export function UsuariosPage() {
  const { hasPermission } = usePermission()

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [estadoFiltro, setEstadoFiltro] = useState<EstadoFiltro>('todos')
  const [rolFiltro, setRolFiltro] = useState<RolFiltro>('todos')
  const [sorting, setSorting] = useState<SortingState>([])
  const [formOpen, setFormOpen] = useState(false)
  const [sesionesOpen, setSesionesOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [selectedUsuario, setSelectedUsuario] = useState<IUsuario | null>(null)

  const activoParam =
    estadoFiltro === 'activos' ? true : estadoFiltro === 'inactivos' ? false : null

  const sort = sorting[0]?.id
  const direction = sorting[0]?.desc ? 'desc' : 'asc'

  const { data, isLoading, isFetching } = useUsuarios({
    page,
    per_page: 15,
    search: search || undefined,
    activo: activoParam,
    role: rolFiltro === 'todos' ? undefined : rolFiltro,
    sort,
    direction,
  })

  const createMutation = useCreateUsuario()
  const updateMutation = useUpdateUsuario()
  const toggleMutation = useToggleUsuario()
  const deleteMutation = useDeleteUsuario()

  const usuarios = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }
  const isSaving = createMutation.isPending || updateMutation.isPending

  const handleSearchChange = (value: string) => {
    setSearch(value)
    setPage(1)
  }

  const handleEstadoChange = (value: string) => {
    setEstadoFiltro(value as EstadoFiltro)
    setPage(1)
  }

  const handleRolChange = (value: string) => {
    setRolFiltro(value as RolFiltro)
    setPage(1)
  }

  const handleSortingChange = (nextSorting: SortingState) => {
    setSorting(nextSorting)
    setPage(1)
  }

  const handleOpenCreate = () => {
    setSelectedUsuario(null)
    setFormOpen(true)
  }

  const handleOpenEdit = (usuario: IUsuario) => {
    setSelectedUsuario(usuario)
    setFormOpen(true)
  }

  const handleOpenSesiones = (usuario: IUsuario) => {
    setSelectedUsuario(usuario)
    setSesionesOpen(true)
  }

  const handleAskDelete = (usuario: IUsuario) => {
    setSelectedUsuario(usuario)
    setDeleteDialogOpen(true)
  }

  const handleFormSubmit = async (payload: IUsuarioFormPayload) => {
    if (selectedUsuario) {
      await updateMutation.mutateAsync({ id: selectedUsuario.id, payload })
    } else {
      await createMutation.mutateAsync(payload)
    }

    setFormOpen(false)
  }

  const handleToggle = (usuario: IUsuario) => {
    toggleMutation.mutate(usuario.id)
  }

  const handleDelete = async () => {
    if (!selectedUsuario) {
      return
    }

    await deleteMutation.mutateAsync(selectedUsuario.id)
    setDeleteDialogOpen(false)
  }

  const columns: ColumnDef<IUsuario>[] = [
    {
      accessorKey: 'name',
      header: 'Nombre',
      enableSorting: true,
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.name}</p>
          <p className="text-xs text-muted-foreground">ID #{row.original.id}</p>
        </div>
      ),
    },
    {
      accessorKey: 'email',
      header: 'Email',
      enableSorting: true,
      cell: ({ row }) => (
        <div className="max-w-[280px] truncate text-sm">{row.original.email}</div>
      ),
    },
    {
      accessorKey: 'role',
      header: 'Rol',
      cell: ({ row }) => (
        <Badge variant={roleBadgeVariant(row.original.role)}>
          {etiquetaRolUsuario(row.original.role)}
        </Badge>
      ),
    },
    {
      accessorKey: 'ferias_count',
      header: 'Ferias',
      enableSorting: true,
      cell: ({ row }) => (
        <div className="space-y-1">
          <p className="font-medium">
            {row.original.ferias_count} feria{row.original.ferias_count === 1 ? '' : 's'}
          </p>
          <p className="text-xs text-muted-foreground">
            {row.original.ferias
              .slice(0, 2)
              .map((feria) => feria.codigo)
              .join(', ') || 'Sin asignar'}
          </p>
        </div>
      ),
    },
    {
      accessorKey: 'activo',
      header: 'Estado',
      enableSorting: true,
      cell: ({ row }) => <StatusBadge status={row.original.activo ? 'activo' : 'inactivo'} />,
    },
    {
      id: 'acciones',
      header: '',
      cell: ({ row }) => {
        const usuario = row.original
        const canEdit = hasPermission('usuarios.editar')
        const canToggle = hasPermission('usuarios.activar')
        const canDelete = hasPermission('usuarios.eliminar')
        const canSessions = hasPermission('usuarios.sesiones')

        if (!canEdit && !canToggle && !canDelete && !canSessions) {
          return null
        }

        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="size-8">
                <MoreHorizontal className="size-4" />
                <span className="sr-only">Acciones</span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              {canEdit && (
                <DropdownMenuItem onClick={() => handleOpenEdit(usuario)}>
                  Editar
                </DropdownMenuItem>
              )}
              {canSessions && (
                <DropdownMenuItem onClick={() => handleOpenSesiones(usuario)}>
                  Sesiones
                </DropdownMenuItem>
              )}
              {canToggle && (
                <DropdownMenuItem
                  onClick={() => handleToggle(usuario)}
                  disabled={toggleMutation.isPending}
                >
                  {usuario.activo ? 'Desactivar' : 'Activar'}
                </DropdownMenuItem>
              )}
              {canDelete && (
                <DropdownMenuItem
                  onClick={() => handleAskDelete(usuario)}
                  className="text-destructive focus:text-destructive"
                  disabled={deleteMutation.isPending}
                >
                  Eliminar
                </DropdownMenuItem>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Usuarios"
        description="Administre los accesos al sistema, sus roles y las ferias asignadas."
        action={
          hasPermission('usuarios.crear')
            ? {
                label: 'Nuevo usuario',
                icon: Plus,
                onClick: handleOpenCreate,
              }
            : undefined
        }
      />

      <div className="space-y-3">
        <FilterBar>
          <SearchInput
            value={search}
            onChange={handleSearchChange}
            placeholder="Buscar por nombre o correo..."
            className="w-full sm:w-72"
          />
          <Select value={estadoFiltro} onValueChange={handleEstadoChange}>
            <SelectTrigger className="w-full sm:w-40">
              <SelectValue placeholder="Estado" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos</SelectItem>
              <SelectItem value="activos">Activos</SelectItem>
              <SelectItem value="inactivos">Inactivos</SelectItem>
            </SelectContent>
          </Select>
          <Select value={rolFiltro} onValueChange={handleRolChange}>
            <SelectTrigger className="w-full sm:w-44">
              <SelectValue placeholder="Rol" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos los roles</SelectItem>
              {ROLES_USUARIO.map((rol) => (
                <SelectItem key={rol} value={rol}>
                  {etiquetaRolUsuario(rol)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </FilterBar>

        <DataTable
          columns={columns}
          data={usuarios}
          isLoading={isLoading}
          isFetching={isFetching}
          pagination={{
            page: meta.current_page,
            pageSize: meta.per_page,
            total: meta.total,
          }}
          onPaginationChange={setPage}
          onSortChange={handleSortingChange}
        />
      </div>

      <UsuarioFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        usuario={selectedUsuario}
        onSubmit={handleFormSubmit}
        isLoading={isSaving}
      />

      <SesionesDialog
        open={sesionesOpen}
        onOpenChange={setSesionesOpen}
        usuario={selectedUsuario}
      />

      <ConfirmDialog
        open={deleteDialogOpen}
        onCancel={() => setDeleteDialogOpen(false)}
        onConfirm={handleDelete}
        title="Eliminar usuario"
        description={
          selectedUsuario
            ? `Se eliminará ${selectedUsuario.name}, se desactivará la cuenta y se cerrarán sus sesiones activas.`
            : 'Se eliminará el usuario seleccionado.'
        }
        confirmText="Eliminar usuario"
        variant="destructive"
      />
    </div>
  )
}
