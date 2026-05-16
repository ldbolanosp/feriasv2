export type TMobileDiagnosticTrigger = 'manual' | 'automatic' | 'crash'

export interface IMobileDiagnosticLogUser {
  id: number
  name: string
  email: string
}

export interface IMobileDiagnosticLogFeria {
  id: number
  codigo: string
  descripcion: string
}

export interface IMobileDiagnosticLogEvent {
  timestamp?: string | null
  level?: string | null
  category?: string | null
  message?: string | null
  route?: string | null
  error?: string | null
  stack_trace?: string | null
  context?: Record<string, unknown> | null
}

export interface IMobileDiagnosticLog {
  id: number
  user_id: number | null
  feria_id: number | null
  session_id: string
  trigger: TMobileDiagnosticTrigger
  platform: string | null
  app_version: string | null
  device_name: string | null
  current_route: string | null
  summary: string | null
  event_count: number
  last_event_at: string | null
  created_at: string | null
  updated_at: string | null
  user?: IMobileDiagnosticLogUser
  feria?: IMobileDiagnosticLogFeria
  payload?: {
    logs?: IMobileDiagnosticLogEvent[]
  }
}

export interface IMobileDiagnosticLogListResponse {
  data: IMobileDiagnosticLog[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}
