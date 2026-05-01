import { ArrowLeft, type LucideIcon } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'

interface PageHeaderAction {
  label: string
  icon?: LucideIcon
  onClick: () => void
}

interface PageHeaderProps {
  title: string
  description?: string
  action?: PageHeaderAction
  backUrl?: string
}

export function PageHeader({ title, description, action, backUrl }: PageHeaderProps) {
  const navigate = useNavigate()

  return (
    <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div className="flex min-w-0 items-start gap-3">
        {backUrl && (
          <Button
            variant="ghost"
            size="icon"
            className="mt-0.5 shrink-0"
            onClick={() => navigate(backUrl)}
          >
            <ArrowLeft className="size-4" />
          </Button>
        )}
        <div className="min-w-0">
          <h1 className="text-xl font-bold tracking-tight text-balance sm:text-2xl">{title}</h1>
          {description && (
            <p className="mt-1 max-w-2xl text-sm leading-6 text-muted-foreground">
              {description}
            </p>
          )}
        </div>
      </div>
      {action && (
        <Button onClick={action.onClick} className="w-full shrink-0 sm:w-auto">
          {action.icon && <action.icon className="size-4" />}
          {action.label}
        </Button>
      )}
    </div>
  )
}
