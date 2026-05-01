import api from './api'
import type { IParqueo, IParqueoFormPayload, IParqueoListResponse } from '@/types/parqueo'

export interface ParqueoListParams {
  page?: number
  per_page?: number
  estado?: string
  fecha?: string
  placa?: string
  feria_id?: number
  sort?: string
  direction?: 'asc' | 'desc'
}

export async function getParqueos(params: ParqueoListParams = {}): Promise<IParqueoListResponse> {
  const { data } = await api.get<IParqueoListResponse>('/parqueos', { params })
  return data
}

export async function getParqueo(id: number): Promise<IParqueo> {
  const { data } = await api.get<{ data: IParqueo }>(`/parqueos/${id}`)
  return data.data
}

export async function createParqueo(payload: IParqueoFormPayload): Promise<IParqueo> {
  const { data } = await api.post<{ data: IParqueo }>('/parqueos', payload)
  return data.data
}

export async function salidaParqueo(id: number): Promise<IParqueo> {
  const { data } = await api.patch<{ data: IParqueo }>(`/parqueos/${id}/salida`)
  return data.data
}

export async function cancelarParqueo(id: number): Promise<IParqueo> {
  const { data } = await api.patch<{ data: IParqueo }>(`/parqueos/${id}/cancelar`)
  return data.data
}

export async function getParqueoPdfBlob(id: number): Promise<Blob> {
  const { data } = await api.get(`/parqueos/${id}/pdf`, {
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
        <title>Ticket de parqueo</title>
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

export async function openParqueoPdf(id: number): Promise<void> {
  const blob = await getParqueoPdfBlob(id)
  openBlobInWindow(blob)
}
