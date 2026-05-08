import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  createItemDiagnostico,
  deleteItemDiagnostico,
  getItemsDiagnostico,
  updateItemDiagnostico,
  type ItemDiagnosticoListParams,
} from '@/services/itemDiagnosticoService'
import type { IItemDiagnosticoFormPayload } from '@/types/itemDiagnostico'

const ITEMS_DIAGNOSTICO_KEY = 'items-diagnostico'

export function useItemsDiagnostico(params: ItemDiagnosticoListParams = {}) {
  return useQuery({
    queryKey: [ITEMS_DIAGNOSTICO_KEY, params],
    queryFn: () => getItemsDiagnostico(params),
    placeholderData: keepPreviousData,
  })
}

export function useCreateItemDiagnostico() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IItemDiagnosticoFormPayload) => createItemDiagnostico(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [ITEMS_DIAGNOSTICO_KEY] })
      toast.success('Item de inspección creado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo crear el item de inspección.')
    },
  })
}

export function useUpdateItemDiagnostico() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: IItemDiagnosticoFormPayload }) =>
      updateItemDiagnostico(id, payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [ITEMS_DIAGNOSTICO_KEY] })
      queryClient.invalidateQueries({ queryKey: [ITEMS_DIAGNOSTICO_KEY, variables.id] })
      toast.success('Item de inspección actualizado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo actualizar el item de inspección.')
    },
  })
}

export function useDeleteItemDiagnostico() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => deleteItemDiagnostico(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [ITEMS_DIAGNOSTICO_KEY] })
      toast.success('Item de inspección eliminado correctamente.')
    },
    onError: () => {
      toast.error('No se pudo eliminar el item de inspección.')
    },
  })
}
