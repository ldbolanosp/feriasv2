import api from './api'
import type {
  IItemDiagnostico,
  IItemDiagnosticoFormPayload,
  IItemDiagnosticoListResponse,
} from '@/types/itemDiagnostico'

export interface ItemDiagnosticoListParams {
  page?: number
  per_page?: number
  search?: string
}

export async function getItemsDiagnostico(
  params: ItemDiagnosticoListParams = {},
): Promise<IItemDiagnosticoListResponse> {
  const { data } = await api.get<IItemDiagnosticoListResponse>('/items-diagnostico', { params })
  return data
}

export async function createItemDiagnostico(
  payload: IItemDiagnosticoFormPayload,
): Promise<IItemDiagnostico> {
  const { data } = await api.post<{ data: IItemDiagnostico }>('/items-diagnostico', payload)
  return data.data
}

export async function updateItemDiagnostico(
  id: number,
  payload: IItemDiagnosticoFormPayload,
): Promise<IItemDiagnostico> {
  const { data } = await api.put<{ data: IItemDiagnostico }>(`/items-diagnostico/${id}`, payload)
  return data.data
}

export async function deleteItemDiagnostico(id: number): Promise<void> {
  await api.delete(`/items-diagnostico/${id}`)
}
