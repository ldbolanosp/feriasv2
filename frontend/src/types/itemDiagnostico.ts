export interface IItemDiagnostico {
  id: number
  nombre: string
  created_at: string
  updated_at: string
}

export interface IItemDiagnosticoFormPayload {
  nombre: string
}

export interface IItemDiagnosticoListResponse {
  data: IItemDiagnostico[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}
