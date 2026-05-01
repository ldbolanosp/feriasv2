import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type { IFeria, IUser } from '@/types/auth'

interface AuthState {
  user: IUser | null
  roles: string[]
  permisos: string[]
  ferias: IFeria[]
  isAuthenticated: boolean
  isLoading: boolean
}

interface AuthActions {
  setUser: (user: IUser, roles: string[], permisos: string[], ferias: IFeria[]) => void
  clearAuth: () => void
  setLoading: (isLoading: boolean) => void
  hasPermission: (permiso: string) => boolean
}

const initialState: AuthState = {
  user: null,
  roles: [],
  permisos: [],
  ferias: [],
  isAuthenticated: false,
  isLoading: false,
}

export const useAuthStore = create<AuthState & AuthActions>()(
  persist(
    (set, get) => ({
      ...initialState,

      setUser: (user, roles, permisos, ferias) =>
        set({ user, roles, permisos, ferias, isAuthenticated: true }),

      clearAuth: () => set(initialState),

      setLoading: (isLoading) => set({ isLoading }),

      hasPermission: (permiso) => get().permisos.includes(permiso),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => sessionStorage),
    },
  ),
)
