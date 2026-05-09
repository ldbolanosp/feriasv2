<?php

namespace Database\Seeders;

use App\Models\MetodoPago;
use Illuminate\Database\Seeder;

class MetodoPagoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        foreach (['Efectivo', 'SINPE', 'Tarjeta de Crédito'] as $nombre) {
            MetodoPago::query()->updateOrCreate(
                ['nombre' => $nombre],
                ['activo' => true]
            );
        }
    }
}
