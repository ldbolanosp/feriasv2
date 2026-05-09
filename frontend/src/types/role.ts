export interface IPermissionCatalogItem {
  name: string
  module: string
  action: string
}

export interface IRolPermisos {
  name: string
  editable: boolean
  permissions: string[]
  permissions_count: number
}

export interface IRolListResponse {
  data: IRolPermisos[]
  meta: {
    permissions: IPermissionCatalogItem[]
  }
}

export interface IUpdateRolPermissionsPayload {
  permissions: string[]
}
