export interface IDashboardResumen {
  rol: 'administrador' | 'supervisor' | 'facturador' | 'inspector'
  facturas_count: number
  parqueos_count: number
  tarimas_count: number
  sanitarios_count: number
  recaudacion_total: number
  mis_facturas_hoy?: number
  mis_borradores?: number
}

export interface IDashboardFacturaItem {
  id: number
  consecutivo: string | null
  cliente: string
  estado: string
  estado_label: string
  subtotal: string
  usuario: string | null
  fecha: string | null
}

export interface IDashboardFacturacion {
  rol: 'administrador' | 'supervisor' | 'facturador' | 'inspector'
  ultimas_facturas: IDashboardFacturaItem[]
  facturas_por_producto: Array<{
    nombre: string
    total: number
  }>
  facturas_por_usuario: Array<{
    nombre: string
    total: number
  }>
  resumen_por_facturador: IDashboardResumenFacturador[]
}

export interface IDashboardResumenFacturador {
  usuario: {
    id: number
    nombre: string
    email: string
  }
  facturas_count: number
  parqueos_count: number
  total_facturas: number
  total_parqueos: number
  total_general: number
  facturas_por_metodo_pago: {
    efectivo: number
    sinpe: number
    tarjeta: number
  }
}

export interface IDashboardParqueos {
  activos: number
  finalizados: number
  cancelados: number
}

export interface IDashboardRecaudacionDiariaItem {
  fecha: string
  label: string
  facturas: number
  parqueos: number
  tarimas: number
  sanitarios: number
  total: number
}
