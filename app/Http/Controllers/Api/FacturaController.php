<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Factura\StoreFacturaRequest;
use App\Http\Requests\Factura\UpdateFacturaRequest;
use App\Http\Resources\FacturaResource;
use App\Models\Factura;
use App\Services\FacturacionService;
use App\Services\PdfTicketService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class FacturaController extends Controller
{
    public function __construct(
        public FacturacionService $facturacionService,
        public PdfTicketService $pdfTicketService,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        $query = Factura::query()
            ->with(['feria', 'participante', 'usuario', 'metodoPago', 'detalles.producto'])
            ->withCount('detalles');

        if ($user->hasRole('administrador')) {
            if ($request->filled('feria_id')) {
                $query->porFeria($request->integer('feria_id'));
            }
        } else {
            $query->porFeria($feriaId);
        }

        if ($user->hasRole('facturador')) {
            $query->porUsuario($user->id);
        }

        if ($request->filled('estado')) {
            $query->where('estado', $request->string('estado')->value());
        }

        if ($request->filled('participante_id')) {
            $query->where('participante_id', $request->integer('participante_id'));
        }

        if ($request->filled('fecha_desde')) {
            $query->whereDate('created_at', '>=', $request->date('fecha_desde'));
        }

        if ($request->filled('fecha_hasta')) {
            $query->whereDate('created_at', '<=', $request->date('fecha_hasta'));
        }

        $allowedSortFields = ['id', 'consecutivo', 'subtotal', 'estado', 'fecha_emision', 'created_at', 'updated_at'];
        $sortField = in_array($request->sort, $allowedSortFields) ? $request->sort : 'created_at';
        $direction = $request->direction === 'asc' ? 'asc' : 'desc';

        $query->orderBy($sortField, $direction);

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return FacturaResource::collection($query->paginate($perPage));
    }

    public function store(StoreFacturaRequest $request): JsonResponse
    {
        $factura = $this->facturacionService->crearFactura(
            $request->validated(),
            (int) $request->header('X-Feria-Id'),
            $request->user()->id
        );

        return response()->json([
            'data' => new FacturaResource($factura),
        ], 201);
    }

    public function show(Request $request, Factura $factura): FacturaResource
    {
        $this->authorizeFacturaAccess($request, $factura, false);

        return new FacturaResource($factura->load(['feria', 'participante', 'usuario', 'metodoPago', 'detalles.producto']));
    }

    public function update(UpdateFacturaRequest $request, Factura $factura): FacturaResource
    {
        $this->authorizeFacturaAccess($request, $factura, true);

        return new FacturaResource(
            $this->facturacionService->actualizarFactura($factura, $request->validated())
        );
    }

    public function facturar(Request $request, Factura $factura): FacturaResource
    {
        $this->authorizeFacturaAccess($request, $factura, true);

        return new FacturaResource($this->facturacionService->facturar($factura));
    }

    public function destroy(Request $request, Factura $factura): JsonResponse
    {
        $this->authorizeFacturaAccess($request, $factura, true);
        $this->facturacionService->eliminar($factura);

        return response()->json(['message' => 'Factura eliminada correctamente.']);
    }

    public function pdf(Request $request, Factura $factura): BinaryFileResponse
    {
        $this->authorizeFacturaAccess($request, $factura, false);

        if ($factura->pdf_path === null || ! Storage::disk('local')->exists($factura->pdf_path)) {
            abort(404, 'El PDF solicitado no existe.');
        }

        return response()->file(
            Storage::disk('local')->path($factura->pdf_path),
            [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'inline; filename="'.basename($factura->pdf_path).'"',
            ]
        );
    }

    public function reimprimir(Request $request, Factura $factura): FacturaResource
    {
        $this->authorizeFacturaAccess($request, $factura, false);

        if ($factura->consecutivo === null) {
            throw ValidationException::withMessages([
                'factura' => 'Solo las facturas emitidas pueden reimprimirse.',
            ]);
        }

        $pdfPath = $this->pdfTicketService->generarTicketFactura(
            $factura->load(['feria', 'participante', 'usuario', 'metodoPago', 'detalles.producto'])
        );

        $factura->update(['pdf_path' => $pdfPath]);

        return new FacturaResource($factura->fresh(['feria', 'participante', 'usuario', 'metodoPago', 'detalles.producto']));
    }

    private function authorizeFacturaAccess(Request $request, Factura $factura, bool $forWrite): void
    {
        $user = $request->user();
        $feriaId = (int) $request->header('X-Feria-Id');

        if ($user->hasRole('administrador')) {
            return;
        }

        if ($factura->feria_id !== $feriaId) {
            abort(404);
        }

        if ($user->hasRole('facturador') && $factura->user_id !== $user->id) {
            abort(404);
        }

        if ($forWrite && $user->hasRole('facturador') && $factura->estado->value !== 'borrador') {
            throw ValidationException::withMessages([
                'factura' => 'Solo puede modificar sus facturas en borrador.',
            ]);
        }
    }
}
