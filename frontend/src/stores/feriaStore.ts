import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type { IFeria } from '@/types/auth'

interface FeriaState {
  feriaActiva: IFeria | null
  ferias: IFeria[]
}

interface FeriaActions {
  setFeriaActiva: (feria: IFeria) => void
  setFerias: (ferias: IFeria[]) => void
  clearFeria: () => void
}

export const useFeriaStore = create<FeriaState & FeriaActions>()(
  persist(
    (set) => ({
      feriaActiva: null,
      ferias: [],

      setFeriaActiva: (feria) => set({ feriaActiva: feria }),

      setFerias: (ferias) => set({ ferias }),

      clearFeria: () => set({ feriaActiva: null, ferias: [] }),
    }),
    {
      name: 'feria-storage',
      storage: createJSONStorage(() => sessionStorage),
    },
  ),
)
