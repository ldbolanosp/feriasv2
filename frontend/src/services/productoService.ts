import api from './api'
import type {
  IAsignarPreciosPayload,
  IProducto,
  IProductoFormPayload,
  IProductoListResponse,
} from '@/types/producto'

export interface ProductoListParams {
  page?: number
  per_page?: number
  search?: string
  sort?: string
  direction?: 'asc' | 'desc'
  activo?: boolean | null
}

export async function getProductos(
  params: ProductoListParams = {},
): Promise<IProductoListResponse> {
  const { data } = await api.get<IProductoListResponse>('/productos', { params })
  return data
}

export async function getProducto(id: number): Promise<IProducto> {
  const { data } = await api.get<{ data: IProducto }>(`/productos/${id}`)
  return data.data
}

export async function createProducto(payload: IProductoFormPayload): Promise<IProducto> {
  const { data } = await api.post<{ data: IProducto }>('/productos', payload)
  return data.data
}

export async function updateProducto(
  id: number,
  payload: IProductoFormPayload,
): Promise<IProducto> {
  const { data } = await api.put<{ data: IProducto }>(`/productos/${id}`, payload)
  return data.data
}

export async function toggleProducto(id: number): Promise<IProducto> {
  const { data } = await api.patch<{ message: string; data: IProducto }>(`/productos/${id}/toggle`)
  return data.data
}

export async function asignarPreciosProducto(
  productoId: number,
  payload: IAsignarPreciosPayload,
): Promise<IProducto> {
  const { data } = await api.post<{ message: string; data: IProducto }>(
    `/productos/${productoId}/precios`,
    payload,
  )

  return data.data
}

export async function eliminarPrecioProducto(
  productoId: number,
  feriaId: number,
): Promise<IProducto> {
  const { data } = await api.delete<{ message: string; data: IProducto }>(
    `/productos/${productoId}/precios/${feriaId}`,
  )

  return data.data
}

export async function searchProductosPorFeria(search?: string): Promise<IProducto[]> {
  const { data } = await api.get<{ data: IProducto[] }>('/productos/por-feria', {
    params: {
      search: search || undefined,
    },
  })

  return data.data
}
