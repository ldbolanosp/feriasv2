import { useMemo, useState } from 'react'
import { Loader2, Plus, Trash2 } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { FormField } from '@/components/shared/FormField'
import { EmptyState } from '@/components/shared/EmptyState'
import { MoneyInput } from '@/components/shared/MoneyInput'
import { useFerias } from '@/hooks/useFerias'
import {
  useAsignarPreciosProducto,
  useEliminarPrecioProducto,
  useProducto,
} from '@/hooks/useProductos'
import type { IFeria } from '@/types/feria'
import type { IProducto } from '@/types/producto'

interface ProductoPreciosDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  producto: IProducto | null
}

const EMPTY_PRECIOS: IProducto['precios'] = []
const EMPTY_FERIAS: IFeria[] = []

export function ProductoPreciosDialog({
  open,
  onOpenChange,
  producto,
}: ProductoPreciosDialogProps) {
  const productoId = producto?.id ?? null
  const { data: productoDetalle, isLoading: isLoadingProducto } = useProducto(productoId, open)
  const { data: feriasData } = useFerias({ page: 1, per_page: 100 })
  const asignarPrecio = useAsignarPreciosProducto()
  const eliminarPrecio = useEliminarPrecioProducto()

  const [feriaSeleccionada, setFeriaSeleccionada] = useState<string>('')
  const [precioNuevo, setPrecioNuevo] = useState<number | null>(null)

  const productoActual = productoDetalle ?? producto
  const precios = productoActual?.precios ?? EMPTY_PRECIOS
  const ferias = feriasData?.data ?? EMPTY_FERIAS

  const feriasDisponibles = useMemo(() => {
    const asignadas = new Set(precios.map((precio) => precio.feria_id))
    return ferias.filter((feria) => !asignadas.has(feria.id))
  }, [ferias, precios])

  const isBusy =
    isLoadingProducto || asignarPrecio.isPending || eliminarPrecio.isPending

  const handleAgregarPrecio = async () => {
    if (!productoActual || feriaSeleccionada === '' || precioNuevo === null) {
      return
    }

    await asignarPrecio.mutateAsync({
      productoId: productoActual.id,
      payload: {
        precios: [
          {
            feria_id: Number(feriaSeleccionada),
            precio: precioNuevo,
          },
        ],
      },
    })

    setFeriaSeleccionada('')
    setPrecioNuevo(null)
  }

  const handleEliminarPrecio = async (feriaId: number) => {
    if (!productoActual) {
      return
    }

    await eliminarPrecio.mutateAsync({ productoId: productoActual.id, feriaId })
  }

  const handleOpenChange = (nextOpen: boolean) => {
    if (!nextOpen) {
      setFeriaSeleccionada('')
      setPrecioNuevo(null)
    }

    onOpenChange(nextOpen)
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>Gestionar precios</DialogTitle>
          <DialogDescription>
            {productoActual
              ? `${productoActual.codigo} · ${productoActual.descripcion}`
              : 'Cargando producto...'}
          </DialogDescription>
        </DialogHeader>

        {isLoadingProducto && !productoActual ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 className="size-7 animate-spin text-muted-foreground" />
          </div>
        ) : !productoActual ? (
          <EmptyState
            title="No se pudo cargar el producto"
            description="Cierre el panel e intente nuevamente."
            className="py-10"
          />
        ) : (
          <div className="space-y-6">
            <div className="rounded-xl border bg-muted/20 p-4">
              <div className="mb-4 flex flex-wrap items-center gap-2">
                <Badge variant="secondary">{precios.length} ferias con precio</Badge>
                <Badge variant={productoActual.activo ? 'default' : 'outline'}>
                  {productoActual.activo ? 'Activo' : 'Inactivo'}
                </Badge>
              </div>

              <div className="grid gap-4 md:grid-cols-[1.2fr_1fr_auto]">
                <FormField label="Feria">
                  <Select
                    value={feriaSeleccionada}
                    onValueChange={setFeriaSeleccionada}
                    disabled={isBusy || feriasDisponibles.length === 0}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Seleccione una feria" />
                    </SelectTrigger>
                    <SelectContent>
                      {feriasDisponibles.map((feria) => (
                        <SelectItem key={feria.id} value={String(feria.id)}>
                          {feria.codigo} — {feria.descripcion}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </FormField>

                <FormField label="Precio">
                  <MoneyInput
                    value={precioNuevo}
                    onChange={setPrecioNuevo}
                    disabled={isBusy}
                    placeholder="0.00"
                  />
                </FormField>

                <div className="flex items-end">
                  <Button
                    type="button"
                    onClick={handleAgregarPrecio}
                    disabled={
                      isBusy ||
                      feriaSeleccionada === '' ||
                      precioNuevo === null ||
                      precioNuevo <= 0
                    }
                    className="w-full md:w-auto"
                  >
                    {asignarPrecio.isPending ? (
                      <Loader2 className="size-4 animate-spin" />
                    ) : (
                      <Plus className="size-4" />
                    )}
                    Agregar
                  </Button>
                </div>
              </div>

              {feriasDisponibles.length === 0 && (
                <p className="mt-3 text-sm text-muted-foreground">
                  Este producto ya tiene precio asignado en todas las ferias disponibles.
                </p>
              )}
            </div>

            <div className="rounded-xl border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Feria</TableHead>
                    <TableHead>Precio</TableHead>
                    <TableHead className="w-[72px]" />
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {precios.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={3} className="py-10 text-center">
                        <EmptyState
                          title="Sin precios asignados"
                          description="Agregue un precio para empezar a vender este producto en una feria."
                          className="py-2"
                        />
                      </TableCell>
                    </TableRow>
                  ) : (
                    precios.map((precio) => (
                      <TableRow key={precio.id}>
                        <TableCell>
                          {precio.feria ? (
                            <div className="space-y-0.5">
                              <p className="font-medium">{precio.feria.descripcion}</p>
                              <p className="text-xs text-muted-foreground">
                                {precio.feria.codigo}
                              </p>
                            </div>
                          ) : (
                            `Feria #${precio.feria_id}`
                          )}
                        </TableCell>
                        <TableCell className="font-medium">
                          {new Intl.NumberFormat('es-CR', {
                            style: 'currency',
                            currency: 'CRC',
                            minimumFractionDigits: 2,
                          }).format(Number(precio.precio))}
                        </TableCell>
                        <TableCell className="text-right">
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            onClick={() => handleEliminarPrecio(precio.feria_id)}
                            disabled={isBusy}
                          >
                            {eliminarPrecio.isPending ? (
                              <Loader2 className="size-4 animate-spin" />
                            ) : (
                              <Trash2 className="size-4 text-destructive" />
                            )}
                            <span className="sr-only">Eliminar precio</span>
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>
          </div>
        )}

        <DialogFooter>
          <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
            Cerrar
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
