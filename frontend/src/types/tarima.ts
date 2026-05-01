export type TEstadoTarima = 'facturado' | 'cancelado'

export interface ITarima {
  id: number
  feria_id: number
  user_id: number
  participante_id: number
  numero_tarima: string | null
  cantidad: number
  precio_unitario: string
  total: string
  estado: TEstadoTarima
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
  participante?: {
    id: number
    nombre: string
    numero_identificacion: string
  } | null
  created_at: string
  updated_at: string
}

export interface ITarimaFormPayload {
  participante_id: number
  numero_tarima?: string | null
  cantidad: number
  observaciones?: string | null
}

export interface ITarimaListResponse {
  data: ITarima[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
  precio_actual: number
}
