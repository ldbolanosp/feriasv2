import { Component, type ErrorInfo, type ReactNode } from 'react'
import { AlertTriangle } from 'lucide-react'
import { Button } from '@/components/ui/button'

interface AppErrorBoundaryProps {
  children: ReactNode
}

interface AppErrorBoundaryState {
  hasError: boolean
}

export class AppErrorBoundary extends Component<
  AppErrorBoundaryProps,
  AppErrorBoundaryState
> {
  public state: AppErrorBoundaryState = {
    hasError: false,
  }

  public static getDerivedStateFromError(): AppErrorBoundaryState {
    return { hasError: true }
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('AppErrorBoundary', error, errorInfo)
  }

  public render(): ReactNode {
    if (!this.state.hasError) {
      return this.props.children
    }

    return (
      <div className="flex min-h-screen items-center justify-center bg-muted/30 p-6">
        <div className="w-full max-w-lg rounded-2xl border bg-background p-8 shadow-sm">
          <div className="mb-4 flex size-12 items-center justify-center rounded-full bg-destructive/10 text-destructive">
            <AlertTriangle className="size-6" />
          </div>
          <h1 className="text-2xl font-bold tracking-tight">Ocurrió un error inesperado</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            La aplicación encontró un problema no controlado. Puede recargar la página para reintentar.
          </p>
          <div className="mt-6 flex gap-3">
            <Button onClick={() => window.location.reload()}>Recargar</Button>
          </div>
        </div>
      </div>
    )
  }
}
