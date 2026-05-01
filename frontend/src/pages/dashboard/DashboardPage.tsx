import { useState } from 'react'
import type { DateRange } from 'react-day-picker'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import {
  BarChart3,
  Car,
  CreditCard,
  Droplets,
  Loader2,
  Receipt,
  Store,
} from 'lucide-react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { DateRangePicker } from '@/components/shared/DateRangePicker'
import { FilterBar } from '@/components/shared/FilterBar'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatsCard } from '@/components/shared/StatsCard'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  useDashboardFacturacion,
  useDashboardParqueos,
  useDashboardRecaudacionDiaria,
  useDashboardResumen,
} from '@/hooks/useDashboard'
import { useAuthStore } from '@/stores/authStore'

function formatMoney(value: number | string): string {
  return new Intl.NumberFormat('es-CR', {
    style: 'currency',
    currency: 'CRC',
    minimumFractionDigits: 2,
  }).format(Number(value))
}

function tooltipMoneyFormatter(
  value: number | string | readonly (number | string)[] | undefined,
): string {
  const resolvedValue = Array.isArray(value) ? value[0] : value
  return formatMoney(Number(resolvedValue ?? 0))
}

function formatDate(value: string | null): string {
  if (!value) {
    return 'Sin fecha'
  }

  return format(new Date(value), 'dd/MM/yyyy HH:mm', { locale: es })
}

function ChartCard({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  )
}

export function DashboardPage() {
  const roles = useAuthStore((state) => state.roles)
  const [dateRange, setDateRange] = useState<DateRange | undefined>({
    from: new Date(new Date().setDate(new Date().getDate() - 6)),
    to: new Date(),
  })

  const params = {
    fecha_desde: dateRange?.from ? format(dateRange.from, 'yyyy-MM-dd') : undefined,
    fecha_hasta: dateRange?.to ? format(dateRange.to, 'yyyy-MM-dd') : undefined,
  }

  const { data: resumen, isLoading: isLoadingResumen } = useDashboardResumen(params)
  const { data: facturacion, isLoading: isLoadingFacturacion } = useDashboardFacturacion(params)
  const { data: parqueos, isLoading: isLoadingParqueos } = useDashboardParqueos(params)
  const { data: recaudacionDiaria, isLoading: isLoadingRecaudacion } =
    useDashboardRecaudacionDiaria(params)

  const isAdminOrSupervisor = roles.includes('administrador') || roles.includes('supervisor')
  const isFacturador = roles.includes('facturador')
  const isInspector = roles.includes('inspector') && !isAdminOrSupervisor && !isFacturador
  const isLoading =
    isLoadingResumen || isLoadingFacturacion || isLoadingParqueos || isLoadingRecaudacion

  if (isLoading || !resumen || !facturacion || !parqueos || !recaudacionDiaria) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center gap-2 text-muted-foreground">
        <Loader2 className="size-5 animate-spin" />
        Cargando dashboard...
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Resumen operativo y comercial de la feria activa."
      />

      <FilterBar className="justify-end">
        <DateRangePicker value={dateRange} onChange={setDateRange} className="w-full sm:w-[280px]" />
      </FilterBar>

      {isAdminOrSupervisor && (
        <>
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
            <StatsCard icon={Receipt} title="Facturas" value={resumen.facturas_count} />
            <StatsCard icon={Car} title="Parqueos" value={resumen.parqueos_count} />
            <StatsCard icon={Store} title="Tarimas" value={resumen.tarimas_count} />
            <StatsCard icon={Droplets} title="Sanitarios" value={resumen.sanitarios_count} />
            <StatsCard icon={CreditCard} title="Recaudación total" value={formatMoney(resumen.recaudacion_total)} />
          </div>

          <div className="grid gap-4 xl:grid-cols-[2fr_1fr]">
            <ChartCard title="Tendencia diaria de recaudación">
              <div className="h-80">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={recaudacionDiaria}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="label" />
                    <YAxis tickFormatter={(value) => `₡${Number(value).toLocaleString('es-CR')}`} />
                    <Tooltip formatter={tooltipMoneyFormatter} />
                    <Legend />
                    <Line type="monotone" dataKey="total" name="Total" stroke="#2563eb" strokeWidth={3} />
                    <Line type="monotone" dataKey="facturas" name="Facturas" stroke="#059669" />
                    <Line type="monotone" dataKey="parqueos" name="Parqueos" stroke="#ea580c" />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>

            <ChartCard title="Estado de parqueos">
              <div className="grid gap-3">
                <StatsCard icon={Car} title="Activos" value={parqueos.activos} />
                <StatsCard icon={Car} title="Finalizados" value={parqueos.finalizados} />
                <StatsCard icon={Car} title="Cancelados" value={parqueos.cancelados} />
              </div>
            </ChartCard>
          </div>

          <div className="grid gap-4 xl:grid-cols-2">
            <ChartCard title="Facturación por producto">
              <div className="h-72">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={facturacion.facturas_por_producto}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="nombre" hide />
                    <YAxis tickFormatter={(value) => `₡${Number(value).toLocaleString('es-CR')}`} />
                    <Tooltip formatter={tooltipMoneyFormatter} />
                    <Bar dataKey="total" name="Monto" fill="#0f766e" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>

            <ChartCard title="Facturas por usuario">
              <div className="h-72">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={facturacion.facturas_por_usuario}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="nombre" hide />
                    <YAxis allowDecimals={false} />
                    <Tooltip />
                    <Bar dataKey="total" name="Facturas" fill="#7c3aed" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Últimas facturas</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Consecutivo</TableHead>
                    <TableHead>Cliente</TableHead>
                    <TableHead>Estado</TableHead>
                    <TableHead>Total</TableHead>
                    <TableHead>Usuario</TableHead>
                    <TableHead>Fecha</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {facturacion.ultimas_facturas.map((factura) => (
                    <TableRow key={factura.id}>
                      <TableCell>{factura.consecutivo ?? 'Borrador'}</TableCell>
                      <TableCell>{factura.cliente}</TableCell>
                      <TableCell>
                        <StatusBadge status={factura.estado} />
                      </TableCell>
                      <TableCell>{formatMoney(factura.subtotal)}</TableCell>
                      <TableCell>{factura.usuario ?? 'N/A'}</TableCell>
                      <TableCell>{formatDate(factura.fecha)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </>
      )}

      {isFacturador && (
        <>
          <div className="grid gap-4 md:grid-cols-3">
            <StatsCard icon={Receipt} title="Mis facturas hoy" value={resumen.mis_facturas_hoy ?? 0} />
            <StatsCard icon={BarChart3} title="Mis borradores" value={resumen.mis_borradores ?? 0} />
            <StatsCard icon={CreditCard} title="Recaudación" value={formatMoney(resumen.recaudacion_total)} />
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Mis últimas facturas</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Consecutivo</TableHead>
                    <TableHead>Cliente</TableHead>
                    <TableHead>Estado</TableHead>
                    <TableHead>Total</TableHead>
                    <TableHead>Fecha</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {facturacion.ultimas_facturas.map((factura) => (
                    <TableRow key={factura.id}>
                      <TableCell>{factura.consecutivo ?? 'Borrador'}</TableCell>
                      <TableCell>{factura.cliente}</TableCell>
                      <TableCell>
                        <StatusBadge status={factura.estado} />
                      </TableCell>
                      <TableCell>{formatMoney(factura.subtotal)}</TableCell>
                      <TableCell>{formatDate(factura.fecha)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </>
      )}

      {isInspector && (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
          <StatsCard icon={Receipt} title="Facturas" value={resumen.facturas_count} />
          <StatsCard icon={Car} title="Parqueos" value={resumen.parqueos_count} />
          <StatsCard icon={Store} title="Tarimas" value={resumen.tarimas_count} />
          <StatsCard icon={Droplets} title="Sanitarios" value={resumen.sanitarios_count} />
          <StatsCard icon={CreditCard} title="Recaudación total" value={formatMoney(resumen.recaudacion_total)} />
        </div>
      )}
    </div>
  )
}
