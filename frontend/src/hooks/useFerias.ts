import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import {
  getFerias,
  createFeria,
  updateFeria,
  toggleFeria,
  type FeriaListParams,
} from '@/services/feriaService'
import { useFeriaStore } from '@/stores/feriaStore'
import type { IFeria } from '@/types/feria'
import type { IFeriaForm } from '@/types/feria'

const FERIAS_KEY = 'ferias'

function syncFeriaStore(feriaActualizada: IFeria): void {
  const { feriaActiva, ferias, setFeriaActiva, setFerias, clearFeria } = useFeriaStore.getState()

  if (feriaActiva?.id === feriaActualizada.id) {
    if (feriaActualizada.activa) {
      setFeriaActiva({
        id: feriaActualizada.id,
        codigo: feriaActualizada.codigo,
        descripcion: feriaActualizada.descripcion,
        facturacion_publico: feriaActualizada.facturacion_publico,
      })
    } else {
      clearFeria()
      return
    }
  }

  if (ferias.length === 0) {
    return
  }

  const feriasActualizadas = ferias
    .map((feria) =>
      feria.id === feriaActualizada.id
        ? {
            id: feriaActualizada.id,
            codigo: feriaActualizada.codigo,
            descripcion: feriaActualizada.descripcion,
            facturacion_publico: feriaActualizada.facturacion_publico,
          }
        : feria,
    )
    .filter((feria) => {
      if (feria.id !== feriaActualizada.id) {
        return true
      }

      return feriaActualizada.activa
    })

  setFerias(feriasActualizadas)
}

export function useFerias(params: FeriaListParams = {}) {
  return useQuery({
    queryKey: [FERIAS_KEY, params],
    queryFn: () => getFerias(params),
    placeholderData: keepPreviousData,
  })
}

export function useCreateFeria() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IFeriaForm) => createFeria(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [FERIAS_KEY] })
      toast.success('Feria creada correctamente.')
    },
    onError: () => {
      toast.error('No se pudo crear la feria.')
    },
  })
}

export function useUpdateFeria() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: IFeriaForm }) =>
      updateFeria(id, payload),
    onSuccess: (feria) => {
      syncFeriaStore(feria)
      queryClient.invalidateQueries({ queryKey: [FERIAS_KEY] })
      toast.success('Feria actualizada correctamente.')
    },
    onError: () => {
      toast.error('No se pudo actualizar la feria.')
    },
  })
}

export function useToggleFeria() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => toggleFeria(id),
    onSuccess: (feria) => {
      syncFeriaStore(feria)
      queryClient.invalidateQueries({ queryKey: [FERIAS_KEY] })
      toast.success(feria.activa ? 'Feria activada.' : 'Feria desactivada.')
    },
    onError: () => {
      toast.error('No se pudo cambiar el estado de la feria.')
    },
  })
}
