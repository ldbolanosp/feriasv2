import api from './api'
import type {
  IAppRelease,
  IAppReleaseListResponse,
  IAppReleaseResponse,
  ICreateAppReleasePayload,
} from '@/types/appRelease'

export async function createAppRelease(
  payload: ICreateAppReleasePayload,
): Promise<IAppReleaseResponse['data']> {
  const formData = new FormData()
  formData.append('platform', payload.platform)
  formData.append('channel', payload.channel)
  formData.append('version_name', payload.version_name)
  formData.append('version_code', String(payload.version_code))
  if (payload.min_supported_version_code) {
    formData.append(
      'min_supported_version_code',
      String(payload.min_supported_version_code),
    )
  }
  if (payload.release_notes?.trim()) {
    formData.append('release_notes', payload.release_notes.trim())
  }
  formData.append('is_mandatory', payload.is_mandatory ? '1' : '0')
  formData.append('apk_file', payload.apk_file)

  const { data } = await api.post<IAppReleaseResponse>('/auth/app-releases', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  })

  return data.data
}

export async function getAppReleases(
  params: { page?: number; per_page?: number; platform?: string } = {},
): Promise<IAppReleaseListResponse> {
  const { data } = await api.get<IAppReleaseListResponse>('/auth/app-releases', {
    params,
  })

  return data
}

export async function deactivateAppRelease(id: number): Promise<IAppRelease> {
  const { data } = await api.patch<{ data: IAppRelease }>(
    `/auth/app-releases/${id}/deactivate`,
  )

  return data.data
}
