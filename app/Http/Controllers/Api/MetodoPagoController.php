<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\MetodoPago\StoreMetodoPagoRequest;
use App\Http\Requests\MetodoPago\UpdateMetodoPagoRequest;
use App\Http\Resources\MetodoPagoResource;
use App\Models\MetodoPago;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class MetodoPagoController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = MetodoPago::query();

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where('nombre', 'ilike', "%{$search}%");
        }

        if ($request->filled('activo')) {
            $query->where('activo', filter_var($request->activo, FILTER_VALIDATE_BOOLEAN));
        }

        $query
            ->orderByDesc('activo')
            ->orderBy('nombre');

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return MetodoPagoResource::collection($query->paginate($perPage));
    }

    public function catalogoFacturacion(): JsonResponse
    {
        $metodosPago = MetodoPago::query()
            ->orderByDesc('activo')
            ->orderByRaw("CASE WHEN nombre = 'Efectivo' THEN 0 ELSE 1 END")
            ->orderBy('nombre')
            ->get();

        return response()->json([
            'data' => MetodoPagoResource::collection($metodosPago),
        ]);
    }

    public function store(StoreMetodoPagoRequest $request): MetodoPagoResource
    {
        $metodoPago = MetodoPago::query()->create([
            'nombre' => trim((string) $request->validated('nombre')),
            'activo' => true,
        ]);

        return new MetodoPagoResource($metodoPago);
    }

    public function update(UpdateMetodoPagoRequest $request, MetodoPago $metodoPago): MetodoPagoResource
    {
        $metodoPago->update([
            'nombre' => trim((string) $request->validated('nombre')),
        ]);

        return new MetodoPagoResource($metodoPago);
    }

    public function toggle(MetodoPago $metodoPago): JsonResponse
    {
        $metodoPago->update([
            'activo' => ! $metodoPago->activo,
        ]);

        return response()->json([
            'message' => $metodoPago->activo
                ? 'Método de pago activado correctamente.'
                : 'Método de pago inactivado correctamente.',
            'data' => new MetodoPagoResource($metodoPago),
        ]);
    }
}
