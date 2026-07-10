<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Reporte\ExportCarnesVencimientoRequest;
use App\Http\Requests\Reporte\ExportReporteRequest;
use App\Services\ReporteService;
use Carbon\CarbonImmutable;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ReporteController extends Controller
{
    public function __construct(
        public ReporteService $reporteService,
    ) {}

    public function facturacion(ExportReporteRequest $request): BinaryFileResponse
    {
        $feriaId = $request->filled('feria_id') ? $request->integer('feria_id') : null;

        $reporte = $this->reporteService->generarFacturacion(
            $request->user(),
            $feriaId,
            CarbonImmutable::parse($request->validated('fecha_inicio')),
            CarbonImmutable::parse($request->validated('fecha_fin')),
        );

        return response()->download(
            $reporte['path'],
            $reporte['filename'],
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]
        )->deleteFileAfterSend(true);
    }

    public function parqueos(ExportReporteRequest $request): BinaryFileResponse
    {
        $feriaId = $request->filled('feria_id') ? $request->integer('feria_id') : null;

        $reporte = $this->reporteService->generarParqueos(
            $request->user(),
            $feriaId,
            CarbonImmutable::parse($request->validated('fecha_inicio')),
            CarbonImmutable::parse($request->validated('fecha_fin')),
        );

        return response()->download(
            $reporte['path'],
            $reporte['filename'],
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]
        )->deleteFileAfterSend(true);
    }

    public function tarimas(ExportReporteRequest $request): BinaryFileResponse
    {
        $feriaId = $request->filled('feria_id') ? $request->integer('feria_id') : null;

        $reporte = $this->reporteService->generarTarimas(
            $request->user(),
            $feriaId,
            CarbonImmutable::parse($request->validated('fecha_inicio')),
            CarbonImmutable::parse($request->validated('fecha_fin')),
        );

        return response()->download(
            $reporte['path'],
            $reporte['filename'],
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]
        )->deleteFileAfterSend(true);
    }

    public function inspecciones(ExportReporteRequest $request): BinaryFileResponse
    {
        $feriaId = $request->filled('feria_id') ? $request->integer('feria_id') : null;

        $reporte = $this->reporteService->generarInspecciones(
            $request->user(),
            $feriaId,
            CarbonImmutable::parse($request->validated('fecha_inicio')),
            CarbonImmutable::parse($request->validated('fecha_fin')),
        );

        return response()->download(
            $reporte['path'],
            $reporte['filename'],
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]
        )->deleteFileAfterSend(true);
    }

    public function reinspecciones(ExportReporteRequest $request): BinaryFileResponse
    {
        $feriaId = $request->filled('feria_id') ? $request->integer('feria_id') : null;

        $reporte = $this->reporteService->generarReinspecciones(
            $request->user(),
            $feriaId,
            CarbonImmutable::parse($request->validated('fecha_inicio')),
            CarbonImmutable::parse($request->validated('fecha_fin')),
        );

        return response()->download(
            $reporte['path'],
            $reporte['filename'],
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]
        )->deleteFileAfterSend(true);
    }

    public function vencimientoCarne(ExportCarnesVencimientoRequest $request): BinaryFileResponse
    {
        $feriaId = $request->filled('feria_id') ? $request->integer('feria_id') : null;

        $reporte = $this->reporteService->generarVencimientosCarne(
            $request->user(),
            $feriaId,
        );

        return response()->download(
            $reporte['path'],
            $reporte['filename'],
            [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]
        )->deleteFileAfterSend(true);
    }
}
