<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Sanitario\StoreSanitarioRequest;
use App\Http\Resources\SanitarioResource;
use App\Models\Sanitario;
use App\Services\SanitarioService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class SanitarioController extends Controller
{
    public function __construct(
        public SanitarioService $sanitarioService,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        $query = Sanitario::query()->with(['feria', 'usuario', 'participante']);

        if ($user->hasRole('administrador')) {
            if ($request->filled('feria_id')) {
                $query->porFeria($request->integer('feria_id'));
            }
        } else {
            $query->porFeria($feriaId);
        }

        if ($user->hasRole('facturador')) {
            $query->where('user_id', $user->id);
        }

        if ($request->filled('estado')) {
            $query->where('estado', $request->string('estado')->value());
        }

        if ($request->filled('search')) {
            $search = trim($request->string('search')->value());
            $searchLower = mb_strtolower($search);
            $searchMatchesPublic = str_contains($searchLower, 'public')
                || str_contains($searchLower, 'uso')
                || str_contains($searchLower, 'general');

            $query->where(function ($innerQuery) use ($search, $searchMatchesPublic): void {
                $innerQuery->whereHas('participante', function ($participanteQuery) use ($search): void {
                    $participanteQuery->where('nombre', 'ilike', "%{$search}%")
                        ->orWhere('numero_identificacion', 'ilike', "%{$search}%");
                });

                if ($searchMatchesPublic) {
                    $innerQuery->orWhereNull('participante_id');
                }
            });
        }

        $allowedSortFields = ['id', 'cantidad', 'precio_unitario', 'total', 'estado', 'created_at', 'updated_at'];
        $sortField = in_array($request->sort, $allowedSortFields, true) ? $request->sort : 'created_at';
        $direction = $request->direction === 'asc' ? 'asc' : 'desc';

        $paginator = $query
            ->orderBy($sortField, $direction)
            ->paginate(min((int) ($request->per_page ?? 15), 100));

        return SanitarioResource::collection($paginator)
            ->additional([
                'precio_actual' => (float) $this->sanitarioService->obtenerPrecioSanitario($feriaId),
            ])
            ->response();
    }

    public function store(StoreSanitarioRequest $request): JsonResponse
    {
        $sanitario = $this->sanitarioService->crear(
            $request->validated(),
            (int) $request->header('X-Feria-Id'),
            $request->user()->id
        );

        return response()->json([
            'message' => 'Sanitario facturado correctamente.',
            'data' => new SanitarioResource($sanitario),
        ], 201);
    }

    public function show(Request $request, Sanitario $sanitario): SanitarioResource
    {
        $this->authorizeSanitarioAccess($request, $sanitario, false);

        return new SanitarioResource($sanitario->load(['feria', 'usuario', 'participante']));
    }

    public function cancelar(Request $request, Sanitario $sanitario): JsonResponse
    {
        $this->authorizeSanitarioAccess($request, $sanitario, true);

        $sanitario = $this->sanitarioService->cancelar($sanitario, [
            'observaciones' => $request->input('observaciones'),
        ]);

        return response()->json([
            'message' => 'Sanitario cancelado correctamente.',
            'data' => new SanitarioResource($sanitario),
        ]);
    }

    public function pdf(Request $request, Sanitario $sanitario): BinaryFileResponse
    {
        $this->authorizeSanitarioAccess($request, $sanitario, false);

        if ($sanitario->pdf_path === null || ! Storage::disk('local')->exists($sanitario->pdf_path)) {
            abort(404, 'El PDF solicitado no existe.');
        }

        return response()->file(
            Storage::disk('local')->path($sanitario->pdf_path),
            [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'inline; filename="'.basename($sanitario->pdf_path).'"',
            ]
        );
    }

    private function authorizeSanitarioAccess(Request $request, Sanitario $sanitario, bool $forWrite): void
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        if ($user->hasRole('administrador')) {
            return;
        }

        if ($sanitario->feria_id !== $feriaId) {
            abort(404);
        }

        if ($user->hasRole('facturador') && $sanitario->user_id !== $user->id) {
            abort(404);
        }

        if ($forWrite && $sanitario->estado !== 'facturado') {
            throw ValidationException::withMessages([
                'sanitario' => 'El sanitario seleccionado ya no admite cambios.',
            ]);
        }
    }
}
