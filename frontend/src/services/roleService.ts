import api from './api'
import type { IRolListResponse, IRolPermisos, IUpdateRolPermissionsPayload } from '@/types/role'

export async function getRoles(): Promise<IRolListResponse> {
  const { data } = await api.get<IRolListResponse>('/usuarios/roles')
  return data
}

export async function updateRolePermissions(
  role: string,
  payload: IUpdateRolPermissionsPayload,
): Promise<IRolPermisos> {
  const { data } = await api.put<{ message: string; data: IRolPermisos }>(`/usuarios/roles/${role}`, payload)
  return data.data
}
