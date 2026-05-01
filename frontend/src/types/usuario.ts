import type { IFeria } from './feria'

export const ROLES_USUARIO = [
  'administrador',
  'supervisor',
  'facturador',
  'inspector',
] as const

export type TRolUsuario = (typeof ROLES_USUARIO)[number]

export const ETIQUETAS_ROL_USUARIO: Record<TRolUsuario, string> = {
  administrador: 'Administrador',
  supervisor: 'Supervisor',
  facturador: 'Facturador',
  inspector: 'Inspector',
}

export interface IUsuario {
  id: number
  name: string
  email: string
  activo: boolean
  role: string | null
  roles: string[]
  permisos: string[]
  ferias_count: number
  ferias: IFeria[]
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export interface IUsuarioFormPayload {
  name: string
  email: string
  activo: boolean
  role: string | null
  ferias: number[]
  password?: string
  password_confirmation?: string
}

export interface IUsuarioSesion {
  id: string
  ip_address: string | null
  user_agent: string | null
  browser: string
  platform: string
  device: string
  last_activity: string
  is_current: boolean
}

export interface IUsuarioListResponse {
  data: IUsuario[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}

export function etiquetaRolUsuario(role: string | null): string {
  if (!role) {
    return 'Sin rol'
  }

  return ETIQUETAS_ROL_USUARIO[role as TRolUsuario] ?? role
}
