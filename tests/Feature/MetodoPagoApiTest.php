<?php

use App\Models\Feria;
use App\Models\MetodoPago;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\getJson;
use function Pest\Laravel\patchJson;
use function Pest\Laravel\postJson;
use function Pest\Laravel\putJson;

uses(RefreshDatabase::class);

function metodoPagoFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForConfiguracion(array $permissions, Feria $feria): User
{
    foreach ($permissions as $permission) {
        Permission::findOrCreate($permission, 'web');
    }

    $user = User::factory()->create();
    $user->givePermissionTo($permissions);
    $user->ferias()->attach($feria->id);

    actingAs($user, 'web');

    return $user;
}

it('lists the default payment methods catalog', function (): void {
    $feria = metodoPagoFeria();
    authenticateForConfiguracion(['configuracion.ver'], $feria);

    getJson('/api/v1/metodos-pago', ['X-Feria-Id' => (string) $feria->id])
        ->assertSuccessful()
        ->assertJsonFragment(['nombre' => 'Efectivo'])
        ->assertJsonFragment(['nombre' => 'SINPE'])
        ->assertJsonFragment(['nombre' => 'Tarjeta de Crédito']);
});

it('creates and updates a payment method', function (): void {
    $feria = metodoPagoFeria();
    authenticateForConfiguracion(['configuracion.editar'], $feria);

    $created = postJson('/api/v1/metodos-pago', [
        'nombre' => 'Transferencia',
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertSuccessful()
        ->assertJsonPath('data.nombre', 'Transferencia')
        ->json('data.id');

    putJson("/api/v1/metodos-pago/{$created}", [
        'nombre' => 'Transferencia bancaria',
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertSuccessful()
        ->assertJsonPath('data.nombre', 'Transferencia bancaria');
});

it('toggles a payment method status', function (): void {
    $feria = metodoPagoFeria();
    authenticateForConfiguracion(['configuracion.editar'], $feria);
    $metodoPago = MetodoPago::query()->where('nombre', 'SINPE')->firstOrFail();

    patchJson("/api/v1/metodos-pago/{$metodoPago->id}/toggle", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertSuccessful()
        ->assertJsonPath('data.activo', false);

    expect($metodoPago->fresh()->activo)->toBeFalse();
});

it('returns the payment method catalog for invoicing including inactive current options', function (): void {
    $feria = metodoPagoFeria();
    authenticateForConfiguracion(['facturas.ver'], $feria);

    getJson('/api/v1/facturas/catalogo/metodos-pago', ['X-Feria-Id' => (string) $feria->id])
        ->assertSuccessful()
        ->assertJsonFragment(['nombre' => 'Efectivo'])
        ->assertJsonFragment(['nombre' => 'SINPE']);
});
