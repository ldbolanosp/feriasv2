import api from './api'
import type { IInspeccion, IInspeccionFormPayload, IInspeccionListResponse } from '@/types/inspeccion'
import type { IParticipante, IParticipanteListResponse } from '@/types/participante'

export interface InspeccionListParams {
  page?: number
  per_page?: number
  search?: string
}

export async function getInspecciones(
  params: InspeccionListParams = {},
): Promise<IInspeccionListResponse> {
  const { data } = await api.get<IInspeccionListResponse>('/inspecciones', { params })
  return data
}

export async function createInspeccion(payload: IInspeccionFormPayload): Promise<IInspeccion> {
  const { data } = await api.post<{ data: IInspeccion }>('/inspecciones', payload)
  return data.data
}

export async function getVencimientosCarne(
  params: InspeccionListParams = {},
): Promise<IParticipanteListResponse> {
  const { data } = await api.get<IParticipanteListResponse>('/inspecciones/vencimientos-carne', {
    params,
  })
  return data
}

export async function getReinspecciones(
  params: InspeccionListParams = {},
): Promise<IInspeccionListResponse> {
  const { data } = await api.get<IInspeccionListResponse>('/inspecciones/reinspecciones', {
    params,
  })
  return data
}

export interface ParticipanteCarnePayload {
  numero_carne: string | null
  fecha_emision_carne: string | null
  fecha_vencimiento_carne: string | null
}

export async function updateParticipanteCarne(
  participanteId: number,
  payload: ParticipanteCarnePayload,
): Promise<IParticipante> {
  const { data } = await api.patch<{ data: IParticipante }>(
    `/participantes/${participanteId}/carne`,
    payload,
  )

  return data.data
}
