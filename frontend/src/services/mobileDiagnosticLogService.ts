import api from './api'
import type { IMobileDiagnosticLogListResponse, TMobileDiagnosticTrigger } from '@/types/mobileDiagnosticLog'

export interface MobileDiagnosticLogListParams {
  page?: number
  per_page?: number
  search?: string
  sort?: string
  direction?: 'asc' | 'desc'
  trigger?: TMobileDiagnosticTrigger | 'todos'
  platform?: string | 'todos'
  feria_id?: number
}

export async function getMobileDiagnosticLogs(
  params: MobileDiagnosticLogListParams = {},
): Promise<IMobileDiagnosticLogListResponse> {
  const normalizedParams = {
    ...params,
    trigger: params.trigger && params.trigger !== 'todos' ? params.trigger : undefined,
    platform: params.platform && params.platform !== 'todos' ? params.platform : undefined,
  }

  const { data } = await api.get<IMobileDiagnosticLogListResponse>('/auth/mobile-diagnostic-logs', {
    params: normalizedParams,
  })

  return data
}
