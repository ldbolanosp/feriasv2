<?php

namespace Database\Seeders;

use App\Models\Configuracion;
use Illuminate\Database\Seeder;

class ConfiguracionesSeeder extends Seeder
{
    public function run(): void
    {
        $configuraciones = [
            ['clave' => 'tarifa_parqueo', 'valor' => '1000.00', 'descripcion' => 'Tarifa de parqueo en colones'],
            ['clave' => 'precio_tarima', 'valor' => '5000.00', 'descripcion' => 'Precio por tarima en colones'],
            ['clave' => 'precio_sanitario', 'valor' => '500.00', 'descripcion' => 'Precio por uso de sanitario en colones'],
            ['clave' => 'moneda', 'valor' => 'CRC', 'descripcion' => 'Moneda del sistema'],
        ];

        foreach ($configuraciones as $config) {
            Configuracion::firstOrCreate(
                ['feria_id' => null, 'clave' => $config['clave']],
                ['valor' => $config['valor'], 'descripcion' => $config['descripcion']]
            );
        }
    }
}
