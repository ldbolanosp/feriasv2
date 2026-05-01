<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Tarima\StoreTarimaRequest;
use App\Http\Resources\TarimaResource;
use App\Models\Tarima;
use App\Services\TarimaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class TarimaController extends Controller
{
    public function __construct(
        public TarimaService $tarimaService,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        $query = Tarima::query()->with(['feria', 'usuario', 'participante']);

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

            $query->where(function ($innerQuery) use ($search): void {
                $innerQuery->where('numero_tarima', 'ilike', "%{$search}%")
                    ->orWhereHas('participante', function ($participanteQuery) use ($search): void {
                        $participanteQuery->where('nombre', 'ilike', "%{$search}%")
                            ->orWhere('numero_identificacion', 'ilike', "%{$search}%");
                    });
            });
        }

        $allowedSortFields = ['id', 'numero_tarima', 'cantidad', 'precio_unitario', 'total', 'estado', 'created_at', 'updated_at'];
        $sortField = in_array($request->sort, $allowedSortFields, true) ? $request->sort : 'created_at';
        $direction = $request->direction === 'asc' ? 'asc' : 'desc';

        $paginator = $query
            ->orderBy($sortField, $direction)
            ->paginate(min((int) ($request->per_page ?? 15), 100));

        return TarimaResource::collection($paginator)
            ->additional([
                'precio_actual' => (float) $this->tarimaService->obtenerPrecioTarima($feriaId),
            ])
            ->response();
    }

    public function store(StoreTarimaRequest $request): JsonResponse
    {
        $tarima = $this->tarimaService->crear(
            $request->validated(),
            (int) $request->header('X-Feria-Id'),
            $request->user()->id
        );

        return response()->json([
            'message' => 'Tarima facturada correctamente.',
            'data' => new TarimaResource($tarima),
        ], 201);
    }

    public function show(Request $request, Tarima $tarima): TarimaResource
    {
        $this->authorizeTarimaAccess($request, $tarima, false);

        return new TarimaResource($tarima->load(['feria', 'usuario', 'participante']));
    }

    public function cancelar(Request $request, Tarima $tarima): JsonResponse
    {
        $this->authorizeTarimaAccess($request, $tarima, true);

        $tarima = $this->tarimaService->cancelar($tarima, [
            'observaciones' => $request->input('observaciones'),
        ]);

        return response()->json([
            'message' => 'Tarima cancelada correctamente.',
            'data' => new TarimaResource($tarima),
        ]);
    }

    public function pdf(Request $request, Tarima $tarima): BinaryFileResponse
    {
        $this->authorizeTarimaAccess($request, $tarima, false);

        if ($tarima->pdf_path === null || ! Storage::disk('local')->exists($tarima->pdf_path)) {
            abort(404, 'El PDF solicitado no existe.');
        }

        return response()->file(
            Storage::disk('local')->path($tarima->pdf_path),
            [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'inline; filename="'.basename($tarima->pdf_path).'"',
            ]
        );
    }

    private function authorizeTarimaAccess(Request $request, Tarima $tarima, bool $forWrite): void
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        if ($user->hasRole('administrador')) {
            return;
        }

        if ($tarima->feria_id !== $feriaId) {
            abort(404);
        }

        if ($user->hasRole('facturador') && $tarima->user_id !== $user->id) {
            abort(404);
        }

        if ($forWrite && $tarima->estado !== 'facturado') {
            throw ValidationException::withMessages([
                'tarima' => 'La tarima seleccionada ya no admite cambios.',
            ]);
        }
    }
}
