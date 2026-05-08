import { useEffect, useMemo, useState } from 'react'
import { isAxiosError } from 'axios'
import { CirclePlus, Loader2, Trash2 } from 'lucide-react'
import { ComboboxSearch } from '@/components/shared/ComboboxSearch'
import { FormField } from '@/components/shared/FormField'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { useItemsDiagnostico } from '@/hooks/useItemsDiagnostico'
import { useParticipantesPorFeria } from '@/hooks/useParticipantes'
import type { IInspeccion, IInspeccionFormPayload } from '@/types/inspeccion'

interface SelectedInspectionItem {
  item_diagnostico_id: number | null
  cumple: boolean
  observaciones: string
}

interface ParticipanteResumen {
  id: number
  nombre: string
  numero_identificacion: string
}

interface InspeccionFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSubmit: (payload: IInspeccionFormPayload) => Promise<void>
  isLoading: boolean
  reinspeccionBase?: IInspeccion | null
}

const defaultItemRow = (): SelectedInspectionItem => ({
  item_diagnostico_id: null,
  cumple: true,
  observaciones: '',
})

function buildParticipanteLabel(participante: ParticipanteResumen | null | undefined): string {
  if (!participante) {
    return ''
  }

  return `${participante.nombre} · ${participante.numero_identificacion}`
}

export function InspeccionFormDialog({
  open,
  onOpenChange,
  onSubmit,
  isLoading,
  reinspeccionBase,
}: InspeccionFormDialogProps) {
  const [participanteSearch, setParticipanteSearch] = useState('')
  const [participanteId, setParticipanteId] = useState<number | null>(null)
  const [participanteLabel, setParticipanteLabel] = useState('')
  const [items, setItems] = useState<SelectedInspectionItem[]>([defaultItemRow()])
  const [submitError, setSubmitError] = useState<string | null>(null)

  const { data: participantesData, isLoading: participantesLoading } =
    useParticipantesPorFeria(participanteSearch)
  const { data: itemsCatalogoData, isLoading: itemsCatalogoLoading } = useItemsDiagnostico({
    page: 1,
    per_page: 100,
  })

  const itemsCatalogo = itemsCatalogoData?.data ?? []

  const participanteOptions = useMemo(() => {
    const options = (participantesData ?? []).map((participante) => ({
      value: participante.id,
      label: `${participante.nombre} · ${participante.numero_identificacion}`,
    }))

    if (participanteId && participanteLabel && !options.some((option) => option.value === participanteId)) {
      options.unshift({
        value: participanteId,
        label: participanteLabel,
      })
    }

    return options
  }, [participanteId, participanteLabel, participantesData])

  useEffect(() => {
    if (!open) {
      return
    }

    if (reinspeccionBase?.participante) {
      setParticipanteId(reinspeccionBase.participante.id)
      setParticipanteLabel(buildParticipanteLabel(reinspeccionBase.participante))
      const failedItems = reinspeccionBase.items.filter((item) => !item.cumple)
      setItems(
        failedItems.length > 0
          ? failedItems.map((item) => ({
              item_diagnostico_id: item.item_diagnostico_id,
              cumple: true,
              observaciones: '',
            }))
          : [defaultItemRow()],
      )
    } else {
      setParticipanteId(null)
      setParticipanteLabel('')
      setItems([defaultItemRow()])
    }

    setParticipanteSearch('')
    setSubmitError(null)
  }, [open, reinspeccionBase])

  const remainingItems = (currentIndex: number) =>
    itemsCatalogo.filter((item) => {
      const selectedElsewhere = items.some(
        (row, index) => index !== currentIndex && row.item_diagnostico_id === item.id,
      )

      return !selectedElsewhere
    })

  const handleSubmit = async () => {
    setSubmitError(null)

    if (!participanteId) {
      setSubmitError('Debe seleccionar un participante.')
      return
    }

    if (items.length === 0 || items.some((item) => item.item_diagnostico_id === null)) {
      setSubmitError('Debe seleccionar al menos un item válido para la inspección.')
      return
    }

    try {
      await onSubmit({
        participante_id: participanteId,
        reinspeccion_de_id: reinspeccionBase?.id ?? null,
        items: items.map((item) => ({
          item_diagnostico_id: item.item_diagnostico_id!,
          cumple: item.cumple,
          observaciones: item.observaciones.trim() === '' ? null : item.observaciones.trim(),
        })),
      })
    } catch (error) {
      if (!isAxiosError(error) || error.response?.status !== 422) {
        throw error
      }

      const apiErrors = error.response.data?.errors as Record<string, string[]> | undefined
      const firstError = apiErrors ? Object.values(apiErrors).flat()[0] : null
      setSubmitError(firstError ?? 'No se pudo guardar la inspección.')
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>
            {reinspeccionBase ? 'Nueva reinspección' : 'Nueva inspección'}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-5">
          {reinspeccionBase?.participante && (
            <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
              Se creará una reinspección para{' '}
              <span className="font-semibold">{reinspeccionBase.participante.nombre}</span> con los
              items pendientes de la última revisión.
            </div>
          )}

          <FormField label="Participante" required>
            <ComboboxSearch
              options={participanteOptions}
              value={participanteId}
              onSelect={(value) => {
                setParticipanteId(value === null ? null : Number(value))
                const selected = participanteOptions.find((option) => option.value === value)
                setParticipanteLabel(selected?.label ?? '')
              }}
              onSearch={setParticipanteSearch}
              placeholder="Buscar participante..."
              isLoading={participantesLoading}
              className="w-full justify-between"
            />
          </FormField>

          <div className="space-y-3">
            <div className="flex items-center justify-between gap-3">
              <div>
                <Label className="text-sm font-medium">Items de inspección</Label>
                <p className="text-xs text-muted-foreground">
                  Seleccione el item, marque si cumple y documente observaciones si aplica.
                </p>
              </div>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setItems((prev) => [...prev, defaultItemRow()])}
                disabled={isLoading || itemsCatalogoLoading || items.length >= itemsCatalogo.length}
              >
                <CirclePlus className="size-4" />
                Agregar item
              </Button>
            </div>

            {itemsCatalogo.length === 0 && !itemsCatalogoLoading ? (
              <div className="rounded-lg border border-dashed p-6 text-sm text-muted-foreground">
                Primero debe crear items en Configuración → Items de Inspección.
              </div>
            ) : (
              <div className="space-y-3">
                {items.map((item, index) => (
                  <Card key={`${index}-${item.item_diagnostico_id ?? 'nuevo'}`}>
                    <CardContent className="space-y-4 pt-6">
                      <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_180px_auto] lg:items-end">
                        <FormField label={`Item ${index + 1}`} required>
                          <Select
                            value={item.item_diagnostico_id?.toString() ?? ''}
                            onValueChange={(value) =>
                              setItems((prev) =>
                                prev.map((row, rowIndex) =>
                                  rowIndex === index
                                    ? { ...row, item_diagnostico_id: Number(value) }
                                    : row,
                                ),
                              )
                            }
                            disabled={isLoading}
                          >
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="Seleccione un item" />
                            </SelectTrigger>
                            <SelectContent>
                              {remainingItems(index).map((catalogoItem) => (
                                <SelectItem
                                  key={catalogoItem.id}
                                  value={catalogoItem.id.toString()}
                                >
                                  {catalogoItem.nombre}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </FormField>

                        <FormField label="Resultado" required>
                          <Select
                            value={item.cumple ? 'cumple' : 'no-cumple'}
                            onValueChange={(value) =>
                              setItems((prev) =>
                                prev.map((row, rowIndex) =>
                                  rowIndex === index
                                    ? { ...row, cumple: value === 'cumple' }
                                    : row,
                                ),
                              )
                            }
                            disabled={isLoading}
                          >
                            <SelectTrigger>
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="cumple">Cumple</SelectItem>
                              <SelectItem value="no-cumple">No cumple</SelectItem>
                            </SelectContent>
                          </Select>
                        </FormField>

                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          className="h-10 w-10 shrink-0 text-muted-foreground hover:text-destructive"
                          onClick={() =>
                            setItems((prev) =>
                              prev.length === 1
                                ? [defaultItemRow()]
                                : prev.filter((_, rowIndex) => rowIndex !== index),
                            )
                          }
                          disabled={isLoading}
                        >
                          <Trash2 className="size-4" />
                          <span className="sr-only">Eliminar item</span>
                        </Button>
                      </div>

                      <FormField label="Observaciones">
                        <Textarea
                          value={item.observaciones}
                          onChange={(event) =>
                            setItems((prev) =>
                              prev.map((row, rowIndex) =>
                                rowIndex === index
                                  ? { ...row, observaciones: event.target.value }
                                  : row,
                              ),
                            )
                          }
                          placeholder="Detalles relevantes de esta revisión..."
                          disabled={isLoading}
                          rows={3}
                        />
                      </FormField>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>

          {submitError && (
            <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
              {submitError}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={isLoading}
          >
            Cancelar
          </Button>
          <Button type="button" onClick={handleSubmit} disabled={isLoading || itemsCatalogo.length === 0}>
            {isLoading && <Loader2 className="size-4 animate-spin" />}
            Guardar inspección
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
