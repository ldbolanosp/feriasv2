export interface IUser {
  id: number
  name: string
  email: string
  activo: boolean
}

export interface IFeria {
  id: number
  codigo: string
  descripcion: string
  facturacion_publico: boolean
}

export interface ILoginRequest {
  email: string
  password: string
}

export interface ILoginResponse {
  user: IUser
  roles: string[]
  permisos: string[]
  ferias: IFeria[]
}

export interface IUpdatePasswordRequest {
  current_password: string
  password: string
  password_confirmation: string
}
