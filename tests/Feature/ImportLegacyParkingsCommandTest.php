<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

it('replaces current parkings with legacy parkings using the requested feria and tariff rules', function () {
    DB::table('ferias')->insert([
        [
            'id' => 1,
            'codigo' => 'LA VILLA',
            'descripcion' => 'Desamparados Villa Olimpica',
            'facturacion_publico' => false,
            'activa' => true,
            'created_at' => now(),
            'updated_at' => now(),
            'deleted_at' => null,
        ],
    ]);

    DB::table('users')->insert([
        [
            'id' => 1,
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'email_verified_at' => now(),
            'password' => bcrypt('password'),
            'remember_token' => null,
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
            'deleted_at' => null,
        ],
    ]);

    DB::table('parqueos')->insert([
        [
            'id' => 999,
            'feria_id' => 1,
            'user_id' => 1,
            'placa' => 'TEST123',
            'fecha_hora_ingreso' => '2026-03-01 10:00:00',
            'fecha_hora_salida' => '2026-03-01 17:00:00',
            'tarifa' => 1000.00,
            'tarifa_tipo' => 'fija',
            'estado' => 'finalizado',
            'observaciones' => null,
            'pdf_path' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ],
    ]);

    $dumpPath = tempnam(sys_get_temp_dir(), 'legacy-parkings-');

    file_put_contents($dumpPath, <<<'SQL'
INSERT INTO `parqueo_registros` (`id`, `placa`, `ingreso_at`, `salida_at`, `user_id`, `created_at`, `updated_at`) VALUES
(1, 'abc123', '2026-03-03 14:38:30', NULL, 1, '2026-03-03 14:38:30', '2026-03-03 14:38:30'),
(2, 'xyz999', '2026-03-03 23:57:25', NULL, 1, '2026-03-03 23:57:25', '2026-03-03 23:57:25');
SQL);

    $this->artisan('app:import-legacy-parkings', [
        'path' => $dumpPath,
        '--feria' => 'LA VILLA',
        '--tarifa' => '700',
        '--replace-current' => true,
    ])
        ->assertSuccessful()
        ->expectsOutputToContain('Importacion de parqueos completada.');

    expect(DB::table('parqueos')->where('id', 999)->doesntExist())->toBeTrue();

    $parqueoDiurno = DB::table('parqueos')->where('id', 1)->first();
    $parqueoNocturno = DB::table('parqueos')->where('id', 2)->first();

    expect($parqueoDiurno)->not->toBeNull();
    expect((int) $parqueoDiurno?->feria_id)->toBe(1);
    expect((string) $parqueoDiurno?->placa)->toBe('ABC123');
    expect((string) $parqueoDiurno?->fecha_hora_ingreso)->toBe('2026-03-03 20:38:30');
    expect((string) $parqueoDiurno?->fecha_hora_salida)->toBe('2026-03-03 23:00:00');
    expect((string) $parqueoDiurno?->estado)->toBe('finalizado');
    expect((float) $parqueoDiurno?->tarifa)->toBe(700.0);

    expect($parqueoNocturno)->not->toBeNull();
    expect((string) $parqueoNocturno?->fecha_hora_ingreso)->toBe('2026-03-04 05:57:25');
    expect((string) $parqueoNocturno?->fecha_hora_salida)->toBe('2026-03-04 05:57:25');
    expect((float) $parqueoNocturno?->tarifa)->toBe(700.0);
});
