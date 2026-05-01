export interface IFeria {
  id: number
  codigo: string
  descripcion: string
  facturacion_publico: boolean
  activa: boolean
  created_at: string
  updated_at: string
}

export interface IFeriaForm {
  codigo: string
  descripcion: string
  facturacion_publico: boolean
}

export interface IFeriaListResponse {
  data: IFeria[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}
