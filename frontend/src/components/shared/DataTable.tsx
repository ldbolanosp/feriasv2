import {
  flexRender,
  getCoreRowModel,
  useReactTable,
  type ColumnDef,
  type SortingState,
} from '@tanstack/react-table'
import { useState } from 'react'
import { ChevronUp, ChevronDown, ChevronsUpDown, ChevronLeft, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

interface PaginationState {
  page: number
  pageSize: number
  total: number
}

interface DataTableProps<TData> {
  columns: ColumnDef<TData>[]
  data: TData[]
  isLoading?: boolean
  isFetching?: boolean
  pagination: PaginationState
  onPaginationChange: (page: number) => void
  onSortChange?: (sorting: SortingState) => void
}

export function DataTable<TData>({
  columns,
  data,
  isLoading = false,
  isFetching = false,
  pagination,
  onPaginationChange,
  onSortChange,
}: DataTableProps<TData>) {
  const [sorting, setSorting] = useState<SortingState>([])

  const table = useReactTable({
    data,
    columns,
    state: { sorting },
    onSortingChange: (updater) => {
      const newSorting = typeof updater === 'function' ? updater(sorting) : updater
      setSorting(newSorting)
      onSortChange?.(newSorting)
    },
    getCoreRowModel: getCoreRowModel(),
    manualPagination: true,
    manualSorting: true,
    rowCount: pagination.total,
  })

  const totalPages = Math.ceil(pagination.total / pagination.pageSize)
  const from = pagination.total === 0 ? 0 : (pagination.page - 1) * pagination.pageSize + 1
  const to = Math.min(pagination.page * pagination.pageSize, pagination.total)

  return (
    <div className="space-y-3">
      <div className="relative overflow-hidden rounded-md border">
        {isFetching && !isLoading && (
          <div className="absolute inset-x-0 top-0 z-10 h-0.5 overflow-hidden rounded-t-md bg-transparent">
            <div className="h-full w-1/3 animate-pulse rounded-full bg-primary/80" />
          </div>
        )}
        <Table className="min-w-[720px]">
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => {
                  const canSort = header.column.getCanSort()
                  const sorted = header.column.getIsSorted()

                  return (
                    <TableHead key={header.id}>
                      {header.isPlaceholder ? null : (
                        <button
                          className={
                            canSort
                              ? 'flex items-center gap-1 hover:text-foreground transition-colors'
                              : undefined
                          }
                          onClick={canSort ? header.column.getToggleSortingHandler() : undefined}
                        >
                          {flexRender(header.column.columnDef.header, header.getContext())}
                          {canSort && (
                            <span className="ml-1 text-muted-foreground">
                              {sorted === 'asc' ? (
                                <ChevronUp className="size-3" />
                              ) : sorted === 'desc' ? (
                                <ChevronDown className="size-3" />
                              ) : (
                                <ChevronsUpDown className="size-3" />
                              )}
                            </span>
                          )}
                        </button>
                      )}
                    </TableHead>
                  )
                })}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {isLoading ? (
              Array.from({ length: pagination.pageSize > 10 ? 10 : pagination.pageSize }).map(
                (_, i) => (
                  <TableRow key={i}>
                    {columns.map((_, j) => (
                      <TableCell key={j}>
                        <Skeleton className="h-4 w-full" />
                      </TableCell>
                    ))}
                  </TableRow>
                ),
              )
            ) : table.getRowModel().rows.length === 0 ? (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-24 text-center text-muted-foreground">
                  No se encontraron registros
                </TableCell>
              </TableRow>
            ) : (
              table.getRowModel().rows.map((row) => (
                <TableRow key={row.id}>
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <div className="flex flex-col gap-2 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
        <span>
          {pagination.total === 0
            ? 'Sin resultados'
            : `Mostrando ${from}–${to} de ${pagination.total}`}
        </span>
        <div className="flex flex-wrap items-center gap-3">
          {isFetching && !isLoading && (
            <span className="text-xs text-muted-foreground">Actualizando...</span>
          )}
          <Button
            variant="outline"
            size="icon"
            className="size-8"
            disabled={pagination.page <= 1 || isLoading || isFetching}
            onClick={() => onPaginationChange(pagination.page - 1)}
          >
            <ChevronLeft className="size-4" />
          </Button>
          <span>
            Página {pagination.page} de {totalPages || 1}
          </span>
          <Button
            variant="outline"
            size="icon"
            className="size-8"
            disabled={pagination.page >= totalPages || isLoading || isFetching}
            onClick={() => onPaginationChange(pagination.page + 1)}
          >
            <ChevronRight className="size-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}
