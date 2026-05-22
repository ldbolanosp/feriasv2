<?php

use App\Models\Configuracion;
use App\Models\Feria;
use App\Models\Parqueo;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\getJson;
use function Pest\Laravel\postJson;
use function Pest\Laravel\putJson;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
});

function configuracionFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForConfiguraciones(array $permissions, Feria $feria): User
{
    foreach ($permissions as $permission) {
        Permission::findOrCreate($permission, 'web');
    }

    Role::findOrCreate('administrador', 'web');

    $user = User::factory()->create();
    $user->assignRole('administrador');
    $user->givePermissionTo($permissions);
    $user->ferias()->attach($feria->id);

    actingAs($user, 'web');

    return $user;
}

it('returns effective fair configurations with global fallback', function (): void {
    $feria = configuracionFeria(['codigo' => 'FER-A']);
    authenticateForConfiguraciones(['configuracion.ver'], $feria);

    Configuracion::create([
        'feria_id' => null,
        'clave' => 'tarifa_parqueo',
        'valor' => '1000.00',
    ]);
    Configuracion::create([
        'feria_id' => null,
        'clave' => 'precio_tarima',
        'valor' => '5000.00',
    ]);
    Configuracion::create([
        'feria_id' => null,
        'clave' => 'precio_sanitario',
        'valor' => '500.00',
    ]);
    Configuracion::create([
        'feria_id' => $feria->id,
        'clave' => 'precio_tarima',
        'valor' => '6500.00',
    ]);

    getJson('/api/v1/configuraciones', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.feria.codigo', 'FER-A')
        ->assertJsonPath('data.configuraciones.tarifa_parqueo.valor', '1000.00')
        ->assertJsonPath('data.configuraciones.tarifa_parqueo.scope', 'global')
        ->assertJsonPath('data.configuraciones.precio_tarima.valor', '6500.00')
        ->assertJsonPath('data.configuraciones.precio_tarima.scope', 'feria');
});

it('updates editable configurations for the active fair', function (): void {
    $feria = configuracionFeria();
    authenticateForConfiguraciones(['configuracion.ver', 'configuracion.editar'], $feria);

    putJson('/api/v1/configuraciones', [
        'tarifa_parqueo' => 1500,
        'precio_tarima' => 7200.5,
        'precio_sanitario' => 800,
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.configuraciones.tarifa_parqueo.valor', '1500.00')
        ->assertJsonPath('data.configuraciones.precio_tarima.valor', '7200.50')
        ->assertJsonPath('data.configuraciones.precio_sanitario.valor', '800.00')
        ->assertJsonPath('data.configuraciones.tarifa_parqueo.scope', 'feria');
});

it('registers exit for all active parking records at 5pm costa rica time', function (): void {
    CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-05-22 02:45:00', 'UTC'));

    $feria = configuracionFeria(['codigo' => 'FER-CIERRE']);
    authenticateForConfiguraciones(['configuracion.ver', 'configuracion.editar'], $feria);
    $otraFeria = configuracionFeria(['codigo' => 'FER-OTRA']);

    $activoManana = Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => 1,
        'placa' => 'AAA111',
        'fecha_hora_ingreso' => CarbonImmutable::create(2026, 5, 21, 14, 0, 0, 'America/Costa_Rica')->setTimezone('UTC'),
        'tarifa' => 1000,
        'tarifa_tipo' => 'fija',
        'estado' => 'activo',
    ]);

    $activoTemprano = Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => 1,
        'placa' => 'BBB222',
        'fecha_hora_ingreso' => CarbonImmutable::create(2026, 5, 20, 8, 15, 0, 'America/Costa_Rica')->setTimezone('UTC'),
        'tarifa' => 1200,
        'tarifa_tipo' => 'fija',
        'estado' => 'activo',
    ]);

    $cancelado = Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => 1,
        'placa' => 'CCC333',
        'fecha_hora_ingreso' => CarbonImmutable::create(2026, 5, 21, 9, 0, 0, 'America/Costa_Rica')->setTimezone('UTC'),
        'fecha_hora_salida' => CarbonImmutable::create(2026, 5, 21, 17, 0, 0, 'America/Costa_Rica')->setTimezone('UTC'),
        'tarifa' => 800,
        'tarifa_tipo' => 'fija',
        'estado' => 'cancelado',
    ]);

    $otraFeriaActivo = Parqueo::create([
        'feria_id' => $otraFeria->id,
        'user_id' => 1,
        'placa' => 'DDD444',
        'fecha_hora_ingreso' => CarbonImmutable::create(2026, 5, 21, 10, 30, 0, 'America/Costa_Rica')->setTimezone('UTC'),
        'tarifa' => 950,
        'tarifa_tipo' => 'fija',
        'estado' => 'activo',
    ]);

    postJson('/api/v1/configuraciones/salida-vehiculos', [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.feria.codigo', 'FER-CIERRE')
        ->assertJsonPath('data.processed_count', 2);

    expect($activoManana->fresh()->estado->value)->toBe('finalizado')
        ->and($activoManana->fresh()->fecha_hora_salida?->format('Y-m-d H:i:s'))->toBe('2026-05-21 23:00:00')
        ->and($activoTemprano->fresh()->estado->value)->toBe('finalizado')
        ->and($activoTemprano->fresh()->fecha_hora_salida?->format('Y-m-d H:i:s'))->toBe('2026-05-20 23:00:00')
        ->and($cancelado->fresh()->estado->value)->toBe('cancelado')
        ->and($otraFeriaActivo->fresh()->estado->value)->toBe('activo');

    CarbonImmutable::setTestNow();
});
