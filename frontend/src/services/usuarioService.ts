import api from './api'
import type {
  IUsuario,
  IUsuarioFormPayload,
  IUsuarioListResponse,
  IUsuarioSesion,
} from '@/types/usuario'

export interface UsuarioListParams {
  page?: number
  per_page?: number
  search?: string
  sort?: string
  direction?: 'asc' | 'desc'
  activo?: boolean | null
  role?: string
}

export async function getUsuarios(
  params: UsuarioListParams = {},
): Promise<IUsuarioListResponse> {
  const { data } = await api.get<IUsuarioListResponse>('/usuarios', { params })
  return data
}

export async function getUsuario(id: number): Promise<IUsuario> {
  const { data } = await api.get<{ data: IUsuario }>(`/usuarios/${id}`)
  return data.data
}

export async function createUsuario(payload: IUsuarioFormPayload): Promise<IUsuario> {
  const { data } = await api.post<{ data: IUsuario }>('/usuarios', payload)
  return data.data
}

export async function updateUsuario(
  id: number,
  payload: IUsuarioFormPayload,
): Promise<IUsuario> {
  const { data } = await api.put<{ data: IUsuario }>(`/usuarios/${id}`, payload)
  return data.data
}

export async function toggleUsuario(id: number): Promise<IUsuario> {
  const { data } = await api.patch<{ message: string; data: IUsuario }>(`/usuarios/${id}/toggle`)
  return data.data
}

export async function deleteUsuario(id: number): Promise<void> {
  await api.delete(`/usuarios/${id}`)
}

export async function getUsuarioSesiones(userId: number): Promise<IUsuarioSesion[]> {
  const { data } = await api.get<{ data: IUsuarioSesion[] }>(`/usuarios/${userId}/sesiones`)
  return data.data
}

export async function cerrarSesionUsuario(userId: number, sessionId: string): Promise<void> {
  await api.delete(`/usuarios/${userId}/sesiones/${sessionId}`)
}

export async function cerrarTodasLasSesionesUsuario(userId: number): Promise<void> {
  await api.delete(`/usuarios/${userId}/sesiones/all`)
}
