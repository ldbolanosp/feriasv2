export interface ICreateAppReleasePayload {
  platform: 'android'
  channel: string
  version_name: string
  version_code: number
  min_supported_version_code?: number
  release_notes?: string
  is_mandatory: boolean
  apk_file: File
}

export interface IAppRelease {
  id: number
  platform: string
  channel: string
  version_name: string
  version_code: number
  min_supported_version_code: number | null
  storage_disk: string
  storage_path: string
  file_name: string
  file_size_bytes: number | null
  checksum_sha256: string | null
  release_notes: string | null
  is_mandatory: boolean
  is_active: boolean
  published_at: string | null
  created_at: string | null
  updated_at: string | null
}

export interface IAppReleaseListResponse {
  data: IAppRelease[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
}

export interface IAppReleaseResponse {
  message: string
  data: {
    id: number
    version_name: string
    version_code: number
    channel: string
    file_name: string
  }
}
