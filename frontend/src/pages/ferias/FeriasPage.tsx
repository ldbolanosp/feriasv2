import { useState } from 'react'
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
import { useFerias, useCreateFeria, useUpdateFeria, useToggleFeria } from '@/hooks/useFerias'
import { FeriaFormDialog } from './FeriaFormDialog'
import type { IFeria, IFeriaForm } from '@/types/feria'

type EstadoFiltro = 'todas' | 'activas' | 'inactivas'

export function FeriasPage() {
  const { hasPermission } = usePermission()

  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [estadoFiltro, setEstadoFiltro] = useState<EstadoFiltro>('todas')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedFeria, setSelectedFeria] = useState<IFeria | null>(null)

  const activaParam =
    estadoFiltro === 'activas' ? true : estadoFiltro === 'inactivas' ? false : null

  const { data, isLoading, isFetching } = useFerias({
    page,
    per_page: 15,
    search: search || undefined,
    activa: activaParam,
  })

  const createMutation = useCreateFeria()
  const updateMutation = useUpdateFeria()
  const toggleMutation = useToggleFeria()

  const ferias = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }

  const handleOpenCreate = () => {
    setSelectedFeria(null)
    setDialogOpen(true)
  }

  const handleOpenEdit = (feria: IFeria) => {
    setSelectedFeria(feria)
    setDialogOpen(true)
  }

  const handleSubmit = async (formData: IFeriaForm) => {
    if (selectedFeria) {
      await updateMutation.mutateAsync({ id: selectedFeria.id, payload: formData })
    } else {
      await createMutation.mutateAsync(formData)
    }
    setDialogOpen(false)
  }

  const handleToggle = (feria: IFeria) => {
    toggleMutation.mutate(feria.id)
  }

  const handleSearchChange = (value: string) => {
    setSearch(value)
    setPage(1)
  }

  const handleEstadoChange = (value: string) => {
    setEstadoFiltro(value as EstadoFiltro)
    setPage(1)
  }

  const isSaving = createMutation.isPending || updateMutation.isPending

  const columns: ColumnDef<IFeria>[] = [
    {
      accessorKey: 'codigo',
      header: 'Código',
      enableSorting: true,
    },
    {
      accessorKey: 'descripcion',
      header: 'Descripción',
      enableSorting: true,
    },
    {
      accessorKey: 'facturacion_publico',
      header: 'Fact. Público',
      cell: ({ row }) => (
        <span
          className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${
            row.original.facturacion_publico
              ? 'bg-green-100 text-green-700 border-green-200'
              : 'bg-gray-100 text-gray-600 border-gray-200'
          }`}
        >
          {row.original.facturacion_publico ? 'Sí' : 'No'}
        </span>
      ),
    },
    {
      accessorKey: 'activa',
      header: 'Estado',
      cell: ({ row }) => (
        <StatusBadge status={row.original.activa ? 'activo' : 'inactivo'} />
      ),
    },
    {
      id: 'acciones',
      header: '',
      cell: ({ row }) => {
        const feria = row.original
        const canEdit = hasPermission('ferias.editar')
        const canToggle = hasPermission('ferias.activar')

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
                <DropdownMenuItem onClick={() => handleOpenEdit(feria)}>
                  Editar
                </DropdownMenuItem>
              )}
              {canToggle && (
                <DropdownMenuItem onClick={() => handleToggle(feria)}>
                  {feria.activa ? 'Desactivar' : 'Activar'}
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
        title="Ferias"
        action={
          hasPermission('ferias.crear')
            ? { label: 'Nueva Feria', icon: Plus, onClick: handleOpenCreate }
            : undefined
        }
      />

      <div className="space-y-3">
        <FilterBar>
          <SearchInput
            value={search}
            onChange={handleSearchChange}
            placeholder="Buscar por código o descripción..."
            className="w-full sm:w-64"
          />
          <Select value={estadoFiltro} onValueChange={handleEstadoChange}>
            <SelectTrigger className="w-full sm:w-36">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todas">Todas</SelectItem>
              <SelectItem value="activas">Activas</SelectItem>
              <SelectItem value="inactivas">Inactivas</SelectItem>
            </SelectContent>
          </Select>
        </FilterBar>

        <DataTable
          columns={columns}
          data={ferias}
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

      <FeriaFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        feria={selectedFeria}
        onSubmit={handleSubmit}
        isLoading={isSaving}
      />
    </div>
  )
}
