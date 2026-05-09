import { useEffect, useMemo, useState } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { isAxiosError } from 'axios'
import { AlertTriangle, Loader2, Plus, Receipt, Trash2 } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { useNavigate, useParams } from 'react-router-dom'
import { z } from 'zod'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { ComboboxSearch } from '@/components/shared/ComboboxSearch'
import { FormField } from '@/components/shared/FormField'
import { MoneyInput } from '@/components/shared/MoneyInput'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { Switch } from '@/components/ui/switch'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Textarea } from '@/components/ui/textarea'
import { useCreateFactura, useFactura, useFacturarFactura, useUpdateFactura } from '@/hooks/useFacturas'
import { useMetodosPagoCatalogoFacturacion } from '@/hooks/useMetodosPago'
import { useParticipantesPorFeria } from '@/hooks/useParticipantes'
import { useProductosPorFeria } from '@/hooks/useProductos'
import { openFacturaPdf } from '@/services/facturaService'
import { useFeriaStore } from '@/stores/feriaStore'
import type { IFacturaFormPayload } from '@/types/factura'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

const schema = z.object({
  es_publico_general: z.boolean(),
  nombre_publico: z.string(),
  participante_id: z.number().nullable(),
  tipo_puesto: z.string(),
  numero_puesto: z.string(),
  metodo_pago_id: z.number().nullable(),
  monto_pago: z.number().nullable(),
  observaciones: z.string(),
})

type FacturaFormValues = z.infer<typeof schema>

interface DetalleLocal {
  producto_id: number
  descripcion_producto: string
  cantidad: number
  precio_unitario: number
  subtotal_linea: number
}

const defaultValues: FacturaFormValues = {
  es_publico_general: false,
  nombre_publico: '',
  participante_id: null,
  tipo_puesto: '',
  numero_puesto: '',
  metodo_pago_id: null,
  monto_pago: null,
  observaciones: '',
}

function toPayload(values: FacturaFormValues, detalles: DetalleLocal[]): IFacturaFormPayload {
  const nullableTrimmed = (value: string) => {
    const trimmed = value.trim()
    return trimmed === '' ? null : trimmed
  }

  return {
    es_publico_general: values.es_publico_general,
    nombre_publico: values.es_publico_general ? nullableTrimmed(values.nombre_publico) : null,
    participante_id: values.es_publico_general ? null : values.participante_id,
    tipo_puesto: nullableTrimmed(values.tipo_puesto),
    numero_puesto: nullableTrimmed(values.numero_puesto),
    metodo_pago_id: values.metodo_pago_id,
    monto_pago: values.monto_pago,
    observaciones: nullableTrimmed(values.observaciones),
    detalles: detalles.map((detalle) => ({
      producto_id: detalle.producto_id,
      cantidad: detalle.cantidad,
    })),
  }
}

function normalizeNumber(value: string | null | undefined): number | null {
  if (!value) {
    return null
  }

  const parsed = Number(value)
  return Number.isNaN(parsed) ? null : parsed
}

export function FacturacionFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const feriaActiva = useFeriaStore((state) => state.feriaActiva)

  const facturaId = id ? Number(id) : null
  const isEditing = facturaId !== null && !Number.isNaN(facturaId)

  const [detalleProductoId, setDetalleProductoId] = useState<number | null>(null)
  const [detalleCantidad, setDetalleCantidad] = useState(1)
  const [detalleSearch, setDetalleSearch] = useState('')
  const [participanteSearch, setParticipanteSearch] = useState('')
  const [detalles, setDetalles] = useState<DetalleLocal[]>([])
  const [confirmSaveOpen, setConfirmSaveOpen] = useState(false)
  const [confirmFacturarOpen, setConfirmFacturarOpen] = useState(false)
  const [confirmCancelOpen, setConfirmCancelOpen] = useState(false)
  const [detailError, setDetailError] = useState<string | null>(null)

  const { data: factura, isLoading: isLoadingFactura } = useFactura(facturaId, isEditing)
  const { data: participantes = [], isFetching: isFetchingParticipantes } =
    useParticipantesPorFeria(participanteSearch)
  const { data: productos = [], isFetching: isFetchingProductos } =
    useProductosPorFeria(detalleSearch)
  const { data: metodosPago = [] } = useMetodosPagoCatalogoFacturacion()

  const createFacturaMutation = useCreateFactura()
  const updateFacturaMutation = useUpdateFactura()
  const facturarFacturaMutation = useFacturarFactura()

  const {
    register,
    watch,
    reset,
    setValue,
    setError,
    clearErrors,
    formState: { errors, isDirty },
    handleSubmit,
  } = useForm<FacturaFormValues>({
    resolver: zodResolver(schema),
    defaultValues,
  })

  const esPublicoGeneral = watch('es_publico_general')
  const participanteId = watch('participante_id')
  const metodoPagoId = watch('metodo_pago_id')
  const montoPago = watch('monto_pago')

  const total = useMemo(
    () => detalles.reduce((acc, detalle) => acc + detalle.subtotal_linea, 0),
    [detalles],
  )

  const cambio = montoPago != null ? montoPago - total : null

  const productosDisponibles = useMemo(
    () => productos.filter((producto) => !detalles.some((detalle) => detalle.producto_id === producto.id)),
    [detalles, productos],
  )

  const selectedProducto =
    productosDisponibles.find((producto) => producto.id === detalleProductoId) ?? null
  const selectedParticipante = participantes.find((item) => item.id === participanteId) ?? null

  const hasUnsavedDetailChanges =
    JSON.stringify(
      detalles.map((detalle) => ({
        producto_id: detalle.producto_id,
        cantidad: detalle.cantidad,
      })),
    ) !==
    JSON.stringify(
      (factura?.detalles ?? []).map((detalle) => ({
        producto_id: detalle.producto_id,
        cantidad: Number(detalle.cantidad),
      })),
    )

  const isBusy =
    createFacturaMutation.isPending ||
    updateFacturaMutation.isPending ||
    facturarFacturaMutation.isPending

  useEffect(() => {
    if (!feriaActiva?.facturacion_publico && esPublicoGeneral) {
      setValue('es_publico_general', false, { shouldDirty: true })
    }
  }, [esPublicoGeneral, feriaActiva?.facturacion_publico, setValue])

  useEffect(() => {
    if (metodoPagoId !== null) {
      return
    }

    const metodoPagoEfectivo = metodosPago.find((metodoPago) => metodoPago.nombre === 'Efectivo')

    if (metodoPagoEfectivo) {
      setValue('metodo_pago_id', metodoPagoEfectivo.id, { shouldDirty: false })
    }
  }, [metodoPagoId, metodosPago, setValue])

  useEffect(() => {
    if (!isEditing || !factura) {
      return
    }

    reset({
      es_publico_general: factura.es_publico_general,
      nombre_publico: factura.nombre_publico ?? '',
      participante_id: factura.participante_id,
      tipo_puesto: factura.tipo_puesto ?? '',
      numero_puesto: factura.numero_puesto ?? '',
      metodo_pago_id: factura.metodo_pago_id,
      monto_pago: normalizeNumber(factura.monto_pago),
      observaciones: factura.observaciones ?? '',
    })

    setDetalles(
      factura.detalles.map((detalle) => ({
        producto_id: detalle.producto_id,
        descripcion_producto: detalle.descripcion_producto,
        cantidad: Number(detalle.cantidad),
        precio_unitario: Number(detalle.precio_unitario),
        subtotal_linea: Number(detalle.subtotal_linea),
      })),
    )
  }, [factura, isEditing, reset])

  const participanteOptions = participantes.map((item) => ({
    value: item.id,
    label: `${item.nombre} · ${item.numero_identificacion}`,
  }))

  const productoOptions = productosDisponibles.map((producto) => ({
    value: producto.id,
    label: `${producto.descripcion} · ₡${Number(producto.precio_feria_actual ?? 0).toFixed(2)}`,
  }))

  const handleAddDetalle = () => {
    if (!selectedProducto) {
      setDetailError('Seleccione un producto para agregar.')
      return
    }

    const cantidad = Number(detalleCantidad)
    if (Number.isNaN(cantidad) || cantidad < 1 || cantidad % 0.5 !== 0) {
      setDetailError('La cantidad debe ser mínimo 1 y avanzar en incrementos de 0.5.')
      return
    }

    const precio = Number(selectedProducto.precio_feria_actual ?? 0)
    const subtotal = cantidad * precio

    setDetalles((current) => [
      ...current,
      {
        producto_id: selectedProducto.id,
        descripcion_producto: selectedProducto.descripcion,
        cantidad,
        precio_unitario: precio,
        subtotal_linea: subtotal,
      },
    ])
    setDetalleProductoId(null)
    setDetalleCantidad(1)
    setDetalleSearch('')
    setDetailError(null)
  }

  const handleRemoveDetalle = (productoId: number) => {
    setDetalles((current) => current.filter((detalle) => detalle.producto_id !== productoId))
  }

  const mapValidationErrors = (error: unknown) => {
    if (!isAxiosError(error) || error.response?.status !== 422) {
      return
    }

    const backendErrors = error.response.data?.errors as Record<string, string[]> | undefined
    if (!backendErrors) {
      return
    }

    Object.entries(backendErrors).forEach(([field, messages]) => {
      const message = messages[0]
      if (!message) {
        return
      }

      if (
        field === 'nombre_publico' ||
        field === 'participante_id' ||
        field === 'tipo_puesto' ||
        field === 'numero_puesto' ||
        field === 'monto_pago' ||
        field === 'observaciones'
      ) {
        setError(field as keyof FacturaFormValues, { type: 'server', message })
      }

      if (field === 'detalles' || field.startsWith('detalles.')) {
        setDetailError(message)
      }
    })
  }

  const saveDraft = async (values: FacturaFormValues) => {
    if (!values.es_publico_general && values.participante_id == null) {
      setError('participante_id', { type: 'manual', message: 'Seleccione un participante.' })
      return null
    }

    if (values.es_publico_general && values.nombre_publico.trim() === '') {
      setError('nombre_publico', { type: 'manual', message: 'Ingrese el nombre del cliente.' })
      return null
    }

    if (detalles.length === 0) {
      setDetailError('Agregue al menos un producto a la factura.')
      return null
    }

    clearErrors()
    setDetailError(null)
    const payload = toPayload(values, detalles)

    try {
      if (isEditing && facturaId !== null) {
        return await updateFacturaMutation.mutateAsync({ id: facturaId, payload })
      }

      return await createFacturaMutation.mutateAsync(payload)
    } catch (error) {
      mapValidationErrors(error)
      throw error
    }
  }

  const handleSave = handleSubmit(async (values) => {
    const saved = await saveDraft(values)
    if (saved) {
      navigate('/facturacion')
    }
  })

  const handleFacturar = handleSubmit(async (values) => {
    const saved = await saveDraft(values)
    if (!saved) {
      return
    }

    const issued = await facturarFacturaMutation.mutateAsync(saved.id)
    await openFacturaPdf(issued.id, true)
    navigate('/facturacion')
  })

  const handleCancel = () => {
    if (isDirty || hasUnsavedDetailChanges) {
      setConfirmCancelOpen(true)
      return
    }

    navigate('/facturacion')
  }

  const isReadOnly = isEditing && factura?.estado !== 'borrador'

  return (
    <div className="space-y-6 pb-10">
      <PageHeader
        title={isEditing ? 'Editar Factura' : 'Nueva Factura'}
        description="Capture la factura completa y emítala cuando confirme el cobro."
        backUrl="/facturacion"
      />

      <div className="flex flex-wrap items-center gap-3">
        {feriaActiva ? (
          <Badge variant="secondary" className="rounded-full px-3 py-1">
            Feria activa: {feriaActiva.codigo} · {feriaActiva.descripcion}
          </Badge>
        ) : (
          <Badge variant="destructive" className="rounded-full px-3 py-1">
            Seleccione una feria para continuar
          </Badge>
        )}
        {factura?.estado && <StatusBadge status={factura.estado} />}
      </div>

      {isLoadingFactura ? (
        <Card>
          <CardContent className="flex items-center justify-center py-16">
            <Loader2 className="size-5 animate-spin" />
          </CardContent>
        </Card>
      ) : isReadOnly ? (
        <Card className="border-amber-300 bg-amber-50/60">
          <CardContent className="flex items-center gap-3 py-8 text-amber-900">
            <AlertTriangle className="size-5 shrink-0" />
            <div>
              <p className="font-medium">Esta factura ya no se puede editar.</p>
              <p className="text-sm text-amber-800">
                Solo los borradores permiten cambios antes de emitirse.
              </p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <>
          <div className="grid gap-6 xl:grid-cols-[minmax(0,1.5fr)_minmax(340px,0.9fr)]">
            <div className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Encabezado</CardTitle>
                  <CardDescription>
                    Defina el cliente, puesto y observaciones generales de la factura.
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-5">
                  {feriaActiva?.facturacion_publico && (
                    <div className="flex flex-col gap-4 rounded-lg border bg-muted/40 px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
                      <div>
                        <Label className="text-sm font-medium">Público general</Label>
                        <p className="text-sm text-muted-foreground">
                          Active esta opción para cobrar sin participante registrado.
                        </p>
                      </div>
                      <Switch
                        checked={esPublicoGeneral}
                        onCheckedChange={(checked) => {
                          setValue('es_publico_general', checked, { shouldDirty: true })
                          if (checked) {
                            setValue('participante_id', null, { shouldDirty: true })
                            clearErrors('participante_id')
                          } else {
                            setValue('nombre_publico', '', { shouldDirty: true })
                            clearErrors('nombre_publico')
                          }
                        }}
                      />
                    </div>
                  )}

                  {esPublicoGeneral ? (
                    <FormField
                      label="Nombre público"
                      required
                      error={errors.nombre_publico?.message}
                    >
                      <Input
                        {...register('nombre_publico')}
                        placeholder="Ej. Cliente de contado"
                      />
                    </FormField>
                  ) : (
                    <FormField
                      label="Participante"
                      required
                      error={errors.participante_id?.message}
                    >
                      <ComboboxSearch
                        options={participanteOptions}
                        value={participanteId}
                        onSelect={(value) => {
                          setValue('participante_id', value ? Number(value) : null, {
                            shouldDirty: true,
                          })
                        }}
                        onSearch={setParticipanteSearch}
                        isLoading={isFetchingParticipantes}
                        placeholder={
                          selectedParticipante
                            ? `${selectedParticipante.nombre} · ${selectedParticipante.numero_identificacion}`
                            : 'Buscar participante'
                        }
                        className="w-full"
                      />
                    </FormField>
                  )}

                  <div className="grid gap-4 md:grid-cols-2">
                    <FormField label="Tipo de puesto" error={errors.tipo_puesto?.message}>
                      <Input {...register('tipo_puesto')} placeholder="Ej. Frutas y verduras" />
                    </FormField>
                    <FormField label="Número de puesto" error={errors.numero_puesto?.message}>
                      <Input {...register('numero_puesto')} placeholder="Ej. B-14" />
                    </FormField>
                  </div>

                  <FormField label="Observaciones" error={errors.observaciones?.message}>
                    <Textarea
                      {...register('observaciones')}
                      placeholder="Notas internas o detalles del cobro"
                      rows={4}
                    />
                  </FormField>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Productos</CardTitle>
                  <CardDescription>
                    Agregue los productos facturados y verifique el subtotal por línea.
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-5">
                  <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-[minmax(0,1fr)_120px_120px_120px_auto]">
                    <div className="space-y-1.5">
                      <Label>Producto</Label>
                      <ComboboxSearch
                        options={productoOptions}
                        value={detalleProductoId}
                        onSelect={(value) => setDetalleProductoId(value ? Number(value) : null)}
                        onSearch={setDetalleSearch}
                        isLoading={isFetchingProductos}
                        placeholder="Buscar producto"
                        className="w-full"
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label>Cantidad</Label>
                      <Input
                        type="number"
                        min={1}
                        step={0.5}
                        value={detalleCantidad}
                        onChange={(event) => setDetalleCantidad(Number(event.target.value))}
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label>Precio</Label>
                      <Input
                        value={
                          selectedProducto
                            ? `₡${Number(selectedProducto.precio_feria_actual ?? 0).toFixed(2)}`
                            : '₡0.00'
                        }
                        disabled
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label>Subtotal</Label>
                      <Input
                        value={
                          selectedProducto
                            ? `₡${(
                                detalleCantidad * Number(selectedProducto.precio_feria_actual ?? 0)
                              ).toFixed(2)}`
                            : '₡0.00'
                        }
                        disabled
                      />
                    </div>
                    <div className="flex items-end">
                      <Button
                        type="button"
                        onClick={handleAddDetalle}
                        disabled={!selectedProducto || detalleCantidad < 1}
                        className="w-full lg:w-auto"
                      >
                        <Plus className="size-4" />
                        Agregar
                      </Button>
                    </div>
                  </div>

                  {detailError && (
                    <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
                      {detailError}
                    </div>
                  )}

                  <div className="rounded-xl border">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Producto</TableHead>
                          <TableHead className="text-right">Cantidad</TableHead>
                          <TableHead className="text-right">Precio</TableHead>
                          <TableHead className="text-right">Subtotal</TableHead>
                          <TableHead className="w-14 text-right">Acción</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {detalles.length === 0 ? (
                          <TableRow>
                            <TableCell colSpan={5} className="py-10 text-center text-muted-foreground">
                              Agregue al menos un producto para continuar.
                            </TableCell>
                          </TableRow>
                        ) : (
                          detalles.map((detalle) => (
                            <TableRow key={detalle.producto_id}>
                              <TableCell className="font-medium">{detalle.descripcion_producto}</TableCell>
                              <TableCell className="text-right">{detalle.cantidad.toFixed(1)}</TableCell>
                              <TableCell className="text-right">
                                ₡{detalle.precio_unitario.toFixed(2)}
                              </TableCell>
                              <TableCell className="text-right">
                                ₡{detalle.subtotal_linea.toFixed(2)}
                              </TableCell>
                              <TableCell className="text-right">
                                <Button
                                  type="button"
                                  variant="ghost"
                                  size="icon"
                                  onClick={() => handleRemoveDetalle(detalle.producto_id)}
                                >
                                  <Trash2 className="size-4" />
                                </Button>
                              </TableCell>
                            </TableRow>
                          ))
                        )}
                      </TableBody>
                    </Table>
                  </div>
                </CardContent>
              </Card>
            </div>

            <div className="space-y-6">
              <Card className="sticky top-0">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Receipt className="size-4" />
                    Resumen de cobro
                  </CardTitle>
                  <CardDescription>
                    Revise el total, capture el pago y emita la factura cuando esté lista.
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-5">
                  <div className="space-y-3 rounded-xl border bg-muted/30 p-4">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">Total</span>
                      <span className="text-lg font-semibold">₡{total.toFixed(2)}</span>
                    </div>
                    <Separator />
                    <FormField label="Método de pago" error={errors.metodo_pago_id?.message}>
                      <Select
                        value={metodoPagoId ? String(metodoPagoId) : undefined}
                        onValueChange={(value) =>
                          setValue('metodo_pago_id', Number(value), {
                            shouldDirty: true,
                          })
                        }
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Seleccione un método de pago" />
                        </SelectTrigger>
                        <SelectContent>
                          {metodosPago
                            .filter((metodoPago) => metodoPago.activo || metodoPago.id === metodoPagoId)
                            .map((metodoPago) => (
                              <SelectItem key={metodoPago.id} value={String(metodoPago.id)}>
                                {metodoPago.nombre}
                                {!metodoPago.activo ? ' (Inactivo)' : ''}
                              </SelectItem>
                            ))}
                        </SelectContent>
                      </Select>
                    </FormField>
                    <FormField label="Monto de pago" error={errors.monto_pago?.message}>
                      <MoneyInput
                        value={montoPago}
                        onChange={(value) =>
                          setValue('monto_pago', value, {
                            shouldDirty: true,
                          })
                        }
                        placeholder="Ingrese el monto recibido"
                      />
                    </FormField>
                    <div className="rounded-lg border bg-background px-4 py-3">
                      <p className="text-xs uppercase tracking-[0.2em] text-muted-foreground">
                        Cambio
                      </p>
                      <p
                        className={`mt-1 text-2xl font-semibold ${
                          cambio != null && cambio < 0 ? 'text-destructive' : 'text-foreground'
                        }`}
                      >
                        ₡{(cambio ?? 0).toFixed(2)}
                      </p>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <Button type="button" variant="outline" className="w-full" onClick={handleCancel}>
                      Cancelar
                    </Button>
                    <Button
                      type="button"
                      variant="secondary"
                      className="w-full"
                      disabled={isBusy || detalles.length === 0}
                      onClick={() => setConfirmSaveOpen(true)}
                    >
                      {isBusy && createFacturaMutation.isPending ? (
                        <Loader2 className="size-4 animate-spin" />
                      ) : null}
                      Guardar borrador
                    </Button>
                    <Button
                      type="button"
                      className="w-full"
                      disabled={isBusy || detalles.length === 0 || (cambio != null && cambio < 0)}
                      onClick={() => setConfirmFacturarOpen(true)}
                    >
                      {isBusy && facturarFacturaMutation.isPending ? (
                        <Loader2 className="size-4 animate-spin" />
                      ) : null}
                      Guardar y facturar
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>

          <ConfirmDialog
            open={confirmSaveOpen}
            onCancel={() => setConfirmSaveOpen(false)}
            onConfirm={() => {
              setConfirmSaveOpen(false)
              void handleSave()
            }}
            title="Guardar borrador"
            description="Se conservará la factura en estado borrador para seguir editándola después."
            confirmText="Guardar"
          />

          <ConfirmDialog
            open={confirmFacturarOpen}
            onCancel={() => setConfirmFacturarOpen(false)}
            onConfirm={() => {
              setConfirmFacturarOpen(false)
              void handleFacturar()
            }}
            title="Emitir factura"
            description="Se guardará la factura, se generará el consecutivo y se abrirá el PDF en una nueva pestaña."
            confirmText="Facturar"
          />

          <ConfirmDialog
            open={confirmCancelOpen}
            onCancel={() => setConfirmCancelOpen(false)}
            onConfirm={() => navigate('/facturacion')}
            title="Descartar cambios"
            description="Hay cambios sin guardar en la factura actual. Si continúa, se perderán."
            confirmText="Descartar"
            variant="destructive"
          />
        </>
      )}
    </div>
  )
}
