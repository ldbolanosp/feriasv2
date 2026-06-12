<?php

namespace App\Services;

use App\Models\Factura;
use App\Models\Feria;
use App\Models\Parqueo;
use App\Models\Participante;
use App\Models\User;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Builder;

class ReporteService
{
    private const STORAGE_TIMEZONE = 'UTC';

    private const BUSINESS_TIMEZONE = 'America/Costa_Rica';

    public function __construct(
        public ReportXlsxService $reportXlsxService,
    ) {}

    /**
     * @return array{path:string, filename:string}
     */
    public function generarFacturacion(User $user, ?int $feriaId, CarbonImmutable $fechaInicio, CarbonImmutable $fechaFin): array
    {
        $feriaIds = $this->resolveFeriaIds($user, $feriaId);
        [$fechaInicioUtc, $fechaFinUtc] = $this->resolveUtcRange($fechaInicio, $fechaFin);

        $facturas = Factura::query()
            ->with(['participante', 'usuario', 'metodoPago', 'detalles.producto'])
            ->whereIn('feria_id', $feriaIds)
            ->where('estado', 'facturado')
            ->whereBetween('fecha_emision', [$fechaInicioUtc, $fechaFinUtc])
            ->when(
                $user->hasRole('facturador'),
                fn (Builder $query) => $query->where('user_id', $user->id)
            )
            ->orderBy('fecha_emision')
            ->orderBy('id')
            ->get();

        $rows = [];

        foreach ($facturas as $factura) {
            $fechaEmisionLocal = $this->toBusinessTimezone($factura->fecha_emision);

            foreach ($factura->detalles as $detalle) {
                $rows[] = [
                    $factura->consecutivo,
                    $fechaEmisionLocal?->format('Y-m-d') ?? '',
                    $factura->es_publico_general
                        ? ($factura->nombre_publico ?? 'Público general')
                        : ($factura->participante?->nombre ?? ''),
                    $factura->participante?->numero_identificacion ?? '',
                    $factura->participante?->correo_electronico ?: 'No aplica',
                    $factura->participante?->telefono ?? '',
                    $factura->usuario?->name ?? '',
                    $factura->metodoPago?->nombre ?? '',
                    $detalle->producto?->codigo ?? '',
                    $detalle->descripcion_producto,
                    $this->numberCell((float) $detalle->cantidad, 'quantity'),
                    $this->numberCell((float) $detalle->precio_unitario, 'money'),
                    $this->numberCell((float) $detalle->subtotal_linea, 'money'),
                    $this->numberCell((float) $factura->subtotal, 'money'),
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
                'Método de Pago',
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
        [$fechaInicioUtc, $fechaFinUtc] = $this->resolveUtcRange($fechaInicio, $fechaFin);

        $parqueos = Parqueo::query()
            ->with('usuario')
            ->whereIn('feria_id', $feriaIds)
            ->whereBetween('fecha_hora_ingreso', [$fechaInicioUtc, $fechaFinUtc])
            ->when(
                $user->hasRole('facturador'),
                fn (Builder $query) => $query->where('user_id', $user->id)
            )
            ->orderBy('fecha_hora_ingreso')
            ->orderBy('id')
            ->get();

        $rows = $parqueos->map(function (Parqueo $parqueo): array {
            $fechaIngresoLocal = $this->toBusinessTimezone($parqueo->fecha_hora_ingreso);
            $fechaSalidaLocal = $this->toBusinessTimezone($parqueo->fecha_hora_salida);

            return [
                $parqueo->placa,
                $fechaIngresoLocal?->format('Y-m-d') ?? '',
                $fechaIngresoLocal?->format('H:i:s') ?? '',
                $fechaSalidaLocal?->format('Y-m-d') ?? '',
                $fechaSalidaLocal?->format('H:i:s') ?? '',
                $parqueo->usuario?->name ?? '',
                $this->numberCell((float) $parqueo->tarifa, 'money'),
            ];
        })->values()->all();

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

    /**
     * @return array{path:string, filename:string}
     */
    public function generarVencimientosCarne(User $user, ?int $feriaId): array
    {
        $feriaIds = $this->resolveFeriaIds($user, $feriaId);

        $participantes = Participante::query()
            ->with('carneActualizadoPor')
            ->where('activo', true)
            ->whereHas('ferias', fn (Builder $query) => $query->whereIn('ferias.id', $feriaIds))
            ->orderByRaw('CASE WHEN fecha_vencimiento_carne IS NULL THEN 1 ELSE 0 END')
            ->orderBy('fecha_vencimiento_carne')
            ->orderBy('nombre')
            ->get();

        $rows = $participantes->map(fn (Participante $participante): array => [
            $participante->numero_identificacion,
            $participante->nombre,
            $participante->fecha_emision_carne?->toDateString() ?? '',
            $participante->fecha_vencimiento_carne?->toDateString() ?? '',
            $participante->carneActualizadoPor?->name ?? 'No registrado',
        ])->values()->all();

        $path = $this->reportXlsxService->create(
            'Vencimiento Carne',
            [
                'Número de Identificación',
                'Nombre',
                'Fecha de Inicio',
                'Fecha de Vencimiento',
                'Último Usuario que Actualizó Carné',
            ],
            $rows
        );

        return [
            'path' => $path,
            'filename' => sprintf(
                'reporte_vencimiento_carne_%s.xlsx',
                now(self::BUSINESS_TIMEZONE)->format('Ymd'),
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
     * @return array{value: float, type: string, format: string}
     */
    private function numberCell(float $value, string $format): array
    {
        return [
            'value' => $value,
            'type' => 'number',
            'format' => $format,
        ];
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

    /**
     * @return array{0: CarbonImmutable, 1: CarbonImmutable}
     */
    private function resolveUtcRange(CarbonImmutable $fechaInicio, CarbonImmutable $fechaFin): array
    {
        $start = CarbonImmutable::createFromFormat(
            'Y-m-d H:i:s',
            $fechaInicio->format('Y-m-d').' 00:00:00',
            self::BUSINESS_TIMEZONE
        )->setTimezone(self::STORAGE_TIMEZONE);

        $end = CarbonImmutable::createFromFormat(
            'Y-m-d H:i:s',
            $fechaFin->format('Y-m-d').' 23:59:59',
            self::BUSINESS_TIMEZONE
        )->setTimezone(self::STORAGE_TIMEZONE);

        return [$start, $end];
    }

    private function toBusinessTimezone(?CarbonInterface $dateTime): ?CarbonInterface
    {
        return $dateTime?->setTimezone(self::BUSINESS_TIMEZONE);
    }
}
