export interface IInspeccionParticipanteResumen {
  id: number
  nombre: string
  numero_identificacion: string
  numero_carne: string | null
  fecha_vencimiento_carne: string | null
}

export interface IInspeccionInspectorResumen {
  id: number
  name: string
  email: string
}

export interface IInspeccionItem {
  id: number
  item_diagnostico_id: number | null
  nombre_item: string
  cumple: boolean
  observaciones: string | null
  orden: number
}

export interface IInspeccion {
  id: number
  feria_id: number
  participante_id: number
  reinspeccion_de_id: number | null
  total_items: number
  total_incumplidos: number
  es_reinspeccion: boolean
  participante: IInspeccionParticipanteResumen | null
  inspector: IInspeccionInspectorResumen | null
  reinspeccion_de: {
    id: number
    created_at: string
    total_incumplidos: number
  } | null
  items: IInspeccionItem[]
  created_at: string
  updated_at: string
}

export interface IInspeccionListResponse {
  data: IInspeccion[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}

export interface IInspeccionItemPayload {
  item_diagnostico_id: number
  cumple: boolean
  observaciones: string | null
}

export interface IInspeccionFormPayload {
  participante_id: number
  reinspeccion_de_id?: number | null
  items: IInspeccionItemPayload[]
}
