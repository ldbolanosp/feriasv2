<?php

use App\Enums\EstadoFactura;
use App\Enums\EstadoParqueo;
use App\Models\Factura;
use App\Models\Feria;
use App\Models\MetodoPago;
use App\Models\Parqueo;
use App\Models\Participante;
use App\Models\Producto;
use App\Models\ProductoPrecio;
use App\Models\Tarima;
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

function cellXml(string $worksheetXml, string $reference): string
{
    preg_match('/<c r="'.preg_quote($reference, '/').'"[^>]*>.*?<\/c>/s', $worksheetXml, $matches);

    expect($matches)->not->toBeEmpty();

    return $matches[0];
}

it('downloads the invoice report as xlsx with one row per invoice line', function (): void {
    $feria = reporteFeria();
    $usuario = authenticateForReportes('supervisor', ['facturas.ver'], $feria);
    $participante = participanteReporte($feria);
    $producto = productoReporte($feria);
    $metodoPago = MetodoPago::query()
        ->where('nombre', 'SINPE')
        ->firstOrFail();

    $factura = Factura::create([
        'feria_id' => $feria->id,
        'participante_id' => $participante->id,
        'user_id' => $usuario->id,
        'metodo_pago_id' => $metodoPago->id,
        'consecutivo' => 'F100005431',
        'es_publico_general' => false,
        'subtotal' => 8040,
        'estado' => EstadoFactura::Facturado,
        'fecha_emision' => '2026-05-03 05:15:00',
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
    expect($worksheetXml)->toContain('2026-05-02');
    expect($worksheetXml)->toContain('Marvin Ruiz Martinez');
    expect($worksheetXml)->toContain('Método de Pago');
    expect($worksheetXml)->toContain('SINPE');
    expect($worksheetXml)->toContain('Combo Artesanía Sencillo');
    expect($worksheetXml)->not->toContain('autoFilter');
    expect($worksheetXml)->toContain('s="1"');
    expect(cellXml($worksheetXml, 'L2'))->toContain('s="2"');
    expect(cellXml($worksheetXml, 'L2'))->toContain('<v>8040</v>');
    expect(cellXml($worksheetXml, 'K2'))->toContain('s="3"');
    expect(cellXml($worksheetXml, 'K2'))->toContain('<v>1</v>');
    expect(cellXml($worksheetXml, 'M2'))->toContain('s="2"');
    expect(cellXml($worksheetXml, 'M2'))->toContain('<v>8040</v>');
    expect(cellXml($worksheetXml, 'N2'))->toContain('s="2"');
    expect(cellXml($worksheetXml, 'N2'))->toContain('<v>8040</v>');
    expect($stylesXml)->toContain('FF0B1F3A');
    expect($stylesXml)->toContain('FFFFFFFF');
    expect($stylesXml)->toContain('formatCode="#,##0.00"');
    expect($stylesXml)->toContain('formatCode="#,##0.0"');
});

it('downloads the parking report as xlsx including charged tariff', function (): void {
    $feria = reporteFeria();
    $usuario = authenticateForReportes('supervisor', ['parqueos.ver'], $feria);

    Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'MCH292',
        'fecha_hora_ingreso' => '2026-05-02 10:56:24',
        'fecha_hora_salida' => '2026-05-02 14:12:10',
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
    expect($worksheetXml)->toContain('2026-05-02');
    expect($worksheetXml)->toContain('ÓSCAR');
    expect(cellXml($worksheetXml, 'G2'))->toContain('s="2"');
    expect(cellXml($worksheetXml, 'G2'))->toContain('<v>2500</v>');
    expect($worksheetXml)->not->toContain('autoFilter');
    expect($stylesXml)->toContain('FF0B1F3A');
});

it('downloads the tarima report as xlsx with charged totals', function (): void {
    $feria = reporteFeria();
    $otraFeria = reporteFeria();
    $usuario = authenticateForReportes('supervisor', ['tarimas.ver'], $feria);
    $participante = participanteReporte($feria);
    $otroParticipante = Participante::create([
        'nombre' => 'Participante Otra Feria',
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => '208880777',
        'activo' => true,
    ]);
    $otroParticipante->ferias()->attach($otraFeria->id);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($otraFeria->id);

    $tarima = Tarima::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => $participante->id,
        'numero_tarima' => 'T-08',
        'cantidad' => 2,
        'precio_unitario' => 5000,
        'total' => 10000,
        'estado' => 'facturado',
        'observaciones' => 'Cobro semanal',
    ]);
    $tarima->forceFill([
        'created_at' => '2026-05-03 05:20:00',
        'updated_at' => '2026-05-03 05:20:00',
    ])->save();

    $tarimaCancelada = Tarima::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => $participante->id,
        'numero_tarima' => 'T-CANCEL',
        'cantidad' => 1,
        'precio_unitario' => 5000,
        'total' => 5000,
        'estado' => 'cancelado',
    ]);
    $tarimaCancelada->forceFill([
        'created_at' => '2026-05-03 05:25:00',
        'updated_at' => '2026-05-03 05:25:00',
    ])->save();

    $tarimaOtraFeria = Tarima::create([
        'feria_id' => $otraFeria->id,
        'user_id' => $otroUsuario->id,
        'participante_id' => $otroParticipante->id,
        'numero_tarima' => 'T-99',
        'cantidad' => 1,
        'precio_unitario' => 5000,
        'total' => 5000,
        'estado' => 'facturado',
    ]);
    $tarimaOtraFeria->forceFill([
        'created_at' => '2026-05-03 05:30:00',
        'updated_at' => '2026-05-03 05:30:00',
    ])->save();

    $response = get('/api/v1/reportes/tarimas?fecha_inicio=2026-05-02&fecha_fin=2026-05-02', [
        'X-Feria-Id' => (string) $feria->id,
    ]);

    $response
        ->assertOk()
        ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ->assertDownload('reporte_tarimas_20260502_20260502.xlsx');

    $worksheetXml = extractWorksheetXml($response->baseResponse->getFile()->getPathname());
    $stylesXml = extractStylesXml($response->baseResponse->getFile()->getPathname());

    expect($worksheetXml)->toContain('Número de Tarima');
    expect($worksheetXml)->toContain('T-08');
    expect($worksheetXml)->toContain('Marvin Ruiz Martinez');
    expect($worksheetXml)->toContain('Cobro semanal');
    expect($worksheetXml)->not->toContain('T-CANCEL');
    expect($worksheetXml)->not->toContain('T-99');
    expect(cellXml($worksheetXml, 'F2'))->toContain('s="3"');
    expect(cellXml($worksheetXml, 'F2'))->toContain('<v>2</v>');
    expect(cellXml($worksheetXml, 'G2'))->toContain('s="2"');
    expect(cellXml($worksheetXml, 'G2'))->toContain('<v>5000</v>');
    expect(cellXml($worksheetXml, 'H2'))->toContain('s="2"');
    expect(cellXml($worksheetXml, 'H2'))->toContain('<v>10000</v>');
    expect($stylesXml)->toContain('FF0B1F3A');
});

it('downloads the card expiration report filtered by fair', function (): void {
    $feria = reporteFeria();
    $otraFeria = reporteFeria();
    authenticateForReportes('supervisor', ['inspecciones.ver'], $feria);
    $actualizador = User::factory()->create([
        'name' => 'Laura Chacón',
    ]);

    $participante = Participante::create([
        'nombre' => 'Ana Gómez',
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => '109990888',
        'numero_carne' => 'CAR-2026-009',
        'fecha_emision_carne' => '2026-04-01',
        'fecha_vencimiento_carne' => '2027-04-01',
        'carne_actualizado_por_user_id' => $actualizador->id,
        'carne_actualizado_en' => '2026-05-10 14:30:00',
        'activo' => true,
    ]);
    $participante->ferias()->attach($feria->id);

    $participanteOtraFeria = Participante::create([
        'nombre' => 'Participante Otra Feria',
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => '208880777',
        'fecha_emision_carne' => '2026-03-01',
        'fecha_vencimiento_carne' => '2027-03-01',
        'activo' => true,
    ]);
    $participanteOtraFeria->ferias()->attach($otraFeria->id);

    $response = get("/api/v1/reportes/vencimiento-carne?feria_id={$feria->id}", [
        'X-Feria-Id' => (string) $feria->id,
    ]);

    $response
        ->assertOk()
        ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ->assertDownload('reporte_vencimiento_carne_'.now('America/Costa_Rica')->format('Ymd').'.xlsx');

    $worksheetXml = extractWorksheetXml($response->baseResponse->getFile()->getPathname());

    expect($worksheetXml)->toContain('Número de Identificación');
    expect($worksheetXml)->toContain('Fecha de Inicio');
    expect($worksheetXml)->toContain('Fecha de Vencimiento');
    expect($worksheetXml)->toContain('Último Usuario que Actualizó Carné');
    expect($worksheetXml)->toContain('109990888');
    expect($worksheetXml)->toContain('Ana Gómez');
    expect($worksheetXml)->toContain('2026-04-01');
    expect($worksheetXml)->toContain('2027-04-01');
    expect($worksheetXml)->toContain('Laura Chacón');
    expect($worksheetXml)->not->toContain('Participante Otra Feria');
});
