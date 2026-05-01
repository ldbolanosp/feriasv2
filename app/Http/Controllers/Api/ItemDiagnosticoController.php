<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ItemDiagnostico\StoreItemDiagnosticoRequest;
use App\Http\Requests\ItemDiagnostico\UpdateItemDiagnosticoRequest;
use App\Http\Resources\ItemDiagnosticoResource;
use App\Models\ItemDiagnostico;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ItemDiagnosticoController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = ItemDiagnostico::query();

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where('nombre', 'ilike', "%{$search}%");
        }

        $query->orderBy('nombre');

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return ItemDiagnosticoResource::collection($query->paginate($perPage));
    }

    public function store(StoreItemDiagnosticoRequest $request): ItemDiagnosticoResource
    {
        $itemDiagnostico = ItemDiagnostico::create([
            'nombre' => trim((string) $request->validated('nombre')),
        ]);

        return new ItemDiagnosticoResource($itemDiagnostico);
    }

    public function show(ItemDiagnostico $itemDiagnostico): ItemDiagnosticoResource
    {
        return new ItemDiagnosticoResource($itemDiagnostico);
    }

    public function update(UpdateItemDiagnosticoRequest $request, ItemDiagnostico $itemDiagnostico): ItemDiagnosticoResource
    {
        $itemDiagnostico->update([
            'nombre' => trim((string) $request->validated('nombre')),
        ]);

        return new ItemDiagnosticoResource($itemDiagnostico);
    }

    public function destroy(ItemDiagnostico $itemDiagnostico): JsonResponse
    {
        $itemDiagnostico->delete();

        return response()->json([
            'message' => 'Item de diagnóstico eliminado correctamente.',
        ]);
    }
}
