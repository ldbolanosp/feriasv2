import { cn } from '@/lib/utils'

const statusColorMap: Record<string, string> = {
  activo: 'bg-green-100 text-green-700 border-green-200',
  borrador: 'bg-yellow-100 text-yellow-700 border-yellow-200',
  eliminado: 'bg-red-100 text-red-700 border-red-200',
  inactivo: 'bg-gray-100 text-gray-600 border-gray-200',
  finalizado: 'bg-blue-100 text-blue-700 border-blue-200',
  facturado: 'bg-blue-100 text-blue-700 border-blue-200',
  cancelado: 'bg-red-100 text-red-700 border-red-200',
}

const statusLabelMap: Record<string, string> = {
  activo: 'Activo',
  borrador: 'Borrador',
  eliminado: 'Eliminado',
  inactivo: 'Inactivo',
  finalizado: 'Finalizado',
  facturado: 'Facturado',
  cancelado: 'Cancelado',
}

interface StatusBadgeProps {
  status: string
  className?: string
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const colorClass = statusColorMap[status] ?? 'bg-gray-100 text-gray-600 border-gray-200'
  const label = statusLabelMap[status] ?? status

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium',
        colorClass,
        className,
      )}
    >
      {label}
    </span>
  )
}
