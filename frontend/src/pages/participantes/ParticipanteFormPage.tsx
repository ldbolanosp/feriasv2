import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm, type FieldPath } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { isAxiosError } from 'axios'
import { Loader2, X } from 'lucide-react'
import { PageHeader } from '@/components/shared/PageHeader'
import { FormField } from '@/components/shared/FormField'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Separator } from '@/components/ui/separator'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { usePermission } from '@/hooks/usePermission'
import { useFerias } from '@/hooks/useFerias'
import {
  useParticipante,
  useCreateParticipante,
  useUpdateParticipante,
  useAsignarFeriasParticipante,
  useDesasignarFeriaParticipante,
} from '@/hooks/useParticipantes'
import type { IParticipante, IParticipanteFormPayload } from '@/types/participante'
import {
  ETIQUETAS_TIPO_IDENTIFICACION,
  TIPOS_IDENTIFICACION,
  TIPOS_SANGRE,
  type TTipoIdentificacion,
  type TTipoSangre,
} from '@/types/participante'

const enumTipoIdentificacion = TIPOS_IDENTIFICACION as unknown as [
  TTipoIdentificacion,
  ...TTipoIdentificacion[],
]

const enumTipoSangre = TIPOS_SANGRE as unknown as [TTipoSangre, ...TTipoSangre[]]

const schema = z
  .object({
    nombre: z.string().min(1, 'El nombre es requerido').max(255, 'Máximo 255 caracteres'),
    tipo_identificacion: z.enum(enumTipoIdentificacion, {
      message: 'Seleccione un tipo de identificación válido',
    }),
    numero_identificacion: z
      .string()
      .min(1, 'El número de identificación es requerido')
      .max(50, 'Máximo 50 caracteres'),
    correo_electronico: z.union([z.literal(''), z.string().email('Correo electrónico no válido')]),
    numero_carne: z.string().max(50, 'Máximo 50 caracteres'),
    fecha_emision_carne: z.string(),
    fecha_vencimiento_carne: z.string(),
    procedencia: z.string().max(255, 'Máximo 255 caracteres'),
    telefono: z.string().max(30, 'Máximo 30 caracteres'),
    tipo_sangre: z.union([z.literal(''), z.enum(enumTipoSangre)]),
    padecimientos: z.string(),
    contacto_emergencia_nombre: z.string().max(255, 'Máximo 255 caracteres'),
    contacto_emergencia_telefono: z.string().max(30, 'Máximo 30 caracteres'),
    activo: z.boolean(),
  })
  .superRefine((data, ctx) => {
    if (data.fecha_emision_carne && data.fecha_vencimiento_carne) {
      const emision = new Date(data.fecha_emision_carne + 'T12:00:00')
      const venc = new Date(data.fecha_vencimiento_carne + 'T12:00:00')
      if (venc <= emision) {
        ctx.addIssue({
          code: 'custom',
          message: 'La fecha de vencimiento del carné debe ser posterior a la fecha de emisión.',
          path: ['fecha_vencimiento_carne'],
        })
      }
    }
  })

type ParticipanteFormValues = z.infer<typeof schema>

const valoresPorDefecto: ParticipanteFormValues = {
  nombre: '',
  tipo_identificacion: 'fisica',
  numero_identificacion: '',
  correo_electronico: '',
  numero_carne: '',
  fecha_emision_carne: '',
  fecha_vencimiento_carne: '',
  procedencia: '',
  telefono: '',
  tipo_sangre: '',
  padecimientos: '',
  contacto_emergencia_nombre: '',
  contacto_emergencia_telefono: '',
  activo: true,
}

function participanteAPayload(values: ParticipanteFormValues): IParticipanteFormPayload {
  const vacioANull = (s: string) => (s.trim() === '' ? null : s.trim())
  return {
    nombre: values.nombre.trim(),
    tipo_identificacion: values.tipo_identificacion,
    numero_identificacion: values.numero_identificacion.trim(),
    correo_electronico: values.correo_electronico === '' ? null : values.correo_electronico,
    numero_carne: vacioANull(values.numero_carne),
    fecha_emision_carne: values.fecha_emision_carne === '' ? null : values.fecha_emision_carne,
    fecha_vencimiento_carne:
      values.fecha_vencimiento_carne === '' ? null : values.fecha_vencimiento_carne,
    procedencia: vacioANull(values.procedencia),
    telefono: vacioANull(values.telefono),
    tipo_sangre: values.tipo_sangre === '' ? null : values.tipo_sangre,
    padecimientos: vacioANull(values.padecimientos),
    contacto_emergencia_nombre: vacioANull(values.contacto_emergencia_nombre),
    contacto_emergencia_telefono: vacioANull(values.contacto_emergencia_telefono),
    activo: values.activo,
  }
}

function participanteAValores(p: IParticipante): ParticipanteFormValues {
  return {
    nombre: p.nombre,
    tipo_identificacion: p.tipo_identificacion as ParticipanteFormValues['tipo_identificacion'],
    numero_identificacion: p.numero_identificacion,
    correo_electronico: p.correo_electronico ?? '',
    numero_carne: p.numero_carne ?? '',
    fecha_emision_carne: p.fecha_emision_carne ?? '',
    fecha_vencimiento_carne: p.fecha_vencimiento_carne ?? '',
    procedencia: p.procedencia ?? '',
    telefono: p.telefono ?? '',
    tipo_sangre: (p.tipo_sangre as ParticipanteFormValues['tipo_sangre']) ?? '',
    padecimientos: p.padecimientos ?? '',
    contacto_emergencia_nombre: p.contacto_emergencia_nombre ?? '',
    contacto_emergencia_telefono: p.contacto_emergencia_telefono ?? '',
    activo: p.activo,
  }
}

interface AsignacionFeriasPanelProps {
  participante: IParticipante
}

function AsignacionFeriasPanel({ participante }: AsignacionFeriasPanelProps) {
  const { data: feriasData, isLoading: cargandoFerias } = useFerias({ per_page: 100, page: 1 })
  const ferias = feriasData?.data ?? []
  const asignar = useAsignarFeriasParticipante()
  const desasignar = useDesasignarFeriaParticipante()

  const asignadas = participante.ferias ?? []
  const idsAsignadas = new Set(asignadas.map((f) => f.id))

  const ocupado = asignar.isPending || desasignar.isPending

  const manejarCasilla = (feriaId: number, marcado: boolean) => {
    if (marcado) {
      asignar.mutate({ participanteId: participante.id, feriaIds: [feriaId] })
    } else {
      desasignar.mutate({ participanteId: participante.id, feriaId })
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">Asignación de ferias</CardTitle>
        <p className="text-sm text-muted-foreground">
          Marque las ferias en las que participa esta persona. Puede quitar una asignación con la
          X en la etiqueta.
        </p>
      </CardHeader>
      <CardContent className="space-y-6">
        <div>
          <Label className="mb-2 block text-sm font-medium">Ferias asignadas</Label>
          <div className="flex min-h-10 flex-wrap gap-2">
            {asignadas.length === 0 ? (
              <span className="text-sm text-muted-foreground">Ninguna feria asignada aún.</span>
            ) : (
              asignadas.map((f) => (
                <Badge
                  key={f.id}
                  variant="secondary"
                  className="gap-1 pr-1 pl-2.5 py-1 text-sm font-normal"
                >
                  <span>
                    {f.codigo} — {f.descripcion}
                  </span>
                  <button
                    type="button"
                    className="rounded-sm p-0.5 hover:bg-muted-foreground/20"
                    disabled={ocupado}
                    onClick={() =>
                      desasignar.mutate({ participanteId: participante.id, feriaId: f.id })
                    }
                    aria-label={`Quitar feria ${f.descripcion}`}
                  >
                    <X className="size-3.5" />
                  </button>
                </Badge>
              ))
            )}
          </div>
        </div>

        <Separator />

        <div>
          <Label className="mb-3 block text-sm font-medium">Todas las ferias</Label>
          {cargandoFerias ? (
            <p className="text-sm text-muted-foreground">Cargando ferias…</p>
          ) : (
            <ul className="max-h-72 space-y-2 overflow-y-auto rounded-md border p-3">
              {ferias.map((feria) => (
                <li key={feria.id} className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    id={`feria-${feria.id}`}
                    className="size-4 rounded border-input"
                    checked={idsAsignadas.has(feria.id)}
                    disabled={ocupado || !feria.activa}
                    onChange={(e) => manejarCasilla(feria.id, e.target.checked)}
                  />
                  <label htmlFor={`feria-${feria.id}`} className="flex-1 cursor-pointer text-sm">
                    <span className="font-medium">{feria.codigo}</span>
                    <span className="text-muted-foreground"> — {feria.descripcion}</span>
                    {!feria.activa && (
                      <span className="ml-2 text-xs text-muted-foreground">(inactiva)</span>
                    )}
                  </label>
                </li>
              ))}
            </ul>
          )}
        </div>
      </CardContent>
    </Card>
  )
}

export function ParticipanteFormPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { hasPermission } = usePermission()

  const participanteId = id ? Number(id) : undefined
  const esEdicion = participanteId !== undefined && !Number.isNaN(participanteId)

  const { data: participante, isLoading: cargandoParticipante } = useParticipante(
    esEdicion ? participanteId : undefined,
  )

  const crear = useCreateParticipante()
  const actualizar = useUpdateParticipante()

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    setError,
    formState: { errors },
  } = useForm<ParticipanteFormValues>({
    resolver: zodResolver(schema),
    defaultValues: valoresPorDefecto,
  })

  const activo = watch('activo')

  useEffect(() => {
    if (participante) {
      reset(participanteAValores(participante))
    }
  }, [participante, reset])

  const aplicarErroresApi = (error: unknown) => {
    if (!isAxiosError(error) || error.response?.status !== 422) {
      return
    }
    const errores = error.response.data?.errors as Record<string, string[]> | undefined
    if (!errores) {
      return
    }
    for (const [campo, mensajes] of Object.entries(errores)) {
      const mensaje = mensajes[0]
      if (mensaje) {
        setError(campo as FieldPath<ParticipanteFormValues>, { message: mensaje })
      }
    }
  }

  const enviar = async (values: ParticipanteFormValues) => {
    const payload = participanteAPayload(values)
    try {
      if (esEdicion && participanteId !== undefined) {
        await actualizar.mutateAsync({ id: participanteId, payload })
      } else {
        const creado = await crear.mutateAsync(payload)
        navigate(`/configuracion/participantes/${creado.id}/editar`, { replace: true })
      }
    } catch (e) {
      aplicarErroresApi(e)
    }
  }

  const guardando = crear.isPending || actualizar.isPending

  if (esEdicion && cargandoParticipante) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="size-8 animate-spin text-muted-foreground" />
      </div>
    )
  }

  if (esEdicion && !cargandoParticipante && !participante) {
    return (
      <div className="space-y-4">
        <PageHeader title="Participante no encontrado" backUrl="/configuracion/participantes" />
        <p className="text-muted-foreground">No se pudo cargar el participante.</p>
      </div>
    )
  }

  const puedeAsignarFerias = hasPermission('participantes.asignar_feria')
  const mostrarAsignacionFerias = puedeAsignarFerias && participante

  return (
    <div className="mx-auto max-w-3xl space-y-8 pb-12">
      <PageHeader
        title={esEdicion ? 'Editar participante' : 'Nuevo participante'}
        description="Registre los datos del productor o comerciante. Los campos con * son obligatorios."
        backUrl="/configuracion/participantes"
      />

      <form onSubmit={handleSubmit(enviar)} className="space-y-8">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Información básica</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <FormField label="Nombre completo" error={errors.nombre?.message} required>
              <Input {...register('nombre')} disabled={guardando} />
            </FormField>
            <FormField label="Tipo de identificación" error={errors.tipo_identificacion?.message} required>
              <Select
                value={watch('tipo_identificacion')}
                onValueChange={(v) =>
                  setValue('tipo_identificacion', v as ParticipanteFormValues['tipo_identificacion'])
                }
                disabled={guardando}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {TIPOS_IDENTIFICACION.map((t) => (
                    <SelectItem key={t} value={t}>
                      {ETIQUETAS_TIPO_IDENTIFICACION[t]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </FormField>
            <FormField
              label="Número de identificación"
              error={errors.numero_identificacion?.message}
              required
              className="sm:col-span-2"
            >
              <Input {...register('numero_identificacion')} disabled={guardando} />
            </FormField>
            <FormField label="Correo electrónico" error={errors.correo_electronico?.message}>
              <Input type="email" {...register('correo_electronico')} disabled={guardando} />
            </FormField>
            <FormField label="Teléfono" error={errors.telefono?.message}>
              <Input {...register('telefono')} disabled={guardando} />
            </FormField>
            <FormField label="Procedencia" error={errors.procedencia?.message} className="sm:col-span-2">
              <Input {...register('procedencia')} disabled={guardando} />
            </FormField>
            <div className="flex items-center justify-between rounded-lg border p-4 sm:col-span-2">
              <div>
                <Label htmlFor="activo">Participante activo</Label>
                <p className="text-xs text-muted-foreground">Los inactivos no aparecen en listas de selección.</p>
              </div>
              <Switch
                id="activo"
                checked={activo}
                onCheckedChange={(v) => setValue('activo', v)}
                disabled={guardando}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Carné</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <FormField label="Número de carné" error={errors.numero_carne?.message}>
              <Input {...register('numero_carne')} disabled={guardando} />
            </FormField>
            <div />
            <FormField label="Fecha de emisión" error={errors.fecha_emision_carne?.message}>
              <Input type="date" {...register('fecha_emision_carne')} disabled={guardando} />
            </FormField>
            <FormField label="Fecha de vencimiento" error={errors.fecha_vencimiento_carne?.message}>
              <Input type="date" {...register('fecha_vencimiento_carne')} disabled={guardando} />
            </FormField>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Información médica</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <FormField label="Tipo de sangre" error={errors.tipo_sangre?.message}>
              <Select
                value={watch('tipo_sangre') === '' ? '__ninguno__' : watch('tipo_sangre')}
                onValueChange={(v) =>
                  setValue('tipo_sangre', v === '__ninguno__' ? '' : (v as ParticipanteFormValues['tipo_sangre']))
                }
                disabled={guardando}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Seleccionar" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__ninguno__">No indicado</SelectItem>
                  {TIPOS_SANGRE.map((t) => (
                    <SelectItem key={t} value={t}>
                      {t}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </FormField>
            <div className="sm:col-span-2">
              <FormField label="Padecimientos o alergias" error={errors.padecimientos?.message}>
                <Textarea rows={4} {...register('padecimientos')} disabled={guardando} />
              </FormField>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Contacto de emergencia</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <FormField
              label="Nombre del contacto"
              error={errors.contacto_emergencia_nombre?.message}
              className="sm:col-span-2"
            >
              <Input {...register('contacto_emergencia_nombre')} disabled={guardando} />
            </FormField>
            <FormField label="Teléfono del contacto" error={errors.contacto_emergencia_telefono?.message}>
              <Input {...register('contacto_emergencia_telefono')} disabled={guardando} />
            </FormField>
          </CardContent>
        </Card>

        <div className="flex justify-end gap-3">
          <Button type="button" variant="outline" onClick={() => navigate('/configuracion/participantes')}>
            Cancelar
          </Button>
          <Button type="submit" disabled={guardando}>
            {guardando && <Loader2 className="mr-2 size-4 animate-spin" />}
            {esEdicion ? 'Guardar cambios' : 'Guardar participante'}
          </Button>
        </div>
      </form>

      {mostrarAsignacionFerias && <AsignacionFeriasPanel participante={participante} />}
    </div>
  )
}
