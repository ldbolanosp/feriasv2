<?php

namespace App\Services;

use App\Models\Factura;
use App\Models\Feria;
use App\Models\Parqueo;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Builder;

class ReporteService
{
    public function __construct(
        public ReportXlsxService $reportXlsxService,
    ) {}

    /**
     * @return array{path:string, filename:string}
     */
    public function generarFacturacion(User $user, ?int $feriaId, CarbonImmutable $fechaInicio, CarbonImmutable $fechaFin): array
    {
        $feriaIds = $this->resolveFeriaIds($user, $feriaId);

        $facturas = Factura::query()
            ->with(['participante', 'usuario', 'detalles.producto'])
            ->whereIn('feria_id', $feriaIds)
            ->where('estado', 'facturado')
            ->whereBetween('fecha_emision', [$fechaInicio->startOfDay(), $fechaFin->endOfDay()])
            ->when(
                $user->hasRole('facturador'),
                fn (Builder $query) => $query->where('user_id', $user->id)
            )
            ->orderBy('fecha_emision')
            ->orderBy('id')
            ->get();

        $rows = [];

        foreach ($facturas as $factura) {
            foreach ($factura->detalles as $detalle) {
                $rows[] = [
                    $factura->consecutivo,
                    $factura->fecha_emision?->format('Y-m-d') ?? '',
                    $factura->es_publico_general
                        ? ($factura->nombre_publico ?? 'Público general')
                        : ($factura->participante?->nombre ?? ''),
                    $factura->participante?->numero_identificacion ?? '',
                    $factura->participante?->correo_electronico ?: 'No aplica',
                    $factura->participante?->telefono ?? '',
                    $factura->usuario?->name ?? '',
                    $detalle->producto?->codigo ?? '',
                    $detalle->descripcion_producto,
                    $this->formatQuantity((float) $detalle->cantidad),
                    $this->formatMoney((float) $detalle->precio_unitario),
                    $this->formatMoney((float) $detalle->subtotal_linea),
                    $this->formatMoney((float) $factura->subtotal),
                ];
            }
        }

        $path = $this->reportXlsxService->create(
            'Facturacion',
            [
                'Consecutivo',
                'Fecha de Emisión',
                'Nombre del Participante',
                'Identificación del Participante',
                'Correo del Participante',
                'Teléfono del Participante',
                'Usuario que Facturó',
                'Código Producto Facturado',
                'Descripción Producto Facturado',
                'Cantidad',
                'Precio Unitario',
                'Total de la Línea',
                'Total de la Factura',
            ],
            $rows
        );

        return [
            'path' => $path,
            'filename' => sprintf(
                'reporte_facturacion_%s_%s.xlsx',
                $fechaInicio->format('Ymd'),
                $fechaFin->format('Ymd'),
            ),
        ];
    }

    /**
     * @return array{path:string, filename:string}
     */
    public function generarParqueos(User $user, ?int $feriaId, CarbonImmutable $fechaInicio, CarbonImmutable $fechaFin): array
    {
        $feriaIds = $this->resolveFeriaIds($user, $feriaId);

        $parqueos = Parqueo::query()
            ->with('usuario')
            ->whereIn('feria_id', $feriaIds)
            ->whereBetween('fecha_hora_ingreso', [$fechaInicio->startOfDay(), $fechaFin->endOfDay()])
            ->when(
                $user->hasRole('facturador'),
                fn (Builder $query) => $query->where('user_id', $user->id)
            )
            ->orderBy('fecha_hora_ingreso')
            ->orderBy('id')
            ->get();

        $rows = $parqueos->map(fn (Parqueo $parqueo): array => [
            $parqueo->placa,
            $parqueo->fecha_hora_ingreso?->format('Y-m-d') ?? '',
            $parqueo->fecha_hora_ingreso?->format('H:i:s') ?? '',
            $parqueo->fecha_hora_salida?->format('Y-m-d') ?? '',
            $parqueo->fecha_hora_salida?->format('H:i:s') ?? '',
            $parqueo->usuario?->name ?? '',
            $this->formatMoney((float) $parqueo->tarifa),
        ])->values()->all();

        $path = $this->reportXlsxService->create(
            'Parqueos',
            [
                'Placa',
                'Fecha ingreso',
                'Hora ingreso',
                'Fecha salida',
                'Hora salida',
                'Usuario que registró',
                'Tarifa cobrada',
            ],
            $rows
        );

        return [
            'path' => $path,
            'filename' => sprintf(
                'reporte_parqueo_%s_%s.xlsx',
                $fechaInicio->format('Ymd'),
                $fechaFin->format('Ymd'),
            ),
        ];
    }

    private function formatMoney(float $value): string
    {
        return number_format($value, 2, '.', ',');
    }

    private function formatQuantity(float $value): string
    {
        if (fmod($value, 1.0) === 0.0) {
            return (string) (int) $value;
        }

        return rtrim(rtrim(number_format($value, 1, '.', ''), '0'), '.');
    }

    /**
     * @return list<int>
     */
    private function resolveFeriaIds(User $user, ?int $feriaId): array
    {
        if ($user->hasRole('administrador')) {
            if ($feriaId !== null) {
                return [$feriaId];
            }

            return Feria::query()
                ->orderBy('id')
                ->pluck('id')
                ->all();
        }

        $allowedFeriaIds = $user->ferias()
            ->orderBy('ferias.id')
            ->pluck('ferias.id')
            ->all();

        if ($feriaId !== null) {
            if (! in_array($feriaId, $allowedFeriaIds, true)) {
                throw new AuthorizationException('No tienes acceso a la feria seleccionada.');
            }

            return [$feriaId];
        }

        return $allowedFeriaIds;
    }
}
