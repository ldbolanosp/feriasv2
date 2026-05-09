import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { getRoles, updateRolePermissions } from '@/services/roleService'

const ROLES_KEY = 'roles'

export function useRoles() {
  return useQuery({
    queryKey: [ROLES_KEY],
    queryFn: getRoles,
  })
}

export function useUpdateRolePermissions() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ role, permissions }: { role: string; permissions: string[] }) =>
      updateRolePermissions(role, { permissions }),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [ROLES_KEY] })
      toast.success(`Permisos del rol ${variables.role} actualizados.`)
    },
    onError: () => {
      toast.error('No se pudieron actualizar los permisos del rol.')
    },
  })
}
