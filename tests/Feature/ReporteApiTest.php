<?php

use App\Enums\EstadoFactura;
use App\Enums\EstadoParqueo;
use App\Models\Factura;
use App\Models\Feria;
use App\Models\Parqueo;
use App\Models\Participante;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\get;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
});

function reporteFeria(): Feria
{
    return Feria::create([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ]);
}

function authenticateForReportes(string $role, array $permissions, Feria $feria): User
{
    foreach ($permissions as $permission) {
        Permission::findOrCreate($permission, 'web');
    }

    Role::findOrCreate($role, 'web');

    $user = User::factory()->create([
        'name' => 'ÓSCAR VEGA MORALES',
    ]);
    $user->assignRole($role);
    $user->givePermissionTo($permissions);
    $user->ferias()->attach($feria->id);

    actingAs($user, 'web');

    return $user;
}

function participanteReporte(Feria $feria): Participante
{
    $participante = Participante::create([
        'nombre' => 'Marvin Ruiz Martinez',
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => '1558044910',
        'correo_electronico' => 'marvin@example.com',
        'telefono' => '61474065',
        'activo' => true,
    ]);

    $participante->ferias()->attach($feria->id);

    return $participante;
}

function productoReporte(Feria $feria): Producto
{
    $producto = Producto::create([
        'codigo' => 'AC01',
        'descripcion' => 'Combo Artesanía Sencillo',
        'activo' => true,
    ]);

    ProductoPrecio::create([
        'producto_id' => $producto->id,
        'feria_id' => $feria->id,
        'precio' => 8040,
    ]);

    return $producto;
}

function extractWorksheetXml(string $xlsxPath): string
{
    $zip = new ZipArchive;
    $opened = $zip->open($xlsxPath);

    expect($opened)->toBeTrue();

    $xml = $zip->getFromName('xl/worksheets/sheet1.xml');
    $zip->close();

    expect($xml)->not->toBeFalse();

    return (string) $xml;
}

function extractStylesXml(string $xlsxPath): string
{
    $zip = new ZipArchive;
    $opened = $zip->open($xlsxPath);

    expect($opened)->toBeTrue();

    $xml = $zip->getFromName('xl/styles.xml');
    $zip->close();

    expect($xml)->not->toBeFalse();

    return (string) $xml;
}

it('downloads the invoice report as xlsx with one row per invoice line', function (): void {
    $feria = reporteFeria();
    $usuario = authenticateForReportes('supervisor', ['facturas.ver'], $feria);
    $participante = participanteReporte($feria);
    $producto = productoReporte($feria);

    $factura = Factura::create([
        'feria_id' => $feria->id,
        'participante_id' => $participante->id,
        'user_id' => $usuario->id,
        'consecutivo' => 'F100005431',
        'es_publico_general' => false,
        'subtotal' => 8040,
        'estado' => EstadoFactura::Facturado,
        'fecha_emision' => '2026-05-02 09:15:00',
    ]);

    $factura->detalles()->create([
        'producto_id' => $producto->id,
        'descripcion_producto' => 'Combo Artesanía Sencillo',
        'cantidad' => 1,
        'precio_unitario' => 8040,
        'subtotal_linea' => 8040,
    ]);

    $response = get('/api/v1/reportes/facturacion?fecha_inicio=2026-05-02&fecha_fin=2026-05-02', [
        'X-Feria-Id' => (string) $feria->id,
    ]);

    $response
        ->assertOk()
        ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ->assertDownload('reporte_facturacion_20260502_20260502.xlsx');

    $worksheetXml = extractWorksheetXml($response->baseResponse->getFile()->getPathname());
    $stylesXml = extractStylesXml($response->baseResponse->getFile()->getPathname());

    expect($worksheetXml)->toContain('Consecutivo');
    expect($worksheetXml)->toContain('F100005431');
    expect($worksheetXml)->toContain('Marvin Ruiz Martinez');
    expect($worksheetXml)->toContain('Combo Artesanía Sencillo');
    expect($worksheetXml)->toContain('8,040.00');
    expect($worksheetXml)->not->toContain('autoFilter');
    expect($worksheetXml)->toContain('s="1"');
    expect($stylesXml)->toContain('FF0B1F3A');
    expect($stylesXml)->toContain('FFFFFFFF');
});

it('downloads the parking report as xlsx including charged tariff', function (): void {
    $feria = reporteFeria();
    $usuario = authenticateForReportes('supervisor', ['parqueos.ver'], $feria);

    Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'MCH292',
        'fecha_hora_ingreso' => '2026-05-02 04:56:24',
        'fecha_hora_salida' => '2026-05-02 08:12:10',
        'tarifa' => 2500,
        'tarifa_tipo' => 'fija',
        'estado' => EstadoParqueo::Finalizado,
    ]);

    $response = get('/api/v1/reportes/parqueos?fecha_inicio=2026-05-02&fecha_fin=2026-05-02', [
        'X-Feria-Id' => (string) $feria->id,
    ]);

    $response
        ->assertOk()
        ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ->assertDownload('reporte_parqueo_20260502_20260502.xlsx');

    $worksheetXml = extractWorksheetXml($response->baseResponse->getFile()->getPathname());
    $stylesXml = extractStylesXml($response->baseResponse->getFile()->getPathname());

    expect($worksheetXml)->toContain('Tarifa cobrada');
    expect($worksheetXml)->toContain('MCH292');
    expect($worksheetXml)->toContain('04:56:24');
    expect($worksheetXml)->toContain('ÓSCAR');
    expect($worksheetXml)->toContain('2,500.00');
    expect($worksheetXml)->not->toContain('autoFilter');
    expect($stylesXml)->toContain('FF0B1F3A');
});
