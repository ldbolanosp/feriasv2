import api from './api'
import type {
  IParticipante,
  IParticipanteFormPayload,
  IParticipanteListResponse,
} from '@/types/participante'

export interface ParticipanteListParams {
  page?: number
  per_page?: number
  search?: string
  sort?: string
  direction?: 'asc' | 'desc'
  activo?: boolean | null
  tipo_identificacion?: string
  feria_id?: number | null
}

export async function getParticipantes(
  params: ParticipanteListParams = {},
): Promise<IParticipanteListResponse> {
  const { data } = await api.get<IParticipanteListResponse>('/participantes', { params })
  return data
}

export async function getParticipante(id: number): Promise<IParticipante> {
  const { data } = await api.get<{ data: IParticipante }>(`/participantes/${id}`)
  return data.data
}

export async function createParticipante(payload: IParticipanteFormPayload): Promise<IParticipante> {
  const { data } = await api.post<{ data: IParticipante }>('/participantes', payload)
  return data.data
}

export async function updateParticipante(
  id: number,
  payload: IParticipanteFormPayload,
): Promise<IParticipante> {
  const { data } = await api.put<{ data: IParticipante }>(`/participantes/${id}`, payload)
  return data.data
}

export async function toggleParticipante(id: number): Promise<IParticipante> {
  const { data } = await api.patch<{ message: string; data: IParticipante }>(
    `/participantes/${id}/toggle`,
  )
  return data.data
}

export async function asignarFeriasParticipante(
  participanteId: number,
  feriaIds: number[],
): Promise<IParticipante> {
  const { data } = await api.post<{ message: string; data: IParticipante }>(
    `/participantes/${participanteId}/ferias`,
    { ferias: feriaIds },
  )
  return data.data
}

export async function desasignarFeriaParticipante(
  participanteId: number,
  feriaId: number,
): Promise<IParticipante> {
  const { data } = await api.delete<{ message: string; data: IParticipante }>(
    `/participantes/${participanteId}/ferias/${feriaId}`,
  )
  return data.data
}

export async function searchParticipantesPorFeria(search?: string): Promise<IParticipante[]> {
  const { data } = await api.get<{ data: IParticipante[] }>('/participantes/por-feria', {
    params: {
      search: search || undefined,
    },
  })

  return data.data
}
