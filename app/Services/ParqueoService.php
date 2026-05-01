<?php

namespace App\Services;

use App\Enums\EstadoParqueo;
use App\Enums\TarifaTipo;
use App\Models\Configuracion;
use App\Models\Parqueo;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ParqueoService
{
    public function __construct(
        public PdfTicketService $pdfTicketService,
    ) {
    }

    /**
     * @param  array{placa:string,observaciones?:string|null}  $data
     */
    public function crear(array $data, int $feriaId, int $userId): Parqueo
    {
        return DB::transaction(function () use ($data, $feriaId, $userId): Parqueo {
            $parqueo = Parqueo::query()->create([
                'feria_id' => $feriaId,
                'user_id' => $userId,
                'placa' => mb_strtoupper(trim($data['placa'])),
                'fecha_hora_ingreso' => now(),
                'tarifa' => $this->obtenerTarifaParqueo($feriaId),
                'tarifa_tipo' => TarifaTipo::Fija,
                'estado' => EstadoParqueo::Activo,
                'observaciones' => $data['observaciones'] ?? null,
            ]);

            $pdfPath = $this->pdfTicketService->generarTicketParqueo($parqueo->load(['feria', 'usuario']));
            $parqueo->update(['pdf_path' => $pdfPath]);

            return $parqueo->fresh(['feria', 'usuario']);
        });
    }

    /**
     * @param  array{observaciones?:string|null}  $data
     */
    public function registrarSalida(Parqueo $parqueo, array $data = []): Parqueo
    {
        if ($parqueo->estado !== EstadoParqueo::Activo) {
            throw ValidationException::withMessages([
                'parqueo' => 'Solo los parqueos activos pueden registrar salida.',
            ]);
        }

        return DB::transaction(function () use ($parqueo, $data): Parqueo {
            $parqueo->update([
                'fecha_hora_salida' => now(),
                'estado' => EstadoParqueo::Finalizado,
                'observaciones' => $data['observaciones'] ?? $parqueo->observaciones,
            ]);

            $pdfPath = $this->pdfTicketService->generarTicketParqueo($parqueo->fresh(['feria', 'usuario']));
            $parqueo->update(['pdf_path' => $pdfPath]);

            return $parqueo->fresh(['feria', 'usuario']);
        });
    }

    /**
     * @param  array{observaciones?:string|null}  $data
     */
    public function cancelar(Parqueo $parqueo, array $data = []): Parqueo
    {
        if ($parqueo->estado !== EstadoParqueo::Activo) {
            throw ValidationException::withMessages([
                'parqueo' => 'Solo los parqueos activos pueden cancelarse.',
            ]);
        }

        return DB::transaction(function () use ($parqueo, $data): Parqueo {
            $parqueo->update([
                'estado' => EstadoParqueo::Cancelado,
                'observaciones' => $data['observaciones'] ?? $parqueo->observaciones,
            ]);

            $pdfPath = $this->pdfTicketService->generarTicketParqueo($parqueo->fresh(['feria', 'usuario']));
            $parqueo->update(['pdf_path' => $pdfPath]);

            return $parqueo->fresh(['feria', 'usuario']);
        });
    }

    public function obtenerTarifaParqueo(int $feriaId): string
    {
        return (string) (Configuracion::query()
            ->where('clave', 'tarifa_parqueo')
            ->where(function ($query) use ($feriaId): void {
                $query->where('feria_id', $feriaId)
                    ->orWhereNull('feria_id');
            })
            ->orderByRaw('CASE WHEN feria_id IS NULL THEN 1 ELSE 0 END')
            ->value('valor') ?? '0.00');
    }
}
