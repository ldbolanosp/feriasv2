import { useMemo, useState } from 'react'
import type { ColumnDef, SortingState } from '@tanstack/react-table'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Ban, CarFront, FileText, MoreHorizontal } from 'lucide-react'
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
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  useCancelarParqueo,
  useCreateParqueo,
  useParqueos,
  useSalidaParqueo,
} from '@/hooks/useParqueos'
import { usePermission } from '@/hooks/usePermission'
import { openParqueoPdf } from '@/services/parqueoService'
import { useAuthStore } from '@/stores/authStore'
import type { IParqueo } from '@/types/parqueo'
import { ParqueoRegistroDialog } from './ParqueoRegistroDialog'

type EstadoFiltro = 'todos' | 'activo' | 'finalizado' | 'cancelado'

function formatDate(date: string | null): string {
  if (!date) {
    return 'Pendiente'
  }

  return format(new Date(date), 'dd/MM/yyyy HH:mm', { locale: es })
}

function formatMoney(value: string): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(Number(value))
}

export function ParqueosPage() {
  const { hasPermission } = usePermission()
  const roles = useAuthStore((state) => state.roles)
  const showUsuario = roles.includes('administrador') || roles.includes('supervisor')

  const [page, setPage] = useState(1)
  const [placa, setPlaca] = useState('')
  const [estado, setEstado] = useState<EstadoFiltro>('todos')
  const [fecha, setFecha] = useState('')
  const [sorting, setSorting] = useState<SortingState>([])
  const [registroOpen, setRegistroOpen] = useState(false)
  const [salidaDialogOpen, setSalidaDialogOpen] = useState(false)
  const [cancelarDialogOpen, setCancelarDialogOpen] = useState(false)
  const [selectedParqueo, setSelectedParqueo] = useState<IParqueo | null>(null)

  const sort = sorting[0]?.id
  const direction = sorting[0]?.desc ? 'desc' : 'asc'

  const { data, isLoading, isFetching } = useParqueos({
    page,
    per_page: 15,
    placa: placa || undefined,
    estado: estado === 'todos' ? undefined : estado,
    fecha: fecha || undefined,
    sort,
    direction,
  })

  const createMutation = useCreateParqueo()
  const salidaMutation = useSalidaParqueo()
  const cancelarMutation = useCancelarParqueo()

  const parqueos = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }
  const tarifaActual = data?.tarifa_actual ?? 0
  const isSaving = createMutation.isPending

  const columns = useMemo<ColumnDef<IParqueo>[]>(
    () => [
      {
        accessorKey: 'placa',
        header: 'Placa',
        enableSorting: true,
        cell: ({ row }) => <span className="font-medium tracking-wide">{row.original.placa}</span>,
      },
      {
        accessorKey: 'fecha_hora_ingreso',
        header: 'Ingreso',
        enableSorting: true,
        cell: ({ row }) => formatDate(row.original.fecha_hora_ingreso),
      },
      {
        accessorKey: 'fecha_hora_salida',
        header: 'Salida',
        enableSorting: true,
        cell: ({ row }) => formatDate(row.original.fecha_hora_salida),
      },
      {
        accessorKey: 'tarifa',
        header: 'Tarifa',
        enableSorting: true,
        cell: ({ row }) => <span className="font-medium">{formatMoney(row.original.tarifa)}</span>,
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
        id: 'acciones',
        header: '',
        cell: ({ row }) => {
          const parqueo = row.original
          const canSalida = hasPermission('parqueos.salida') && parqueo.estado === 'activo'
          const canCancelar = hasPermission('parqueos.cancelar') && parqueo.estado === 'activo'

          return (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="size-8">
                  <MoreHorizontal className="size-4" />
                  <span className="sr-only">Acciones</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => void openParqueoPdf(parqueo.id)}>
                  <FileText className="mr-2 size-4" />
                  PDF
                </DropdownMenuItem>
                {canSalida && (
                  <DropdownMenuItem
                    onClick={() => {
                      setSelectedParqueo(parqueo)
                      setSalidaDialogOpen(true)
                    }}
                  >
                    <CarFront className="mr-2 size-4" />
                    Registrar salida
                  </DropdownMenuItem>
                )}
                {canCancelar && (
                  <DropdownMenuItem
                    className="text-destructive focus:text-destructive"
                    onClick={() => {
                      setSelectedParqueo(parqueo)
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

  const handleSearchChange = (value: string) => {
    setPlaca(value.toUpperCase())
    setPage(1)
  }

  const handleEstadoChange = (value: string) => {
    setEstado(value as EstadoFiltro)
    setPage(1)
  }

  const handleFechaChange = (value: string) => {
    setFecha(value)
    setPage(1)
  }

  const handleRegistrar = async (payload: { placa: string }) => {
    const parqueo = await createMutation.mutateAsync(payload)
    setRegistroOpen(false)
    await openParqueoPdf(parqueo.id)
  }

  const handleSalida = async () => {
    if (!selectedParqueo) {
      return
    }

    const parqueo = await salidaMutation.mutateAsync(selectedParqueo.id)
    setSalidaDialogOpen(false)
    await openParqueoPdf(parqueo.id)
  }

  const handleCancelar = async () => {
    if (!selectedParqueo) {
      return
    }

    const parqueo = await cancelarMutation.mutateAsync(selectedParqueo.id)
    setCancelarDialogOpen(false)
    await openParqueoPdf(parqueo.id)
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Parqueos"
        description="Registre ingresos, controle salidas y consulte los tickets emitidos en la feria activa."
        action={
          hasPermission('parqueos.crear')
            ? {
                label: 'Registrar parqueo',
                icon: CarFront,
                onClick: () => setRegistroOpen(true),
              }
            : undefined
        }
      />

      <div className="space-y-3">
        <FilterBar>
          <SearchInput
            value={placa}
            onChange={handleSearchChange}
            placeholder="Buscar por placa..."
            className="w-full sm:w-72"
          />

          <Select value={estado} onValueChange={handleEstadoChange}>
            <SelectTrigger className="w-full sm:w-44">
              <SelectValue placeholder="Estado" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos</SelectItem>
              <SelectItem value="activo">Activos</SelectItem>
              <SelectItem value="finalizado">Finalizados</SelectItem>
              <SelectItem value="cancelado">Cancelados</SelectItem>
            </SelectContent>
          </Select>

          <Input
            type="date"
            value={fecha}
            onChange={(event) => handleFechaChange(event.target.value)}
            className="w-full sm:w-[180px]"
          />
        </FilterBar>

        <DataTable
          columns={columns}
          data={parqueos}
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

      <ParqueoRegistroDialog
        open={registroOpen}
        onOpenChange={setRegistroOpen}
        tarifaActual={tarifaActual}
        isLoading={isSaving}
        onSubmit={async (payload) => {
          try {
            await handleRegistrar(payload)
          } catch (error) {
            if (isAxiosError(error) && error.response?.status === 422) {
              throw error
            }

            throw error
          }
        }}
      />

      <ConfirmDialog
        open={salidaDialogOpen}
        onCancel={() => setSalidaDialogOpen(false)}
        onConfirm={() => void handleSalida()}
        title="Registrar salida"
        description={
          selectedParqueo
            ? `Se marcará la salida del vehículo ${selectedParqueo.placa} y se abrirá el ticket actualizado.`
            : 'Se registrará la salida del parqueo seleccionado.'
        }
        confirmText="Registrar salida"
      />

      <ConfirmDialog
        open={cancelarDialogOpen}
        onCancel={() => setCancelarDialogOpen(false)}
        onConfirm={() => void handleCancelar()}
        title="Cancelar parqueo"
        description={
          selectedParqueo
            ? `Se cancelará el registro del vehículo ${selectedParqueo.placa} y se abrirá el ticket actualizado.`
            : 'Se cancelará el parqueo seleccionado.'
        }
        confirmText="Cancelar parqueo"
        variant="destructive"
      />
    </div>
  )
}
