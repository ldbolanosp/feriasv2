<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Inspeccion\StoreInspeccionRequest;
use App\Http\Resources\InspeccionResource;
use App\Http\Resources\ParticipanteResource;
use App\Models\Inspeccion;
use App\Models\ItemDiagnostico;
use App\Models\Participante;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class InspeccionController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $feriaId = (int) $request->header('X-Feria-Id');

        $query = Inspeccion::query()
            ->where('feria_id', $feriaId)
            ->with(['participante', 'inspector', 'reinspeccionDe', 'items'])
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search');
                $query->whereHas('participante', function ($innerQuery) use ($search): void {
                    $innerQuery->where('nombre', 'ilike', "%{$search}%")
                        ->orWhere('numero_identificacion', 'ilike', "%{$search}%");
                });
            })
            ->latest();

        $perPage = min((int) ($request->per_page ?? 10), 100);

        return InspeccionResource::collection($query->paginate($perPage));
    }

    public function store(StoreInspeccionRequest $request): InspeccionResource
    {
        $feriaId = (int) $request->header('X-Feria-Id');
        $validated = $request->validated();
        $itemsSeleccionados = collect($validated['items']);
        $catalogo = ItemDiagnostico::query()
            ->whereIn('id', $itemsSeleccionados->pluck('item_diagnostico_id')->all())
            ->get()
            ->keyBy('id');

        $inspeccion = DB::transaction(function () use ($catalogo, $feriaId, $itemsSeleccionados, $request, $validated): Inspeccion {
            $inspeccion = Inspeccion::create([
                'feria_id' => $feriaId,
                'participante_id' => $validated['participante_id'],
                'user_id' => $request->user()?->id,
                'reinspeccion_de_id' => $validated['reinspeccion_de_id'] ?? null,
                'total_items' => $itemsSeleccionados->count(),
                'total_incumplidos' => $itemsSeleccionados->where('cumple', false)->count(),
            ]);

            $inspeccion->items()->createMany(
                $itemsSeleccionados->values()->map(function (array $item, int $index) use ($catalogo): array {
                    $itemDiagnostico = $catalogo->get($item['item_diagnostico_id']);

                    return [
                        'item_diagnostico_id' => $item['item_diagnostico_id'],
                        'nombre_item' => $itemDiagnostico?->nombre ?? 'Item eliminado',
                        'cumple' => (bool) $item['cumple'],
                        'observaciones' => isset($item['observaciones']) && trim((string) $item['observaciones']) !== ''
                            ? trim((string) $item['observaciones'])
                            : null,
                        'orden' => $index + 1,
                    ];
                })->all()
            );

            return $inspeccion;
        });

        return new InspeccionResource($inspeccion->load(['participante', 'inspector', 'reinspeccionDe', 'items']));
    }

    public function vencimientosCarne(Request $request): AnonymousResourceCollection
    {
        $feriaId = (int) $request->header('X-Feria-Id');

        $query = Participante::query()
            ->with('ferias')
            ->porFeria($feriaId)
            ->where('activo', true)
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search');
                $query->where(function ($innerQuery) use ($search): void {
                    $innerQuery->where('nombre', 'ilike', "%{$search}%")
                        ->orWhere('numero_identificacion', 'ilike', "%{$search}%")
                        ->orWhere('numero_carne', 'ilike', "%{$search}%");
                });
            })
            ->orderByRaw('CASE WHEN fecha_vencimiento_carne IS NULL THEN 1 ELSE 0 END')
            ->orderBy('fecha_vencimiento_carne')
            ->orderBy('nombre');

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return ParticipanteResource::collection($query->paginate($perPage));
    }

    public function reinspecciones(Request $request): AnonymousResourceCollection
    {
        $feriaId = (int) $request->header('X-Feria-Id');

        $latestInspectionIds = Inspeccion::query()
            ->selectRaw('MAX(id) as id')
            ->where('feria_id', $feriaId)
            ->groupBy('participante_id');

        $query = Inspeccion::query()
            ->whereIn('id', $latestInspectionIds)
            ->where('feria_id', $feriaId)
            ->where('total_incumplidos', '>', 0)
            ->with([
                'participante',
                'inspector',
                'items' => fn ($query) => $query->where('cumple', false)->orderBy('orden'),
            ])
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = $request->string('search');
                $query->whereHas('participante', function ($innerQuery) use ($search): void {
                    $innerQuery->where('nombre', 'ilike', "%{$search}%")
                        ->orWhere('numero_identificacion', 'ilike', "%{$search}%");
                });
            })
            ->orderByDesc('total_incumplidos')
            ->latest();

        $perPage = min((int) ($request->per_page ?? 10), 100);

        return InspeccionResource::collection($query->paginate($perPage));
    }
}
