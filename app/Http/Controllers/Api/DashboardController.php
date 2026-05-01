<?php

namespace App\Http\Controllers\Api;

use App\Enums\EstadoFactura;
use App\Http\Controllers\Controller;
use App\Models\Factura;
use App\Models\Parqueo;
use App\Models\Sanitario;
use App\Models\Tarima;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
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
            ->selectRaw("DATE(created_at) as fecha, SUM(subtotal) as total")
            ->where('estado', EstadoFactura::Facturado->value)
            ->where('feria_id', $feriaId)
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween(DB::raw('DATE(created_at)'), [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->groupBy(DB::raw('DATE(created_at)'))
            ->pluck('total', 'fecha');

        $parqueos = DB::table('parqueos')
            ->selectRaw("DATE(created_at) as fecha, SUM(tarifa) as total")
            ->where('estado', '!=', 'cancelado')
            ->where('feria_id', $feriaId)
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween(DB::raw('DATE(created_at)'), [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->groupBy(DB::raw('DATE(created_at)'))
            ->pluck('total', 'fecha');

        $tarimas = DB::table('tarimas')
            ->selectRaw("DATE(created_at) as fecha, SUM(total) as total")
            ->where('estado', 'facturado')
            ->where('feria_id', $feriaId)
            ->when($user->hasRole('facturador'), fn ($query) => $query->where('user_id', $user->id))
            ->whereBetween(DB::raw('DATE(created_at)'), [$from->format('Y-m-d'), $to->format('Y-m-d')])
            ->groupBy(DB::raw('DATE(created_at)'))
            ->pluck('total', 'fecha');

        $sanitarios = DB::table('sanitarios')
            ->selectRaw("DATE(created_at) as fecha, SUM(total) as total")
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
