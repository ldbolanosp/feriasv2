import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  cerrarSesionUsuario,
  cerrarTodasLasSesionesUsuario,
  createUsuario,
  deleteUsuario,
  getUsuario,
  getUsuarios,
  getUsuarioSesiones,
  toggleUsuario,
  updateUsuario,
  type UsuarioListParams,
} from '@/services/usuarioService'
import type { IUsuarioFormPayload } from '@/types/usuario'

const USUARIOS_KEY = 'usuarios'

export function useUsuarios(params: UsuarioListParams = {}) {
  return useQuery({
    queryKey: [USUARIOS_KEY, params],
    queryFn: () => getUsuarios(params),
    placeholderData: keepPreviousData,
  })
}

export function useUsuario(id: number | null, enabled = true) {
  return useQuery({
    queryKey: [USUARIOS_KEY, id],
    queryFn: () => getUsuario(id!),
    enabled: enabled && id !== null,
  })
}

export function useCreateUsuario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IUsuarioFormPayload) => createUsuario(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY] })
      toast.success('Usuario creado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo crear el usuario.')
    },
  })
}

export function useUpdateUsuario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: IUsuarioFormPayload }) =>
      updateUsuario(id, payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY, variables.id] })
      toast.success('Usuario actualizado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudo actualizar el usuario.')
    },
  })
}

export function useToggleUsuario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => toggleUsuario(id),
    onSuccess: (usuario) => {
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY] })
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY, usuario.id] })
      toast.success(usuario.activo ? 'Usuario activado.' : 'Usuario desactivado.')
    },
    onError: () => {
      toast.error('No se pudo cambiar el estado del usuario.')
    },
  })
}

export function useDeleteUsuario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => deleteUsuario(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY] })
      toast.success('Usuario eliminado correctamente.')
    },
    onError: () => {
      toast.error('No se pudo eliminar el usuario.')
    },
  })
}

export function useUsuarioSesiones(userId: number | null, enabled = true) {
  return useQuery({
    queryKey: [USUARIOS_KEY, userId, 'sesiones'],
    queryFn: () => getUsuarioSesiones(userId!),
    enabled: enabled && userId !== null,
  })
}

export function useCerrarSesionUsuario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ userId, sessionId }: { userId: number; sessionId: string }) =>
      cerrarSesionUsuario(userId, sessionId),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY, variables.userId, 'sesiones'] })
      toast.success('Sesión cerrada correctamente.')
    },
    onError: () => {
      toast.error('No se pudo cerrar la sesión.')
    },
  })
}

export function useCerrarTodasLasSesionesUsuario() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (userId: number) => cerrarTodasLasSesionesUsuario(userId),
    onSuccess: (_, userId) => {
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY, userId, 'sesiones'] })
      queryClient.invalidateQueries({ queryKey: [USUARIOS_KEY] })
      toast.success('Todas las sesiones fueron cerradas.')
    },
    onError: () => {
      toast.error('No se pudieron cerrar las sesiones.')
    },
  })
}
