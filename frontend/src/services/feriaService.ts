import api from './api'
import type { IFeria, IFeriaForm, IFeriaListResponse } from '@/types/feria'

export interface FeriaListParams {
  page?: number
  per_page?: number
  search?: string
  sort?: string
  direction?: 'asc' | 'desc'
  activa?: boolean | null
}

export async function getFerias(params: FeriaListParams = {}): Promise<IFeriaListResponse> {
  const { data } = await api.get<IFeriaListResponse>('/ferias', { params })
  return data
}

export async function getFeria(id: number): Promise<IFeria> {
  const { data } = await api.get<{ data: IFeria }>(`/ferias/${id}`)
  return data.data
}

export async function createFeria(payload: IFeriaForm): Promise<IFeria> {
  const { data } = await api.post<{ data: IFeria }>('/ferias', payload)
  return data.data
}

export async function updateFeria(id: number, payload: IFeriaForm): Promise<IFeria> {
  const { data } = await api.put<{ data: IFeria }>(`/ferias/${id}`, payload)
  return data.data
}

export async function toggleFeria(id: number): Promise<IFeria> {
  const { data } = await api.patch<{ message: string; data: IFeria }>(`/ferias/${id}/toggle`)
  return data.data
}
