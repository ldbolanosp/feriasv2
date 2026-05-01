import { useAuthStore } from '@/stores/authStore'

export function usePermission() {
  const hasPermission = useAuthStore((state) => state.hasPermission)
  return { hasPermission }
}
