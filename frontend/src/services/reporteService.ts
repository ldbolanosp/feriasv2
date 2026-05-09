import api from './api'

export interface ReporteParams {
  fecha_inicio: string
  fecha_fin: string
  feria_id?: number
}

function extractFilename(contentDisposition: string | undefined, fallback: string): string {
  if (!contentDisposition) {
    return fallback
  }

  const utf8Match = contentDisposition.match(/filename\*=UTF-8''([^;]+)/i)

  if (utf8Match?.[1]) {
    return decodeURIComponent(utf8Match[1])
  }

  const filenameMatch = contentDisposition.match(/filename="([^"]+)"/i)

  if (filenameMatch?.[1]) {
    return filenameMatch[1]
  }

  return fallback
}

function triggerDownload(blob: Blob, filename: string): void {
  const url = window.URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  window.URL.revokeObjectURL(url)
}

async function downloadReporte(
  endpoint: string,
  params: ReporteParams,
  fallbackFilename: string,
): Promise<void> {
  const response = await api.get(endpoint, {
    params,
    responseType: 'blob',
    headers: {
      Accept: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    },
  })

  const filename = extractFilename(
    response.headers['content-disposition'] as string | undefined,
    fallbackFilename,
  )

  triggerDownload(response.data as Blob, filename)
}

export async function downloadReporteFacturacion(params: ReporteParams): Promise<void> {
  const feriaIdLabel = params.feria_id ? `_feria_${params.feria_id}` : ''
  const fallbackFilename = `reporte_facturacion_${params.fecha_inicio.replaceAll('-', '')}_${params.fecha_fin.replaceAll('-', '')}.xlsx`

  await downloadReporte(
    '/reportes/facturacion',
    params,
    fallbackFilename.replace('.xlsx', `${feriaIdLabel}.xlsx`),
  )
}

export async function downloadReporteParqueos(params: ReporteParams): Promise<void> {
  const feriaIdLabel = params.feria_id ? `_feria_${params.feria_id}` : ''
  const fallbackFilename = `reporte_parqueo_${params.fecha_inicio.replaceAll('-', '')}_${params.fecha_fin.replaceAll('-', '')}.xlsx`

  await downloadReporte(
    '/reportes/parqueos',
    params,
    fallbackFilename.replace('.xlsx', `${feriaIdLabel}.xlsx`),
  )
}
