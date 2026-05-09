export type TEstadoFactura = 'borrador' | 'facturado' | 'eliminado'

export interface IFacturaDetalle {
  id: number
  producto_id: number
  descripcion_producto: string
  cantidad: string
  precio_unitario: string
  subtotal_linea: string
  producto: {
    id: number
    codigo: string
    descripcion: string
  } | null
}

export interface IFactura {
  id: number
  feria_id: number
  participante_id: number | null
  user_id: number
  metodo_pago_id: number
  consecutivo: string | null
  es_publico_general: boolean
  nombre_publico: string | null
  tipo_puesto: string | null
  numero_puesto: string | null
  subtotal: string
  monto_pago: string | null
  monto_cambio: string | null
  observaciones: string | null
  estado: TEstadoFactura
  estado_label: string
  fecha_emision: string | null
  pdf_path: string | null
  detalles_count: number
  feria?: {
    id: number
    codigo: string
    descripcion: string
    facturacion_publico: boolean
  }
  participante?: {
    id: number
    nombre: string
    numero_identificacion: string
  } | null
  usuario?: {
    id: number
    name: string
    email: string
  } | null
  metodo_pago?: {
    id: number
    nombre: string
    activo: boolean
  } | null
  detalles: IFacturaDetalle[]
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export interface IFacturaFormPayload {
  es_publico_general: boolean
  nombre_publico: string | null
  participante_id: number | null
  tipo_puesto: string | null
  numero_puesto: string | null
  metodo_pago_id: number | null
  monto_pago: number | null
  observaciones: string | null
  detalles: Array<{
    producto_id: number
    cantidad: number
  }>
}

export interface IFacturaListResponse {
  data: IFactura[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}
