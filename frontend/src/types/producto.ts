import type { IFeria } from './feria'

export interface IProductoPrecio {
  id: number
  feria_id: number
  precio: string
  feria: Pick<IFeria, 'id' | 'codigo' | 'descripcion'> | null
  created_at: string
  updated_at: string
}

export interface IProducto {
  id: number
  codigo: string
  descripcion: string
  activo: boolean
  precios_count: number
  precio_feria_actual?: number
  precios: IProductoPrecio[]
  created_at: string
  updated_at: string
}

export interface IProductoFormPayload {
  codigo: string
  descripcion: string
  activo: boolean
}

export interface IAsignarPreciosPayload {
  precios: Array<{
    feria_id: number
    precio: number
  }>
}

export interface IProductoListResponse {
  data: IProducto[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}
