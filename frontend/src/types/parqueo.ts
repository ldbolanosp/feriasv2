export type TEstadoParqueo = 'activo' | 'finalizado' | 'cancelado'

export interface IParqueo {
  id: number
  feria_id: number
  user_id: number
  placa: string
  fecha_hora_ingreso: string
  fecha_hora_salida: string | null
  tarifa: string
  tarifa_tipo: string
  tarifa_tipo_label: string
  estado: TEstadoParqueo
  estado_label: string
  observaciones: string | null
  pdf_path: string | null
  feria?: {
    id: number
    codigo: string
    descripcion: string
  }
  usuario?: {
    id: number
    name: string
    email: string
  } | null
  created_at: string
  updated_at: string
}

export interface IParqueoFormPayload {
  placa: string
  observaciones?: string | null
}

export interface IParqueoListResponse {
  data: IParqueo[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
  tarifa_actual: number
}
