<?php

use Database\Seeders\RolesAndPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

it('replaces current invoices with legacy invoices and details', function () {
    Artisan::call('db:seed', ['--class' => RolesAndPermissionsSeeder::class, '--no-interaction' => true]);

    DB::table('ferias')->insert([
        ['id' => 1, 'codigo' => 'FERIA1', 'descripcion' => 'Feria 1', 'facturacion_publico' => false, 'activa' => true, 'created_at' => now(), 'updated_at' => now(), 'deleted_at' => null],
    ]);

    DB::table('participantes')->insert([
        ['id' => 5, 'nombre' => 'Participante Legacy', 'tipo_identificacion' => 'fisica', 'numero_identificacion' => '123', 'correo_electronico' => null, 'numero_carne' => null, 'fecha_emision_carne' => null, 'fecha_vencimiento_carne' => null, 'procedencia' => null, 'telefono' => null, 'tipo_sangre' => null, 'padecimientos' => null, 'contacto_emergencia_nombre' => null, 'contacto_emergencia_telefono' => null, 'activo' => true, 'created_at' => now(), 'updated_at' => now(), 'deleted_at' => null],
    ]);

    DB::table('users')->insert([
        ['id' => 1, 'name' => 'Admin', 'email' => 'admin@example.com', 'email_verified_at' => now(), 'password' => bcrypt('password'), 'remember_token' => null, 'activo' => true, 'created_at' => now(), 'updated_at' => now(), 'deleted_at' => null],
        ['id' => 2, 'name' => 'Cajero', 'email' => 'cajero@example.com', 'email_verified_at' => now(), 'password' => bcrypt('password'), 'remember_token' => null, 'activo' => true, 'created_at' => now(), 'updated_at' => now(), 'deleted_at' => null],
    ]);

    DB::table('productos')->insert([
        ['id' => 13, 'codigo' => 'P13', 'descripcion' => 'Producto 13', 'activo' => true, 'created_at' => now(), 'updated_at' => now(), 'deleted_at' => null],
    ]);

    DB::table('facturas')->insert([
        ['id' => 999, 'feria_id' => 1, 'participante_id' => 5, 'user_id' => 1, 'consecutivo' => 'TEST-1', 'es_publico_general' => false, 'nombre_publico' => null, 'tipo_puesto' => null, 'numero_puesto' => null, 'subtotal' => 10.00, 'monto_pago' => 10.00, 'monto_cambio' => 0.00, 'observaciones' => null, 'estado' => 'facturado', 'fecha_emision' => now(), 'pdf_path' => null, 'created_at' => now(), 'updated_at' => now(), 'deleted_at' => null],
    ]);

    DB::table('factura_detalles')->insert([
        ['id' => 999, 'factura_id' => 999, 'producto_id' => 13, 'descripcion_producto' => 'Producto Test', 'cantidad' => 1, 'precio_unitario' => 10.00, 'subtotal_linea' => 10.00, 'created_at' => now(), 'updated_at' => now()],
    ]);

    $dumpPath = tempnam(sys_get_temp_dir(), 'legacy-invoices-');

    file_put_contents($dumpPath, <<<'SQL'
INSERT INTO `facturas` (`id`, `consecutivo`, `feria_id`, `participant_id`, `nombre_cliente_general`, `user_id`, `observaciones`, `estatus`, `total`, `monto_pago`, `cambio`, `fecha`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 5, NULL, NULL, 'Legacy factura; observacion importada', 'Facturado', 9140.00, NULL, NULL, '2025-11-07', '2025-11-07 02:50:20', '2025-11-07 02:50:20');

INSERT INTO `factura_items` (`id`, `factura_id`, `facturacion_producto_id`, `cantidad`, `precio`, `subtotal`, `created_at`, `updated_at`) VALUES
(1, 1, 13, 1, 9140.00, 9140.00, '2025-11-07 02:50:20', '2025-11-07 02:50:20');
SQL);

    $this->artisan('app:import-legacy-invoices', ['path' => $dumpPath, '--replace-current' => true])
        ->assertSuccessful()
        ->expectsOutputToContain('Importacion de facturas completada.');

    expect(DB::table('facturas')->where('id', 999)->doesntExist())->toBeTrue();
    expect(DB::table('factura_detalles')->where('id', 999)->doesntExist())->toBeTrue();

    $factura = DB::table('facturas')->where('id', 1)->first();
    $detalle = DB::table('factura_detalles')->where('id', 1)->first();

    expect($factura)->not->toBeNull();
    expect($factura?->consecutivo)->toBe('F100000001');
    expect((int) $factura?->user_id)->toBe(1);
    expect((float) $factura?->subtotal)->toBe(9140.0);
    expect((string) $factura?->estado)->toBe('facturado');
    expect((string) $factura?->observaciones)->toBe('Legacy factura; observacion importada');
    expect((string) $factura?->fecha_emision)->toBe('2025-11-07 08:50:20');
    expect((string) $factura?->created_at)->toBe('2025-11-07 08:50:20');

    expect($detalle)->not->toBeNull();
    expect((int) $detalle?->producto_id)->toBe(13);
    expect((string) $detalle?->descripcion_producto)->toBe('Producto 13');
    expect((float) $detalle?->subtotal_linea)->toBe(9140.0);
    expect((string) $detalle?->created_at)->toBe('2025-11-07 08:50:20');
});
