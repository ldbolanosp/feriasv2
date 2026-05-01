import { useNavigate } from 'react-router-dom'
import { MapPin } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { queryClient } from '@/main'
import { useAuthStore } from '@/stores/authStore'
import { useFeriaStore } from '@/stores/feriaStore'
import { seleccionarFeria } from '@/services/authService'
import { useState } from 'react'
import type { IFeria } from '@/types/auth'

export function SeleccionFeriaPage() {
  const navigate = useNavigate()
  const { ferias } = useAuthStore()
  const { setFeriaActiva } = useFeriaStore()
  const [selecting, setSelecting] = useState<number | null>(null)

  async function handleSelect(feria: IFeria) {
    setSelecting(feria.id)
    try {
      const selected = await seleccionarFeria(feria.id)
      setFeriaActiva(selected)
      queryClient.clear()
      navigate('/dashboard')
    } finally {
      setSelecting(null)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/40 p-4">
      <div className="w-full max-w-md space-y-4">
        <div className="text-center">
          <h1 className="text-2xl font-bold">Seleccionar feria</h1>
          <p className="text-sm text-muted-foreground">Elige la feria con la que deseas trabajar</p>
        </div>

        <div className="grid gap-3">
          {ferias.map((feria) => (
            <Card
              key={feria.id}
              className="cursor-pointer transition-colors hover:bg-accent"
              onClick={() => !selecting && handleSelect(feria)}
            >
              <CardHeader className="pb-2">
                <div className="flex items-center gap-3">
                  <div className="flex size-9 items-center justify-center rounded-full bg-primary/10">
                    <MapPin className="size-4 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">{feria.descripcion}</CardTitle>
                    <p className="text-xs text-muted-foreground">{feria.codigo}</p>
                  </div>
                </div>
              </CardHeader>
              {selecting === feria.id && (
                <CardContent className="pt-0">
                  <p className="text-xs text-muted-foreground">Seleccionando...</p>
                </CardContent>
              )}
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}
