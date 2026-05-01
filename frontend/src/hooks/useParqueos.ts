import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  cancelarParqueo,
  createParqueo,
  getParqueo,
  getParqueos,
  salidaParqueo,
  type ParqueoListParams,
} from '@/services/parqueoService'
import type { IParqueoFormPayload } from '@/types/parqueo'

const PARQUEOS_KEY = 'parqueos'

export function useParqueos(params: ParqueoListParams = {}) {
  return useQuery({
    queryKey: [PARQUEOS_KEY, params],
    queryFn: () => getParqueos(params),
    placeholderData: keepPreviousData,
  })
}

export function useParqueo(id: number | null, enabled = true) {
  return useQuery({
    queryKey: [PARQUEOS_KEY, id],
    queryFn: () => getParqueo(id!),
    enabled: enabled && id !== null,
  })
}

export function useCreateParqueo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IParqueoFormPayload) => createParqueo(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [PARQUEOS_KEY] })
      toast.success('Parqueo registrado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo registrar el parqueo.')
    },
  })
}

export function useSalidaParqueo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => salidaParqueo(id),
    onSuccess: (parqueo) => {
      queryClient.invalidateQueries({ queryKey: [PARQUEOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [PARQUEOS_KEY, parqueo.id] })
      toast.success('Salida registrada correctamente.')
    },
    onError: () => {
      toast.error('No se pudo registrar la salida.')
    },
  })
}

export function useCancelarParqueo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => cancelarParqueo(id),
    onSuccess: (parqueo) => {
      queryClient.invalidateQueries({ queryKey: [PARQUEOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [PARQUEOS_KEY, parqueo.id] })
      toast.success('Parqueo cancelado correctamente.')
    },
    onError: () => {
      toast.error('No se pudo cancelar el parqueo.')
    },
  })
}
