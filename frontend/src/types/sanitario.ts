export type TEstadoSanitario = 'facturado' | 'cancelado'

export interface ISanitario {
  id: number
  feria_id: number
  user_id: number
  participante_id: number | null
  cantidad: number
  precio_unitario: string
  total: string
  estado: TEstadoSanitario
  estado_label: string
  observaciones: string | null
  pdf_path: string | null
  es_publico: boolean
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

export interface ISanitarioFormPayload {
  participante_id?: number | null
  cantidad: number
  observaciones?: string | null
}

export interface ISanitarioListResponse {
  data: ISanitario[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
  precio_actual: number
}
