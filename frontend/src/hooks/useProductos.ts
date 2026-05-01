import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  asignarPreciosProducto,
  createProducto,
  eliminarPrecioProducto,
  getProducto,
  getProductos,
  searchProductosPorFeria,
  toggleProducto,
  updateProducto,
  type ProductoListParams,
} from '@/services/productoService'
import type { IAsignarPreciosPayload, IProductoFormPayload } from '@/types/producto'

const PRODUCTOS_KEY = 'productos'

export function useProductos(params: ProductoListParams = {}) {
  return useQuery({
    queryKey: [PRODUCTOS_KEY, params],
    queryFn: () => getProductos(params),
    placeholderData: keepPreviousData,
  })
}

export function useProducto(id: number | null, enabled = true) {
  return useQuery({
    queryKey: [PRODUCTOS_KEY, id],
    queryFn: () => getProducto(id!),
    enabled: enabled && id !== null,
  })
}

export function useProductosPorFeria(search: string) {
  return useQuery({
    queryKey: [PRODUCTOS_KEY, 'por-feria', search],
    queryFn: () => searchProductosPorFeria(search),
  })
}

export function useCreateProducto() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IProductoFormPayload) => createProducto(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY] })
      toast.success('Producto creado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo crear el producto.')
    },
  })
}

export function useUpdateProducto() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: IProductoFormPayload }) =>
      updateProducto(id, payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY, variables.id] })
      toast.success('Producto actualizado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo actualizar el producto.')
    },
  })
}

export function useToggleProducto() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => toggleProducto(id),
    onSuccess: (producto) => {
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY, producto.id] })
      toast.success(producto.activo ? 'Producto activado.' : 'Producto desactivado.')
    },
    onError: () => {
      toast.error('No se pudo cambiar el estado del producto.')
    },
  })
}

export function useAsignarPreciosProducto() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      productoId,
      payload,
    }: {
      productoId: number
      payload: IAsignarPreciosPayload
    }) => asignarPreciosProducto(productoId, payload),
    onSuccess: (producto) => {
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY, producto.id] })
      toast.success('Precio agregado correctamente.')
    },
    onError: () => {
      toast.error('No se pudo guardar el precio.')
    },
  })
}

export function useEliminarPrecioProducto() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ productoId, feriaId }: { productoId: number; feriaId: number }) =>
      eliminarPrecioProducto(productoId, feriaId),
    onSuccess: (producto) => {
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [PRODUCTOS_KEY, producto.id] })
      toast.success('Precio eliminado correctamente.')
    },
    onError: () => {
      toast.error('No se pudo eliminar el precio.')
    },
  })
}
