<?php

use App\Enums\EstadoFactura;
use App\Models\ConsecutivoFeria;
use App\Models\Factura;
use App\Models\Feria;
use App\Models\Participante;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use App\Models\User;
use App\Services\ConsecutivoService;
use App\Services\FacturacionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

uses(RefreshDatabase::class);

function crearFeriaParaFacturacion(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function crearProductoConPrecio(Feria $feria, array $overrides = [], float $precio = 1250): Producto
{
    $producto = Producto::create(array_merge([
        'codigo' => fake()->unique()->bothify('PROD-###'),
        'descripcion' => fake()->words(2, true),
        'activo' => true,
    ], $overrides));

    ProductoPrecio::create([
        'producto_id' => $producto->id,
        'feria_id' => $feria->id,
        'precio' => $precio,
    ]);

    return $producto;
}

it('creates a draft invoice with calculated totals and snapshots', function (): void {
    $feria = crearFeriaParaFacturacion();
    $usuario = User::factory()->create();
    $usuario->ferias()->attach($feria->id);
    $participante = Participante::create([
        'nombre' => 'Mariela Vargas',
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => '102340987',
        'activo' => true,
    ]);
    $participante->ferias()->attach($feria->id);

    $productoA = crearProductoConPrecio($feria, ['descripcion' => 'Tomate'], 1000);
    $productoB = crearProductoConPrecio($feria, ['descripcion' => 'Papa'], 800);

    $factura = app(FacturacionService::class)->crearFactura([
        'participante_id' => $participante->id,
        'tipo_puesto' => 'Verduras',
        'numero_puesto' => 'B-12',
        'monto_pago' => 3000,
        'observaciones' => 'Cobro semanal',
        'detalles' => [
            ['producto_id' => $productoA->id, 'cantidad' => 1.5],
            ['producto_id' => $productoB->id, 'cantidad' => 1],
        ],
    ], $feria->id, $usuario->id);

    expect($factura->estado)->toBe(EstadoFactura::Borrador);
    expect($factura->metodoPago?->nombre)->toBe('Efectivo');
    expect($factura->subtotal)->toBe('2300.00');
    expect($factura->monto_cambio)->toBe('700.00');
    expect($factura->detalles)->toHaveCount(2);
    expect($factura->detalles[0]->descripcion_producto)->toBe('Tomate');
    expect($factura->detalles[0]->subtotal_linea)->toBe('1500.00');
    expect($factura->detalles[1]->descripcion_producto)->toBe('Papa');
});

it('generates sequential fair invoices and stores the pdf when issuing', function (): void {
    Storage::fake('local');

    $feria = crearFeriaParaFacturacion(['codigo' => 'F400']);
    $usuario = User::factory()->create();
    ConsecutivoFeria::create([
        'feria_id' => $feria->id,
        'ultimo_consecutivo' => 0,
    ]);

    $factura = Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente contado',
        'subtotal' => 1500,
        'estado' => EstadoFactura::Borrador,
    ]);

    $producto = crearProductoConPrecio($feria, ['descripcion' => 'Pepino'], 1500);

    $factura->detalles()->create([
        'producto_id' => $producto->id,
        'descripcion_producto' => 'Pepino',
        'cantidad' => 1,
        'precio_unitario' => 1500,
        'subtotal_linea' => 1500,
    ]);

    $facturaEmitida = app(FacturacionService::class)->facturar($factura);
    $segundoConsecutivo = app(ConsecutivoService::class)->generarConsecutivo($feria->id);

    expect($facturaEmitida->estado)->toBe(EstadoFactura::Facturado);
    expect($facturaEmitida->consecutivo)->toBe('F100000001');
    expect($facturaEmitida->pdf_path)->toBe("tickets/{$feria->id}/".now()->format('Y-m-d').'/F100000001.pdf');
    Storage::disk('local')->assertExists($facturaEmitida->pdf_path);
    expect($segundoConsecutivo)->toBe('F100000002');
});

it('rejects a participant that does not belong to the selected fair', function (): void {
    $feria = crearFeriaParaFacturacion();
    $otraFeria = crearFeriaParaFacturacion();
    $usuario = User::factory()->create();
    $participante = Participante::create([
        'nombre' => 'Luis Quesada',
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => '901230456',
        'activo' => true,
    ]);
    $participante->ferias()->attach($otraFeria->id);
    $producto = crearProductoConPrecio($feria);

    app(FacturacionService::class)->crearFactura([
        'participante_id' => $participante->id,
        'detalles' => [
            ['producto_id' => $producto->id, 'cantidad' => 1],
        ],
    ], $feria->id, $usuario->id);
})->throws(ValidationException::class);
