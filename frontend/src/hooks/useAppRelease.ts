import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  createAppRelease,
  deactivateAppRelease,
  getAppReleases,
} from '@/services/appReleaseService'
import type { ICreateAppReleasePayload } from '@/types/appRelease'

const APP_RELEASES_KEY = 'app-releases'

export function useAppReleases(params: { page?: number; per_page?: number; platform?: string } = {}) {
  return useQuery({
    queryKey: [APP_RELEASES_KEY, params],
    queryFn: () => getAppReleases(params),
    placeholderData: keepPreviousData,
  })
}

export function useCreateAppRelease() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: ICreateAppReleasePayload) => createAppRelease(payload),
    onSuccess: (release) => {
      queryClient.invalidateQueries({ queryKey: [APP_RELEASES_KEY] })
      toast.success(
        `APK publicado: ${release.version_name} (${release.version_code}).`,
      )
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      if (isAxiosError(error) && error.response?.status === 403) {
        toast.error('No tienes permiso para publicar releases.')
        return
      }

      toast.error('No se pudo publicar el APK.')
    },
  })
}

export function useDeactivateAppRelease() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => deactivateAppRelease(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [APP_RELEASES_KEY] })
      toast.success('Release desactivada correctamente.')
    },
    onError: () => {
      toast.error('No se pudo desactivar la release.')
    },
  })
}
