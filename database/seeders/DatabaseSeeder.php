<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            RolesAndPermissionsSeeder::class,
            FeriaInicialSeeder::class,
            AdminUserSeeder::class,
            ConfiguracionesSeeder::class,
            MetodoPagoSeeder::class,
        ]);

        if (app()->isLocal()) {
            $this->call(FeriaSeeder::class);
        }
    }
}
