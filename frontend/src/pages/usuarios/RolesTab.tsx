import { useMemo, useState } from 'react'
import { ChevronRight, Loader2, RotateCcw, Save, ShieldCheck } from 'lucide-react'
import { useRoles, useUpdateRolePermissions } from '@/hooks/useRoles'
import { cn } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { etiquetaRolUsuario } from '@/types/usuario'
import type { IPermissionCatalogItem, IRolPermisos } from '@/types/role'

const MODULE_LABELS: Record<string, string> = {
  dashboard: 'Dashboard',
  facturas: 'Facturación',
  parqueos: 'Parqueos',
  tarimas: 'Tarimas',
  sanitarios: 'Sanitarios',
  inspecciones: 'Inspecciones',
  configuracion: 'Configuración',
  ferias: 'Ferias',
  participantes: 'Participantes',
  productos: 'Productos',
  usuarios: 'Usuarios',
}

const MODULE_ORDER = [
  'dashboard',
  'facturas',
  'parqueos',
  'tarimas',
  'sanitarios',
  'inspecciones',
  'configuracion',
  'ferias',
  'participantes',
  'productos',
  'usuarios',
]

const ACTION_LABELS: Record<string, string> = {
  ver: 'Ver',
  crear: 'Crear',
  editar: 'Editar',
  activar: 'Activar',
  eliminar: 'Eliminar',
  sesiones: 'Gestionar sesiones',
  facturar: 'Facturar',
  salida: 'Registrar salida',
  cancelar: 'Cancelar',
  asignar_feria: 'Asignar feria',
}

interface PermissionGroup {
  module: string
  label: string
  permissions: IPermissionCatalogItem[]
}

function sortPermissionNames(permissions: string[]): string[] {
  return [...permissions].sort((left, right) => left.localeCompare(right))
}

function permissionActionLabel(permission: IPermissionCatalogItem): string {
  return ACTION_LABELS[permission.action] ?? permission.action.replaceAll('_', ' ')
}

function groupPermissions(catalog: IPermissionCatalogItem[]): PermissionGroup[] {
  const grouped = new Map<string, IPermissionCatalogItem[]>()

  for (const permission of catalog) {
    const current = grouped.get(permission.module) ?? []
    current.push(permission)
    grouped.set(permission.module, current)
  }

  return Array.from(grouped.entries())
    .sort(([leftModule], [rightModule]) => {
      const leftIndex = MODULE_ORDER.indexOf(leftModule)
      const rightIndex = MODULE_ORDER.indexOf(rightModule)

      if (leftIndex === -1 && rightIndex === -1) {
        return leftModule.localeCompare(rightModule)
      }

      if (leftIndex === -1) {
        return 1
      }

      if (rightIndex === -1) {
        return -1
      }

      return leftIndex - rightIndex
    })
    .map(([module, permissions]) => ({
      module,
      label: MODULE_LABELS[module] ?? module,
      permissions: permissions.sort((left, right) => left.name.localeCompare(right.name)),
    }))
}

function rolePermissions(role: IRolPermisos, drafts: Record<string, string[]>): string[] {
  return drafts[role.name] ?? role.permissions
}

function roleSummary(role: IRolPermisos, groups: PermissionGroup[]): string {
  const activeModules = groups.filter((group) =>
    group.permissions.some((permission) => role.permissions.includes(permission.name)),
  )

  if (activeModules.length === 0) {
    return 'Sin permisos asignados'
  }

  return activeModules
    .slice(0, 3)
    .map((group) => group.label)
    .join(' · ')
}

export function RolesTab() {
  const { data, isLoading, isFetching } = useRoles()
  const updateRolePermissionsMutation = useUpdateRolePermissions()

  const [draftPermissions, setDraftPermissions] = useState<Record<string, string[]>>({})
  const [savingRole, setSavingRole] = useState<string | null>(null)
  const [selectedRoleName, setSelectedRoleName] = useState<string | null>(null)

  const roles = data?.data ?? []
  const permissionGroups = useMemo(
    () => groupPermissions(data?.meta.permissions ?? []),
    [data?.meta.permissions],
  )

  const selectedRole = roles.find((role) => role.name === selectedRoleName) ?? null

  const handleTogglePermission = (roleName: string, permissionName: string, checked: boolean) => {
    setDraftPermissions((current) => {
      const existing = new Set(
        current[roleName] ?? roles.find((role) => role.name === roleName)?.permissions ?? [],
      )

      if (checked) {
        existing.add(permissionName)
      } else {
        existing.delete(permissionName)
      }

      return {
        ...current,
        [roleName]: sortPermissionNames(Array.from(existing)),
      }
    })
  }

  const handleReset = (roleName: string) => {
    setDraftPermissions((current) => {
      const next = { ...current }
      delete next[roleName]
      return next
    })
  }

  const handleSave = async (role: IRolPermisos) => {
    const permissions = rolePermissions(role, draftPermissions)

    setSavingRole(role.name)

    try {
      await updateRolePermissionsMutation.mutateAsync({
        role: role.name,
        permissions,
      })

      handleReset(role.name)
      setSelectedRoleName(null)
    } finally {
      setSavingRole(null)
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center rounded-xl border bg-card py-16">
        <Loader2 className="size-6 animate-spin text-muted-foreground" />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <Badge variant="secondary" className="rounded-full px-3 py-1">
          {roles.length} roles configurados
        </Badge>
        {isFetching && (
          <span className="text-sm text-muted-foreground">Actualizando roles…</span>
        )}
      </div>

      <p className="text-sm text-muted-foreground">
        Seleccione un rol para revisar o ajustar sus permisos. Los cambios se aplican de inmediato
        en el backend.
      </p>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {roles.map((role) => (
          <button
            key={role.name}
            type="button"
            onClick={() => setSelectedRoleName(role.name)}
            className="text-left"
          >
            <Card className="h-full border-border/70 transition-all hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-md">
              <CardHeader className="gap-3">
                <div className="flex items-start justify-between gap-3">
                  <div className="space-y-1">
                    <CardTitle className="flex items-center gap-2 text-base">
                      <ShieldCheck className="size-4 text-primary" />
                      {etiquetaRolUsuario(role.name)}
                    </CardTitle>
                    <CardDescription>
                      {role.editable
                        ? 'Permisos personalizados por rol'
                        : 'Acceso total permanente'}
                    </CardDescription>
                  </div>
                  <ChevronRight className="mt-0.5 size-4 text-muted-foreground" />
                </div>
              </CardHeader>

              <CardContent className="space-y-3">
                <div className="flex flex-wrap gap-2">
                  <Badge variant={role.editable ? 'outline' : 'default'}>
                    {role.permissions_count} permisos
                  </Badge>
                  {!role.editable && <Badge variant="secondary">Solo lectura</Badge>}
                </div>

                <p className="text-sm text-muted-foreground">{roleSummary(role, permissionGroups)}</p>
              </CardContent>
            </Card>
          </button>
        ))}
      </div>

      <Dialog open={selectedRole !== null} onOpenChange={(open) => !open && setSelectedRoleName(null)}>
        {selectedRole && (
          <DialogContent className="max-h-[90vh] sm:max-w-4xl">
            <DialogHeader>
              <DialogTitle>{etiquetaRolUsuario(selectedRole.name)}</DialogTitle>
              <DialogDescription>
                {selectedRole.editable
                  ? 'Active o desactive permisos para este rol desde una vista más enfocada.'
                  : 'Este rol siempre conserva acceso total a todos los permisos del sistema.'}
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-5 overflow-y-auto pr-1">
              <div className="flex flex-wrap items-center gap-2">
                <Badge variant={selectedRole.editable ? 'outline' : 'default'}>
                  {selectedRole.permissions_count} permisos
                </Badge>
                {!selectedRole.editable && <Badge variant="secondary">Solo lectura</Badge>}
              </div>

              {permissionGroups.map((group) => {
                const selectedPermissions = rolePermissions(selectedRole, draftPermissions)
                const selectedInGroup = group.permissions.filter((permission) =>
                  selectedPermissions.includes(permission.name),
                ).length
                const isSaving = savingRole === selectedRole.name

                return (
                  <section key={group.module} className="space-y-3 rounded-xl border p-4">
                    <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                      <div>
                        <h3 className="font-medium">{group.label}</h3>
                        <p className="text-sm text-muted-foreground">
                          {selectedInGroup} de {group.permissions.length} permisos activos
                        </p>
                      </div>
                    </div>

                    <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
                      {group.permissions.map((permission) => {
                        const checked = selectedPermissions.includes(permission.name)

                        return (
                          <label
                            key={permission.name}
                            className={cn(
                              'flex items-start gap-3 rounded-xl border p-3 transition-colors',
                              checked && 'border-primary/40 bg-primary/5',
                              selectedRole.editable && 'cursor-pointer hover:bg-muted/30',
                              !selectedRole.editable && 'opacity-80',
                            )}
                          >
                            <input
                              type="checkbox"
                              className="mt-0.5 size-4 rounded border-input text-primary focus:ring-2 focus:ring-primary/30"
                              checked={checked}
                              disabled={!selectedRole.editable || isSaving}
                              onChange={(event) =>
                                handleTogglePermission(
                                  selectedRole.name,
                                  permission.name,
                                  event.target.checked,
                                )
                              }
                            />
                            <div className="min-w-0">
                              <p className="text-sm font-medium">{permissionActionLabel(permission)}</p>
                            </div>
                          </label>
                        )
                      })}
                    </div>
                  </section>
                )
              })}
            </div>

            <DialogFooter className="border-t pt-4">
              {selectedRole.editable && (
                <>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => handleReset(selectedRole.name)}
                    disabled={
                      JSON.stringify(sortPermissionNames(rolePermissions(selectedRole, draftPermissions))) ===
                        JSON.stringify(sortPermissionNames(selectedRole.permissions)) ||
                      savingRole === selectedRole.name
                    }
                  >
                    <RotateCcw className="size-4" />
                    Revertir
                  </Button>
                  <Button
                    type="button"
                    onClick={() => void handleSave(selectedRole)}
                    disabled={
                      JSON.stringify(sortPermissionNames(rolePermissions(selectedRole, draftPermissions))) ===
                        JSON.stringify(sortPermissionNames(selectedRole.permissions)) ||
                      savingRole === selectedRole.name
                    }
                  >
                    {savingRole === selectedRole.name ? (
                      <Loader2 className="size-4 animate-spin" />
                    ) : (
                      <Save className="size-4" />
                    )}
                    Guardar permisos
                  </Button>
                </>
              )}
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>
    </div>
  )
}
