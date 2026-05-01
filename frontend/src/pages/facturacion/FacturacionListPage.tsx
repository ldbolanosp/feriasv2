import { useMemo, useState } from 'react'
import type { DateRange } from 'react-day-picker'
import type { ColumnDef, SortingState } from '@tanstack/react-table'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Eye, FileText, MoreHorizontal, Pencil, Plus, Receipt, Trash2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { DataTable } from '@/components/shared/DataTable'
import { DateRangePicker } from '@/components/shared/DateRangePicker'
import { FilterBar } from '@/components/shared/FilterBar'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
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
import { useFerias } from '@/hooks/useFerias'
import { useDeleteFactura, useFacturarFactura, useFacturas } from '@/hooks/useFacturas'
import { usePermission } from '@/hooks/usePermission'
import { openFacturaPdf } from '@/services/facturaService'
import { useAuthStore } from '@/stores/authStore'
import type { IFactura } from '@/types/factura'

type EstadoFiltro = 'todos' | 'borrador' | 'facturado' | 'eliminado'

function formatDate(date: string | null): string {
  if (!date) {
    return 'Sin emitir'
  }

  return format(new Date(date), 'dd/MM/yyyy HH:mm', { locale: es })
}

function formatMoney(value: string | null): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(Number(value ?? 0))
}

export function FacturacionListPage() {
  const navigate = useNavigate()
  const { hasPermission } = usePermission()
  const roles = useAuthStore((state) => state.roles)
  const isAdmin = roles.includes('administrador')
  const isSupervisor = roles.includes('supervisor')

  const [page, setPage] = useState(1)
  const [estado, setEstado] = useState<EstadoFiltro>('todos')
  const [dateRange, setDateRange] = useState<DateRange | undefined>()
  const [feriaId, setFeriaId] = useState<string>('todas')
  const [sorting, setSorting] = useState<SortingState>([])
  const [selectedFactura, setSelectedFactura] = useState<IFactura | null>(null)
  const [facturarDialogOpen, setFacturarDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)

  const sort = sorting[0]?.id
  const direction = sorting[0]?.desc ? 'desc' : 'asc'

  const { data: feriasData } = useFerias({
    page: 1,
    per_page: 100,
  })

  const { data, isLoading, isFetching } = useFacturas({
    page,
    per_page: 15,
    estado: estado === 'todos' ? undefined : estado,
    fecha_desde: dateRange?.from ? format(dateRange.from, 'yyyy-MM-dd') : undefined,
    fecha_hasta: dateRange?.to ? format(dateRange.to, 'yyyy-MM-dd') : undefined,
    feria_id: isAdmin && feriaId !== 'todas' ? Number(feriaId) : undefined,
    sort,
    direction,
  })

  const facturarMutation = useFacturarFactura()
  const deleteMutation = useDeleteFactura()

  const facturas = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }
  const ferias = feriasData?.data ?? []

  const columns = useMemo<ColumnDef<IFactura>[]>(
    () => [
      {
        accessorKey: 'consecutivo',
        header: 'Consecutivo',
        enableSorting: true,
        cell: ({ row }) => row.original.consecutivo ?? 'Borrador',
      },
      {
        id: 'cliente',
        header: 'Participante',
        cell: ({ row }) => (
          <div className="space-y-1">
            <p className="font-medium">
              {row.original.es_publico_general
                ? row.original.nombre_publico ?? 'Público general'
                : row.original.participante?.nombre ?? 'Sin participante'}
            </p>
            {(row.original.tipo_puesto || row.original.numero_puesto) && (
              <p className="text-xs text-muted-foreground">
                {row.original.tipo_puesto ?? 'Puesto'} {row.original.numero_puesto ?? ''}
              </p>
            )}
          </div>
        ),
      },
      {
        accessorKey: 'subtotal',
        header: 'Total',
        enableSorting: true,
        cell: ({ row }) => <span className="font-medium">{formatMoney(row.original.subtotal)}</span>,
      },
      {
        accessorKey: 'estado',
        header: 'Estado',
        enableSorting: true,
        cell: ({ row }) => <StatusBadge status={row.original.estado} />,
      },
      {
        accessorKey: 'fecha_emision',
        header: 'Fecha',
        enableSorting: true,
        cell: ({ row }) => formatDate(row.original.fecha_emision ?? row.original.created_at),
      },
      {
        id: 'usuario',
        header: 'Usuario',
        cell: ({ row }) =>
          isAdmin || isSupervisor ? row.original.usuario?.name ?? 'N/A' : null,
      },
      {
        id: 'acciones',
        header: '',
        cell: ({ row }) => {
          const factura = row.original

          return (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="size-8">
                  <MoreHorizontal className="size-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => navigate(`/facturacion/${factura.id}`)}>
                  <Eye className="mr-2 size-4" />
                  Ver
                </DropdownMenuItem>

                {factura.estado === 'borrador' && hasPermission('facturas.editar') && (
                  <DropdownMenuItem onClick={() => navigate(`/facturacion/${factura.id}/editar`)}>
                    <Pencil className="mr-2 size-4" />
                    Editar
                  </DropdownMenuItem>
                )}

                {factura.estado === 'borrador' && hasPermission('facturas.facturar') && (
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedFactura(factura)
                      setFacturarDialogOpen(true)
                    }}
                  >
                    <Receipt className="mr-2 size-4" />
                    Facturar
                  </DropdownMenuItem>
                )}

                {factura.estado === 'facturado' && (
                  <DropdownMenuItem
                    onClick={() => void openFacturaPdf(factura.id)}
                  >
                    <FileText className="mr-2 size-4" />
                    PDF
                  </DropdownMenuItem>
                )}

                {factura.estado !== 'eliminado' && hasPermission('facturas.eliminar') && (
                  <DropdownMenuItem
                    className="text-destructive focus:text-destructive"
                    onClick={() => {
                      setSelectedFactura(factura)
                      setDeleteDialogOpen(true)
                    }}
                  >
                    <Trash2 className="mr-2 size-4" />
                    Eliminar
                  </DropdownMenuItem>
                )}
              </DropdownMenuContent>
            </DropdownMenu>
          )
        },
      },
    ],
    [hasPermission, isAdmin, isSupervisor, navigate],
  )

  const handleSortingChange = (nextSorting: SortingState) => {
    setSorting(nextSorting)
    setPage(1)
  }

  const handleFacturar = async () => {
    if (!selectedFactura) {
      return
    }

    const factura = await facturarMutation.mutateAsync(selectedFactura.id)
    setFacturarDialogOpen(false)
    await openFacturaPdf(factura.id, true)
  }

  const handleDelete = async () => {
    if (!selectedFactura) {
      return
    }

    await deleteMutation.mutateAsync(selectedFactura.id)
    setDeleteDialogOpen(false)
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Facturación"
        description="Consulte, emita y controle los comprobantes generados por la feria activa."
        action={
          hasPermission('facturas.crear')
            ? {
                label: 'Nueva Factura',
                icon: Plus,
                onClick: () => navigate('/facturacion/crear'),
              }
            : undefined
        }
      />

      <div className="flex flex-wrap items-center gap-3">
        {isAdmin && (
          <Badge variant="outline" className="rounded-full px-3 py-1">
            Vista global de administrador
          </Badge>
        )}
        {isSupervisor && !isAdmin && (
          <Badge variant="secondary" className="rounded-full px-3 py-1">
            Visibilidad de supervisión por feria activa
          </Badge>
        )}
      </div>

      <FilterBar>
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
            <SelectItem value="borrador">Borrador</SelectItem>
            <SelectItem value="facturado">Facturado</SelectItem>
            <SelectItem value="eliminado">Eliminado</SelectItem>
          </SelectContent>
        </Select>

        <DateRangePicker
          value={dateRange}
          onChange={(range) => {
            setDateRange(range)
            setPage(1)
          }}
          className="w-full sm:min-w-72"
          placeholder="Fecha desde / hasta"
        />

        {isAdmin && (
          <Select
            value={feriaId}
            onValueChange={(value) => {
              setFeriaId(value)
              setPage(1)
            }}
          >
            <SelectTrigger className="w-full sm:w-56">
              <SelectValue placeholder="Feria" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todas">Todas las ferias</SelectItem>
              {ferias.map((feria) => (
                <SelectItem key={feria.id} value={String(feria.id)}>
                  {feria.codigo} · {feria.descripcion}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}
      </FilterBar>

      <DataTable
        columns={columns}
        data={facturas}
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

      <ConfirmDialog
        open={facturarDialogOpen}
        onCancel={() => setFacturarDialogOpen(false)}
        onConfirm={() => void handleFacturar()}
        title="Emitir factura"
        description="Se generará el consecutivo oficial y se abrirá el PDF en una nueva pestaña."
        confirmText="Facturar"
      />

      <ConfirmDialog
        open={deleteDialogOpen}
        onCancel={() => setDeleteDialogOpen(false)}
        onConfirm={() => void handleDelete()}
        title="Eliminar factura"
        description="La factura cambiará a estado eliminado y dejará de estar disponible para edición."
        confirmText="Eliminar"
        variant="destructive"
      />
    </div>
  )
}
