export interface IConfiguracionEditable {
  clave: string
  valor: string | null
  descripcion: string
  scope: 'feria' | 'global'
  global_valor: string | null
}

export interface IConfiguracionResponse {
  data: {
    feria: {
      id: number
      codigo: string
      descripcion: string
    }
    configuraciones: Record<string, IConfiguracionEditable>
  }
}

export interface IConfiguracionFormPayload {
  tarifa_parqueo: number
  precio_tarima: number
  precio_sanitario: number
}
