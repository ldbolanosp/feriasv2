import { Navigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { useFeriaStore } from '@/stores/feriaStore'

interface ProtectedRouteProps {
  children: React.ReactNode
  permission?: string
}

export function ProtectedRoute({ children, permission }: ProtectedRouteProps) {
  const { isAuthenticated, hasPermission } = useAuthStore()
  const { feriaActiva } = useFeriaStore()
  const location = useLocation()

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />
  }

  if (!feriaActiva) {
    return <Navigate to="/seleccionar-feria" replace />
  }

  if (permission && !hasPermission(permission)) {
    return <Navigate to="/dashboard" replace />
  }

  return <>{children}</>
}
