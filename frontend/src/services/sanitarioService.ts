import api from './api'
import type {
  ISanitario,
  ISanitarioFormPayload,
  ISanitarioListResponse,
} from '@/types/sanitario'

export interface SanitarioListParams {
  page?: number
  per_page?: number
  estado?: string
  search?: string
  feria_id?: number
  sort?: string
  direction?: 'asc' | 'desc'
}

export async function getSanitarios(
  params: SanitarioListParams = {},
): Promise<ISanitarioListResponse> {
  const { data } = await api.get<ISanitarioListResponse>('/sanitarios', { params })
  return data
}

export async function getSanitario(id: number): Promise<ISanitario> {
  const { data } = await api.get<{ data: ISanitario }>(`/sanitarios/${id}`)
  return data.data
}

export async function createSanitario(payload: ISanitarioFormPayload): Promise<ISanitario> {
  const { data } = await api.post<{ data: ISanitario }>('/sanitarios', payload)
  return data.data
}

export async function cancelarSanitario(id: number): Promise<ISanitario> {
  const { data } = await api.patch<{ data: ISanitario }>(`/sanitarios/${id}/cancelar`)
  return data.data
}

export async function getSanitarioPdfBlob(id: number): Promise<Blob> {
  const { data } = await api.get(`/sanitarios/${id}/pdf`, {
    responseType: 'blob',
    headers: {
      Accept: 'application/pdf',
    },
  })

  return data as Blob
}

function openBlobInWindow(blob: Blob): void {
  const blobUrl = URL.createObjectURL(blob)
  const printWindow = window.open('about:blank', '_blank')

  if (!printWindow) {
    window.open(blobUrl, '_blank')
    return
  }

  printWindow.document.open()
  printWindow.document.write(`
    <!doctype html>
    <html lang="es">
      <head>
        <title>Ticket de sanitario</title>
        <style>
          html, body { margin: 0; height: 100%; background: #111; }
          iframe { border: 0; width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <iframe src="${blobUrl}"></iframe>
      </body>
    </html>
  `)
  printWindow.document.close()
  printWindow.addEventListener(
    'beforeunload',
    () => {
      URL.revokeObjectURL(blobUrl)
    },
    { once: true },
  )
}

export async function openSanitarioPdf(id: number): Promise<void> {
  const blob = await getSanitarioPdfBlob(id)
  openBlobInWindow(blob)
}
