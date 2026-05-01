<?php

use App\Models\Feria;
use App\Models\Inspeccion;
use App\Models\ItemDiagnostico;
use App\Models\Participante;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\getJson;
use function Pest\Laravel\patchJson;
use function Pest\Laravel\postJson;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
});

function inspeccionFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForInspeccionModule(array $permissions, Feria $feria): User
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

function participanteInspeccionEnFeria(Feria $feria, array $overrides = []): Participante
{
    $participante = Participante::create(array_merge([
        'nombre' => fake()->name(),
        'tipo_identificacion' => 'fisica',
        'numero_identificacion' => fake()->unique()->numerify('#########'),
        'correo_electronico' => fake()->safeEmail(),
        'numero_carne' => null,
        'fecha_emision_carne' => null,
        'fecha_vencimiento_carne' => null,
        'procedencia' => 'San José',
        'telefono' => fake()->numerify('########'),
        'tipo_sangre' => 'O+',
        'padecimientos' => null,
        'contacto_emergencia_nombre' => null,
        'contacto_emergencia_telefono' => null,
        'activo' => true,
    ], $overrides));

    $participante->ferias()->attach($feria->id);

    return $participante;
}

it('lists diagnostic items catalog', function (): void {
    $feria = inspeccionFeria();
    authenticateForInspeccionModule(['configuracion.ver'], $feria);

    ItemDiagnostico::create(['nombre' => 'Uso de carné visible']);
    ItemDiagnostico::create(['nombre' => 'Zona limpia']);

    getJson('/api/v1/items-diagnostico', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.0.nombre', 'Uso de carné visible')
        ->assertJsonPath('data.1.nombre', 'Zona limpia');
});

it('creates an inspection with item snapshot and summary counts', function (): void {
    $feria = inspeccionFeria(['codigo' => 'FER-INS']);
    $user = authenticateForInspeccionModule(['inspecciones.crear'], $feria);
    $participante = participanteInspeccionEnFeria($feria, ['nombre' => 'María López']);
    $itemA = ItemDiagnostico::create(['nombre' => 'Uso correcto del carné']);
    $itemB = ItemDiagnostico::create(['nombre' => 'Orden del puesto']);

    postJson('/api/v1/inspecciones', [
        'participante_id' => $participante->id,
        'items' => [
            [
                'item_diagnostico_id' => $itemA->id,
                'cumple' => true,
                'observaciones' => 'Todo en orden',
            ],
            [
                'item_diagnostico_id' => $itemB->id,
                'cumple' => false,
                'observaciones' => 'Debe reorganizar productos',
            ],
        ],
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertCreated()
        ->assertJsonPath('data.participante.nombre', 'María López')
        ->assertJsonPath('data.total_items', 2)
        ->assertJsonPath('data.total_incumplidos', 1)
        ->assertJsonPath('data.inspector.id', $user->id)
        ->assertJsonPath('data.items.1.nombre_item', 'Orden del puesto');

    $inspeccion = Inspeccion::query()->firstOrFail();

    expect($inspeccion->items()->count())->toBe(2);
});

it('orders card expirations with expired first', function (): void {
    $feria = inspeccionFeria();
    authenticateForInspeccionModule(['inspecciones.ver'], $feria);

    participanteInspeccionEnFeria($feria, [
        'nombre' => 'Participante Vencido',
        'fecha_vencimiento_carne' => now()->subDays(2)->toDateString(),
    ]);
    participanteInspeccionEnFeria($feria, [
        'nombre' => 'Participante Próximo',
        'fecha_vencimiento_carne' => now()->addDays(5)->toDateString(),
    ]);
    participanteInspeccionEnFeria($feria, [
        'nombre' => 'Participante Lejano',
        'fecha_vencimiento_carne' => now()->addDays(60)->toDateString(),
    ]);

    getJson('/api/v1/inspecciones/vencimientos-carne', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.0.nombre', 'Participante Vencido')
        ->assertJsonPath('data.1.nombre', 'Participante Próximo')
        ->assertJsonPath('data.2.nombre', 'Participante Lejano');
});

it('returns latest failed inspection per participant in reinspection queue', function (): void {
    $feria = inspeccionFeria();
    $user = authenticateForInspeccionModule(['inspecciones.ver'], $feria);
    $participantePendiente = participanteInspeccionEnFeria($feria, ['nombre' => 'Pendiente']);
    $participanteResuelto = participanteInspeccionEnFeria($feria, ['nombre' => 'Resuelto']);

    $inspeccionPendiente = Inspeccion::create([
        'feria_id' => $feria->id,
        'participante_id' => $participantePendiente->id,
        'user_id' => $user->id,
        'reinspeccion_de_id' => null,
        'total_items' => 2,
        'total_incumplidos' => 1,
    ]);
    $inspeccionPendiente->items()->create([
        'item_diagnostico_id' => null,
        'nombre_item' => 'Señalización',
        'cumple' => false,
        'observaciones' => 'Hace falta rotulación',
        'orden' => 1,
    ]);

    $inspeccionFallida = Inspeccion::create([
        'feria_id' => $feria->id,
        'participante_id' => $participanteResuelto->id,
        'user_id' => $user->id,
        'reinspeccion_de_id' => null,
        'total_items' => 1,
        'total_incumplidos' => 1,
    ]);

    Inspeccion::create([
        'feria_id' => $feria->id,
        'participante_id' => $participanteResuelto->id,
        'user_id' => $user->id,
        'reinspeccion_de_id' => $inspeccionFallida->id,
        'total_items' => 1,
        'total_incumplidos' => 0,
    ]);

    getJson('/api/v1/inspecciones/reinspecciones', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.participante.nombre', 'Pendiente')
        ->assertJsonPath('data.0.total_incumplidos', 1)
        ->assertJsonPath('data.0.items.0.nombre_item', 'Señalización');
});

it('updates participant card information from inspections module', function (): void {
    $feria = inspeccionFeria();
    $participante = participanteInspeccionEnFeria($feria, ['nombre' => 'Ana Gómez']);
    authenticateForInspeccionModule(['participantes.editar'], $feria);

    patchJson("/api/v1/participantes/{$participante->id}/carne", [
        'numero_carne' => 'CAR-2026-009',
        'fecha_emision_carne' => '2026-04-01',
        'fecha_vencimiento_carne' => '2027-04-01',
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.nombre', 'Ana Gómez')
        ->assertJsonPath('data.numero_carne', 'CAR-2026-009')
        ->assertJsonPath('data.fecha_vencimiento_carne', '2027-04-01');
});
