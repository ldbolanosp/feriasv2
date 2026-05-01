import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  createFactura,
  deleteFactura,
  facturarFactura,
  getFactura,
  getFacturas,
  updateFactura,
  type FacturaListParams,
} from '@/services/facturaService'
import type { IFacturaFormPayload } from '@/types/factura'

const FACTURAS_KEY = 'facturas'

export function useFacturas(params: FacturaListParams = {}) {
  return useQuery({
    queryKey: [FACTURAS_KEY, params],
    queryFn: () => getFacturas(params),
  })
}

export function useFactura(id: number | null, enabled = true) {
  return useQuery({
    queryKey: [FACTURAS_KEY, id],
    queryFn: () => getFactura(id!),
    enabled: enabled && id !== null,
  })
}

export function useCreateFactura() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IFacturaFormPayload) => createFactura(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [FACTURAS_KEY] })
      toast.success('Factura guardada como borrador.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo guardar la factura.')
    },
  })
}

export function useUpdateFactura() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: IFacturaFormPayload }) =>
      updateFactura(id, payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [FACTURAS_KEY] })
      queryClient.invalidateQueries({ queryKey: [FACTURAS_KEY, variables.id] })
      toast.success('Factura actualizada correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo actualizar la factura.')
    },
  })
}

export function useFacturarFactura() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => facturarFactura(id),
    onSuccess: (factura) => {
      queryClient.invalidateQueries({ queryKey: [FACTURAS_KEY] })
      queryClient.invalidateQueries({ queryKey: [FACTURAS_KEY, factura.id] })
      toast.success('Factura emitida correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo facturar la factura.')
    },
  })
}

export function useDeleteFactura() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => deleteFactura(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [FACTURAS_KEY] })
      toast.success('Factura eliminada correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo eliminar la factura.')
    },
  })
}
