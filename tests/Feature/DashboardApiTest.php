<?php

use App\Enums\EstadoFactura;
use App\Models\Factura;
use App\Models\Feria;
use App\Models\MetodoPago;
use App\Models\Parqueo;
use App\Models\Participante;
use App\Models\Sanitario;
use App\Models\Tarima;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\getJson;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
});

function dashboardFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForDashboard(string $role, array $permissions, Feria $feria): User
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

function participanteDashboard(Feria $feria): Participante
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

it('returns aggregated summary for the active fair', function (): void {
    $feria = dashboardFeria();
    $usuario = authenticateForDashboard('supervisor', ['dashboard.ver'], $feria);
    $participante = participanteDashboard($feria);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente',
        'subtotal' => 1000,
        'estado' => EstadoFactura::Facturado,
    ]);

    Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'ABC123',
        'tarifa' => 1500,
        'tarifa_tipo' => 'fija',
        'estado' => 'activo',
        'fecha_hora_ingreso' => now(),
    ]);

    Tarima::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => $participante->id,
        'cantidad' => 1,
        'precio_unitario' => 5000,
        'total' => 5000,
        'estado' => 'facturado',
    ]);

    Sanitario::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'cantidad' => 2,
        'precio_unitario' => 500,
        'total' => 1000,
        'estado' => 'facturado',
    ]);

    getJson('/api/v1/dashboard/resumen', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.rol', 'supervisor')
        ->assertJsonPath('data.facturas_count', 1)
        ->assertJsonPath('data.parqueos_count', 1)
        ->assertJsonPath('data.tarimas_count', 1)
        ->assertJsonPath('data.sanitarios_count', 1)
        ->assertJsonPath('data.recaudacion_total', 8500);
});

it('limits dashboard data for facturador to own records', function (): void {
    $feria = dashboardFeria();
    $usuario = authenticateForDashboard('facturador', ['dashboard.ver'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($feria->id);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Mío',
        'subtotal' => 1000,
        'estado' => EstadoFactura::Borrador,
    ]);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $otroUsuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Ajeno',
        'subtotal' => 2000,
        'estado' => EstadoFactura::Borrador,
    ]);

    getJson('/api/v1/dashboard/resumen', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.rol', 'facturador')
        ->assertJsonPath('data.mis_borradores', 1)
        ->assertJsonPath('data.mis_facturas_hoy', 1);
});

it('returns daily revenue combined across modules', function (): void {
    $feria = dashboardFeria();
    $usuario = authenticateForDashboard('supervisor', ['dashboard.ver'], $feria);
    $participante = participanteDashboard($feria);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente',
        'subtotal' => 1000,
        'estado' => EstadoFactura::Facturado,
        'created_at' => now()->subDay(),
        'updated_at' => now()->subDay(),
    ]);

    Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'REV111',
        'tarifa' => 800,
        'tarifa_tipo' => 'fija',
        'estado' => 'activo',
        'fecha_hora_ingreso' => now()->subDay(),
        'created_at' => now()->subDay(),
        'updated_at' => now()->subDay(),
    ]);

    Tarima::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => $participante->id,
        'cantidad' => 1,
        'precio_unitario' => 5000,
        'total' => 5000,
        'estado' => 'facturado',
        'created_at' => now()->subDay(),
        'updated_at' => now()->subDay(),
    ]);

    getJson('/api/v1/dashboard/recaudacion-diaria?fecha_desde='.now()->subDays(2)->format('Y-m-d').'&fecha_hasta='.now()->format('Y-m-d'), [
        'X-Feria-Id' => (string) $feria->id,
    ])
        ->assertOk()
        ->assertJsonFragment([
            'facturas' => 1000,
            'parqueos' => 800,
            'tarimas' => 5000,
            'total' => 6800,
        ]);
});

it('returns cierre totals for a facturador on the selected date', function (): void {
    CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-05-22 02:45:00', 'UTC'));

    $feria = dashboardFeria(['codigo' => 'VLL-001', 'descripcion' => 'La Villa']);
    $usuario = authenticateForDashboard('facturador', ['dashboard.ver'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($feria->id);
    $efectivo = MetodoPago::query()->where('nombre', 'Efectivo')->firstOrFail();
    $sinpe = MetodoPago::query()->where('nombre', 'SINPE')->firstOrFail();
    $tarjeta = MetodoPago::query()->where('nombre', 'Tarjeta de Crédito')->firstOrFail();
    $fechaSeleccionada = CarbonImmutable::create(2026, 5, 21, 0, 0, 0, 'America/Costa_Rica');

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'metodo_pago_id' => $efectivo->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente 1',
        'subtotal' => 1000,
        'estado' => EstadoFactura::Facturado,
        'fecha_emision' => $fechaSeleccionada->setTime(8, 30)->setTimezone('UTC'),
    ]);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'metodo_pago_id' => $sinpe->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente 2',
        'subtotal' => 2000,
        'estado' => EstadoFactura::Facturado,
        'fecha_emision' => $fechaSeleccionada->setTime(9, 15)->setTimezone('UTC'),
    ]);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'metodo_pago_id' => $tarjeta->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Cliente 3',
        'subtotal' => 3000,
        'estado' => EstadoFactura::Facturado,
        'fecha_emision' => $fechaSeleccionada->setTime(10, 0)->setTimezone('UTC'),
    ]);

    Factura::create([
        'feria_id' => $feria->id,
        'user_id' => $otroUsuario->id,
        'metodo_pago_id' => $efectivo->id,
        'es_publico_general' => true,
        'nombre_publico' => 'Ajeno',
        'subtotal' => 9999,
        'estado' => EstadoFactura::Facturado,
        'fecha_emision' => $fechaSeleccionada->setTime(10, 30)->setTimezone('UTC'),
    ]);

    Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'placa' => 'CLS101',
        'tarifa' => 1500,
        'tarifa_tipo' => 'fija',
        'estado' => 'finalizado',
        'fecha_hora_ingreso' => $fechaSeleccionada->setTime(7, 0)->setTimezone('UTC'),
    ]);

    Parqueo::create([
        'feria_id' => $feria->id,
        'user_id' => $otroUsuario->id,
        'placa' => 'OTH202',
        'tarifa' => 4500,
        'tarifa_tipo' => 'fija',
        'estado' => 'finalizado',
        'fecha_hora_ingreso' => $fechaSeleccionada->setTime(7, 30)->setTimezone('UTC'),
    ]);

    getJson('/api/v1/dashboard/cierre?fecha='.$fechaSeleccionada->format('Y-m-d'), [
        'X-Feria-Id' => (string) $feria->id,
    ])
        ->assertOk()
        ->assertJsonPath('data.fecha', $fechaSeleccionada->format('Y-m-d'))
        ->assertJsonPath('data.hora_generacion', '20:45')
        ->assertJsonPath('data.usuario.nombre', $usuario->name)
        ->assertJsonPath('data.feria.codigo', 'VLL-001')
        ->assertJsonPath('data.totales.facturas', 6000)
        ->assertJsonPath('data.totales.parqueos', 1500)
        ->assertJsonPath('data.totales.general', 7500)
        ->assertJsonPath('data.facturas_por_metodo_pago.efectivo', 1000)
        ->assertJsonPath('data.facturas_por_metodo_pago.sinpe', 2000)
        ->assertJsonPath('data.facturas_por_metodo_pago.tarjeta', 3000);

    CarbonImmutable::setTestNow();
});

it('forbids cierre generation for non facturador roles', function (): void {
    $feria = dashboardFeria();
    authenticateForDashboard('supervisor', ['dashboard.ver'], $feria);

    getJson('/api/v1/dashboard/cierre?fecha='.now()->format('Y-m-d'), [
        'X-Feria-Id' => (string) $feria->id,
    ])->assertForbidden();
});
