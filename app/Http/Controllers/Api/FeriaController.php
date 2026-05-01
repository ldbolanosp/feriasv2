<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Feria\StoreFeriaRequest;
use App\Http\Requests\Feria\UpdateFeriaRequest;
use App\Http\Resources\FeriaResource;
use App\Models\Feria;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class FeriaController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Feria::query();

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search): void {
                $q->where('codigo', 'ilike', "%{$search}%")
                    ->orWhere('descripcion', 'ilike', "%{$search}%");
            });
        }

        if ($request->filled('activa')) {
            $query->where('activa', filter_var($request->activa, FILTER_VALIDATE_BOOLEAN));
        }

        $allowedSortFields = ['id', 'codigo', 'descripcion', 'activa', 'created_at', 'updated_at'];
        $sortField = in_array($request->sort, $allowedSortFields) ? $request->sort : 'id';
        $direction = $request->direction === 'desc' ? 'desc' : 'asc';

        $query->orderBy($sortField, $direction);

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return FeriaResource::collection($query->paginate($perPage));
    }

    public function store(StoreFeriaRequest $request): FeriaResource
    {
        $feria = Feria::create($request->validated());

        return new FeriaResource($feria);
    }

    public function show(Feria $feria): FeriaResource
    {
        return new FeriaResource($feria);
    }

    public function update(UpdateFeriaRequest $request, Feria $feria): FeriaResource
    {
        $feria->update($request->validated());

        return new FeriaResource($feria);
    }

    public function toggle(Feria $feria): JsonResponse
    {
        $feria->update(['activa' => ! $feria->activa]);

        return response()->json([
            'message' => $feria->activa ? 'Feria activada correctamente.' : 'Feria desactivada correctamente.',
            'data' => new FeriaResource($feria),
        ]);
    }
}
