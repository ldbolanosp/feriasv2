<?php

use App\Models\Configuracion;
use App\Models\Feria;
use App\Models\Participante;
use App\Models\Sanitario;
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

function sanitarioFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateForSanitarios(string $role, array $permissions, Feria $feria): User
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

function participanteSanitario(Feria $feria): Participante
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

it('lists sanitarios for active fair and exposes current price', function (): void {
    $feria = sanitarioFeria();
    $otraFeria = sanitarioFeria();
    $usuario = authenticateForSanitarios('supervisor', ['sanitarios.ver'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($otraFeria->id);

    Configuracion::create([
        'feria_id' => null,
        'clave' => 'precio_sanitario',
        'valor' => '750.00',
    ]);

    Sanitario::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => null,
        'cantidad' => 2,
        'precio_unitario' => 750,
        'total' => 1500,
        'estado' => 'facturado',
    ]);

    Sanitario::create([
        'feria_id' => $otraFeria->id,
        'user_id' => $otroUsuario->id,
        'participante_id' => null,
        'cantidad' => 1,
        'precio_unitario' => 750,
        'total' => 750,
        'estado' => 'facturado',
    ]);

    getJson('/api/v1/sanitarios', ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('precio_actual', 750)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.es_publico', true);
});

it('creates a sanitario with optional public use and generates its pdf', function (): void {
    Storage::fake('local');

    $feria = sanitarioFeria();
    $usuario = authenticateForSanitarios('facturador', ['sanitarios.crear'], $feria);

    Configuracion::create([
        'feria_id' => $feria->id,
        'clave' => 'precio_sanitario',
        'valor' => '900.00',
    ]);

    postJson('/api/v1/sanitarios', [
        'cantidad' => 3,
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertCreated()
        ->assertJsonPath('data.user_id', $usuario->id)
        ->assertJsonPath('data.participante_id', null)
        ->assertJsonPath('data.precio_unitario', '900.00')
        ->assertJsonPath('data.total', '2700.00')
        ->assertJsonPath('data.es_publico', true);

    Storage::disk('local')->assertExists("tickets/{$feria->id}/".now()->format('Y-m-d').'/sanitario-1.pdf');
});

it('supports participant linked sanitario and allows cancellation', function (): void {
    Storage::fake('local');

    $feria = sanitarioFeria();
    $usuario = authenticateForSanitarios('supervisor', ['sanitarios.ver', 'sanitarios.cancelar'], $feria);
    $participante = participanteSanitario($feria);

    $sanitario = Sanitario::create([
        'feria_id' => $feria->id,
        'user_id' => $usuario->id,
        'participante_id' => $participante->id,
        'cantidad' => 1,
        'precio_unitario' => 500,
        'total' => 500,
        'estado' => 'facturado',
    ]);

    $sanitario->update([
        'pdf_path' => app(\App\Services\PdfTicketService::class)->generarTicketSanitario(
            $sanitario->load(['feria', 'usuario', 'participante'])
        ),
    ]);

    getJson("/api/v1/sanitarios/{$sanitario->id}/pdf", ['X-Feria-Id' => (string) $feria->id])
        ->assertOk();

    patchJson("/api/v1/sanitarios/{$sanitario->id}/cancelar", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.estado', 'cancelado')
        ->assertJsonPath('data.es_publico', false);
});

it('validates participant fair when participant is provided', function (): void {
    $feria = sanitarioFeria();
    $otraFeria = sanitarioFeria();
    authenticateForSanitarios('supervisor', ['sanitarios.crear'], $feria);
    $participante = participanteSanitario($otraFeria);

    postJson('/api/v1/sanitarios', [
        'participante_id' => $participante->id,
        'cantidad' => 1,
    ], ['X-Feria-Id' => (string) $feria->id])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['participante_id']);
});

it('prevents a facturador from cancelling another users sanitario', function (): void {
    $feria = sanitarioFeria();
    authenticateForSanitarios('facturador', ['sanitarios.cancelar'], $feria);
    $otroUsuario = User::factory()->create();
    $otroUsuario->ferias()->attach($feria->id);

    $sanitario = Sanitario::create([
        'feria_id' => $feria->id,
        'user_id' => $otroUsuario->id,
        'participante_id' => null,
        'cantidad' => 1,
        'precio_unitario' => 500,
        'total' => 500,
        'estado' => 'facturado',
    ]);

    patchJson("/api/v1/sanitarios/{$sanitario->id}/cancelar", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertNotFound();
});
