import { useState } from 'react'
import { isAxiosError } from 'axios'
import { MoreHorizontal, Pencil, Plus, Trash2 } from 'lucide-react'
import type { ColumnDef } from '@tanstack/react-table'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
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
import { useItemsDiagnostico, useCreateItemDiagnostico, useDeleteItemDiagnostico, useUpdateItemDiagnostico } from '@/hooks/useItemsDiagnostico'
import { usePermission } from '@/hooks/usePermission'
import type { IItemDiagnostico, IItemDiagnosticoFormPayload } from '@/types/itemDiagnostico'
import { ItemDiagnosticoFormDialog } from './ItemDiagnosticoFormDialog'

function formatDate(date: string): string {
  return new Intl.DateTimeFormat('es-CR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(date))
}

export function ItemsDiagnosticoPage() {
  const { hasPermission } = usePermission()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [formOpen, setFormOpen] = useState(false)
  const [selectedItem, setSelectedItem] = useState<IItemDiagnostico | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<IItemDiagnostico | null>(null)

  const { data, isLoading, isFetching } = useItemsDiagnostico({
    page,
    per_page: 15,
    search: search || undefined,
  })
  const createMutation = useCreateItemDiagnostico()
  const updateMutation = useUpdateItemDiagnostico()
  const deleteMutation = useDeleteItemDiagnostico()

  const items = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, per_page: 15, total: 0 }
  const isSaving = createMutation.isPending || updateMutation.isPending

  const handleOpenCreate = () => {
    setSelectedItem(null)
    setFormOpen(true)
  }

  const handleOpenEdit = (item: IItemDiagnostico) => {
    setSelectedItem(item)
    setFormOpen(true)
  }

  const handleFormSubmit = async (payload: IItemDiagnosticoFormPayload) => {
    if (selectedItem) {
      await updateMutation.mutateAsync({ id: selectedItem.id, payload })
    } else {
      await createMutation.mutateAsync(payload)
    }

    setFormOpen(false)
  }

  const columns: ColumnDef<IItemDiagnostico>[] = [
    {
      accessorKey: 'nombre',
      header: 'Nombre',
      cell: ({ row }) => <span className="font-medium">{row.original.nombre}</span>,
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
                onClick={() => setDeleteTarget(row.original)}
                className="text-destructive focus:text-destructive"
              >
                <Trash2 className="size-4" />
                Eliminar
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
        title="Items de Diagnóstico"
        description="Catálogo base de items que se podrán evaluar dentro de cada inspección."
        action={
          hasPermission('configuracion.editar')
            ? {
                label: 'Nuevo item',
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
          data={items}
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

      <ItemDiagnosticoFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        item={selectedItem}
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

      <ConfirmDialog
        open={deleteTarget !== null}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (!deleteTarget) {
            return
          }

          deleteMutation.mutate(deleteTarget.id, {
            onSuccess: () => setDeleteTarget(null),
          })
        }}
        title="Eliminar item de diagnóstico"
        description={`Se eliminará "${deleteTarget?.nombre ?? ''}" del catálogo. Las inspecciones ya guardadas conservarán el nombre histórico del item.`}
        confirmText="Eliminar"
        variant="destructive"
      />
    </div>
  )
}
