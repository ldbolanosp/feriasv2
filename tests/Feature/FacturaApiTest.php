<?php

use App\Enums\EstadoFactura;
use App\Models\ConsecutivoFeria;
use App\Models\Factura;
use App\Models\Feria;
use App\Models\MetodoPago;
use App\Models\Participante;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
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

function facturaFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForFacturas(string $role, array $permissions, Feria $feria): User
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

function participanteEnFeria(Feria $feria): Participante
{
    $participante = Participante::create([
        'nombre' => fake()->name(),
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => fake()->unique()->numerify('#########'),
        'activo' => true,
    ]);

    $participante->ferias()->attach($feria->id);

    return $participante;
}

function productoEnFeria(Feria $feria, float $precio = 1000): Producto
{
    $producto = Producto::create([
        'codigo' => fake()->unique()->bothify('PROD-###'),
        'descripcion' => fake()->words(2, true),
        'activo' => true,
    ]);

    ProductoPrecio::create([
        'producto_id' => $producto->id,
        'feria_id' => $feria->id,
        'precio' => $precio,
    ]);

    return $producto;
}

it('limits invoice listing for facturador to own records in active fair', function (): void {
    $feria = facturaFeria();
    $usuario = authenticateForFacturas('facturador', ['facturas.ver'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($feria->id);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente A',
        'subtotal' => 1000,
        'estado' => EstadoFactura::Borrador,
    ]);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $otroUsuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente B',
        'subtotal' => 1500,
        'estado' => EstadoFactura::Borrador,
    ]);

    getJson('/api/v1/facturas', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.nombre_publico', 'Cliente A')
        ->assertJsonMissing(['nombre_publico' => 'Cliente B']);
});

it('creates a draft invoice through the api', function (): void {
    $feria = facturaFeria();
    $usuario = authenticateForFacturas('supervisor', ['facturas.crear'], $feria);
    $participante = participanteEnFeria($feria);
    $producto = productoEnFeria($feria, 1250);

    postJson('/api/v1/facturas', [
        'participante_id' => $participante->id,
        'tipo_puesto' => 'Frutas',
        'numero_puesto' => 'A-01',
        'monto_pago' => 2000,
        'detalles' => [
            ['producto_id' => $producto->id, 'cantidad' => 1],
        ],
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertCreated()
        ->assertJsonPath('data.user_id', $usuario->id)
        ->assertJsonPath('data.estado', 'borrador')
        ->assertJsonPath('data.subtotal', '1250.00')
        ->assertJsonPath('data.metodo_pago.nombre', 'Efectivo')
        ->assertJsonPath('data.detalles.0.producto_id', $producto->id);
});

it('stores the selected payment method on the invoice', function (): void {
    $feria = facturaFeria();
    authenticateForFacturas('supervisor', ['facturas.crear'], $feria);
    $participante = participanteEnFeria($feria);
    $producto = productoEnFeria($feria, 1250);
    $metodoPago = MetodoPago::query()->where('nombre', 'SINPE')->firstOrFail();

    postJson('/api/v1/facturas', [
        'participante_id' => $participante->id,
        'metodo_pago_id' => $metodoPago->id,
        'monto_pago' => 2000,
        'detalles' => [
            ['producto_id' => $producto->id, 'cantidad' => 1],
        ],
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertCreated()
        ->assertJsonPath('data.metodo_pago_id', $metodoPago->id)
        ->assertJsonPath('data.metodo_pago.nombre', 'SINPE');
});

it('issues an invoice and allows reprint and pdf download', function (): void {
    Storage::fake('local');

    $feria = facturaFeria();
    $usuario = authenticateForFacturas('supervisor', ['facturas.ver', 'facturas.facturar'], $feria);
    $producto = productoEnFeria($feria, 1700);
    ConsecutivoFeria::create([
        'feria_id' => $feria->id,
        'ultimo_consecutivo' => 0,
    ]);

    $factura = Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Mostrador',
        'subtotal' => 1700,
        'estado' => EstadoFactura::Borrador,
    ]);

    $factura->detalles()->create([
        'producto_id' => $producto->id,
        'descripcion_producto' => $producto->descripcion,
        'cantidad' => 1,
        'precio_unitario' => 1700,
        'subtotal_linea' => 1700,
    ]);

    postJson("/api/v1/facturas/{$factura->id}/facturar", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.estado', 'facturado')
        ->assertJsonPath('data.consecutivo', 'F100000001');

    postJson("/api/v1/facturas/{$factura->id}/reimprimir", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.consecutivo', 'F100000001');

    getJson("/api/v1/facturas/{$factura->id}/pdf", ['X-Feria-Id' => (string) $feria->id])
        ->assertOk();

    Storage::disk('local')->assertExists("tickets/{$feria->id}/".now()->format('Y-m-d').'/F100000001.pdf');
});

it('validates that selected products have price in the active fair', function (): void {
    $feria = facturaFeria();
    $otraFeria = facturaFeria();
    authenticateForFacturas('supervisor', ['facturas.crear'], $feria);
    $participante = participanteEnFeria($feria);
    $producto = productoEnFeria($otraFeria, 1500);

    postJson('/api/v1/facturas', [
        'participante_id' => $participante->id,
        'detalles' => [
            ['producto_id' => $producto->id, 'cantidad' => 1],
        ],
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['detalles.0.producto_id']);
});

it('prevents a facturador from editing another users invoice', function (): void {
    $feria = facturaFeria();
    $usuario = authenticateForFacturas('facturador', ['facturas.editar'], $feria);
    $participante = participanteEnFeria($feria);
    $producto = productoEnFeria($feria, 900);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($feria->id);

    $factura = Factura::create([
        'feria_id' => $feria->id,
        'participante_id' => $participante->id,
        'user_id' => $otroUsuario->id,
        'subtotal' => 900,
        'estado' => EstadoFactura::Borrador,
    ]);

    $factura->detalles()->create([
        'producto_id' => $producto->id,
        'descripcion_producto' => $producto->descripcion,
        'cantidad' => 1,
        'precio_unitario' => 900,
        'subtotal_linea' => 900,
    ]);

    putJson("/api/v1/facturas/{$factura->id}", [
        'participante_id' => $participante->id,
        'detalles' => [
            ['producto_id' => $producto->id, 'cantidad' => 2],
        ],
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertNotFound();
});
