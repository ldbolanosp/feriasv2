import { useMemo, useState } from 'react'
import type { ColumnDef, SortingState } from '@tanstack/react-table'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Ban, FileText, MoreHorizontal, PackagePlus } from 'lucide-react'
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
import { useCancelarTarima, useCreateTarima, useTarimas } from '@/hooks/useTarimas'
import { openTarimaPdf } from '@/services/tarimaService'
import { useAuthStore } from '@/stores/authStore'
import type { ITarima } from '@/types/tarima'
import { TarimaFormDialog } from './TarimaFormDialog'

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

export function TarimasPage() {
  const { hasPermission } = usePermission()
  const roles = useAuthStore((state) => state.roles)
  const showUsuario = roles.includes('administrador') || roles.includes('supervisor')

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [estado, setEstado] = useState<EstadoFiltro>('todos')
  const [sorting, setSorting] = useState<SortingState>([])
  const [formOpen, setFormOpen] = useState(false)
  const [cancelarDialogOpen, setCancelarDialogOpen] = useState(false)
  const [selectedTarima, setSelectedTarima] = useState<ITarima | null>(null)

  const sort = sorting[0]?.id
  const direction = sorting[0]?.desc ? 'desc' : 'asc'

  const { data, isLoading, isFetching } = useTarimas({
    page,
    per_page: 15,
    search: search || undefined,
    estado: estado === 'todos' ? undefined : estado,
    sort,
    direction,
  })

  const createMutation = useCreateTarima()
  const cancelarMutation = useCancelarTarima()

  const tarimas = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }
  const precioActual = data?.precio_actual ?? 0

  const columns = useMemo<ColumnDef<ITarima>[]>(
    () => [
      {
        id: 'participante',
        header: 'Participante',
        cell: ({ row }) => (
          <div className="space-y-1">
            <p className="font-medium">{row.original.participante?.nombre ?? 'N/A'}</p>
            <p className="text-xs text-muted-foreground">
              {row.original.participante?.numero_identificacion ?? 'Sin identificación'}
            </p>
          </div>
        ),
      },
      {
        accessorKey: 'numero_tarima',
        header: 'Número',
        enableSorting: true,
        cell: ({ row }) => row.original.numero_tarima ?? 'Sin número',
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
          const tarima = row.original

          return (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="size-8">
                  <MoreHorizontal className="size-4" />
                  <span className="sr-only">Acciones</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => void openTarimaPdf(tarima.id)}>
                  <FileText className="mr-2 size-4" />
                  PDF
                </DropdownMenuItem>
                {hasPermission('tarimas.cancelar') && tarima.estado === 'facturado' && (
                  <DropdownMenuItem
                    className="text-destructive focus:text-destructive"
                    onClick={() => {
                      setSelectedTarima(tarima)
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
    participante_id: number
    numero_tarima?: string | null
    cantidad: number
    observaciones?: string | null
  }) => {
    const tarima = await createMutation.mutateAsync(payload)
    setFormOpen(false)
    await openTarimaPdf(tarima.id)
  }

  const handleCancelar = async () => {
    if (!selectedTarima) {
      return
    }

    const tarima = await cancelarMutation.mutateAsync(selectedTarima.id)
    setCancelarDialogOpen(false)
    await openTarimaPdf(tarima.id)
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Tarimas"
        description="Facture tarimas, consulte tickets emitidos y controle cancelaciones de la feria activa."
        action={
          hasPermission('tarimas.crear')
            ? {
                label: 'Facturar tarima',
                icon: PackagePlus,
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
            placeholder="Buscar participante o número..."
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
          data={tarimas}
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

      <TarimaFormDialog
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
        title="Cancelar tarima"
        description={
          selectedTarima
            ? `Se cancelará la tarima de ${selectedTarima.participante?.nombre ?? 'este participante'} y se abrirá el ticket actualizado.`
            : 'Se cancelará la tarima seleccionada.'
        }
        confirmText="Cancelar tarima"
        variant="destructive"
      />
    </div>
  )
}
