<?php

namespace App\Services;

use App\Models\Configuracion;
use App\Models\Tarima;
use Illuminate\Support\Facades\DB;

class TarimaService
{
    public function __construct(
        public PdfTicketService $pdfTicketService,
    ) {
    }

    /**
     * @param  array{participante_id:int,numero_tarima?:string|null,cantidad:int,observaciones?:string|null}  $data
     */
    public function crear(array $data, int $feriaId, int $userId): Tarima
    {
        return DB::transaction(function () use ($data, $feriaId, $userId): Tarima {
            $precioUnitario = $this->obtenerPrecioTarima($feriaId);
            $cantidad = (int) $data['cantidad'];

            $tarima = Tarima::query()->create([
                'feria_id' => $feriaId,
                'user_id' => $userId,
                'participante_id' => $data['participante_id'],
                'numero_tarima' => isset($data['numero_tarima']) ? trim((string) $data['numero_tarima']) : null,
                'cantidad' => $cantidad,
                'precio_unitario' => $precioUnitario,
                'total' => bcmul($precioUnitario, (string) $cantidad, 2),
                'estado' => 'facturado',
                'observaciones' => $data['observaciones'] ?? null,
            ]);

            $pdfPath = $this->pdfTicketService->generarTicketTarima(
                $tarima->load(['feria', 'usuario', 'participante'])
            );

            $tarima->update(['pdf_path' => $pdfPath]);

            return $tarima->fresh(['feria', 'usuario', 'participante']);
        });
    }

    /**
     * @param  array{observaciones?:string|null}  $data
     */
    public function cancelar(Tarima $tarima, array $data = []): Tarima
    {
        return DB::transaction(function () use ($tarima, $data): Tarima {
            $tarima->update([
                'estado' => 'cancelado',
                'observaciones' => $data['observaciones'] ?? $tarima->observaciones,
            ]);

            $pdfPath = $this->pdfTicketService->generarTicketTarima(
                $tarima->fresh(['feria', 'usuario', 'participante'])
            );

            $tarima->update(['pdf_path' => $pdfPath]);

            return $tarima->fresh(['feria', 'usuario', 'participante']);
        });
    }

    public function obtenerPrecioTarima(int $feriaId): string
    {
        return (string) (Configuracion::query()
            ->where('clave', 'precio_tarima')
            ->where(function ($query) use ($feriaId): void {
                $query->where('feria_id', $feriaId)
                    ->orWhereNull('feria_id');
            })
            ->orderByRaw('CASE WHEN feria_id IS NULL THEN 1 ELSE 0 END')
            ->value('valor') ?? '0.00');
    }
}
