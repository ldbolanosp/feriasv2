<?php

use App\Models\Feria;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\deleteJson;
use function Pest\Laravel\getJson;
use function Pest\Laravel\postJson;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
});

function authenticateForProductos(string $permission, Feria $feria): User
{
    Permission::findOrCreate($permission, 'web');

    $user = User::factory()->create();
    $user->givePermissionTo($permission);
    $user->ferias()->attach($feria->id);

    actingAs($user, 'web');

    return $user;
}

function feriaAttributes(array $overrides = []): array
{
    return array_merge([
        'codigo' => fake()->unique()->bothify('FERIA-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides);
}

it('lists products with prices count and fair details', function (): void {
    $feriaA = Feria::create(feriaAttributes(['codigo' => 'FER-A']));
    $feriaB = Feria::create(feriaAttributes(['codigo' => 'FER-B']));
    authenticateForProductos('productos.ver', $feriaA);

    $producto = Producto::create([
        'codigo' => 'PROD-001',
        'descripcion' => 'Tomate premium',
        'activo' => true,
    ]);

    ProductoPrecio::create([
        'producto_id' => $producto->id,
        'feria_id' => $feriaA->id,
        'precio' => 1250.50,
    ]);

    ProductoPrecio::create([
        'producto_id' => $producto->id,
        'feria_id' => $feriaB->id,
        'precio' => 1350.00,
    ]);

    getJson('/api/v1/productos', ['X-Feria-Id' => (string) $feriaA->id])
        ->assertOk()
        ->assertJsonPath('data.0.codigo', 'PROD-001')
        ->assertJsonPath('data.0.precios_count', 2)
        ->assertJsonPath('data.0.precios.0.feria.codigo', 'FER-A')
        ->assertJsonPath('data.0.precios.1.feria.codigo', 'FER-B');
});

it('upserts prices for a product by fair', function (): void {
    $feriaA = Feria::create(feriaAttributes(['codigo' => 'FER-A']));
    $feriaB = Feria::create(feriaAttributes(['codigo' => 'FER-B']));
    authenticateForProductos('productos.editar', $feriaA);

    $producto = Producto::create([
        'codigo' => 'PROD-002',
        'descripcion' => 'Papa lavada',
        'activo' => true,
    ]);

    ProductoPrecio::create([
        'producto_id' => $producto->id,
        'feria_id' => $feriaA->id,
        'precio' => 900.00,
    ]);

    postJson(
        "/api/v1/productos/{$producto->id}/precios",
        [
            'precios' => [
                ['feria_id' => $feriaA->id, 'precio' => 950.00],
                ['feria_id' => $feriaB->id, 'precio' => 1100.00],
            ],
        ],
        ['X-Feria-Id' => (string) $feriaA->id]
    )
        ->assertOk()
        ->assertJsonPath('data.precios_count', 2);

    expect(ProductoPrecio::query()->count())->toBe(2);

    expect(
        ProductoPrecio::query()
            ->where('producto_id', $producto->id)
            ->where('feria_id', $feriaA->id)
            ->value('precio')
    )->toBe('950.00');

    expect(
        ProductoPrecio::query()
            ->where('producto_id', $producto->id)
            ->where('feria_id', $feriaB->id)
            ->value('precio')
    )->toBe('1100.00');
});

it('returns only active fair products in por feria', function (): void {
    $feriaA = Feria::create(feriaAttributes(['codigo' => 'FER-A']));
    $feriaB = Feria::create(feriaAttributes(['codigo' => 'FER-B']));
    authenticateForProductos('productos.ver', $feriaA);

    $productoVisible = Producto::create([
        'codigo' => 'PROD-003',
        'descripcion' => 'Cebolla dulce',
        'activo' => true,
    ]);

    $productoOculto = Producto::create([
        'codigo' => 'PROD-004',
        'descripcion' => 'Zanahoria orgánica',
        'activo' => true,
    ]);

    ProductoPrecio::create([
        'producto_id' => $productoVisible->id,
        'feria_id' => $feriaA->id,
        'precio' => 1500.00,
    ]);

    ProductoPrecio::create([
        'producto_id' => $productoOculto->id,
        'feria_id' => $feriaB->id,
        'precio' => 1750.00,
    ]);

    getJson('/api/v1/productos/por-feria', ['X-Feria-Id' => (string) $feriaA->id])
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.codigo', 'PROD-003')
        ->assertJsonPath('data.0.precio_feria_actual', 1500)
        ->assertJsonMissing(['codigo' => 'PROD-004']);
});

it('deletes a fair price from a product', function (): void {
    $feriaA = Feria::create(feriaAttributes(['codigo' => 'FER-A']));
    authenticateForProductos('productos.editar', $feriaA);

    $producto = Producto::create([
        'codigo' => 'PROD-005',
        'descripcion' => 'Yuca',
        'activo' => true,
    ]);

    ProductoPrecio::create([
        'producto_id' => $producto->id,
        'feria_id' => $feriaA->id,
        'precio' => 800.00,
    ]);

    deleteJson(
        "/api/v1/productos/{$producto->id}/precios/{$feriaA->id}",
        [],
        ['X-Feria-Id' => (string) $feriaA->id]
    )
        ->assertOk()
        ->assertJsonPath('data.precios_count', 0);

    expect(ProductoPrecio::query()->count())->toBe(0);
});
