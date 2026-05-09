import api from './api'
import type { IMetodoPago, IMetodoPagoFormPayload, IMetodoPagoListResponse } from '@/types/metodoPago'

export interface MetodoPagoListParams {
  page?: number
  per_page?: number
  search?: string
  activo?: boolean | null
}

export async function getMetodosPago(
  params: MetodoPagoListParams = {},
): Promise<IMetodoPagoListResponse> {
  const { data } = await api.get<IMetodoPagoListResponse>('/metodos-pago', { params })
  return data
}

export async function getMetodosPagoCatalogoFacturacion(): Promise<IMetodoPago[]> {
  const { data } = await api.get<{ data: IMetodoPago[] }>('/facturas/catalogo/metodos-pago')
  return data.data
}

export async function createMetodoPago(payload: IMetodoPagoFormPayload): Promise<IMetodoPago> {
  const { data } = await api.post<{ data: IMetodoPago }>('/metodos-pago', payload)
  return data.data
}

export async function updateMetodoPago(
  id: number,
  payload: IMetodoPagoFormPayload,
): Promise<IMetodoPago> {
  const { data } = await api.put<{ data: IMetodoPago }>(`/metodos-pago/${id}`, payload)
  return data.data
}

export async function toggleMetodoPago(id: number): Promise<IMetodoPago> {
  const { data } = await api.patch<{ data: IMetodoPago }>(`/metodos-pago/${id}/toggle`)
  return data.data
}
