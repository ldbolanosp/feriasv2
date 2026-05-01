<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::firstOrCreate(
            ['email' => 'admin@ferias.cr'],
            [
                'name' => 'Administrador',
                'password' => bcrypt('password'),
                'activo' => true,
            ]
        );

        $admin->syncRoles(['administrador']);
    }
}
