import { useMemo, useState } from 'react'
import { isAxiosError } from 'axios'
import { CalendarClock, CircleAlert, ClipboardList, MoreHorizontal, Plus, RefreshCw, SquarePen } from 'lucide-react'
import type { ColumnDef } from '@tanstack/react-table'
import { DataTable } from '@/components/shared/DataTable'
import { FilterBar } from '@/components/shared/FilterBar'
import { PageHeader } from '@/components/shared/PageHeader'
import { SearchInput } from '@/components/shared/SearchInput'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { useInspecciones, useReinspecciones, useUpdateParticipanteCarne, useVencimientosCarne, useCreateInspeccion } from '@/hooks/useInspecciones'
import { usePermission } from '@/hooks/usePermission'
import type { IInspeccion } from '@/types/inspeccion'
import type { IParticipante } from '@/types/participante'
import { cn } from '@/lib/utils'
import { InspeccionFormDialog } from './InspeccionFormDialog'
import { ParticipanteCarneDialog } from './ParticipanteCarneDialog'

type TabValue = 'vencimientos-carne' | 'inspecciones' | 'reinspeccion'

function formatDate(date: string | null | undefined): string {
  if (!date) {
    return '—'
  }

  return new Intl.DateTimeFormat('es-CR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(`${date}T12:00:00`))
}

function formatDateTime(date: string): string {
  return new Intl.DateTimeFormat('es-CR', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(date))
}

function getInfoVencimientoCarne(fecha: string | null | undefined): {
  texto: string
  variante: 'normal' | 'advertencia' | 'vencido' | 'vacio'
} {
  if (!fecha) {
    return { texto: 'Sin fecha', variante: 'vacio' }
  }

  const fin = new Date(`${fecha}T12:00:00`)
  const hoy = new Date()
  hoy.setHours(0, 0, 0, 0)

  const finDia = new Date(fin)
  finDia.setHours(0, 0, 0, 0)

  const diffDias = Math.ceil((finDia.getTime() - hoy.getTime()) / (1000 * 60 * 60 * 24))
  const texto = formatDate(fecha)

  if (diffDias < 0) {
    return { texto, variante: 'vencido' }
  }

  if (diffDias <= 30) {
    return { texto, variante: 'advertencia' }
  }

  return { texto, variante: 'normal' }
}

function ResultadoBadge({ totalIncumplidos }: { totalIncumplidos: number }) {
  return (
    <span
      className={cn(
        'inline-flex rounded-full px-2.5 py-1 text-xs font-semibold',
        totalIncumplidos > 0
          ? 'bg-red-100 text-red-800'
          : 'bg-emerald-100 text-emerald-800',
      )}
    >
      {totalIncumplidos > 0 ? `${totalIncumplidos} pendientes` : 'Completa'}
    </span>
  )
}

export function InspeccionesPage() {
  const { hasPermission } = usePermission()
  const [tab, setTab] = useState<TabValue>('vencimientos-carne')
  const [vencimientosPage, setVencimientosPage] = useState(1)
  const [vencimientosSearch, setVencimientosSearch] = useState('')
  const [inspeccionesPage, setInspeccionesPage] = useState(1)
  const [inspeccionesSearch, setInspeccionesSearch] = useState('')
  const [reinspeccionesPage, setReinspeccionesPage] = useState(1)
  const [reinspeccionesSearch, setReinspeccionesSearch] = useState('')
  const [formOpen, setFormOpen] = useState(false)
  const [reinspeccionBase, setReinspeccionBase] = useState<IInspeccion | null>(null)
  const [participanteCarneOpen, setParticipanteCarneOpen] = useState(false)
  const [selectedParticipante, setSelectedParticipante] = useState<IParticipante | null>(null)

  const vencimientosQuery = useVencimientosCarne({
    page: vencimientosPage,
    per_page: 15,
    search: vencimientosSearch || undefined,
  })
  const inspeccionesQuery = useInspecciones({
    page: inspeccionesPage,
    per_page: 10,
    search: inspeccionesSearch || undefined,
  })
  const reinspeccionesQuery = useReinspecciones({
    page: reinspeccionesPage,
    per_page: 10,
    search: reinspeccionesSearch || undefined,
  })

  const createMutation = useCreateInspeccion()
  const updateCarneMutation = useUpdateParticipanteCarne()

  const vencimientos = vencimientosQuery.data?.data ?? []
  const vencimientosMeta = vencimientosQuery.data?.meta ?? {
    current_page: 1,
    per_page: 15,
    total: 0,
  }
  const inspecciones = inspeccionesQuery.data?.data ?? []
  const inspeccionesMeta = inspeccionesQuery.data?.meta ?? {
    current_page: 1,
    per_page: 10,
    total: 0,
  }
  const reinspecciones = reinspeccionesQuery.data?.data ?? []
  const reinspeccionesMeta = reinspeccionesQuery.data?.meta ?? {
    current_page: 1,
    per_page: 10,
    total: 0,
  }

  const tabDescription = useMemo(() => {
    if (tab === 'vencimientos-carne') {
      return 'Seguimiento rápido de participantes con carné vencido o próximo a vencer.'
    }

    if (tab === 'reinspeccion') {
      return 'Participantes cuya última inspección dejó items pendientes por corregir.'
    }

    return 'Registro histórico de inspecciones realizadas en la feria activa.'
  }, [tab])

  const handleOpenNewInspection = () => {
    setReinspeccionBase(null)
    setFormOpen(true)
  }

  const vencimientosColumns: ColumnDef<IParticipante>[] = [
    {
      accessorKey: 'nombre',
      header: 'Participante',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.nombre}</p>
          <p className="text-xs text-muted-foreground">{row.original.numero_identificacion}</p>
        </div>
      ),
    },
    {
      accessorKey: 'numero_carne',
      header: 'Carné',
      cell: ({ row }) => row.original.numero_carne ?? 'Sin número',
    },
    {
      accessorKey: 'fecha_emision_carne',
      header: 'Emisión',
      cell: ({ row }) => formatDate(row.original.fecha_emision_carne),
    },
    {
      accessorKey: 'fecha_vencimiento_carne',
      header: 'Vencimiento',
      cell: ({ row }) => {
        const info = getInfoVencimientoCarne(row.original.fecha_vencimiento_carne)

        return (
          <span
            className={cn(
              'inline-flex rounded-full px-2.5 py-1 text-xs font-semibold',
              info.variante === 'vencido' && 'bg-red-100 text-red-800',
              info.variante === 'advertencia' && 'bg-amber-100 text-amber-800',
              info.variante === 'normal' && 'bg-slate-100 text-slate-800',
              info.variante === 'vacio' && 'bg-muted text-muted-foreground',
            )}
          >
            {info.texto}
          </span>
        )
      },
    },
    {
      id: 'acciones',
      header: '',
      cell: ({ row }) =>
        hasPermission('participantes.editar') ? (
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              setSelectedParticipante(row.original)
              setParticipanteCarneOpen(true)
            }}
          >
            <SquarePen className="size-4" />
            Actualizar carné
          </Button>
        ) : null,
    },
  ]

  const inspeccionesColumns: ColumnDef<IInspeccion>[] = [
    {
      accessorKey: 'created_at',
      header: 'Fecha',
      cell: ({ row }) => formatDateTime(row.original.created_at),
    },
    {
      accessorKey: 'participante',
      header: 'Participante',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.participante?.nombre ?? '—'}</p>
          <p className="text-xs text-muted-foreground">
            {row.original.participante?.numero_identificacion ?? 'Sin identificación'}
          </p>
        </div>
      ),
    },
    {
      id: 'tipo',
      header: 'Tipo',
      cell: ({ row }) => (
        <span className="inline-flex rounded-full bg-sky-100 px-2.5 py-1 text-xs font-semibold text-sky-800">
          {row.original.es_reinspeccion ? 'Reinspección' : 'Inspección'}
        </span>
      ),
    },
    {
      accessorKey: 'total_items',
      header: 'Items',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.total_items}</p>
          <p className="text-xs text-muted-foreground">
            {row.original.items.slice(0, 2).map((item) => item.nombre_item).join(', ') || 'Sin detalle'}
          </p>
        </div>
      ),
    },
    {
      accessorKey: 'total_incumplidos',
      header: 'Resultado',
      cell: ({ row }) => <ResultadoBadge totalIncumplidos={row.original.total_incumplidos} />,
    },
    {
      accessorKey: 'inspector',
      header: 'Inspector',
      cell: ({ row }) => row.original.inspector?.name ?? 'Sistema',
    },
  ]

  const reinspeccionesColumns: ColumnDef<IInspeccion>[] = [
    {
      accessorKey: 'participante',
      header: 'Participante',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.participante?.nombre ?? '—'}</p>
          <p className="text-xs text-muted-foreground">
            {row.original.participante?.numero_identificacion ?? 'Sin identificación'}
          </p>
        </div>
      ),
    },
    {
      accessorKey: 'created_at',
      header: 'Última inspección',
      cell: ({ row }) => formatDateTime(row.original.created_at),
    },
    {
      accessorKey: 'items',
      header: 'Items pendientes',
      cell: ({ row }) => (
        <div className="max-w-[320px]">
          <p className="font-medium">{row.original.total_incumplidos} pendientes</p>
          <p className="truncate text-xs text-muted-foreground">
            {row.original.items.map((item) => item.nombre_item).join(', ')}
          </p>
        </div>
      ),
    },
    {
      id: 'acciones',
      header: '',
      cell: ({ row }) => {
        if (!hasPermission('inspecciones.crear')) {
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
              <DropdownMenuItem
                onClick={() => {
                  setReinspeccionBase(row.original)
                  setFormOpen(true)
                }}
              >
                <RefreshCw className="size-4" />
                Crear reinspección
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
        title="Inspecciones"
        description={tabDescription}
        action={
          tab === 'inspecciones' && hasPermission('inspecciones.crear')
            ? {
                label: 'Nueva inspección',
                icon: Plus,
                onClick: handleOpenNewInspection,
              }
            : undefined
        }
      />

      <Tabs value={tab} onValueChange={(value) => setTab(value as TabValue)} className="space-y-4">
        <TabsList className="grid h-auto w-full grid-cols-1 gap-2 bg-transparent p-0 sm:grid-cols-3">
          <TabsTrigger
            value="vencimientos-carne"
            className="min-h-10 rounded-xl border border-border/70 bg-background px-4 py-2.5 text-sm font-medium data-[state=active]:border-slate-300 data-[state=active]:bg-slate-100 data-[state=active]:text-slate-950 data-[state=active]:shadow-none"
          >
            <CalendarClock className="size-4" />
            Vencimiento Carné
          </TabsTrigger>
          <TabsTrigger
            value="inspecciones"
            className="min-h-10 rounded-xl border border-border/70 bg-background px-4 py-2.5 text-sm font-medium data-[state=active]:border-slate-300 data-[state=active]:bg-slate-100 data-[state=active]:text-slate-950 data-[state=active]:shadow-none"
          >
            <ClipboardList className="size-4" />
            Inspecciones
          </TabsTrigger>
          <TabsTrigger
            value="reinspeccion"
            className="min-h-10 rounded-xl border border-border/70 bg-background px-4 py-2.5 text-sm font-medium data-[state=active]:border-slate-300 data-[state=active]:bg-slate-100 data-[state=active]:text-slate-950 data-[state=active]:shadow-none"
          >
            <CircleAlert className="size-4" />
            Reinspección
          </TabsTrigger>
        </TabsList>

        <TabsContent value="vencimientos-carne" className="space-y-3">
          <FilterBar>
            <SearchInput
              value={vencimientosSearch}
              onChange={(value) => {
                setVencimientosSearch(value)
                setVencimientosPage(1)
              }}
              placeholder="Buscar participante, identificación o carné..."
              className="w-full sm:w-80"
            />
          </FilterBar>

          <DataTable
            columns={vencimientosColumns}
            data={vencimientos}
            isLoading={vencimientosQuery.isLoading}
            isFetching={vencimientosQuery.isFetching}
            pagination={{
              page: vencimientosMeta.current_page,
              pageSize: vencimientosMeta.per_page,
              total: vencimientosMeta.total,
            }}
            onPaginationChange={setVencimientosPage}
          />
        </TabsContent>

        <TabsContent value="inspecciones" className="space-y-3">
          <FilterBar>
            <SearchInput
              value={inspeccionesSearch}
              onChange={(value) => {
                setInspeccionesSearch(value)
                setInspeccionesPage(1)
              }}
              placeholder="Buscar por participante o identificación..."
              className="w-full sm:w-80"
            />
          </FilterBar>

          <DataTable
            columns={inspeccionesColumns}
            data={inspecciones}
            isLoading={inspeccionesQuery.isLoading}
            isFetching={inspeccionesQuery.isFetching}
            pagination={{
              page: inspeccionesMeta.current_page,
              pageSize: inspeccionesMeta.per_page,
              total: inspeccionesMeta.total,
            }}
            onPaginationChange={setInspeccionesPage}
          />
        </TabsContent>

        <TabsContent value="reinspeccion" className="space-y-3">
          <FilterBar>
            <SearchInput
              value={reinspeccionesSearch}
              onChange={(value) => {
                setReinspeccionesSearch(value)
                setReinspeccionesPage(1)
              }}
              placeholder="Buscar por participante o identificación..."
              className="w-full sm:w-80"
            />
          </FilterBar>

          <DataTable
            columns={reinspeccionesColumns}
            data={reinspecciones}
            isLoading={reinspeccionesQuery.isLoading}
            isFetching={reinspeccionesQuery.isFetching}
            pagination={{
              page: reinspeccionesMeta.current_page,
              pageSize: reinspeccionesMeta.per_page,
              total: reinspeccionesMeta.total,
            }}
            onPaginationChange={setReinspeccionesPage}
          />
        </TabsContent>
      </Tabs>

      <InspeccionFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        reinspeccionBase={reinspeccionBase}
        onSubmit={async (payload) => {
          try {
            await createMutation.mutateAsync(payload)
            setFormOpen(false)
            setReinspeccionBase(null)
          } catch (error) {
            if (isAxiosError(error) && error.response?.status === 422) {
              throw error
            }

            throw error
          }
        }}
        isLoading={createMutation.isPending}
      />

      <ParticipanteCarneDialog
        open={participanteCarneOpen}
        onOpenChange={setParticipanteCarneOpen}
        participante={selectedParticipante}
        onSubmit={async (payload) => {
          if (!selectedParticipante) {
            return
          }

          try {
            await updateCarneMutation.mutateAsync({
              participanteId: selectedParticipante.id,
              payload,
            })
            setParticipanteCarneOpen(false)
            setSelectedParticipante(null)
          } catch (error) {
            if (isAxiosError(error) && error.response?.status === 422) {
              throw error
            }

            throw error
          }
        }}
        isLoading={updateCarneMutation.isPending}
      />
    </div>
  )
}
