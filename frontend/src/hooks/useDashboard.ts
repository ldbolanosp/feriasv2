import { useQuery } from '@tanstack/react-query'
import {
  getDashboardFacturacion,
  getDashboardParqueos,
  getDashboardRecaudacionDiaria,
  getDashboardResumen,
  type DashboardParams,
} from '@/services/dashboardService'

const DASHBOARD_KEY = 'dashboard'

export function useDashboardResumen(params: DashboardParams = {}) {
  return useQuery({
    queryKey: [DASHBOARD_KEY, 'resumen', params],
    queryFn: () => getDashboardResumen(params),
  })
}

export function useDashboardFacturacion(params: DashboardParams = {}) {
  return useQuery({
    queryKey: [DASHBOARD_KEY, 'facturacion', params],
    queryFn: () => getDashboardFacturacion(params),
  })
}

export function useDashboardParqueos(params: DashboardParams = {}) {
  return useQuery({
    queryKey: [DASHBOARD_KEY, 'parqueos', params],
    queryFn: () => getDashboardParqueos(params),
  })
}

export function useDashboardRecaudacionDiaria(params: DashboardParams = {}) {
  return useQuery({
    queryKey: [DASHBOARD_KEY, 'recaudacion-diaria', params],
    queryFn: () => getDashboardRecaudacionDiaria(params),
  })
}
