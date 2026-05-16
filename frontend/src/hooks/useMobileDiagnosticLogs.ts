import { keepPreviousData, useQuery } from '@tanstack/react-query'
import {
  getMobileDiagnosticLogs,
  type MobileDiagnosticLogListParams,
} from '@/services/mobileDiagnosticLogService'

const MOBILE_DIAGNOSTIC_LOGS_KEY = 'mobile-diagnostic-logs'

export function useMobileDiagnosticLogs(params: MobileDiagnosticLogListParams = {}) {
  return useQuery({
    queryKey: [MOBILE_DIAGNOSTIC_LOGS_KEY, params],
    queryFn: () => getMobileDiagnosticLogs(params),
    placeholderData: keepPreviousData,
  })
}
