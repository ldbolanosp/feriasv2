import { useMemo, useState } from 'react'
import type { ColumnDef, SortingState } from '@tanstack/react-table'
import { Bug, RefreshCcw } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { PageHeader } from '@/components/shared/PageHeader'
import { FilterBar } from '@/components/shared/FilterBar'
import { SearchInput } from '@/components/shared/SearchInput'
import { DataTable } from '@/components/shared/DataTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useMobileDiagnosticLogs } from '@/hooks/useMobileDiagnosticLogs'
import type { IMobileDiagnosticLog, TMobileDiagnosticTrigger } from '@/types/mobileDiagnosticLog'

type TriggerFilter = 'todos' | TMobileDiagnosticTrigger
type PlatformFilter = 'todos' | 'android' | 'ios'

function triggerLabel(trigger: TMobileDiagnosticTrigger): string {
  switch (trigger) {
    case 'automatic':
      return 'Automático'
    case 'crash':
      return 'Crash'
    default:
      return 'Manual'
  }
}

function triggerVariant(trigger: TMobileDiagnosticTrigger): 'default' | 'secondary' | 'destructive' {
  switch (trigger) {
    case 'crash':
      return 'destructive'
    case 'automatic':
      return 'secondary'
    default:
      return 'default'
  }
}

function formatDateTime(value: string | null): string {
  if (!value) {
    return 'Sin fecha'
  }

  return format(new Date(value), 'dd/MM/yyyy HH:mm', { locale: es })
}

export function MobileDiagnosticLogsPage() {
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [triggerFilter, setTriggerFilter] = useState<TriggerFilter>('todos')
  const [platformFilter, setPlatformFilter] = useState<PlatformFilter>('todos')
  const [sorting, setSorting] = useState<SortingState>([
    { id: 'last_event_at', desc: true },
  ])

  const sort = sorting[0]?.id
  const direction = sorting[0]?.desc ? 'desc' : 'asc'

  const { data, isLoading, isFetching, refetch } = useMobileDiagnosticLogs({
    page,
    per_page: 15,
    search: search || undefined,
    sort,
    direction,
    trigger: triggerFilter,
    platform: platformFilter,
  })

  const logs = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, last_page: 1, per_page: 15, total: 0 }

  const columns = useMemo<ColumnDef<IMobileDiagnosticLog>[]>(
    () => [
      {
        accessorKey: 'summary',
        header: 'Incidente',
        cell: ({ row }) => (
          <div className="space-y-1">
            <p className="font-medium leading-5">
              {row.original.summary ?? 'Diagnóstico sin resumen'}
            </p>
            <p className="text-xs text-muted-foreground">
              Ruta: {row.original.current_route ?? 'No registrada'}
            </p>
          </div>
        ),
      },
      {
        accessorKey: 'user',
        header: 'Usuario',
        cell: ({ row }) => (
          <div className="space-y-1 text-sm">
            <p className="font-medium">{row.original.user?.name ?? 'Sin usuario'}</p>
            <p className="text-xs text-muted-foreground">
              {row.original.user?.email ?? 'No disponible'}
            </p>
          </div>
        ),
      },
      {
        accessorKey: 'trigger',
        header: 'Origen',
        enableSorting: true,
        cell: ({ row }) => (
          <Badge variant={triggerVariant(row.original.trigger)}>
            {triggerLabel(row.original.trigger)}
          </Badge>
        ),
      },
      {
        accessorKey: 'platform',
        header: 'Dispositivo',
        enableSorting: true,
        cell: ({ row }) => (
          <div className="space-y-1 text-sm">
            <p className="font-medium uppercase">{row.original.platform ?? 'N/D'}</p>
            <p className="text-xs text-muted-foreground">
              {row.original.app_version ?? 'Versión desconocida'}
            </p>
          </div>
        ),
      },
      {
        accessorKey: 'event_count',
        header: 'Eventos',
        enableSorting: true,
        cell: ({ row }) => (
          <div className="space-y-1 text-sm">
            <p className="font-medium">{row.original.event_count}</p>
            <p className="text-xs text-muted-foreground">
              Sesión: {row.original.session_id}
            </p>
          </div>
        ),
      },
      {
        accessorKey: 'last_event_at',
        header: 'Último evento',
        enableSorting: true,
        cell: ({ row }) => (
          <div className="space-y-1 text-sm">
            <p className="font-medium">{formatDateTime(row.original.last_event_at)}</p>
            <p className="text-xs text-muted-foreground">
              {row.original.feria?.codigo ?? 'Sin feria'}
            </p>
          </div>
        ),
      },
    ],
    [],
  )

  return (
    <div className="space-y-6">
      <PageHeader
        title="Diagnósticos móviles"
        description="Revisa cierres inesperados y reportes enviados desde la app Flutter."
        backUrl="/configuracion"
        action={{
          label: 'Actualizar',
          icon: RefreshCcw,
          onClick: () => {
            void refetch()
          },
        }}
      />

      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-xl border bg-card p-4 shadow-sm">
          <p className="text-sm text-muted-foreground">Incidentes visibles</p>
          <p className="mt-2 text-3xl font-semibold tracking-tight">{meta.total}</p>
          <p className="mt-1 text-xs text-muted-foreground">
            Filtrados por la feria activa cuando aplica.
          </p>
        </div>
        <div className="rounded-xl border bg-card p-4 shadow-sm">
          <p className="text-sm text-muted-foreground">Página actual</p>
          <p className="mt-2 text-3xl font-semibold tracking-tight">{meta.current_page}</p>
          <p className="mt-1 text-xs text-muted-foreground">
            {isFetching ? 'Actualizando resultados...' : 'Listado sincronizado.'}
          </p>
        </div>
        <div className="rounded-xl border bg-card p-4 shadow-sm">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Bug className="size-4" />
            Estado del monitoreo
          </div>
          <p className="mt-2 text-lg font-semibold tracking-tight">
            {logs.length > 0 ? 'Con reportes recientes' : 'Sin reportes en este filtro'}
          </p>
          <p className="mt-1 text-xs text-muted-foreground">
            Usa búsqueda por usuario, ruta o resumen para aislar casos.
          </p>
        </div>
      </div>

      <FilterBar>
        <SearchInput
          value={search}
          onChange={(value) => {
            setSearch(value)
            setPage(1)
          }}
          placeholder="Buscar por usuario, correo, ruta o resumen..."
          className="sm:min-w-80"
        />
        <Select
          value={triggerFilter}
          onValueChange={(value) => {
            setTriggerFilter(value as TriggerFilter)
            setPage(1)
          }}
        >
          <SelectTrigger className="sm:w-44">
            <SelectValue placeholder="Origen" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todos">Todos los orígenes</SelectItem>
            <SelectItem value="manual">Manual</SelectItem>
            <SelectItem value="automatic">Automático</SelectItem>
            <SelectItem value="crash">Crash</SelectItem>
          </SelectContent>
        </Select>
        <Select
          value={platformFilter}
          onValueChange={(value) => {
            setPlatformFilter(value as PlatformFilter)
            setPage(1)
          }}
        >
          <SelectTrigger className="sm:w-40">
            <SelectValue placeholder="Plataforma" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todos">Todas</SelectItem>
            <SelectItem value="android">Android</SelectItem>
            <SelectItem value="ios">iOS</SelectItem>
          </SelectContent>
        </Select>
        <Button
          type="button"
          variant="outline"
          onClick={() => {
            setSearch('')
            setTriggerFilter('todos')
            setPlatformFilter('todos')
            setSorting([{ id: 'last_event_at', desc: true }])
            setPage(1)
          }}
        >
          Limpiar filtros
        </Button>
      </FilterBar>

      <DataTable
        columns={columns}
        data={logs}
        isLoading={isLoading}
        isFetching={isFetching}
        pagination={{
          page: meta.current_page,
          pageSize: meta.per_page,
          total: meta.total,
        }}
        onPaginationChange={setPage}
        onSortChange={(nextSorting) => {
          setSorting(nextSorting)
          setPage(1)
        }}
      />
    </div>
  )
}
