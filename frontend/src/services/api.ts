import axios from 'axios'
import { toast } from 'sonner'
import { useFeriaStore } from '@/stores/feriaStore'
import { useAuthStore } from '@/stores/authStore'

const api = axios.create({
  baseURL: '/api/v1',
  withCredentials: true,
  withXSRFToken: true,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

api.interceptors.request.use((config) => {
  const feriaActiva = useFeriaStore.getState().feriaActiva
  if (feriaActiva) {
    config.headers['X-Feria-Id'] = feriaActiva.id
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status

    if (status === 401) {
      useAuthStore.getState().clearAuth()
      useFeriaStore.getState().clearFeria()
      window.location.href = '/login'
      return Promise.reject(error)
    }

    if (status === 403) {
      toast.error(error.response?.data?.message ?? 'No tienes permiso para realizar esta acción.')
      return Promise.reject(error)
    }

    if (status === 422) {
      return Promise.reject(error)
    }

    if (status === 500) {
      toast.error('Ha ocurrido un error en el servidor. Intente de nuevo.')
      return Promise.reject(error)
    }

    return Promise.reject(error)
  },
)

export async function getCsrfCookie(): Promise<void> {
  await axios.get('/sanctum/csrf-cookie', { withCredentials: true, withXSRFToken: true })
}

export default api
