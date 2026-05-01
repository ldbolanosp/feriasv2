import type { IFeria } from './feria'

export const TIPOS_IDENTIFICACION = ['fisica', 'juridica', 'dimex', 'nite'] as const

export type TTipoIdentificacion = (typeof TIPOS_IDENTIFICACION)[number]

export const ETIQUETAS_TIPO_IDENTIFICACION: Record<TTipoIdentificacion, string> = {
  fisica: 'Cédula Física',
  juridica: 'Cédula Jurídica',
  dimex: 'DIMEX',
  nite: 'NITE',
}

export const TIPOS_SANGRE = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] as const

export type TTipoSangre = (typeof TIPOS_SANGRE)[number]

export interface IParticipante {
  id: number
  nombre: string
  tipo_identificacion: string
  numero_identificacion: string
  correo_electronico: string | null
  numero_carne: string | null
  fecha_emision_carne: string | null
  fecha_vencimiento_carne: string | null
  procedencia: string | null
  telefono: string | null
  tipo_sangre: string | null
  padecimientos: string | null
  contacto_emergencia_nombre: string | null
  contacto_emergencia_telefono: string | null
  activo: boolean
  ferias?: IFeria[]
  created_at: string
  updated_at: string
}

export interface IParticipanteFormPayload {
  nombre: string
  tipo_identificacion: string
  numero_identificacion: string
  correo_electronico: string | null
  numero_carne: string | null
  fecha_emision_carne: string | null
  fecha_vencimiento_carne: string | null
  procedencia: string | null
  telefono: string | null
  tipo_sangre: string | null
  padecimientos: string | null
  contacto_emergencia_nombre: string | null
  contacto_emergencia_telefono: string | null
  activo: boolean
}

export interface IParticipanteListResponse {
  data: IParticipante[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}

export function etiquetaTipoIdentificacion(tipo: string): string {
  return ETIQUETAS_TIPO_IDENTIFICACION[tipo as TTipoIdentificacion] ?? tipo
}
