import { useState } from 'react'
import { format } from 'date-fns'
import { Car, Download, Loader2, Receipt } from 'lucide-react'
import { isAxiosError } from 'axios'
import { useFerias } from '@/hooks/useFerias'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { downloadReporteFacturacion, downloadReporteParqueos } from '@/services/reporteService'
import { useAuthStore } from '@/stores/authStore'
import type { IFeria } from '@/types/auth'

const today = format(new Date(), 'yyyy-MM-dd')
const ALL_FAIRS = 'todas'

interface FeriaOption {
  id: number
  label: string
}

interface ReporteCardProps {
  title: string
  description: string
  icon: typeof Receipt
  buttonLabel: string
  feriaOptions: FeriaOption[]
  onDownload: (params: { fecha_inicio: string; fecha_fin: string; feria_id?: number }) => Promise<void>
}

function ReporteCard({
  title,
  description,
  icon: Icon,
  buttonLabel,
  feriaOptions,
  onDownload,
}: ReporteCardProps) {
  const [fechaInicio, setFechaInicio] = useState(today)
  const [fechaFin, setFechaFin] = useState(today)
  const [feriaId, setFeriaId] = useState<string>(ALL_FAIRS)
  const [isDownloading, setIsDownloading] = useState(false)

  const invalidRange = fechaInicio > fechaFin

  const handleDownload = async () => {
    if (invalidRange) {
      return
    }

    setIsDownloading(true)

    try {
      await onDownload({
        fecha_inicio: fechaInicio,
        fecha_fin: fechaFin,
        feria_id: feriaId === ALL_FAIRS ? undefined : Number(feriaId),
      })
    } catch (error) {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }
    } finally {
      setIsDownloading(false)
    }
  }

  return (
    <Card className="border-border/70">
      <CardHeader className="gap-3 border-b">
        <div className="flex items-start gap-3">
          <div className="rounded-xl bg-primary/10 p-3 text-primary">
            <Icon className="size-5" />
          </div>
          <div className="space-y-1">
            <CardTitle>{title}</CardTitle>
            <CardDescription>{description}</CardDescription>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-5 pt-6">
        <div className="grid gap-4 md:grid-cols-3">
          <div className="space-y-2">
            <Label htmlFor={`${title}-feria`}>Feria</Label>
            <Select value={feriaId} onValueChange={setFeriaId}>
              <SelectTrigger id={`${title}-feria`}>
                <SelectValue placeholder="Seleccione una feria" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ALL_FAIRS}>Todas las ferias</SelectItem>
                {feriaOptions.map((feria) => (
                  <SelectItem key={feria.id} value={String(feria.id)}>
                    {feria.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor={`${title}-fecha-inicio`}>Fecha inicial</Label>
            <Input
              id={`${title}-fecha-inicio`}
              type="date"
              value={fechaInicio}
              max={fechaFin}
              onChange={(event) => setFechaInicio(event.target.value)}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor={`${title}-fecha-fin`}>Fecha final</Label>
            <Input
              id={`${title}-fecha-fin`}
              type="date"
              value={fechaFin}
              min={fechaInicio}
              onChange={(event) => setFechaFin(event.target.value)}
            />
          </div>
        </div>

        <div className="flex flex-col gap-3 rounded-2xl border border-dashed border-border/70 bg-muted/30 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="space-y-1">
            <p className="text-sm font-medium">Exportación en Excel (.xlsx)</p>
            <p className="text-sm text-muted-foreground">
              Puede exportar una feria específica o consolidar todas las ferias disponibles.
            </p>
          </div>

          <Button
            onClick={() => void handleDownload()}
            disabled={isDownloading || invalidRange}
            className="w-full sm:w-auto"
          >
            {isDownloading ? <Loader2 className="size-4 animate-spin" /> : <Download className="size-4" />}
            {buttonLabel}
          </Button>
        </div>

        {invalidRange && (
          <p className="text-sm text-destructive">
            La fecha final debe ser igual o posterior a la fecha inicial.
          </p>
        )}
      </CardContent>
    </Card>
  )
}

function buildFeriaOptions(ferias: IFeria[]): FeriaOption[] {
  return ferias
    .map((feria) => ({
      id: feria.id,
      label: `${feria.codigo} · ${feria.descripcion}`,
    }))
    .sort((left, right) => left.label.localeCompare(right.label))
}

export function ReportesFacturacionPage() {
  const roles = useAuthStore((state) => state.roles)
  const feriasUsuario = useAuthStore((state) => state.ferias)
  const isAdmin = roles.includes('administrador')
  const { data: feriasData } = useFerias(
    {
      page: 1,
      per_page: 100,
      activa: true,
      sort: 'codigo',
      direction: 'asc',
    },
    isAdmin,
  )

  const feriaOptions = buildFeriaOptions(isAdmin ? (feriasData?.data ?? []) : feriasUsuario)

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reporte de facturación"
        description="Exporte las líneas facturadas en formato Excel para el rango de fechas seleccionado."
      />

      <ReporteCard
        title="Facturación"
        description="Genera una fila por cada línea facturada, incluyendo participante, usuario y totales."
        icon={Receipt}
        buttonLabel="Descargar reporte"
        feriaOptions={feriaOptions}
        onDownload={downloadReporteFacturacion}
      />
    </div>
  )
}

export function ReportesParqueosPage() {
  const roles = useAuthStore((state) => state.roles)
  const feriasUsuario = useAuthStore((state) => state.ferias)
  const isAdmin = roles.includes('administrador')
  const { data: feriasData } = useFerias(
    {
      page: 1,
      per_page: 100,
      activa: true,
      sort: 'codigo',
      direction: 'asc',
    },
    isAdmin,
  )

  const feriaOptions = buildFeriaOptions(isAdmin ? (feriasData?.data ?? []) : feriasUsuario)

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reporte de parqueos"
        description="Exporte los ingresos y salidas de parqueo en formato Excel para el rango de fechas seleccionado."
      />

      <ReporteCard
        title="Parqueos"
        description="Incluye placa, fechas, horas, usuario que registró y la tarifa cobrada."
        icon={Car}
        buttonLabel="Descargar reporte"
        feriaOptions={feriaOptions}
        onDownload={downloadReporteParqueos}
      />
    </div>
  )
}
