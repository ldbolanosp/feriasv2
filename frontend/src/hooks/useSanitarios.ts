import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  cancelarSanitario,
  createSanitario,
  getSanitario,
  getSanitarios,
  type SanitarioListParams,
} from '@/services/sanitarioService'
import type { ISanitarioFormPayload } from '@/types/sanitario'

const SANITARIOS_KEY = 'sanitarios'

export function useSanitarios(params: SanitarioListParams = {}) {
  return useQuery({
    queryKey: [SANITARIOS_KEY, params],
    queryFn: () => getSanitarios(params),
    placeholderData: keepPreviousData,
  })
}

export function useSanitario(id: number | null, enabled = true) {
  return useQuery({
    queryKey: [SANITARIOS_KEY, id],
    queryFn: () => getSanitario(id!),
    enabled: enabled && id !== null,
  })
}

export function useCreateSanitario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: ISanitarioFormPayload) => createSanitario(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [SANITARIOS_KEY] })
      toast.success('Sanitario facturado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo facturar el sanitario.')
    },
  })
}

export function useCancelarSanitario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => cancelarSanitario(id),
    onSuccess: (sanitario) => {
      queryClient.invalidateQueries({ queryKey: [SANITARIOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [SANITARIOS_KEY, sanitario.id] })
      toast.success('Sanitario cancelado correctamente.')
    },
    onError: () => {
      toast.error('No se pudo cancelar el sanitario.')
    },
  })
}
