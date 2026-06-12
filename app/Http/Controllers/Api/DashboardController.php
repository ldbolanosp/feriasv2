<?php

namespace App\Http\Controllers\Api;

use App\Enums\EstadoFactura;
use App\Http\Controllers\Controller;
use App\Http\Requests\Dashboard\GenerarCierreRequest;
use App\Models\Factura;
use App\Models\Feria;
use App\Models\Parqueo;
use App\Models\Sanitario;
use App\Models\Tarima;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    private const STORAGE_TIMEZONE = 'UTC';

    private const BUSINESS_TIMEZONE = 'America/Costa_Rica';

    public function resumen(Request $request): JsonResponse
    {
        $user = $request->user();

        $facturasBase = $this->facturasQuery($request);
        $facturasEmitidasBase = $this->facturasQuery($request)->where('estado', EstadoFactura::Facturado->value);
        $parqueosBase = $this->parqueosQuery($request);
        $tarimasBase = $this->tarimasQuery($request);
        $sanitariosBase = $this->sanitariosQuery($request);

        $facturasCount = (clone $facturasEmitidasBase)->count();
        $parqueosCount = (clone $parqueosBase)->where('estado', '!=', 'cancelado')->count();
        $tarimasCount = (clone $tarimasBase)->where('estado', 'facturado')->count();
        $sanitariosCount = (clone $sanitariosBase)->where('estado', 'facturado')->count();

        $recaudacionFacturas = (float) ((clone $facturasEmitidasBase)->sum('subtotal') ?? 0);
        $recaudacionParqueos = (float) ((clone $parqueosBase)->where('estado', '!=', 'cancelado')->sum('tarifa') ?? 0);
        $recaudacionTarimas = (float) ((clone $tarimasBase)->where('estado', 'facturado')->sum('total') ?? 0);
        $recaudacionSanitarios = (float) ((clone $sanitariosBase)->where('estado', 'facturado')->sum('total') ?? 0);

        $payload = [
            'rol' => $this->dashboardRole($user),
            'facturas_count' => $facturasCount,
            'parqueos_count' => $parqueosCount,
            'tarimas_count' => $tarimasCount,
            'sanitarios_count' => $sanitariosCount,
            'recaudacion_total' => round(
                $recaudacionFacturas + $recaudacionParqueos + $recaudacionTarimas + $recaudacionSanitarios,
                2
            ),
        ];

        if ($user->hasRole('facturador')) {
            $today = today();

            $payload['mis_facturas_hoy'] = (clone $facturasBase)
                ->whereDate('created_at', $today)
                ->count();
            $payload['mis_borradores'] = (clone $facturasBase)
                ->where('estado', EstadoFactura::Borrador->value)
                ->count();
        }

        return response()->json(['data' => $payload]);
    }

    public function facturacion(Request $request): JsonResponse
    {
        $user = $request->user();

        $facturasBase = $this->facturasQuery($request)
            ->with(['usuario', 'participante'])
            ->orderByDesc('created_at');

        $ultimasFacturas = (clone $facturasBase)
            ->limit(8)
            ->get()
            ->map(function (Factura $factura): array {
                return [
                    'id' => $factura->id,
                    'consecutivo' => $factura->consecutivo,
                    'cliente' => $factura->es_publico_general
                        ? ($factura->nombre_publico ?? 'Público general')
                        : ($factura->participante?->nombre ?? 'Sin participante'),
                    'estado' => $factura->estado->value,
                    'estado_label' => $factura->estado->label(),
                    'subtotal' => $factura->subtotal,
                    'usuario' => $factura->usuario?->name,
                    'fecha' => ($factura->fecha_emision ?? $factura->created_at)?->toIso8601String(),
                ];
            })
            ->all();

        $facturasEmitidas = $this->facturasQuery($request)
            ->where('estado', EstadoFactura::Facturado->value);

        $facturasPorProducto = DB::table('factura_detalles')
            ->join('facturas', 'facturas.id', '=', 'factura_detalles.factura_id')
            ->selectRaw('factura_detalles.descripcion_producto as nombre, SUM(factura_detalles.subtotal_linea) as total')
            ->where('facturas.feria_id', (int) $request->header('X-Feria-Id'))
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('facturas.user_id', $user->id))
            ->where('facturas.estado', EstadoFactura::Facturado->value);

        $facturasPorUsuario = DB::table('facturas')
            ->join('users', 'users.id', '=', 'facturas.user_id')
            ->selectRaw('users.name as nombre, COUNT(facturas.id) as total')
            ->where('facturas.feria_id', (int) $request->header('X-Feria-Id'))
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('facturas.user_id', $user->id))
            ->where('facturas.estado', EstadoFactura::Facturado->value);

        $this->applyDateRangeToQuery($facturasEmitidas, 'created_at', $request);
        $this->applyDateRangeToBaseQuery($facturasPorProducto, 'facturas.created_at', $request);
        $this->applyDateRangeToBaseQuery($facturasPorUsuario, 'facturas.created_at', $request);

        $productos = $facturasPorProducto
            ->groupBy('factura_detalles.descripcion_producto')
            ->orderByDesc('total')
            ->limit(8)
            ->get()
            ->map(fn ($row): array => [
                'nombre' => $row->nombre,
                'total' => round((float) $row->total, 2),
            ])
            ->all();

        $usuarios = $facturasPorUsuario
            ->groupBy('users.name')
            ->orderByDesc('total')
            ->limit(8)
            ->get()
            ->map(fn ($row): array => [
                'nombre' => $row->nombre,
                'total' => (int) $row->total,
            ])
            ->all();

        return response()->json([
            'data' => [
                'rol' => $this->dashboardRole($user),
                'ultimas_facturas' => $ultimasFacturas,
                'facturas_por_producto' => $productos,
                'facturas_por_usuario' => $usuarios,
                'resumen_por_facturador' => $user->hasRole('administrador')
                    ? $this->resumenPorFacturador($request)
                    : [],
            ],
        ]);
    }

    public function parqueos(Request $request): JsonResponse
    {
        $base = $this->parqueosQuery($request);

        return response()->json([
            'data' => [
                'activos' => (clone $base)->where('estado', 'activo')->count(),
                'finalizados' => (clone $base)->where('estado', 'finalizado')->count(),
                'cancelados' => (clone $base)->where('estado', 'cancelado')->count(),
            ],
        ]);
    }

    public function recaudacionDiaria(Request $request): JsonResponse
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');
        $from = $request->date('fecha_desde') ?? now()->subDays(6);
        $to = $request->date('fecha_hasta') ?? now();

        $period = collect();
        for ($date = $from->copy(); $date->lte($to); $date->addDay()) {
            $period->push([
                'fecha' => $date->format('Y-m-d'),
                'label' => $date->format('d/m'),
                'facturas' => 0.0,
                'parqueos' => 0.0,
                'tarimas' => 0.0,
                'sanitarios' => 0.0,
            ]);
        }

        $facturas = DB::table('facturas')
            ->selectRaw('DATE(created_at) as fecha, SUM(subtotal) as total')
            ->where('estado', EstadoFactura::Facturado->value)
            ->where('feria_id', $feriaId)
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween(DB::raw('DATE(created_at)'), [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->groupBy(DB::raw('DATE(created_at)'))
            ->pluck('total', 'fecha');

        $parqueos = DB::table('parqueos')
            ->selectRaw('DATE(created_at) as fecha, SUM(tarifa) as total')
            ->where('estado', '!=', 'cancelado')
            ->where('feria_id', $feriaId)
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween(DB::raw('DATE(created_at)'), [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->groupBy(DB::raw('DATE(created_at)'))
            ->pluck('total', 'fecha');

        $tarimas = DB::table('tarimas')
            ->selectRaw('DATE(created_at) as fecha, SUM(total) as total')
            ->where('estado', 'facturado')
            ->where('feria_id', $feriaId)
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween(DB::raw('DATE(created_at)'), [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->groupBy(DB::raw('DATE(created_at)'))
            ->pluck('total', 'fecha');

        $sanitarios = DB::table('sanitarios')
            ->selectRaw('DATE(created_at) as fecha, SUM(total) as total')
            ->where('estado', 'facturado')
            ->where('feria_id', $feriaId)
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween(DB::raw('DATE(created_at)'), [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->groupBy(DB::raw('DATE(created_at)'))
            ->pluck('total', 'fecha');

        $items = $period->map(function (array $item) use ($facturas, $parqueos, $tarimas, $sanitarios): array {
            $item['facturas'] = round((float) ($facturas[$item['fecha']] ?? 0), 2);
            $item['parqueos'] = round((float) ($parqueos[$item['fecha']] ?? 0), 2);
            $item['tarimas'] = round((float) ($tarimas[$item['fecha']] ?? 0), 2);
            $item['sanitarios'] = round((float) ($sanitarios[$item['fecha']] ?? 0), 2);
            $item['total'] = round($item['facturas'] + $item['parqueos'] + $item['tarimas'] + $item['sanitarios'], 2);

            return $item;
        })->all();

        return response()->json(['data' => $items]);
    }

    public function cierre(GenerarCierreRequest $request): JsonResponse
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');
        $fecha = CarbonImmutable::createFromFormat(
            'Y-m-d',
            $request->validated('fecha'),
            self::BUSINESS_TIMEZONE
        )->startOfDay();
        [$fechaInicioUtc, $fechaFinUtc] = $this->resolveUtcDayRange($fecha);
        $feria = Feria::query()->findOrFail($feriaId);

        $facturas = Factura::query()
            ->with('metodoPago')
            ->where('feria_id', $feriaId)
            ->where('user_id', $user->id)
            ->where('estado', EstadoFactura::Facturado->value)
            ->whereBetween('fecha_emision', [$fechaInicioUtc, $fechaFinUtc])
            ->get();

        $parqueosTotal = (float) Parqueo::query()
            ->where('feria_id', $feriaId)
            ->where('user_id', $user->id)
            ->where('estado', '!=', 'cancelado')
            ->whereBetween('fecha_hora_ingreso', [$fechaInicioUtc, $fechaFinUtc])
            ->sum('tarifa');

        $facturasTotal = (float) $facturas->sum('subtotal');
        $efectivoTotal = 0.0;
        $sinpeTotal = 0.0;
        $tarjetaTotal = 0.0;

        foreach ($facturas as $factura) {
            $metodoNombre = mb_strtolower($factura->metodoPago?->nombre ?? '');
            $monto = (float) $factura->subtotal;

            if (str_contains($metodoNombre, 'efectivo')) {
                $efectivoTotal += $monto;

                continue;
            }

            if (str_contains($metodoNombre, 'sinpe')) {
                $sinpeTotal += $monto;

                continue;
            }

            if (str_contains($metodoNombre, 'tarjeta')) {
                $tarjetaTotal += $monto;
            }
        }

        return response()->json([
            'data' => [
                'fecha' => $fecha->format('Y-m-d'),
                'hora_generacion' => now(self::STORAGE_TIMEZONE)
                    ->setTimezone(self::BUSINESS_TIMEZONE)
                    ->format('H:i'),
                'usuario' => [
                    'id' => $user->id,
                    'nombre' => $user->name,
                    'email' => $user->email,
                ],
                'feria' => [
                    'id' => $feria->id,
                    'codigo' => $feria->codigo,
                    'descripcion' => $feria->descripcion,
                ],
                'totales' => [
                    'facturas' => round($facturasTotal, 2),
                    'parqueos' => round($parqueosTotal, 2),
                    'general' => round($facturasTotal + $parqueosTotal, 2),
                ],
                'facturas_por_metodo_pago' => [
                    'efectivo' => round($efectivoTotal, 2),
                    'sinpe' => round($sinpeTotal, 2),
                    'tarjeta' => round($tarjetaTotal, 2),
                ],
            ],
        ]);
    }

    /**
     * @return array{0: CarbonImmutable, 1: CarbonImmutable}
     */
    private function resolveUtcDayRange(CarbonImmutable $fecha): array
    {
        $inicio = CarbonImmutable::createFromFormat(
            'Y-m-d H:i:s',
            $fecha->format('Y-m-d').' 00:00:00',
            self::BUSINESS_TIMEZONE
        )->setTimezone(self::STORAGE_TIMEZONE);

        $fin = CarbonImmutable::createFromFormat(
            'Y-m-d H:i:s',
            $fecha->format('Y-m-d').' 23:59:59',
            self::BUSINESS_TIMEZONE
        )->setTimezone(self::STORAGE_TIMEZONE);

        return [$inicio, $fin];
    }

    /**
     * @return list<array{
     *     usuario: array{id:int, nombre:string, email:string},
     *     facturas_count:int,
     *     parqueos_count:int,
     *     total_facturas:float,
     *     total_parqueos:float,
     *     total_general:float,
     *     facturas_por_metodo_pago: array{efectivo:float, sinpe:float, tarjeta:float}
     * }>
     */
    private function resumenPorFacturador(Request $request): array
    {
        $feriaId = (int) $request->header('X-Feria-Id');

        $facturas = DB::table('facturas')
            ->join('users', 'users.id', '=', 'facturas.user_id')
            ->leftJoin('metodo_pagos', 'metodo_pagos.id', '=', 'facturas.metodo_pago_id')
            ->selectRaw('
                users.id as user_id,
                users.name as user_name,
                users.email as user_email,
                COUNT(facturas.id) as facturas_count,
                SUM(facturas.subtotal) as total_facturas,
                SUM(CASE WHEN LOWER(COALESCE(metodo_pagos.nombre, \'\')) LIKE \'%efectivo%\' THEN facturas.subtotal ELSE 0 END) as total_efectivo,
                SUM(CASE WHEN LOWER(COALESCE(metodo_pagos.nombre, \'\')) LIKE \'%sinpe%\' THEN facturas.subtotal ELSE 0 END) as total_sinpe,
                SUM(CASE WHEN LOWER(COALESCE(metodo_pagos.nombre, \'\')) LIKE \'%tarjeta%\' THEN facturas.subtotal ELSE 0 END) as total_tarjeta
            ')
            ->where('facturas.feria_id', $feriaId)
            ->where('facturas.estado', EstadoFactura::Facturado->value);

        $this->applyBusinessDateRangeToBaseQuery($facturas, 'facturas.fecha_emision', $request);

        $facturasPorUsuario = $facturas
            ->groupBy('users.id', 'users.name', 'users.email')
            ->get()
            ->keyBy('user_id');

        $parqueos = DB::table('parqueos')
            ->join('users', 'users.id', '=', 'parqueos.user_id')
            ->selectRaw('
                users.id as user_id,
                users.name as user_name,
                users.email as user_email,
                COUNT(parqueos.id) as parqueos_count,
                SUM(parqueos.tarifa) as total_parqueos
            ')
            ->where('parqueos.feria_id', $feriaId)
            ->where('parqueos.estado', '!=', 'cancelado');

        $this->applyBusinessDateRangeToBaseQuery($parqueos, 'parqueos.fecha_hora_ingreso', $request);

        $parqueosPorUsuario = $parqueos
            ->groupBy('users.id', 'users.name', 'users.email')
            ->get()
            ->keyBy('user_id');

        return $facturasPorUsuario
            ->keys()
            ->merge($parqueosPorUsuario->keys())
            ->unique()
            ->map(function ($userId) use ($facturasPorUsuario, $parqueosPorUsuario): array {
                $facturas = $facturasPorUsuario->get($userId);
                $parqueos = $parqueosPorUsuario->get($userId);
                $userName = (string) ($facturas?->user_name ?? $parqueos?->user_name ?? '');
                $userEmail = (string) ($facturas?->user_email ?? $parqueos?->user_email ?? '');
                $totalFacturas = round((float) ($facturas?->total_facturas ?? 0), 2);
                $totalParqueos = round((float) ($parqueos?->total_parqueos ?? 0), 2);

                return [
                    'usuario' => [
                        'id' => (int) $userId,
                        'nombre' => $userName,
                        'email' => $userEmail,
                    ],
                    'facturas_count' => (int) ($facturas?->facturas_count ?? 0),
                    'parqueos_count' => (int) ($parqueos?->parqueos_count ?? 0),
                    'total_facturas' => $totalFacturas,
                    'total_parqueos' => $totalParqueos,
                    'total_general' => round($totalFacturas + $totalParqueos, 2),
                    'facturas_por_metodo_pago' => [
                        'efectivo' => round((float) ($facturas?->total_efectivo ?? 0), 2),
                        'sinpe' => round((float) ($facturas?->total_sinpe ?? 0), 2),
                        'tarjeta' => round((float) ($facturas?->total_tarjeta ?? 0), 2),
                    ],
                ];
            })
            ->sortByDesc('total_general')
            ->values()
            ->all();
    }

    private function facturasQuery(Request $request): Builder
    {
        $query = Factura::query();
        $user = $request->user();

        $query->where('feria_id', (int) $request->header('X-Feria-Id'));

        if ($user->hasRole('facturador')) {
            $query->where('user_id', $user->id);
        }

        $this->applyDateRangeToQuery($query, 'created_at', $request);

        return $query;
    }

    private function parqueosQuery(Request $request): Builder
    {
        $query = Parqueo::query();
        $user = $request->user();

        $query->where('feria_id', (int) $request->header('X-Feria-Id'));

        if ($user->hasRole('facturador')) {
            $query->where('user_id', $user->id);
        }

        $this->applyDateRangeToQuery($query, 'created_at', $request);

        return $query;
    }

    private function tarimasQuery(Request $request): Builder
    {
        $query = Tarima::query();
        $user = $request->user();

        $query->where('feria_id', (int) $request->header('X-Feria-Id'));

        if ($user->hasRole('facturador')) {
            $query->where('user_id', $user->id);
        }

        $this->applyDateRangeToQuery($query, 'created_at', $request);

        return $query;
    }

    private function sanitariosQuery(Request $request): Builder
    {
        $query = Sanitario::query();
        $user = $request->user();

        $query->where('feria_id', (int) $request->header('X-Feria-Id'));

        if ($user->hasRole('facturador')) {
            $query->where('user_id', $user->id);
        }

        $this->applyDateRangeToQuery($query, 'created_at', $request);

        return $query;
    }

    private function applyDateRangeToQuery(Builder $query, string $column, Request $request): void
    {
        if ($request->filled('fecha_desde')) {
            $query->whereDate($column, '>=', $request->date('fecha_desde'));
        }

        if ($request->filled('fecha_hasta')) {
            $query->whereDate($column, '<=', $request->date('fecha_hasta'));
        }
    }

    private function applyDateRangeToBaseQuery(\Illuminate\Database\Query\Builder $query, string $column, Request $request): void
    {
        if ($request->filled('fecha_desde')) {
            $query->whereDate($column, '>=', $request->date('fecha_desde'));
        }

        if ($request->filled('fecha_hasta')) {
            $query->whereDate($column, '<=', $request->date('fecha_hasta'));
        }
    }

    private function applyBusinessDateRangeToBaseQuery(\Illuminate\Database\Query\Builder $query, string $column, Request $request): void
    {
        if (! $request->filled('fecha_desde') && ! $request->filled('fecha_hasta')) {
            return;
        }

        $fechaDesde = $request->filled('fecha_desde')
            ? CarbonImmutable::parse($request->date('fecha_desde'), self::BUSINESS_TIMEZONE)
            : CarbonImmutable::create(1900, 1, 1, 0, 0, 0, self::BUSINESS_TIMEZONE);

        $fechaHasta = $request->filled('fecha_hasta')
            ? CarbonImmutable::parse($request->date('fecha_hasta'), self::BUSINESS_TIMEZONE)
            : CarbonImmutable::create(2999, 12, 31, 23, 59, 59, self::BUSINESS_TIMEZONE);

        $query->whereBetween($column, [
            $fechaDesde->startOfDay()->setTimezone(self::STORAGE_TIMEZONE),
            $fechaHasta->endOfDay()->setTimezone(self::STORAGE_TIMEZONE),
        ]);
    }

    private function dashboardRole(User $user): string
    {
        return match (true) {
            $user->hasRole('administrador') => 'administrador',
            $user->hasRole('supervisor') => 'supervisor',
            $user->hasRole('facturador') => 'facturador',
            default => 'inspector',
        };
    }
}
