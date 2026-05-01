<?php

use App\Models\Configuracion;
use App\Models\Feria;
use App\Models\Participante;
use App\Models\Tarima;
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

function tarimaFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForTarimas(string $role, array $permissions, Feria $feria): User
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

function participanteTarima(Feria $feria): Participante
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

it('lists tarimas for active fair and exposes current price', function (): void {
    $feria = tarimaFeria();
    $otraFeria = tarimaFeria();
    $usuario = authenticateForTarimas('supervisor', ['tarimas.ver'], $feria);
    $participante = participanteTarima($feria);
    $otroParticipante = participanteTarima($otraFeria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($otraFeria->id);

    Configuracion::create([
        'feria_id' => null,
        'clave' => 'precio_tarima',
        'valor' => '5000.00',
    ]);

    Tarima::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => $participante->id,
        'numero_tarima' => 'T-01',
        'cantidad' => 2,
        'precio_unitario' => 5000,
        'total' => 10000,
        'estado' => 'facturado',
    ]);

    Tarima::create([
        'feria_id' => $otraFeria->id,
        'user_id' => $otroUsuario->id,
        'participante_id' => $otroParticipante->id,
        'numero_tarima' => 'T-99',
        'cantidad' => 1,
        'precio_unitario' => 5000,
        'total' => 5000,
        'estado' => 'facturado',
    ]);

    getJson('/api/v1/tarimas', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('precio_actual', 5000)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.numero_tarima', 'T-01')
        ->assertJsonMissing(['numero_tarima' => 'T-99']);
});

it('creates a tarima using configured price and generates its pdf', function (): void {
    Storage::fake('local');

    $feria = tarimaFeria();
    $usuario = authenticateForTarimas('facturador', ['tarimas.crear'], $feria);
    $participante = participanteTarima($feria);

    Configuracion::create([
        'feria_id' => $feria->id,
        'clave' => 'precio_tarima',
        'valor' => '6200.00',
    ]);

    postJson('/api/v1/tarimas', [
        'participante_id' => $participante->id,
        'numero_tarima' => 'A-12',
        'cantidad' => 3,
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertCreated()
        ->assertJsonPath('data.user_id', $usuario->id)
        ->assertJsonPath('data.numero_tarima', 'A-12')
        ->assertJsonPath('data.precio_unitario', '6200.00')
        ->assertJsonPath('data.total', '18600.00')
        ->assertJsonPath('data.estado', 'facturado');

    Storage::disk('local')->assertExists("tickets/{$feria->id}/".now()->format('Y-m-d').'/tarima-1.pdf');
});

it('downloads the tarima pdf and allows cancellation', function (): void {
    Storage::fake('local');

    $feria = tarimaFeria();
    $usuario = authenticateForTarimas('supervisor', ['tarimas.ver', 'tarimas.cancelar'], $feria);
    $participante = participanteTarima($feria);

    $tarima = Tarima::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => $participante->id,
        'numero_tarima' => 'B-01',
        'cantidad' => 1,
        'precio_unitario' => 5000,
        'total' => 5000,
        'estado' => 'facturado',
    ]);

    $tarima->update([
        'pdf_path' => app(\App\Services\PdfTicketService::class)->generarTicketTarima(
            $tarima->load(['feria', 'usuario', 'participante'])
        ),
    ]);

    getJson("/api/v1/tarimas/{$tarima->id}/pdf", ['X-Feria-Id' => (string) $feria->id])
        ->assertOk();

    patchJson("/api/v1/tarimas/{$tarima->id}/cancelar", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.estado', 'cancelado');
});

it('validates that participant belongs to active fair', function (): void {
    $feria = tarimaFeria();
    $otraFeria = tarimaFeria();
    authenticateForTarimas('supervisor', ['tarimas.crear'], $feria);
    $participante = participanteTarima($otraFeria);

    postJson('/api/v1/tarimas', [
        'participante_id' => $participante->id,
        'cantidad' => 1,
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['participante_id']);
});

it('prevents a facturador from cancelling another users tarima', function (): void {
    $feria = tarimaFeria();
    authenticateForTarimas('facturador', ['tarimas.cancelar'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($feria->id);
    $participante = participanteTarima($feria);

    $tarima = Tarima::create([
        'feria_id' => $feria->id,
        'user_id' => $otroUsuario->id,
        'participante_id' => $participante->id,
        'cantidad' => 1,
        'precio_unitario' => 5000,
        'total' => 5000,
        'estado' => 'facturado',
    ]);

    patchJson("/api/v1/tarimas/{$tarima->id}/cancelar", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertNotFound();
});
