import { zodResolver } from '@hookform/resolvers/zod'
import { isAxiosError } from 'axios'
import { useMemo, useState } from 'react'
import type { ColumnDef } from '@tanstack/react-table'
import { Ban, Loader2, UploadCloud } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { DataTable } from '@/components/shared/DataTable'
import { FormField } from '@/components/shared/FormField'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Switch } from '@/components/ui/switch'
import { Textarea } from '@/components/ui/textarea'
import { useAppReleases, useCreateAppRelease, useDeactivateAppRelease } from '@/hooks/useAppRelease'
import type { IAppRelease } from '@/types/appRelease'

const schema = z.object({
  version_name: z.string().min(1, 'La version es requerida').max(40, 'Maximo 40 caracteres'),
  version_code: z.string().min(1, 'El build number es requerido'),
  min_supported_version_code: z.string().optional(),
  channel: z.string().min(1, 'El canal es requerido').max(30, 'Maximo 30 caracteres'),
  release_notes: z.string().max(10000, 'Maximo 10000 caracteres').optional(),
  is_mandatory: z.boolean(),
  apk_file: z
    .custom<FileList>((value) => value instanceof FileList && value.length > 0, {
      message: 'Debe adjuntar un APK.',
    }),
})

type AppReleaseFormValues = z.infer<typeof schema>

export function AppReleaseCard() {
  const [page, setPage] = useState(1)
  const createMutation = useCreateAppRelease()
  const deactivateMutation = useDeactivateAppRelease()
  const { data, isLoading: isLoadingReleases, isFetching } = useAppReleases({
    page,
    per_page: 10,
    platform: 'android',
  })
  const [selectedRelease, setSelectedRelease] = useState<IAppRelease | null>(null)

  const {
    register,
    handleSubmit,
    setError,
    watch,
    setValue,
    reset,
    formState: { errors },
  } = useForm<AppReleaseFormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      version_name: '',
      version_code: '1',
      min_supported_version_code: '',
      channel: 'stable',
      release_notes: '',
      is_mandatory: false,
    },
  })

  const mandatory = watch('is_mandatory')
  const apkFile = watch('apk_file')
  const releases = data?.data ?? []
  const meta = data?.meta ?? { current_page: 1, last_page: 1, per_page: 10, total: 0 }

  const columns = useMemo<ColumnDef<IAppRelease>[]>(
    () => [
      {
        accessorKey: 'version_name',
        header: 'Version',
        cell: ({ row }) => (
          <div className="space-y-1">
            <p className="font-medium">
              {row.original.version_name} ({row.original.version_code})
            </p>
            <p className="text-xs text-muted-foreground">{row.original.file_name}</p>
          </div>
        ),
      },
      {
        accessorKey: 'channel',
        header: 'Canal',
        cell: ({ row }) => <span className="font-medium">{row.original.channel}</span>,
      },
      {
        accessorKey: 'is_active',
        header: 'Estado',
        cell: ({ row }) => (
          <StatusBadge status={row.original.is_active ? 'activo' : 'inactivo'} />
        ),
      },
      {
        accessorKey: 'is_mandatory',
        header: 'Tipo',
        cell: ({ row }) => (
          <span className="text-sm">
            {row.original.is_mandatory ? 'Obligatoria' : 'Opcional'}
          </span>
        ),
      },
      {
        id: 'acciones',
        header: '',
        cell: ({ row }) => (
          <div className="flex justify-end">
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={!row.original.is_active || deactivateMutation.isPending}
              onClick={() => setSelectedRelease(row.original)}
            >
              <Ban className="size-4" />
              Desactivar
            </Button>
          </div>
        ),
      },
    ],
    [deactivateMutation.isPending],
  )

  const onSubmit = async (values: AppReleaseFormValues) => {
    try {
      await createMutation.mutateAsync({
        platform: 'android',
        channel: values.channel.trim(),
        version_name: values.version_name.trim(),
        version_code: Number(values.version_code),
        min_supported_version_code: values.min_supported_version_code?.trim()
          ? Number(values.min_supported_version_code)
          : undefined,
        release_notes: values.release_notes?.trim() || undefined,
        is_mandatory: values.is_mandatory,
        apk_file: values.apk_file.item(0)!,
      })

      reset({
        version_name: '',
        version_code: String(Number(values.version_code) + 1),
        min_supported_version_code: '',
        channel: values.channel,
        release_notes: '',
        is_mandatory: false,
      })
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
          setError(field as keyof AppReleaseFormValues, { message })
        }
      }
    }
  }

  return (
    <Card className="max-w-3xl">
      <CardHeader>
        <CardTitle>Publicar APK Android</CardTitle>
        <CardDescription>
          Sube el APK final y se registrara como la release activa del canal seleccionado.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Version" error={errors.version_name?.message} required>
              <Input
                {...register('version_name')}
                placeholder="Ej. 1.1.0"
                disabled={createMutation.isPending}
              />
            </FormField>

            <FormField label="Build number" error={errors.version_code?.message} required>
              <Input
                type="number"
                {...register('version_code')}
                disabled={createMutation.isPending}
              />
            </FormField>

            <FormField label="Canal" error={errors.channel?.message} required>
              <Input
                {...register('channel')}
                placeholder="stable"
                disabled={createMutation.isPending}
              />
            </FormField>

            <FormField
              label="Build minimo soportado"
              error={errors.min_supported_version_code?.message}
            >
              <Input
                type="number"
                {...register('min_supported_version_code')}
                placeholder="Opcional"
                disabled={createMutation.isPending}
              />
            </FormField>
          </div>

          <FormField label="Notas de release" error={errors.release_notes?.message}>
            <Textarea
              {...register('release_notes')}
              rows={5}
              placeholder="Resumen de cambios, correcciones o ajustes del release..."
              disabled={createMutation.isPending}
            />
          </FormField>

          <div className="flex items-center justify-between rounded-lg border p-3">
            <div className="space-y-0.5">
              <p className="text-sm font-medium">Actualizacion obligatoria</p>
              <p className="text-xs text-muted-foreground">
                Si esta activa, la app mostrara la actualizacion como requerida.
              </p>
            </div>
            <Switch
              checked={mandatory}
              onCheckedChange={(checked) => setValue('is_mandatory', checked)}
              disabled={createMutation.isPending}
            />
          </div>

          <FormField label="Archivo APK" error={errors.apk_file?.message} required>
            <Input
              type="file"
              accept=".apk,application/vnd.android.package-archive"
              {...register('apk_file')}
              disabled={createMutation.isPending}
            />
            {apkFile?.item(0) && (
              <p className="text-xs text-muted-foreground">
                Archivo seleccionado: {apkFile.item(0)?.name}
              </p>
            )}
          </FormField>

          <div className="flex justify-end">
            <Button type="submit" disabled={createMutation.isPending}>
              {createMutation.isPending ? (
                <Loader2 className="size-4 animate-spin" />
              ) : (
                <UploadCloud className="size-4" />
              )}
              Publicar APK
            </Button>
          </div>
        </form>

        <div className="mt-8 space-y-4">
          <div>
            <h3 className="text-base font-semibold">Releases publicadas</h3>
            <p className="text-sm text-muted-foreground">
              Revisa las versiones recientes y desactiva una release si necesitas retirarla.
            </p>
          </div>

          <DataTable
            columns={columns}
            data={releases}
            isLoading={isLoadingReleases}
            isFetching={isFetching}
            pagination={{
              page: meta.current_page,
              pageSize: meta.per_page,
              total: meta.total,
            }}
            onPaginationChange={setPage}
          />
        </div>
      </CardContent>

      <ConfirmDialog
        open={selectedRelease !== null}
        onCancel={() => setSelectedRelease(null)}
        onConfirm={() => {
          if (!selectedRelease) {
            return
          }

          deactivateMutation.mutate(selectedRelease.id, {
            onSuccess: () => {
              setSelectedRelease(null)
            },
          })
        }}
        title="Desactivar release"
        description={
          selectedRelease
            ? `Se desactivara la release ${selectedRelease.version_name} (${selectedRelease.version_code}).`
            : ''
        }
        confirmText="Desactivar"
      />
    </Card>
  )
}
