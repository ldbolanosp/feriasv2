import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  createMetodoPago,
  getMetodosPago,
  getMetodosPagoCatalogoFacturacion,
  toggleMetodoPago,
  updateMetodoPago,
  type MetodoPagoListParams,
} from '@/services/metodoPagoService'
import type { IMetodoPagoFormPayload } from '@/types/metodoPago'

const METODOS_PAGO_KEY = 'metodos-pago'

export function useMetodosPago(params: MetodoPagoListParams = {}) {
  return useQuery({
    queryKey: [METODOS_PAGO_KEY, params],
    queryFn: () => getMetodosPago(params),
    placeholderData: keepPreviousData,
  })
}

export function useMetodosPagoCatalogoFacturacion() {
  return useQuery({
    queryKey: [METODOS_PAGO_KEY, 'catalogo-facturacion'],
    queryFn: getMetodosPagoCatalogoFacturacion,
  })
}

export function useCreateMetodoPago() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IMetodoPagoFormPayload) => createMetodoPago(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [METODOS_PAGO_KEY] })
      toast.success('Método de pago creado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo crear el método de pago.')
    },
  })
}

export function useUpdateMetodoPago() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: IMetodoPagoFormPayload }) =>
      updateMetodoPago(id, payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [METODOS_PAGO_KEY] })
      queryClient.invalidateQueries({ queryKey: [METODOS_PAGO_KEY, variables.id] })
      toast.success('Método de pago actualizado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo actualizar el método de pago.')
    },
  })
}

export function useToggleMetodoPago() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => toggleMetodoPago(id),
    onSuccess: (metodoPago) => {
      queryClient.invalidateQueries({ queryKey: [METODOS_PAGO_KEY] })
      toast.success(
        metodoPago.activo
          ? 'Método de pago activado correctamente.'
          : 'Método de pago inactivado correctamente.',
      )
    },
    onError: () => {
      toast.error('No se pudo cambiar el estado del método de pago.')
    },
  })
}
