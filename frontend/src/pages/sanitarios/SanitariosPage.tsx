import { useMemo, useState } from 'react'
import type { ColumnDef, SortingState } from '@tanstack/react-table'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Ban, FileText, MoreHorizontal, ShieldPlus } from 'lucide-react'
import { isAxiosError } from 'axios'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { usePermission } from '@/hooks/usePermission'
import { useCancelarSanitario, useCreateSanitario, useSanitarios } from '@/hooks/useSanitarios'
import { openSanitarioPdf } from '@/services/sanitarioService'
import { useAuthStore } from '@/stores/authStore'
import type { ISanitario } from '@/types/sanitario'
import { SanitarioFormDialog } from './SanitarioFormDialog'

type EstadoFiltro = 'todos' | 'facturado' | 'cancelado'

function formatDate(date: string): string {
  return format(new Date(date), 'dd/MM/yyyy HH:mm', { locale: es })
}

function formatMoney(value: string): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(Number(value))
}

export function SanitariosPage() {
  const { hasPermission } = usePermission()
  const roles = useAuthStore((state) => state.roles)
  const showUsuario = roles.includes('administrador') || roles.includes('supervisor')

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [estado, setEstado] = useState<EstadoFiltro>('todos')
  const [sorting, setSorting] = useState<SortingState>([])
  const [formOpen, setFormOpen] = useState(false)
  const [cancelarDialogOpen, setCancelarDialogOpen] = useState(false)
  const [selectedSanitario, setSelectedSanitario] = useState<ISanitario | null>(null)

  const sort = sorting[0]?.id
  const direction = sorting[0]?.desc ? 'desc' : 'asc'

  const { data, isLoading, isFetching } = useSanitarios({
    page,
    per_page: 15,
    search: search || undefined,
    estado: estado === 'todos' ? undefined : estado,
    sort,
    direction,
  })

  const createMutation = useCreateSanitario()
  const cancelarMutation = useCancelarSanitario()

  const sanitarios = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }
  const precioActual = data?.precio_actual ?? 0

  const columns = useMemo<ColumnDef<ISanitario>[]>(
    () => [
      {
        id: 'participante',
        header: 'Participante',
        cell: ({ row }) => (
          <div className="space-y-1">
            <p className="font-medium">
              {row.original.participante?.nombre ?? 'Uso público'}
            </p>
            <p className="text-xs text-muted-foreground">
              {row.original.participante?.numero_identificacion ?? 'Sin participante asignado'}
            </p>
          </div>
        ),
      },
      {
        accessorKey: 'cantidad',
        header: 'Cantidad',
        enableSorting: true,
      },
      {
        accessorKey: 'precio_unitario',
        header: 'Precio',
        enableSorting: true,
        cell: ({ row }) => formatMoney(row.original.precio_unitario),
      },
      {
        accessorKey: 'total',
        header: 'Total',
        enableSorting: true,
        cell: ({ row }) => <span className="font-medium">{formatMoney(row.original.total)}</span>,
      },
      {
        accessorKey: 'estado',
        header: 'Estado',
        enableSorting: true,
        cell: ({ row }) => <StatusBadge status={row.original.estado} />,
      },
      {
        id: 'usuario',
        header: 'Usuario',
        cell: ({ row }) => (showUsuario ? row.original.usuario?.name ?? 'N/A' : 'Mi registro'),
      },
      {
        accessorKey: 'created_at',
        header: 'Fecha',
        enableSorting: true,
        cell: ({ row }) => formatDate(row.original.created_at),
      },
      {
        id: 'acciones',
        header: '',
        cell: ({ row }) => {
          const sanitario = row.original

          return (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="size-8">
                  <MoreHorizontal className="size-4" />
                  <span className="sr-only">Acciones</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => void openSanitarioPdf(sanitario.id)}>
                  <FileText className="mr-2 size-4" />
                  PDF
                </DropdownMenuItem>
                {hasPermission('sanitarios.cancelar') && sanitario.estado === 'facturado' && (
                  <DropdownMenuItem
                    className="text-destructive focus:text-destructive"
                    onClick={() => {
                      setSelectedSanitario(sanitario)
                      setCancelarDialogOpen(true)
                    }}
                  >
                    <Ban className="mr-2 size-4" />
                    Cancelar
                  </DropdownMenuItem>
                )}
              </DropdownMenuContent>
            </DropdownMenu>
          )
        },
      },
    ],
    [hasPermission, showUsuario],
  )

  const handleSortingChange = (nextSorting: SortingState) => {
    setSorting(nextSorting)
    setPage(1)
  }

  const handleFacturar = async (payload: {
    participante_id?: number | null
    cantidad: number
    observaciones?: string | null
  }) => {
    const sanitario = await createMutation.mutateAsync(payload)
    setFormOpen(false)
    await openSanitarioPdf(sanitario.id)
  }

  const handleCancelar = async () => {
    if (!selectedSanitario) {
      return
    }

    const sanitario = await cancelarMutation.mutateAsync(selectedSanitario.id)
    setCancelarDialogOpen(false)
    await openSanitarioPdf(sanitario.id)
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Sanitarios"
        description="Facture sanitarios para uso público o participantes y consulte los tickets emitidos."
        action={
          hasPermission('sanitarios.crear')
            ? {
                label: 'Facturar sanitario',
                icon: ShieldPlus,
                onClick: () => setFormOpen(true),
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
            placeholder="Buscar participante..."
            className="w-full sm:w-72"
          />

          <Select
            value={estado}
            onValueChange={(value) => {
              setEstado(value as EstadoFiltro)
              setPage(1)
            }}
          >
            <SelectTrigger className="w-full sm:w-44">
              <SelectValue placeholder="Estado" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos</SelectItem>
              <SelectItem value="facturado">Facturados</SelectItem>
              <SelectItem value="cancelado">Cancelados</SelectItem>
            </SelectContent>
          </Select>
        </FilterBar>

        <DataTable
          columns={columns}
          data={sanitarios}
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

      <SanitarioFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        precioActual={precioActual}
        isLoading={createMutation.isPending}
        onSubmit={async (payload) => {
          try {
            await handleFacturar(payload)
          } catch (error) {
            if (isAxiosError(error) && error.response?.status === 422) {
              throw error
            }

            throw error
          }
        }}
      />

      <ConfirmDialog
        open={cancelarDialogOpen}
        onCancel={() => setCancelarDialogOpen(false)}
        onConfirm={() => void handleCancelar()}
        title="Cancelar sanitario"
        description={
          selectedSanitario
            ? `Se cancelará el cobro de sanitario de ${selectedSanitario.participante?.nombre ?? 'uso público'} y se abrirá el ticket actualizado.`
            : 'Se cancelará el sanitario seleccionado.'
        }
        confirmText="Cancelar sanitario"
        variant="destructive"
      />
    </div>
  )
}
