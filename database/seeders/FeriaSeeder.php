<?php

namespace Database\Seeders;

use App\Enums\TipoIdentificacion;
use App\Enums\TipoSangre;
use App\Models\Configuracion;
use App\Models\ConsecutivoFeria;
use App\Models\Feria;
use App\Models\Participante;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use App\Models\User;
use Illuminate\Database\Seeder;

class FeriaSeeder extends Seeder
{
    public function run(): void
    {
        $feria1 = Feria::firstOrCreate(
            ['codigo' => 'F400'],
            [
                'descripcion' => 'Feria del Agricultor de Cartago',
                'facturacion_publico' => true,
                'activa' => true,
            ]
        );

        $feria2 = Feria::firstOrCreate(
            ['codigo' => 'F500'],
            [
                'descripcion' => 'Feria del Agricultor de San José',
                'facturacion_publico' => false,
                'activa' => true,
            ]
        );

        ConsecutivoFeria::firstOrCreate(['feria_id' => $feria1->id], ['ultimo_consecutivo' => 0]);
        ConsecutivoFeria::firstOrCreate(['feria_id' => $feria2->id], ['ultimo_consecutivo' => 0]);

        $participantes = [
            [
                'nombre' => 'Juan Carlos Mora Jiménez',
                'tipo_identificacion' => TipoIdentificacion::Fisica,
                'numero_identificacion' => '303450678',
                'correo_electronico' => 'jcmora@gmail.com',
                'telefono' => '88001234',
                'procedencia' => 'Cartago',
                'tipo_sangre' => TipoSangre::OPositivo,
                'activo' => true,
            ],
            [
                'nombre' => 'María Fernanda Solís Castro',
                'tipo_identificacion' => TipoIdentificacion::Fisica,
                'numero_identificacion' => '109876543',
                'correo_electronico' => 'mfsolis@hotmail.com',
                'telefono' => '72345678',
                'procedencia' => 'San José',
                'tipo_sangre' => TipoSangre::APositivo,
                'activo' => true,
            ],
            [
                'nombre' => 'Productos Orgánicos del Valle S.A.',
                'tipo_identificacion' => TipoIdentificacion::Juridica,
                'numero_identificacion' => '3101789456',
                'correo_electronico' => 'organicos@valle.cr',
                'telefono' => '22891234',
                'procedencia' => 'Heredia',
                'activo' => true,
            ],
            [
                'nombre' => 'Carlos Rodríguez Ulate',
                'tipo_identificacion' => TipoIdentificacion::Fisica,
                'numero_identificacion' => '502340987',
                'telefono' => '83456789',
                'procedencia' => 'Alajuela',
                'tipo_sangre' => TipoSangre::BPositivo,
                'activo' => true,
            ],
            [
                'nombre' => 'Ana Patricia Vega Obando',
                'tipo_identificacion' => TipoIdentificacion::Fisica,
                'numero_identificacion' => '701234567',
                'correo_electronico' => 'apvega@yahoo.com',
                'telefono' => '65432187',
                'procedencia' => 'Limón',
                'activo' => true,
            ],
        ];

        $createdParticipantes = [];
        foreach ($participantes as $data) {
            $createdParticipantes[] = Participante::firstOrCreate(
                ['numero_identificacion' => $data['numero_identificacion']],
                $data
            );
        }

        $feria1->participantes()->syncWithoutDetaching(
            collect($createdParticipantes)->take(3)->pluck('id')->toArray()
        );
        $feria2->participantes()->syncWithoutDetaching(
            collect($createdParticipantes)->pluck('id')->toArray()
        );

        $productos = [
            ['codigo' => 'VEG001', 'descripcion' => 'Lechuga Romana', 'activo' => true],
            ['codigo' => 'FRU001', 'descripcion' => 'Tomate Cherry', 'activo' => true],
            ['codigo' => 'TUB001', 'descripcion' => 'Papa Blanca', 'activo' => true],
        ];

        $preciosFeria1 = [800, 1200, 600];
        $preciosFeria2 = [900, 1400, 700];

        foreach ($productos as $index => $data) {
            $producto = Producto::firstOrCreate(['codigo' => $data['codigo']], $data);

            ProductoPrecio::firstOrCreate(
                ['producto_id' => $producto->id, 'feria_id' => $feria1->id],
                ['precio' => $preciosFeria1[$index]]
            );

            ProductoPrecio::firstOrCreate(
                ['producto_id' => $producto->id, 'feria_id' => $feria2->id],
                ['precio' => $preciosFeria2[$index]]
            );
        }

        $supervisor = User::firstOrCreate(
            ['email' => 'supervisor@ferias.cr'],
            [
                'name' => 'Supervisor Prueba',
                'password' => bcrypt('password'),
                'activo' => true,
            ]
        );
        $supervisor->syncRoles(['supervisor']);

        $facturador = User::firstOrCreate(
            ['email' => 'facturador@ferias.cr'],
            [
                'name' => 'Facturador Prueba',
                'password' => bcrypt('password'),
                'activo' => true,
            ]
        );
        $facturador->syncRoles(['facturador']);

        $feria1->usuarios()->syncWithoutDetaching([$supervisor->id, $facturador->id]);
        $feria2->usuarios()->syncWithoutDetaching([$supervisor->id]);

        Configuracion::firstOrCreate(
            ['feria_id' => $feria1->id, 'clave' => 'tarifa_parqueo'],
            ['valor' => '1000.00', 'descripcion' => 'Tarifa parqueo Cartago']
        );

        Configuracion::firstOrCreate(
            ['feria_id' => $feria2->id, 'clave' => 'tarifa_parqueo'],
            ['valor' => '1200.00', 'descripcion' => 'Tarifa parqueo San José']
        );
    }
}
