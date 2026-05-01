import api from './api'
import type {
  IDashboardFacturacion,
  IDashboardParqueos,
  IDashboardRecaudacionDiariaItem,
  IDashboardResumen,
} from '@/types/dashboard'

export interface DashboardParams {
  fecha_desde?: string
  fecha_hasta?: string
}

export async function getDashboardResumen(
  params: DashboardParams = {},
): Promise<IDashboardResumen> {
  const { data } = await api.get<{ data: IDashboardResumen }>('/dashboard/resumen', { params })
  return data.data
}

export async function getDashboardFacturacion(
  params: DashboardParams = {},
): Promise<IDashboardFacturacion> {
  const { data } = await api.get<{ data: IDashboardFacturacion }>('/dashboard/facturacion', {
    params,
  })
  return data.data
}

export async function getDashboardParqueos(
  params: DashboardParams = {},
): Promise<IDashboardParqueos> {
  const { data } = await api.get<{ data: IDashboardParqueos }>('/dashboard/parqueos', {
    params,
  })
  return data.data
}

export async function getDashboardRecaudacionDiaria(
  params: DashboardParams = {},
): Promise<IDashboardRecaudacionDiariaItem[]> {
  const { data } = await api.get<{ data: IDashboardRecaudacionDiariaItem[] }>(
    '/dashboard/recaudacion-diaria',
    { params },
  )
  return data.data
}
