<?php

use App\Enums\EstadoParqueo;
use App\Models\Configuracion;
use App\Models\Feria;
use App\Models\Parqueo;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\getJson;
use function Pest\Laravel\patchJson;
use function Pest\Laravel\postJson;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
});

function parqueoFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForParqueos(string $role, array $permissions, Feria $feria): User
{
    foreach ($permissions as $permission) {
        Permission::findOrCreate($permission, 'web');
    }

    Role::findOrCreate($role, 'web');

    $user = User::factory()->create();
    $user->assignRole($role);
    $user->givePermissionTo($permissions);
    $user->ferias()->attach($feria->id);

    actingAs($user, 'web');

    return $user;
}

it('lists parking records for the active fair and exposes current fee', function (): void {
    $feria = parqueoFeria(['codigo' => 'FER-001']);
    $otraFeria = parqueoFeria(['codigo' => 'FER-002']);
    $usuario = authenticateForParqueos('supervisor', ['parqueos.ver'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($otraFeria->id);

    Configuracion::create([
        'feria_id' => null,
        'clave' => 'tarifa_parqueo',
        'valor' => '1250.00',
    ]);

    Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'ABC123',
        'fecha_hora_ingreso' => now()->subHour(),
        'tarifa' => 1250,
        'tarifa_tipo' => 'fija',
        'estado' => EstadoParqueo::Activo,
    ]);

    Parqueo::create([
        'feria_id' => $otraFeria->id,
        'user_id' => $otroUsuario->id,
        'placa' => 'XYZ999',
        'fecha_hora_ingreso' => now()->subMinutes(30),
        'tarifa' => 1250,
        'tarifa_tipo' => 'fija',
        'estado' => EstadoParqueo::Activo,
    ]);

    getJson('/api/v1/parqueos', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('tarifa_actual', 1250)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.placa', 'ABC123')
        ->assertJsonMissing(['placa' => 'XYZ999']);
});

it('creates a parking record using fair fee and generates its pdf', function (): void {
    Storage::fake('local');

    $feria = parqueoFeria();
    $usuario = authenticateForParqueos('facturador', ['parqueos.crear'], $feria);

    Configuracion::create([
        'feria_id' => $feria->id,
        'clave' => 'tarifa_parqueo',
        'valor' => '1800.00',
    ]);

    postJson('/api/v1/parqueos', [
        'placa' => 'abc123',
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertCreated()
        ->assertJsonPath('data.user_id', $usuario->id)
        ->assertJsonPath('data.placa', 'ABC123')
        ->assertJsonPath('data.tarifa', '1800.00')
        ->assertJsonPath('data.estado', 'activo');

    Storage::disk('local')->assertExists("tickets/{$feria->id}/".now()->format('Y-m-d').'/parqueo-1.pdf');
});

it('registers exit and refreshes parking pdf', function (): void {
    Storage::fake('local');

    $feria = parqueoFeria();
    $usuario = authenticateForParqueos('supervisor', ['parqueos.salida', 'parqueos.ver'], $feria);

    $parqueo = Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'SAL123',
        'fecha_hora_ingreso' => now()->subHours(2),
        'tarifa' => 1000,
        'tarifa_tipo' => 'fija',
        'estado' => EstadoParqueo::Activo,
    ]);

    patchJson("/api/v1/parqueos/{$parqueo->id}/salida", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.estado', 'finalizado');

    getJson("/api/v1/parqueos/{$parqueo->id}/pdf", ['X-Feria-Id' => (string) $feria->id])
        ->assertOk();

    Storage::disk('local')->assertExists("tickets/{$feria->id}/".now()->format('Y-m-d')."/parqueo-{$parqueo->id}.pdf");

    expect($parqueo->fresh()->fecha_hora_salida)->not->toBeNull();
});

it('cancels an active parking record', function (): void {
    Storage::fake('local');

    $feria = parqueoFeria();
    $usuario = authenticateForParqueos('supervisor', ['parqueos.cancelar'], $feria);

    $parqueo = Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'CAN456',
        'fecha_hora_ingreso' => now()->subHour(),
        'tarifa' => 900,
        'tarifa_tipo' => 'fija',
        'estado' => EstadoParqueo::Activo,
    ]);

    patchJson("/api/v1/parqueos/{$parqueo->id}/cancelar", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.estado', 'cancelado');
});

it('prevents a facturador from registering exit on another users parking record', function (): void {
    $feria = parqueoFeria();
    authenticateForParqueos('facturador', ['parqueos.salida'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($feria->id);

    $parqueo = Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $otroUsuario->id,
        'placa' => 'OWN777',
        'fecha_hora_ingreso' => now()->subHour(),
        'tarifa' => 900,
        'tarifa_tipo' => 'fija',
        'estado' => EstadoParqueo::Activo,
    ]);

    patchJson("/api/v1/parqueos/{$parqueo->id}/salida", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertNotFound();
});
