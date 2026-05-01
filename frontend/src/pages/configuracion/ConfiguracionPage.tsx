import { useEffect } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { isAxiosError } from 'axios'
import { Loader2, Save } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { FormField } from '@/components/shared/FormField'
import { MoneyInput } from '@/components/shared/MoneyInput'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { useConfiguraciones, useUpdateConfiguraciones } from '@/hooks/useConfiguraciones'

const schema = z.object({
  tarifa_parqueo: z.number().gt(0, 'La tarifa de parqueo debe ser mayor a cero.'),
  precio_tarima: z.number().gt(0, 'El precio de tarima debe ser mayor a cero.'),
  precio_sanitario: z.number().gt(0, 'El precio de sanitario debe ser mayor a cero.'),
})

type ConfiguracionFormValues = z.infer<typeof schema>

function parseMoney(value: string | null | undefined): number {
  const parsed = Number(value ?? 0)
  return Number.isNaN(parsed) ? 0 : parsed
}

export function ConfiguracionPage() {
  const { data, isLoading } = useConfiguraciones()
  const updateMutation = useUpdateConfiguraciones()

  const {
    handleSubmit,
    reset,
    setValue,
    setError,
    watch,
    formState: { errors, isDirty },
  } = useForm<ConfiguracionFormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      tarifa_parqueo: 0,
      precio_tarima: 0,
      precio_sanitario: 0,
    },
  })

  useEffect(() => {
    if (!data) {
      return
    }

    reset({
      tarifa_parqueo: parseMoney(data.configuraciones.tarifa_parqueo.valor),
      precio_tarima: parseMoney(data.configuraciones.precio_tarima.valor),
      precio_sanitario: parseMoney(data.configuraciones.precio_sanitario.valor),
    })
  }, [data, reset])

  const onSubmit = async (values: ConfiguracionFormValues) => {
    try {
      await updateMutation.mutateAsync(values)
    } catch (error) {
      if (!isAxiosError(error) || error.response?.status !== 422) {
        throw error
      }

      const apiErrors = error.response.data?.errors as Record<string, string[]> | undefined

      if (!apiErrors) {
        return
      }

      for (const [field, messages] of Object.entries(apiErrors)) {
        const message = messages[0]

        if (message) {
          setError(field as keyof ConfiguracionFormValues, { message })
        }
      }
    }
  }

  const configuraciones = data?.configuraciones

  return (
    <div className="space-y-6">
      <PageHeader
        title="Configuración"
        description={
          data
            ? `Parámetros de precios para la feria activa ${data.feria.codigo} · ${data.feria.descripcion}.`
            : 'Parámetros de precios de la feria activa.'
        }
      />

      <Card className="max-w-3xl">
        <CardHeader>
          <CardTitle>Parámetros editables</CardTitle>
          <CardDescription>
            Los valores guardados aquí aplican sobre la feria activa y reemplazan el fallback global.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Loader2 className="size-4 animate-spin" />
              Cargando configuraciones...
            </div>
          ) : (
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
              <div className="space-y-1.5">
                <FormField label="Tarifa de parqueo" error={errors.tarifa_parqueo?.message} required>
                  <MoneyInput
                    value={watch('tarifa_parqueo')}
                    onChange={(value) =>
                      setValue('tarifa_parqueo', value ?? 0, { shouldValidate: true, shouldDirty: true })
                    }
                    disabled={updateMutation.isPending}
                  />
                </FormField>
                {configuraciones && (
                  <p className="text-xs text-muted-foreground">
                    Origen actual: {configuraciones.tarifa_parqueo.scope === 'feria' ? 'feria activa' : 'global'}
                  </p>
                )}
              </div>

              <div className="space-y-1.5">
                <FormField label="Precio de tarima" error={errors.precio_tarima?.message} required>
                  <MoneyInput
                    value={watch('precio_tarima')}
                    onChange={(value) =>
                      setValue('precio_tarima', value ?? 0, { shouldValidate: true, shouldDirty: true })
                    }
                    disabled={updateMutation.isPending}
                  />
                </FormField>
                {configuraciones && (
                  <p className="text-xs text-muted-foreground">
                    Origen actual: {configuraciones.precio_tarima.scope === 'feria' ? 'feria activa' : 'global'}
                  </p>
                )}
              </div>

              <div className="space-y-1.5">
                <FormField label="Precio de sanitario" error={errors.precio_sanitario?.message} required>
                  <MoneyInput
                    value={watch('precio_sanitario')}
                    onChange={(value) =>
                      setValue('precio_sanitario', value ?? 0, { shouldValidate: true, shouldDirty: true })
                    }
                    disabled={updateMutation.isPending}
                  />
                </FormField>
                {configuraciones && (
                  <p className="text-xs text-muted-foreground">
                    Origen actual: {configuraciones.precio_sanitario.scope === 'feria' ? 'feria activa' : 'global'}
                  </p>
                )}
              </div>

              <div className="flex justify-end">
                <Button type="submit" disabled={updateMutation.isPending || !isDirty}>
                  {updateMutation.isPending ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    <Save className="size-4" />
                  )}
                  Guardar configuración
                </Button>
              </div>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
