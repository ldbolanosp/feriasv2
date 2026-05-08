<?php

use App\Models\ConsecutivoFeria;
use App\Models\Feria;
use App\Models\Participante;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use App\Models\User;
use Database\Seeders\FeriaInicialSeeder;
use Database\Seeders\RolesAndPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

it('imports legacy catalogs and users from a sql dump', function () {
    Artisan::call('db:seed', ['--class' => RolesAndPermissionsSeeder::class, '--no-interaction' => true]);
    Artisan::call('db:seed', ['--class' => FeriaInicialSeeder::class, '--no-interaction' => true]);

    DB::table('ferias')->insert([
        'id' => 2,
        'codigo' => 'EXTRA',
        'descripcion' => 'Feria extra para prueba',
        'facturacion_publico' => false,
        'activa' => true,
        'created_at' => now(),
        'updated_at' => now(),
        'deleted_at' => null,
    ]);

    DB::table('consecutivos_feria')->insert([
        'feria_id' => 2,
        'ultimo_consecutivo' => 0,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    DB::table('productos')->insert([
        'id' => 10,
        'codigo' => 'LOCAL-PROD',
        'descripcion' => 'Producto local',
        'activo' => true,
        'created_at' => now(),
        'updated_at' => now(),
        'deleted_at' => null,
    ]);

    DB::table('producto_precios')->insert([
        'producto_id' => 10,
        'feria_id' => 2,
        'precio' => 999.00,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    DB::table('participantes')->insert([
        'id' => 50,
        'nombre' => 'Participante local',
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => 'LOCAL-50',
        'correo_electronico' => null,
        'numero_carne' => null,
        'fecha_emision_carne' => null,
        'fecha_vencimiento_carne' => null,
        'procedencia' => null,
        'telefono' => null,
        'tipo_sangre' => null,
        'padecimientos' => null,
        'contacto_emergencia_nombre' => null,
        'contacto_emergencia_telefono' => null,
        'activo' => true,
        'created_at' => now(),
        'updated_at' => now(),
        'deleted_at' => null,
    ]);

    DB::table('feria_participante')->insert([
        'feria_id' => 1,
        'participante_id' => 50,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    $dumpPath = tempnam(sys_get_temp_dir(), 'legacy-dump-');

    file_put_contents($dumpPath, <<<'SQL'
INSERT INTO `ferias` (`id`, `codigo`, `descripcion`, `facturacion_publico`, `consecutivo_actual`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'VILLA', 'Feria Villa', 0, 25, '2025-11-07 01:02:47', '2026-04-25 12:07:27', NULL),
(2, 'CAFETERIA', 'Feria Cafeteria', 1, 3, '2025-11-07 01:13:21', '2025-11-07 01:13:21', '2026-01-01 00:00:00');

INSERT INTO `participants` (`id`, `name`, `identification_type`, `identification_number`, `email`, `card_number`, `origin`, `phone`, `blood_type`, `medical_conditions`, `emergency_contact_name`, `emergency_contact_phone`, `created_at`, `updated_at`, `deleted_at`) VALUES
(5, 'MARIA LOPEZ', 'Física', '105700527', 'maria@example.com', 'A-1', 'Cartago', '88887777', 'O+', 'Ninguno', 'ANA', '77776666', '2025-11-07 01:54:21', '2026-02-17 02:48:09', NULL),
(6, 'ANA LOPEZ', 'Física', '105700527', 'ana@example.com', 'A-2', 'Cartago', '88886666', 'A+', 'Ninguno', 'MARIA', '77775555', '2025-11-07 01:54:21', '2026-02-17 02:48:09', NULL);

INSERT INTO `feria_participant` (`id`, `participant_id`, `feria_id`, `created_at`, `updated_at`) VALUES
(9, 5, 1, '2025-11-07 01:54:21', '2025-11-07 01:54:21');

INSERT INTO `facturacion_productos` (`id`, `codigo`, `descripcion`, `created_at`, `updated_at`, `deleted_at`) VALUES
(10, 'P-01', 'Producto legado', '2025-11-07 01:14:21', '2025-11-07 01:14:21', NULL);

INSERT INTO `feria_facturacion_producto` (`id`, `feria_id`, `facturacion_producto_id`, `precio`, `created_at`, `updated_at`) VALUES
(15, 1, 10, 7040.00, '2025-11-07 01:19:31', '2026-02-24 20:41:16');

INSERT INTO `roles` (`id`, `name`, `slug`, `description`, `created_at`, `updated_at`) VALUES
(1, 'Administradores', 'administradores', 'Grupo de administradores', '2025-11-07 01:02:14', '2025-11-07 01:02:14'),
(4, 'Facturadores', 'facturadores', 'Grupo de facturadores', '2025-11-07 01:02:14', '2025-11-07 01:02:14');

INSERT INTO `users` (`id`, `role_id`, `active`, `name`, `email`, `email_verified_at`, `password`, `two_factor_secret`, `two_factor_recovery_codes`, `two_factor_confirmed_at`, `remember_token`, `current_team_id`, `profile_photo_path`, `created_at`, `updated_at`) VALUES
(7, 1, 1, 'Legacy Admin', 'legacy-admin@example.com', '2025-11-07 01:02:14', '$2y$10$usesomesillystringforsalt$Q9YjZ6.rT3Yf8FJkB6bV7Ok9wM66K2M1OJjK4V3l4I7U9gJfD6L2K', NULL, NULL, NULL, 'remember-me', NULL, NULL, '2025-11-07 01:02:14', '2025-11-13 04:08:09'),
(8, 4, 0, 'Legacy Facturador', 'legacy-facturador@example.com', NULL, '$2y$10$usesomesillystringforsalt$Q9YjZ6.rT3Yf8FJkB6bV7Ok9wM66K2M1OJjK4V3l4I7U9gJfD6L2K', NULL, NULL, NULL, NULL, NULL, NULL, '2025-11-08 02:19:46', '2025-11-08 02:19:54');
SQL);

    $this->artisan('app:import-legacy-catalog-data', ['path' => $dumpPath])
        ->assertSuccessful()
        ->expectsOutputToContain('Importacion completada.');

    $feriaActiva = Feria::query()->find(1);

    expect($feriaActiva)->not->toBeNull();
    expect($feriaActiva?->codigo)->toBe('VILLA');

    expect(Feria::withTrashed()->find(2)?->activa)->toBeFalse();
    expect(ConsecutivoFeria::query()->where('feria_id', 1)->value('ultimo_consecutivo'))->toBe(25);

    $participante = Participante::query()->find(5);

    expect($participante)->not->toBeNull();
    expect($participante?->nombre)->toBe('MARIA LOPEZ');
    expect($participante?->tipo_identificacion?->value)->toBe('fisica');
    expect($participante?->numero_carne)->toBe('A-1');

    expect(Participante::query()->find(6)?->numero_identificacion)->toBe('105700527-legacy-6');
    expect(DB::table('feria_participante')
        ->where('feria_id', 1)
        ->where('participante_id', 5)
        ->exists())->toBeTrue();
    expect(DB::table('feria_participante')
        ->where('feria_id', 1)
        ->where('participante_id', 50)
        ->doesntExist())->toBeTrue();

    $producto = Producto::query()->find(10);

    expect($producto)->not->toBeNull();
    expect($producto?->codigo)->toBe('P-01');
    expect($producto?->descripcion)->toBe('Producto legado');

    $productoPrecio = ProductoPrecio::query()
        ->where('feria_id', 1)
        ->where('producto_id', 10)
        ->first();

    expect($productoPrecio)->not->toBeNull();
    expect($productoPrecio?->precio)->toBe('7040.00');
    expect(ProductoPrecio::query()
        ->where('producto_id', 10)
        ->where('feria_id', 2)
        ->doesntExist())->toBeTrue();

    $legacyAdmin = User::query()->find(7);
    $legacyFacturador = User::query()->find(8);

    expect($legacyAdmin)
        ->not->toBeNull()
        ->email->toBe('legacy-admin@example.com');

    expect($legacyFacturador?->activo)->toBeFalse();
    expect($legacyAdmin?->password)->toBe('$2y$10$usesomesillystringforsalt$Q9YjZ6.rT3Yf8FJkB6bV7Ok9wM66K2M1OJjK4V3l4I7U9gJfD6L2K');
    expect($legacyAdmin?->hasRole('administrador'))->toBeTrue();
    expect($legacyFacturador?->hasRole('facturador'))->toBeTrue();
});
