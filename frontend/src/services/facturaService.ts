import api from './api'
import type { IFactura, IFacturaFormPayload, IFacturaListResponse } from '@/types/factura'

export interface FacturaListParams {
  page?: number
  per_page?: number
  estado?: string
  fecha_desde?: string
  fecha_hasta?: string
  participante_id?: number
  feria_id?: number
  sort?: string
  direction?: 'asc' | 'desc'
}

export async function getFacturas(params: FacturaListParams = {}): Promise<IFacturaListResponse> {
  const { data } = await api.get<IFacturaListResponse>('/facturas', { params })
  return data
}

export async function getFactura(id: number): Promise<IFactura> {
  const { data } = await api.get<{ data: IFactura }>(`/facturas/${id}`)
  return data.data
}

export async function createFactura(payload: IFacturaFormPayload): Promise<IFactura> {
  const { data } = await api.post<{ data: IFactura }>('/facturas', payload)
  return data.data
}

export async function updateFactura(id: number, payload: IFacturaFormPayload): Promise<IFactura> {
  const { data } = await api.put<{ data: IFactura }>(`/facturas/${id}`, payload)
  return data.data
}

export async function facturarFactura(id: number): Promise<IFactura> {
  const { data } = await api.post<{ data: IFactura }>(`/facturas/${id}/facturar`)
  return data.data
}

export async function deleteFactura(id: number): Promise<void> {
  await api.delete(`/facturas/${id}`)
}

export async function getFacturaPdfBlob(id: number): Promise<Blob> {
  const { data } = await api.get(`/facturas/${id}/pdf`, {
    responseType: 'blob',
    headers: {
      Accept: 'application/pdf',
    },
  })

  return data as Blob
}

function openBlobInWindow(blob: Blob, autoPrint: boolean): void {
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
        <title>Factura PDF</title>
        <style>
          html, body { margin: 0; height: 100%; background: #111; }
          iframe { border: 0; width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <iframe id="pdf-frame" src="${blobUrl}"></iframe>
      </body>
    </html>
  `)
  printWindow.document.close()

  const cleanup = () => {
    URL.revokeObjectURL(blobUrl)
  }

  printWindow.addEventListener('beforeunload', cleanup, { once: true })

  if (!autoPrint) {
    return
  }

  printWindow.addEventListener(
    'load',
    () => {
      const iframe = printWindow.document.getElementById('pdf-frame') as HTMLIFrameElement | null

      if (!iframe) {
        return
      }

      iframe.addEventListener(
        'load',
        () => {
          printWindow.focus()
          setTimeout(() => {
            iframe.contentWindow?.focus()
            iframe.contentWindow?.print()
          }, 350)
        },
        { once: true },
      )
    },
    { once: true },
  )
}

export async function openFacturaPdf(id: number, autoPrint = false): Promise<void> {
  const blob = await getFacturaPdfBlob(id)
  openBlobInWindow(blob, autoPrint)
}
