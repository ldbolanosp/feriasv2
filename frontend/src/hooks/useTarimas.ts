import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  cancelarTarima,
  createTarima,
  getTarima,
  getTarimas,
  type TarimaListParams,
} from '@/services/tarimaService'
import type { ITarimaFormPayload } from '@/types/tarima'

const TARIMAS_KEY = 'tarimas'

export function useTarimas(params: TarimaListParams = {}) {
  return useQuery({
    queryKey: [TARIMAS_KEY, params],
    queryFn: () => getTarimas(params),
    placeholderData: keepPreviousData,
  })
}

export function useTarima(id: number | null, enabled = true) {
  return useQuery({
    queryKey: [TARIMAS_KEY, id],
    queryFn: () => getTarima(id!),
    enabled: enabled && id !== null,
  })
}

export function useCreateTarima() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: ITarimaFormPayload) => createTarima(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [TARIMAS_KEY] })
      toast.success('Tarima facturada correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo facturar la tarima.')
    },
  })
}

export function useCancelarTarima() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => cancelarTarima(id),
    onSuccess: (tarima) => {
      queryClient.invalidateQueries({ queryKey: [TARIMAS_KEY] })
      queryClient.invalidateQueries({ queryKey: [TARIMAS_KEY, tarima.id] })
      toast.success('Tarima cancelada correctamente.')
    },
    onError: () => {
      toast.error('No se pudo cancelar la tarima.')
    },
  })
}
