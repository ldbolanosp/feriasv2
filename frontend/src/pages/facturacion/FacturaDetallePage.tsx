import { useParams } from 'react-router-dom'
import { Loader2 } from 'lucide-react'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { useFactura } from '@/hooks/useFacturas'
import { openFacturaPdf } from '@/services/facturaService'

function formatMoney(value: string | null): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(Number(value ?? 0))
}

function formatDate(value: string | null): string {
  if (!value) {
    return 'Sin fecha'
  }

  return new Intl.DateTimeFormat('es-CR', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function FacturaDetallePage() {
  const { id } = useParams<{ id: string }>()
  const facturaId = id ? Number(id) : null
  const { data: factura, isLoading } = useFactura(facturaId, facturaId !== null)

  if (isLoading) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center gap-2 text-muted-foreground">
        <Loader2 className="size-5 animate-spin" />
        Cargando factura...
      </div>
    )
  }

  if (!factura) {
    return <PageHeader title="Factura no encontrada" backUrl="/facturacion" />
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Factura ${factura.consecutivo ?? `#${factura.id}`}`}
        description="Detalle completo del comprobante."
        backUrl="/facturacion"
      />

      <div className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <Card>
          <CardHeader>
            <CardTitle>Información general</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Estado</span>
              <StatusBadge status={factura.estado} />
            </div>
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Cliente</span>
              <span className="text-right font-medium">
                {factura.es_publico_general
                  ? factura.nombre_publico ?? 'Público general'
                  : factura.participante?.nombre ?? 'Sin participante'}
              </span>
            </div>
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Fecha</span>
              <span>{formatDate(factura.fecha_emision ?? factura.created_at)}</span>
            </div>
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Usuario</span>
              <span>{factura.usuario?.name ?? 'N/A'}</span>
            </div>
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Total</span>
              <span className="font-semibold">{formatMoney(factura.subtotal)}</span>
            </div>
            {factura.observaciones && (
              <div className="rounded-lg border bg-muted/20 p-3 text-sm">
                <p className="mb-1 font-medium">Observaciones</p>
                <p className="text-muted-foreground">{factura.observaciones}</p>
              </div>
            )}
            {factura.estado === 'facturado' && (
              <div className="pt-2">
                <Button onClick={() => void openFacturaPdf(factura.id)}>Abrir PDF</Button>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Resumen de pago</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Subtotal</span>
              <span>{formatMoney(factura.subtotal)}</span>
            </div>
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Pago recibido</span>
              <span>{formatMoney(factura.monto_pago)}</span>
            </div>
            <div className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">Cambio</span>
              <span>{formatMoney(factura.monto_cambio)}</span>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Detalle de líneas</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Producto</TableHead>
                <TableHead>Cantidad</TableHead>
                <TableHead>Precio</TableHead>
                <TableHead>Subtotal</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {factura.detalles.map((detalle) => (
                <TableRow key={detalle.id}>
                  <TableCell>{detalle.descripcion_producto}</TableCell>
                  <TableCell>{detalle.cantidad}</TableCell>
                  <TableCell>{formatMoney(detalle.precio_unitario)}</TableCell>
                  <TableCell>{formatMoney(detalle.subtotal_linea)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
