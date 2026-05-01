import api from './api'
import type { ITarima, ITarimaFormPayload, ITarimaListResponse } from '@/types/tarima'

export interface TarimaListParams {
  page?: number
  per_page?: number
  estado?: string
  search?: string
  feria_id?: number
  sort?: string
  direction?: 'asc' | 'desc'
}

export async function getTarimas(params: TarimaListParams = {}): Promise<ITarimaListResponse> {
  const { data } = await api.get<ITarimaListResponse>('/tarimas', { params })
  return data
}

export async function getTarima(id: number): Promise<ITarima> {
  const { data } = await api.get<{ data: ITarima }>(`/tarimas/${id}`)
  return data.data
}

export async function createTarima(payload: ITarimaFormPayload): Promise<ITarima> {
  const { data } = await api.post<{ data: ITarima }>('/tarimas', payload)
  return data.data
}

export async function cancelarTarima(id: number): Promise<ITarima> {
  const { data } = await api.patch<{ data: ITarima }>(`/tarimas/${id}/cancelar`)
  return data.data
}

export async function getTarimaPdfBlob(id: number): Promise<Blob> {
  const { data } = await api.get(`/tarimas/${id}/pdf`, {
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
        <title>Ticket de tarima</title>
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

export async function openTarimaPdf(id: number): Promise<void> {
  const blob = await getTarimaPdfBlob(id)
  openBlobInWindow(blob)
}
