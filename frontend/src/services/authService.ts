import api, { getCsrfCookie } from './api'
import type { IFeria, ILoginRequest, ILoginResponse, IUpdatePasswordRequest } from '@/types/auth'

export async function login(credentials: ILoginRequest): Promise<ILoginResponse> {
  await getCsrfCookie()
  const { data } = await api.post<ILoginResponse>('/auth/login', credentials)
  return data
}

export async function logout(): Promise<void> {
  await api.post('/auth/logout')
}

export async function getUser(): Promise<ILoginResponse> {
  const { data } = await api.get<ILoginResponse>('/auth/user')
  return data
}

export async function updatePassword(payload: IUpdatePasswordRequest): Promise<void> {
  await api.put('/auth/password', payload)
}

export async function getFerias(): Promise<IFeria[]> {
  const { data } = await api.get<{ data: IFeria[] }>('/auth/mis-ferias')
  return data.data
}

export async function seleccionarFeria(feriaId: number): Promise<IFeria> {
  const { data } = await api.post<{ feria: IFeria }>('/auth/seleccionar-feria', {
    feria_id: feriaId,
  })
  return data.feria
}
