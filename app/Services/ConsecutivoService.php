<?php

namespace App\Services;

use App\Models\ConsecutivoFeria;
use RuntimeException;
use Illuminate\Support\Facades\DB;

class ConsecutivoService
{
    public function generarConsecutivo(int $feriaId): string
    {
        return DB::transaction(function () use ($feriaId): string {
            $consecutivo = ConsecutivoFeria::query()
                ->where('feria_id', $feriaId)
                ->lockForUpdate()
                ->first();

            if ($consecutivo === null) {
                throw new RuntimeException('No existe configuración de consecutivo para la feria seleccionada.');
            }

            $consecutivo->increment('ultimo_consecutivo');
            $consecutivo->refresh();

            return 'F'.$feriaId.str_pad((string) $consecutivo->ultimo_consecutivo, 8, '0', STR_PAD_LEFT);
        });
    }
}
