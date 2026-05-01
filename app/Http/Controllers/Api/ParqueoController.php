<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Parqueo\SalidaParqueoRequest;
use App\Http\Requests\Parqueo\StoreParqueoRequest;
use App\Http\Resources\ParqueoResource;
use App\Models\Parqueo;
use App\Services\ParqueoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ParqueoController extends Controller
{
    public function __construct(
        public ParqueoService $parqueoService,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        $query = Parqueo::query()
            ->with(['feria', 'usuario']);

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

        if ($request->filled('placa')) {
            $placa = mb_strtoupper(trim($request->string('placa')->value()));
            $query->where('placa', 'ilike', "%{$placa}%");
        }

        if ($request->filled('fecha')) {
            $query->whereDate('fecha_hora_ingreso', $request->date('fecha'));
        }

        $allowedSortFields = ['id', 'placa', 'fecha_hora_ingreso', 'fecha_hora_salida', 'tarifa', 'estado', 'created_at', 'updated_at'];
        $sortField = in_array($request->sort, $allowedSortFields, true) ? $request->sort : 'fecha_hora_ingreso';
        $direction = $request->direction === 'asc' ? 'asc' : 'desc';

        $paginator = $query
            ->orderBy($sortField, $direction)
            ->paginate(min((int) ($request->per_page ?? 15), 100));

        return ParqueoResource::collection($paginator)
            ->additional([
                'tarifa_actual' => (float) $this->parqueoService->obtenerTarifaParqueo($feriaId),
            ])
            ->response();
    }

    public function store(StoreParqueoRequest $request): JsonResponse
    {
        $parqueo = $this->parqueoService->crear(
            $request->validated(),
            (int) $request->header('X-Feria-Id'),
            $request->user()->id
        );

        return response()->json([
            'message' => 'Parqueo registrado correctamente.',
            'data' => new ParqueoResource($parqueo),
        ], 201);
    }

    public function show(Request $request, Parqueo $parqueo): ParqueoResource
    {
        $this->authorizeParqueoAccess($request, $parqueo, false);

        return new ParqueoResource($parqueo->load(['feria', 'usuario']));
    }

    public function salida(SalidaParqueoRequest $request, Parqueo $parqueo): JsonResponse
    {
        $this->authorizeParqueoAccess($request, $parqueo, true);

        $parqueo = $this->parqueoService->registrarSalida($parqueo, $request->validated());

        return response()->json([
            'message' => 'Salida registrada correctamente.',
            'data' => new ParqueoResource($parqueo),
        ]);
    }

    public function cancelar(Request $request, Parqueo $parqueo): JsonResponse
    {
        $this->authorizeParqueoAccess($request, $parqueo, true);

        $parqueo = $this->parqueoService->cancelar($parqueo, [
            'observaciones' => $request->input('observaciones'),
        ]);

        return response()->json([
            'message' => 'Parqueo cancelado correctamente.',
            'data' => new ParqueoResource($parqueo),
        ]);
    }

    public function pdf(Request $request, Parqueo $parqueo): BinaryFileResponse
    {
        $this->authorizeParqueoAccess($request, $parqueo, false);

        if ($parqueo->pdf_path === null || ! Storage::disk('local')->exists($parqueo->pdf_path)) {
            abort(404, 'El PDF solicitado no existe.');
        }

        return response()->file(
            Storage::disk('local')->path($parqueo->pdf_path),
            [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'inline; filename="'.basename($parqueo->pdf_path).'"',
            ]
        );
    }

    private function authorizeParqueoAccess(Request $request, Parqueo $parqueo, bool $forWrite): void
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        if ($user->hasRole('administrador')) {
            return;
        }

        if ($parqueo->feria_id !== $feriaId) {
            abort(404);
        }

        if ($user->hasRole('facturador') && $parqueo->user_id !== $user->id) {
            abort(404);
        }

        if ($forWrite && $parqueo->estado->value !== 'activo') {
            throw ValidationException::withMessages([
                'parqueo' => 'El parqueo seleccionado ya no admite cambios.',
            ]);
        }
    }
}
