<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Producto\AsignarPreciosRequest;
use App\Http\Requests\Producto\StoreProductoRequest;
use App\Http\Requests\Producto\UpdateProductoRequest;
use App\Http\Resources\ProductoResource;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProductoController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Producto::query()
            ->with(['precios.feria'])
            ->withCount('precios');

        if ($request->filled('search')) {
            $search = $request->string('search');

            $query->where(function ($innerQuery) use ($search): void {
                $innerQuery->where('codigo', 'ilike', "%{$search}%")
                    ->orWhere('descripcion', 'ilike', "%{$search}%");
            });
        }

        if ($request->filled('activo')) {
            $query->where('activo', filter_var($request->activo, FILTER_VALIDATE_BOOLEAN));
        }

        $allowedSortFields = ['id', 'codigo', 'descripcion', 'activo', 'created_at', 'updated_at', 'precios_count'];
        $sortField = in_array($request->sort, $allowedSortFields) ? $request->sort : 'codigo';
        $direction = $request->direction === 'desc' ? 'desc' : 'asc';

        $query->orderBy($sortField, $direction);

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return ProductoResource::collection($query->paginate($perPage));
    }

    public function store(StoreProductoRequest $request): ProductoResource
    {
        $validated = $request->validated();
        $precios = $validated['precios'] ?? [];
        unset($validated['precios']);

        $producto = Producto::create($validated);

        if ($precios !== []) {
            $this->upsertPrecios($producto, $precios);
        }

        return new ProductoResource($producto->load(['precios.feria'])->loadCount('precios'));
    }

    public function show(Producto $producto): ProductoResource
    {
        return new ProductoResource($producto->load(['precios.feria'])->loadCount('precios'));
    }

    public function update(UpdateProductoRequest $request, Producto $producto): ProductoResource
    {
        $validated = $request->validated();
        $precios = $validated['precios'] ?? [];
        unset($validated['precios']);

        $producto->update($validated);

        if ($precios !== []) {
            $this->upsertPrecios($producto, $precios);
        }

        return new ProductoResource($producto->load(['precios.feria'])->loadCount('precios'));
    }

    public function toggle(Producto $producto): JsonResponse
    {
        $producto->update(['activo' => ! $producto->activo]);

        return response()->json([
            'message' => $producto->activo ? 'Producto activado correctamente.' : 'Producto desactivado correctamente.',
            'data' => new ProductoResource($producto->load(['precios.feria'])->loadCount('precios')),
        ]);
    }

    public function asignarPrecios(AsignarPreciosRequest $request, Producto $producto): JsonResponse
    {
        $this->upsertPrecios($producto, $request->validated('precios'));

        return response()->json([
            'message' => 'Precios asignados correctamente.',
            'data' => new ProductoResource($producto->load(['precios.feria'])->loadCount('precios')),
        ]);
    }

    public function eliminarPrecio(Producto $producto, int $feriaId): JsonResponse
    {
        $precio = $producto->precios()->where('feria_id', $feriaId)->firstOrFail();
        $precio->delete();

        return response()->json([
            'message' => 'Precio eliminado correctamente.',
            'data' => new ProductoResource($producto->load(['precios.feria'])->loadCount('precios')),
        ]);
    }

    public function porFeria(Request $request): AnonymousResourceCollection
    {
        $feriaId = (int) $request->header('X-Feria-Id');

        $productos = Producto::query()
            ->where('activo', true)
            ->with([
                'precios' => fn ($query) => $query->where('feria_id', $feriaId)->with('feria'),
            ])
            ->withCount('precios')
            ->whereHas('precios', fn ($query) => $query->where('feria_id', $feriaId))
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search');

                $query->where(function ($innerQuery) use ($search): void {
                    $innerQuery->where('codigo', 'ilike', "%{$search}%")
                        ->orWhere('descripcion', 'ilike', "%{$search}%");
                });
            })
            ->addSelect([
                'precio_feria_actual' => ProductoPrecio::query()
                    ->select('precio')
                    ->whereColumn('producto_id', 'productos.id')
                    ->where('feria_id', $feriaId)
                    ->limit(1),
            ])
            ->orderBy('descripcion')
            ->get();

        return ProductoResource::collection($productos);
    }

    /**
     * @param  array<int, array{feria_id:int, precio:numeric-string|int|float}>  $precios
     */
    private function upsertPrecios(Producto $producto, array $precios): void
    {
        $timestamp = now();

        $rows = collect($precios)
            ->map(fn (array $precio): array => [
                'producto_id' => $producto->id,
                'feria_id' => (int) $precio['feria_id'],
                'precio' => $precio['precio'],
                'created_at' => $timestamp,
                'updated_at' => $timestamp,
            ])
            ->all();

        ProductoPrecio::query()->upsert(
            $rows,
            ['producto_id', 'feria_id'],
            ['precio', 'updated_at']
        );
    }
}
