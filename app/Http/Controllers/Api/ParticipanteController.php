<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Participante\AsignarFeriasRequest;
use App\Http\Requests\Participante\StoreParticipanteRequest;
use App\Http\Requests\Participante\UpdateParticipanteCarneRequest;
use App\Http\Requests\Participante\UpdateParticipanteRequest;
use App\Http\Resources\FeriaResource;
use App\Http\Resources\ParticipanteResource;
use App\Models\Feria;
use App\Models\Participante;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Carbon;

class ParticipanteController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Participante::query()->with('ferias');

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search): void {
                $q->where('nombre', 'ilike', "%{$search}%")
                    ->orWhere('numero_identificacion', 'ilike', "%{$search}%");
            });
        }

        if ($request->filled('activo')) {
            $query->where('activo', filter_var($request->activo, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('tipo_identificacion')) {
            $query->where('tipo_identificacion', $request->tipo_identificacion);
        }

        if ($request->filled('feria_id')) {
            $query->porFeria($request->integer('feria_id'));
        }

        $allowedSortFields = ['id', 'nombre', 'numero_identificacion', 'tipo_identificacion', 'activo', 'created_at', 'updated_at'];
        $sortField = in_array($request->sort, $allowedSortFields) ? $request->sort : 'nombre';
        $direction = $request->direction === 'desc' ? 'desc' : 'asc';

        $query->orderBy($sortField, $direction);

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return ParticipanteResource::collection($query->paginate($perPage));
    }

    public function store(StoreParticipanteRequest $request): ParticipanteResource
    {
        $participante = Participante::create(
            $this->withCarneUpdateTracking($request, $request->validated())
        );

        return new ParticipanteResource($participante->load('ferias'));
    }

    public function show(Participante $participante): ParticipanteResource
    {
        return new ParticipanteResource($participante->load('ferias'));
    }

    public function update(UpdateParticipanteRequest $request, Participante $participante): ParticipanteResource
    {
        $participante->fill($request->validated());

        if ($this->hasDirtyCarneFields($participante)) {
            $participante->forceFill($this->carneUpdateTracking($request));
        }

        $participante->save();

        return new ParticipanteResource($participante->load('ferias'));
    }

    public function actualizarCarne(UpdateParticipanteCarneRequest $request, Participante $participante): ParticipanteResource
    {
        $feriaId = (int) $request->header('X-Feria-Id');

        abort_unless(
            $participante->ferias()->whereKey($feriaId)->exists(),
            404,
            'El participante no pertenece a la feria activa.'
        );

        $participante->fill($request->validated());

        if ($this->hasDirtyCarneFields($participante)) {
            $participante->forceFill($this->carneUpdateTracking($request));
        }

        $participante->save();

        return new ParticipanteResource($participante->load('ferias'));
    }

    public function toggle(Participante $participante): JsonResponse
    {
        $participante->update(['activo' => ! $participante->activo]);

        return response()->json([
            'message' => $participante->activo ? 'Participante activado correctamente.' : 'Participante desactivado correctamente.',
            'data' => new ParticipanteResource($participante->load('ferias')),
        ]);
    }

    public function ferias(Participante $participante): AnonymousResourceCollection
    {
        return FeriaResource::collection($participante->ferias);
    }

    public function asignarFerias(AsignarFeriasRequest $request, Participante $participante): JsonResponse
    {
        $participante->ferias()->syncWithoutDetaching($request->validated('ferias'));

        return response()->json([
            'message' => 'Ferias asignadas correctamente.',
            'data' => new ParticipanteResource($participante->load('ferias')),
        ]);
    }

    public function desasignarFeria(Participante $participante, Feria $feria): JsonResponse
    {
        $participante->ferias()->detach($feria->id);

        return response()->json([
            'message' => 'Feria desasignada correctamente.',
            'data' => new ParticipanteResource($participante->load('ferias')),
        ]);
    }

    public function porFeria(Request $request): AnonymousResourceCollection
    {
        $feriaId = (int) $request->header('X-Feria-Id');

        $participantes = Participante::query()
            ->porFeria($feriaId)
            ->where('activo', true)
            ->when($request->filled('search'), function ($q) use ($request): void {
                $search = $request->string('search');
                $q->where(function ($inner) use ($search): void {
                    $inner->where('nombre', 'ilike', "%{$search}%")
                        ->orWhere('numero_identificacion', 'ilike', "%{$search}%");
                });
            })
            ->orderBy('nombre')
            ->get(['id', 'nombre', 'numero_identificacion', 'tipo_identificacion']);

        return ParticipanteResource::collection($participantes);
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function withCarneUpdateTracking(FormRequest $request, array $data): array
    {
        if (! $this->hasFilledCarneFields($data)) {
            return $data;
        }

        return [
            ...$data,
            ...$this->carneUpdateTracking($request),
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function hasFilledCarneFields(array $data): bool
    {
        foreach (['numero_carne', 'fecha_emision_carne', 'fecha_vencimiento_carne'] as $field) {
            if (($data[$field] ?? null) !== null && $data[$field] !== '') {
                return true;
            }
        }

        return false;
    }

    private function hasDirtyCarneFields(Participante $participante): bool
    {
        return $participante->isDirty([
            'numero_carne',
            'fecha_emision_carne',
            'fecha_vencimiento_carne',
        ]);
    }

    /**
     * @return array{carne_actualizado_por_user_id:int|null, carne_actualizado_en:Carbon}
     */
    private function carneUpdateTracking(Request $request): array
    {
        return [
            'carne_actualizado_por_user_id' => $request->user()?->id,
            'carne_actualizado_en' => now(),
        ];
    }
}
