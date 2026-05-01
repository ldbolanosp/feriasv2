import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  createInspeccion,
  getInspecciones,
  getReinspecciones,
  getVencimientosCarne,
  updateParticipanteCarne,
  type InspeccionListParams,
  type ParticipanteCarnePayload,
} from '@/services/inspeccionService'
import type { IInspeccionFormPayload } from '@/types/inspeccion'

const INSPECCIONES_KEY = 'inspecciones'

export function useInspecciones(params: InspeccionListParams = {}) {
  return useQuery({
    queryKey: [INSPECCIONES_KEY, params],
    queryFn: () => getInspecciones(params),
    placeholderData: keepPreviousData,
  })
}

export function useVencimientosCarne(params: InspeccionListParams = {}) {
  return useQuery({
    queryKey: [INSPECCIONES_KEY, 'vencimientos-carne', params],
    queryFn: () => getVencimientosCarne(params),
    placeholderData: keepPreviousData,
  })
}

export function useReinspecciones(params: InspeccionListParams = {}) {
  return useQuery({
    queryKey: [INSPECCIONES_KEY, 'reinspecciones', params],
    queryFn: () => getReinspecciones(params),
    placeholderData: keepPreviousData,
  })
}

export function useCreateInspeccion() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IInspeccionFormPayload) => createInspeccion(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [INSPECCIONES_KEY] })
      queryClient.invalidateQueries({ queryKey: ['participantes'] })
      toast.success('Inspección guardada correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo guardar la inspección.')
    },
  })
}

export function useUpdateParticipanteCarne() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      participanteId,
      payload,
    }: {
      participanteId: number
      payload: ParticipanteCarnePayload
    }) => updateParticipanteCarne(participanteId, payload),
    onSuccess: (participante) => {
      queryClient.invalidateQueries({ queryKey: ['participantes'] })
      queryClient.invalidateQueries({ queryKey: [INSPECCIONES_KEY, 'vencimientos-carne'] })
      queryClient.invalidateQueries({ queryKey: [INSPECCIONES_KEY, 'reinspecciones'] })
      queryClient.invalidateQueries({ queryKey: [INSPECCIONES_KEY] })
      toast.success(`Carné actualizado para ${participante.nombre}.`)
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo actualizar la información del carné.')
    },
  })
}
