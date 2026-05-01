<?php

namespace Database\Seeders;

use App\Models\ConsecutivoFeria;
use App\Models\Feria;
use Illuminate\Database\Seeder;

class FeriaInicialSeeder extends Seeder
{
    public function run(): void
    {
        $feria = Feria::firstOrCreate(
            ['codigo' => 'F001'],
            [
                'descripcion' => 'Feria Principal',
                'facturacion_publico' => true,
                'activa' => true,
            ]
        );

        ConsecutivoFeria::firstOrCreate(
            ['feria_id' => $feria->id],
            ['ultimo_consecutivo' => 0]
        );
    }
}
