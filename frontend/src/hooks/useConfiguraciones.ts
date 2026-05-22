import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  getConfiguraciones,
  registrarSalidaVehiculosActivos,
  updateConfiguraciones,
} from '@/services/configuracionService'
import type { IConfiguracionFormPayload } from '@/types/configuracion'

const CONFIGURACIONES_KEY = 'configuraciones'

export function useConfiguraciones() {
  return useQuery({
    queryKey: [CONFIGURACIONES_KEY],
    queryFn: () => getConfiguraciones(),
  })
}

export function useUpdateConfiguraciones() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IConfiguracionFormPayload) => updateConfiguraciones(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [CONFIGURACIONES_KEY] })
      toast.success('Configuraciones actualizadas correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }

      toast.error('No se pudieron actualizar las configuraciones.')
    },
  })
}

export function useRegistrarSalidaVehiculosActivos() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: () => registrarSalidaVehiculosActivos(),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: [CONFIGURACIONES_KEY] })
      toast.success(
        result.processed_count > 0
          ? `Se cerraron ${result.processed_count} parqueos activos.`
          : 'No había parqueos activos para cerrar.',
      )
    },
    onError: () => {
      toast.error('No se pudo registrar la salida de los vehículos activos.')
    },
  })
}
