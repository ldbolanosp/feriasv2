import api from './api'
import type {
  IConfiguracionFormPayload,
  IConfiguracionResponse,
} from '@/types/configuracion'

export async function getConfiguraciones(): Promise<IConfiguracionResponse['data']> {
  const { data } = await api.get<IConfiguracionResponse>('/configuraciones')
  return data.data
}

export async function updateConfiguraciones(
  payload: IConfiguracionFormPayload,
): Promise<IConfiguracionResponse['data']> {
  const { data } = await api.put<IConfiguracionResponse>('/configuraciones', payload)
  return data.data
}
