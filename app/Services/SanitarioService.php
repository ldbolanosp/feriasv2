<?php

namespace App\Services;

use App\Models\Configuracion;
use App\Models\Sanitario;
use Illuminate\Support\Facades\DB;

class SanitarioService
{
    public function __construct(
        public PdfTicketService $pdfTicketService,
    ) {
    }

    /**
     * @param  array{participante_id?:int|null,cantidad:int,observaciones?:string|null}  $data
     */
    public function crear(array $data, int $feriaId, int $userId): Sanitario
    {
        return DB::transaction(function () use ($data, $feriaId, $userId): Sanitario {
            $precioUnitario = $this->obtenerPrecioSanitario($feriaId);
            $cantidad = (int) $data['cantidad'];

            $sanitario = Sanitario::query()->create([
                'feria_id' => $feriaId,
                'user_id' => $userId,
                'participante_id' => $data['participante_id'] ?? null,
                'cantidad' => $cantidad,
                'precio_unitario' => $precioUnitario,
                'total' => bcmul($precioUnitario, (string) $cantidad, 2),
                'estado' => 'facturado',
                'observaciones' => $data['observaciones'] ?? null,
            ]);

            $pdfPath = $this->pdfTicketService->generarTicketSanitario(
                $sanitario->load(['feria', 'usuario', 'participante'])
            );

            $sanitario->update(['pdf_path' => $pdfPath]);

            return $sanitario->fresh(['feria', 'usuario', 'participante']);
        });
    }

    /**
     * @param  array{observaciones?:string|null}  $data
     */
    public function cancelar(Sanitario $sanitario, array $data = []): Sanitario
    {
        return DB::transaction(function () use ($sanitario, $data): Sanitario {
            $sanitario->update([
                'estado' => 'cancelado',
                'observaciones' => $data['observaciones'] ?? $sanitario->observaciones,
            ]);

            $pdfPath = $this->pdfTicketService->generarTicketSanitario(
                $sanitario->fresh(['feria', 'usuario', 'participante'])
            );

            $sanitario->update(['pdf_path' => $pdfPath]);

            return $sanitario->fresh(['feria', 'usuario', 'participante']);
        });
    }

    public function obtenerPrecioSanitario(int $feriaId): string
    {
        return (string) (Configuracion::query()
            ->where('clave', 'precio_sanitario')
            ->where(function ($query) use ($feriaId): void {
                $query->where('feria_id', $feriaId)
                    ->orWhereNull('feria_id');
            })
            ->orderByRaw('CASE WHEN feria_id IS NULL THEN 1 ELSE 0 END')
            ->value('valor') ?? '0.00');
    }
}
