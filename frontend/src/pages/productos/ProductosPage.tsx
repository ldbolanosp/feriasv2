import { useState } from 'react'
import type { SortingState, ColumnDef } from '@tanstack/react-table'
import { MoreHorizontal, Plus } from 'lucide-react'
import { isAxiosError } from 'axios'
import { PageHeader } from '@/components/shared/PageHeader'
import { DataTable } from '@/components/shared/DataTable'
import { SearchInput } from '@/components/shared/SearchInput'
import { FilterBar } from '@/components/shared/FilterBar'
import { StatusBadge } from '@/components/shared/StatusBadge'
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
  useCreateProducto,
  useProductos,
  useToggleProducto,
  useUpdateProducto,
} from '@/hooks/useProductos'
import type { IProducto, IProductoFormPayload } from '@/types/producto'
import { ProductoFormDialog } from './ProductoFormDialog'
import { ProductoPreciosDialog } from './ProductoPreciosDialog'

type EstadoFiltro = 'todos' | 'activos' | 'inactivos'

export function ProductosPage() {
  const { hasPermission } = usePermission()

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [estadoFiltro, setEstadoFiltro] = useState<EstadoFiltro>('todos')
  const [sorting, setSorting] = useState<SortingState>([])
  const [formOpen, setFormOpen] = useState(false)
  const [preciosOpen, setPreciosOpen] = useState(false)
  const [selectedProducto, setSelectedProducto] = useState<IProducto | null>(null)

  const activoParam =
    estadoFiltro === 'activos' ? true : estadoFiltro === 'inactivos' ? false : null

  const sort = sorting[0]?.id
  const direction = sorting[0]?.desc ? 'desc' : 'asc'

  const { data, isLoading, isFetching } = useProductos({
    page,
    per_page: 15,
    search: search || undefined,
    activo: activoParam,
    sort,
    direction,
  })

  const createMutation = useCreateProducto()
  const updateMutation = useUpdateProducto()
  const toggleMutation = useToggleProducto()

  const productos = data?.data ?? []
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

  const handleSortingChange = (nextSorting: SortingState) => {
    setSorting(nextSorting)
    setPage(1)
  }

  const handleOpenCreate = () => {
    setSelectedProducto(null)
    setFormOpen(true)
  }

  const handleOpenEdit = (producto: IProducto) => {
    setSelectedProducto(producto)
    setFormOpen(true)
  }

  const handleOpenPrecios = (producto: IProducto) => {
    setSelectedProducto(producto)
    setPreciosOpen(true)
  }

  const handleFormSubmit = async (payload: IProductoFormPayload) => {
    if (selectedProducto) {
      await updateMutation.mutateAsync({ id: selectedProducto.id, payload })
    } else {
      await createMutation.mutateAsync(payload)
    }

    setFormOpen(false)
  }

  const handleToggle = (producto: IProducto) => {
    toggleMutation.mutate(producto.id)
  }

  const columns: ColumnDef<IProducto>[] = [
    {
      accessorKey: 'codigo',
      header: 'Código',
      enableSorting: true,
    },
    {
      accessorKey: 'descripcion',
      header: 'Descripción',
      enableSorting: true,
      cell: ({ row }) => (
        <div className="max-w-[320px] truncate font-medium">{row.original.descripcion}</div>
      ),
    },
    {
      accessorKey: 'precios_count',
      header: 'Precios',
      enableSorting: true,
      cell: ({ row }) => (
        <div className="inline-flex items-center rounded-full border border-amber-200 bg-amber-50 px-2.5 py-0.5 text-xs font-medium text-amber-700">
          {row.original.precios_count} feria{row.original.precios_count === 1 ? '' : 's'}
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
        const producto = row.original
        const canEdit = hasPermission('productos.editar')
        const canToggle = hasPermission('productos.activar')

        if (!canEdit && !canToggle) {
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
                <DropdownMenuItem onClick={() => handleOpenEdit(producto)}>
                  Editar
                </DropdownMenuItem>
              )}
              {canEdit && (
                <DropdownMenuItem onClick={() => handleOpenPrecios(producto)}>
                  Precios
                </DropdownMenuItem>
              )}
              {canToggle && (
                <DropdownMenuItem
                  onClick={() => handleToggle(producto)}
                  disabled={toggleMutation.isPending}
                >
                  {producto.activo ? 'Desactivar' : 'Activar'}
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
        title="Productos"
        description="Administre el catálogo base y sus precios por feria."
        action={
          hasPermission('productos.crear')
            ? {
                label: 'Nuevo producto',
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
            placeholder="Buscar por código o descripción..."
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
        </FilterBar>

        <DataTable
          columns={columns}
          data={productos}
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

      <ProductoFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        producto={selectedProducto}
        onSubmit={async (payload) => {
          try {
            await handleFormSubmit(payload)
          } catch (error) {
            if (isAxiosError(error) && error.response?.status === 422) {
              throw error
            }

            throw error
          }
        }}
        isLoading={isSaving}
      />

      <ProductoPreciosDialog
        open={preciosOpen}
        onOpenChange={setPreciosOpen}
        producto={selectedProducto}
      />
    </div>
  )
}
