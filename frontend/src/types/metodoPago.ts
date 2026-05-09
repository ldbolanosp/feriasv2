export interface IMetodoPago {
  id: number
  nombre: string
  activo: boolean
  created_at: string
  updated_at: string
}

export interface IMetodoPagoFormPayload {
  nombre: string
}

export interface IMetodoPagoListResponse {
  data: IMetodoPago[]
  meta?: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}
