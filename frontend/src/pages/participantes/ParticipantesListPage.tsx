import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Plus, MoreHorizontal } from 'lucide-react'
import type { ColumnDef } from '@tanstack/react-table'
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
import { useParticipantes, useToggleParticipante } from '@/hooks/useParticipantes'
import { useFerias } from '@/hooks/useFerias'
import type { IParticipante } from '@/types/participante'
import {
  ETIQUETAS_TIPO_IDENTIFICACION,
  TIPOS_IDENTIFICACION,
  etiquetaTipoIdentificacion,
} from '@/types/participante'
import { cn } from '@/lib/utils'

type EstadoFiltro = 'todos' | 'activos' | 'inactivos'

function getInfoVencimientoCarne(fecha: string | null | undefined): {
  texto: string
  variante: 'normal' | 'advertencia' | 'vencido' | 'vacío'
} {
  if (!fecha) {
    return { texto: '—', variante: 'vacío' }
  }
  const fin = new Date(fecha + 'T12:00:00')
  const hoy = new Date()
  hoy.setHours(0, 0, 0, 0)
  const finDia = new Date(fin)
  finDia.setHours(0, 0, 0, 0)
  const diffDias = Math.ceil((finDia.getTime() - hoy.getTime()) / (1000 * 60 * 60 * 24))

  const texto = new Intl.DateTimeFormat('es-CR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(fin)

  if (diffDias < 0) {
    return { texto, variante: 'vencido' }
  }
  if (diffDias <= 30) {
    return { texto, variante: 'advertencia' }
  }
  return { texto, variante: 'normal' }
}

export function ParticipantesListPage() {
  const navigate = useNavigate()
  const { hasPermission } = usePermission()

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [estadoFiltro, setEstadoFiltro] = useState<EstadoFiltro>('todos')
  const [tipoIdentificacionFiltro, setTipoIdentificacionFiltro] = useState<string>('todos')
  const [feriaFiltro, setFeriaFiltro] = useState<string>('todas')

  const activoParam =
    estadoFiltro === 'activos' ? true : estadoFiltro === 'inactivos' ? false : null

  const { data: feriasData } = useFerias({ per_page: 100, page: 1 })
  const feriasOpciones = feriasData?.data ?? []

  const { data, isLoading, isFetching } = useParticipantes({
    page,
    per_page: 15,
    search: search || undefined,
    activo: activoParam,
    tipo_identificacion:
      tipoIdentificacionFiltro !== 'todos' ? tipoIdentificacionFiltro : undefined,
    feria_id: feriaFiltro !== 'todas' ? Number(feriaFiltro) : undefined,
  })

  const toggleMutation = useToggleParticipante()

  const participantes = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }

  const handleSearchChange = (value: string) => {
    setSearch(value)
    setPage(1)
  }

  const handleEstadoChange = (value: string) => {
    setEstadoFiltro(value as EstadoFiltro)
    setPage(1)
  }

  const handleTipoIdentificacionChange = (value: string) => {
    setTipoIdentificacionFiltro(value)
    setPage(1)
  }

  const handleFeriaChange = (value: string) => {
    setFeriaFiltro(value)
    setPage(1)
  }

  const columns: ColumnDef<IParticipante>[] = [
    {
      accessorKey: 'nombre',
      header: 'Nombre',
      enableSorting: true,
    },
    {
      id: 'identificacion',
      header: 'Identificación',
      cell: ({ row }) => {
        const p = row.original
        return (
          <div className="max-w-[220px]">
            <span className="text-muted-foreground text-xs">
              {etiquetaTipoIdentificacion(p.tipo_identificacion)}
            </span>
            <br />
            <span className="font-medium">{p.numero_identificacion}</span>
          </div>
        )
      },
    },
    {
      accessorKey: 'telefono',
      header: 'Teléfono',
      cell: ({ row }) => row.original.telefono ?? '—',
    },
    {
      accessorKey: 'numero_carne',
      header: 'Carné',
      cell: ({ row }) => row.original.numero_carne ?? '—',
    },
    {
      id: 'vencimiento_carne',
      header: 'Venc. Carné',
      cell: ({ row }) => {
        const info = getInfoVencimientoCarne(row.original.fecha_vencimiento_carne)
        return (
          <span
            className={cn(
              'text-sm',
              info.variante === 'vencido' && 'font-medium text-red-700',
              info.variante === 'advertencia' &&
                'rounded-md bg-yellow-100 px-2 py-0.5 font-medium text-yellow-800',
              info.variante === 'normal' && 'text-foreground',
            )}
            title={
              info.variante === 'advertencia'
                ? 'Carné próximo a vencer (30 días o menos)'
                : info.variante === 'vencido'
                  ? 'Carné vencido'
                  : undefined
            }
          >
            {info.texto}
          </span>
        )
      },
    },
    {
      accessorKey: 'activo',
      header: 'Estado',
      cell: ({ row }) => (
        <StatusBadge status={row.original.activo ? 'activo' : 'inactivo'} />
      ),
    },
    {
      id: 'acciones',
      header: '',
      cell: ({ row }) => {
        const participante = row.original
        const canEdit = hasPermission('participantes.editar')
        const canToggle = hasPermission('participantes.activar')

        if (!canEdit && !canToggle) return null

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
                <DropdownMenuItem asChild>
                  <Link to={`/configuracion/participantes/${participante.id}/editar`}>
                    Editar
                  </Link>
                </DropdownMenuItem>
              )}
              {canToggle && (
                <DropdownMenuItem
                  onClick={() => toggleMutation.mutate(participante.id)}
                  disabled={toggleMutation.isPending}
                >
                  {participante.activo ? 'Desactivar' : 'Activar'}
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
        title="Participantes"
        action={
          hasPermission('participantes.crear')
            ? {
                label: 'Nuevo participante',
                icon: Plus,
                onClick: () => navigate('/configuracion/participantes/crear'),
              }
            : undefined
        }
      />

      <div className="space-y-3">
        <FilterBar>
          <SearchInput
            value={search}
            onChange={handleSearchChange}
            placeholder="Buscar por nombre o identificación..."
            className="w-full sm:w-64"
          />
          <Select value={estadoFiltro} onValueChange={handleEstadoChange}>
            <SelectTrigger className="w-full sm:w-36">
              <SelectValue placeholder="Estado" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos</SelectItem>
              <SelectItem value="activos">Activos</SelectItem>
              <SelectItem value="inactivos">Inactivos</SelectItem>
            </SelectContent>
          </Select>
          <Select value={tipoIdentificacionFiltro} onValueChange={handleTipoIdentificacionChange}>
            <SelectTrigger className="w-full sm:w-48">
              <SelectValue placeholder="Tipo ID" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Tipo identificación</SelectItem>
              {TIPOS_IDENTIFICACION.map((t) => (
                <SelectItem key={t} value={t}>
                  {ETIQUETAS_TIPO_IDENTIFICACION[t]}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={feriaFiltro} onValueChange={handleFeriaChange}>
            <SelectTrigger className="w-full sm:w-56">
              <SelectValue placeholder="Feria" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todas">Todas las ferias</SelectItem>
              {feriasOpciones.map((f) => (
                <SelectItem key={f.id} value={String(f.id)}>
                  {f.codigo} — {f.descripcion}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </FilterBar>

        <DataTable
          columns={columns}
          data={participantes}
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
    </div>
  )
}
