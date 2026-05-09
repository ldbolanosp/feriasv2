import { useState } from 'react'
import { isAxiosError } from 'axios'
import { MoreHorizontal, Pencil, Plus } from 'lucide-react'
import type { ColumnDef } from '@tanstack/react-table'
import { DataTable } from '@/components/shared/DataTable'
import { FilterBar } from '@/components/shared/FilterBar'
import { PageHeader } from '@/components/shared/PageHeader'
import { SearchInput } from '@/components/shared/SearchInput'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { usePermission } from '@/hooks/usePermission'
import {
  useCreateMetodoPago,
  useMetodosPago,
  useToggleMetodoPago,
  useUpdateMetodoPago,
} from '@/hooks/useMetodosPago'
import type { IMetodoPago, IMetodoPagoFormPayload } from '@/types/metodoPago'
import { MetodoPagoFormDialog } from './MetodoPagoFormDialog'

function formatDate(date: string): string {
  return new Intl.DateTimeFormat('es-CR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(date))
}

export function MetodosPagoPage() {
  const { hasPermission } = usePermission()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [formOpen, setFormOpen] = useState(false)
  const [selectedMetodoPago, setSelectedMetodoPago] = useState<IMetodoPago | null>(null)

  const { data, isLoading, isFetching } = useMetodosPago({
    page,
    per_page: 15,
    search: search || undefined,
  })
  const createMutation = useCreateMetodoPago()
  const updateMutation = useUpdateMetodoPago()
  const toggleMutation = useToggleMetodoPago()

  const metodosPago = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }
  const isSaving = createMutation.isPending || updateMutation.isPending

  const handleOpenCreate = () => {
    setSelectedMetodoPago(null)
    setFormOpen(true)
  }

  const handleOpenEdit = (metodoPago: IMetodoPago) => {
    setSelectedMetodoPago(metodoPago)
    setFormOpen(true)
  }

  const handleFormSubmit = async (payload: IMetodoPagoFormPayload) => {
    if (selectedMetodoPago) {
      await updateMutation.mutateAsync({ id: selectedMetodoPago.id, payload })
    } else {
      await createMutation.mutateAsync(payload)
    }

    setFormOpen(false)
  }

  const columns: ColumnDef<IMetodoPago>[] = [
    {
      accessorKey: 'nombre',
      header: 'Nombre',
      cell: ({ row }) => <span className="font-medium">{row.original.nombre}</span>,
    },
    {
      accessorKey: 'activo',
      header: 'Estado',
      cell: ({ row }) => <StatusBadge status={row.original.activo ? 'activo' : 'inactivo'} />,
    },
    {
      accessorKey: 'updated_at',
      header: 'Última actualización',
      cell: ({ row }) => formatDate(row.original.updated_at),
    },
    {
      id: 'acciones',
      header: '',
      cell: ({ row }) => {
        if (!hasPermission('configuracion.editar')) {
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
              <DropdownMenuItem onClick={() => handleOpenEdit(row.original)}>
                <Pencil className="size-4" />
                Editar
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={() => toggleMutation.mutate(row.original.id)}
                disabled={toggleMutation.isPending}
              >
                {row.original.activo ? 'Inactivar' : 'Activar'}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Métodos de pago"
        description="Catálogo de opciones disponibles para capturar cobros en facturación."
        action={
          hasPermission('configuracion.editar')
            ? {
                label: 'Nuevo método',
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
            onChange={(value) => {
              setSearch(value)
              setPage(1)
            }}
            placeholder="Buscar por nombre..."
            className="w-full sm:w-72"
          />
        </FilterBar>

        <DataTable
          columns={columns}
          data={metodosPago}
          isLoading={isLoading}
          isFetching={isFetching}
          pagination={{
            page: meta.current_page,
            pageSize: meta.per_page,
            total: meta.total,
          }}
          onPaginationChange={setPage}
        />
      </div>

      <MetodoPagoFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        metodoPago={selectedMetodoPago}
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
    </div>
  )
}
