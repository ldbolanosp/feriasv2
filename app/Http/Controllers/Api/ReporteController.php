<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
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
        $feriaId = $request->validated('feria_id');

        $reporte = $this->reporteService->generarFacturacion(
            $request->user(),
            is_int($feriaId) ? $feriaId : null,
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
        $feriaId = $request->validated('feria_id');

        $reporte = $this->reporteService->generarParqueos(
            $request->user(),
            is_int($feriaId) ? $feriaId : null,
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
}
