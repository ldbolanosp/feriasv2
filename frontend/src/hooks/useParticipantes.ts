import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { isAxiosError } from 'axios'
import { toast } from 'sonner'
import {
  asignarFeriasParticipante,
  createParticipante,
  desasignarFeriaParticipante,
  getParticipante,
  getParticipantes,
  searchParticipantesPorFeria,
  toggleParticipante,
  updateParticipante,
  type ParticipanteListParams,
} from '@/services/participanteService'
import type { IParticipanteFormPayload } from '@/types/participante'

const PARTICIPANTES_KEY = 'participantes'

export function useParticipantes(params: ParticipanteListParams = {}) {
  return useQuery({
    queryKey: [PARTICIPANTES_KEY, params],
    queryFn: () => getParticipantes(params),
    placeholderData: keepPreviousData,
  })
}

export function useParticipante(id: number | undefined) {
  return useQuery({
    queryKey: [PARTICIPANTES_KEY, id],
    queryFn: () => getParticipante(id!),
    enabled: id !== undefined && !Number.isNaN(id),
  })
}

export function useParticipantesPorFeria(search: string) {
  return useQuery({
    queryKey: [PARTICIPANTES_KEY, 'por-feria', search],
    queryFn: () => searchParticipantesPorFeria(search),
  })
}

export function useCreateParticipante() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: IParticipanteFormPayload) => createParticipante(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY] })
      toast.success('Participante creado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }
      toast.error('No se pudo crear el participante.')
    },
  })
}

export function useUpdateParticipante() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: IParticipanteFormPayload }) =>
      updateParticipante(id, payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY] })
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY, variables.id] })
      toast.success('Participante actualizado correctamente.')
    },
    onError: (error) => {
      if (isAxiosError(error) && error.response?.status === 422) {
        return
      }
      toast.error('No se pudo actualizar el participante.')
    },
  })
}

export function useToggleParticipante() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: number) => toggleParticipante(id),
    onSuccess: (participante) => {
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY] })
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY, participante.id] })
      toast.success(participante.activo ? 'Participante activado.' : 'Participante desactivado.')
    },
    onError: () => {
      toast.error('No se pudo cambiar el estado del participante.')
    },
  })
}

export function useAsignarFeriasParticipante() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ participanteId, feriaIds }: { participanteId: number; feriaIds: number[] }) =>
      asignarFeriasParticipante(participanteId, feriaIds),
    onSuccess: (participante) => {
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY] })
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY, participante.id] })
      toast.success('Ferias asignadas correctamente.')
    },
    onError: () => {
      toast.error('No se pudieron asignar las ferias.')
    },
  })
}

export function useDesasignarFeriaParticipante() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      participanteId,
      feriaId,
    }: {
      participanteId: number
      feriaId: number
    }) => desasignarFeriaParticipante(participanteId, feriaId),
    onSuccess: (participante) => {
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY] })
      queryClient.invalidateQueries({ queryKey: [PARTICIPANTES_KEY, participante.id] })
      toast.success('Feria desasignada correctamente.')
    },
    onError: () => {
      toast.error('No se pudo desasignar la feria.')
    },
  })
}
