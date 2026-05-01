<?php

use App\Models\Feria;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\deleteJson;
use function Pest\Laravel\getJson;
use function Pest\Laravel\patchJson;
use function Pest\Laravel\postJson;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
});

function feriaData(array $overrides = []): array
{
    return array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides);
}

function authenticateForUsuarios(array $permissions, Feria $feria): User
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

it('creates a user with role and fair assignments', function (): void {
    $feria = Feria::create(feriaData(['codigo' => 'FER-001']));
    $otraFeria = Feria::create(feriaData(['codigo' => 'FER-002']));
    authenticateForUsuarios(['usuarios.crear'], $feria);

    Role::findOrCreate('facturador', 'web');

    postJson(
        '/api/v1/usuarios',
        [
            'name' => 'Usuario de Prueba',
            'email' => 'usuario@ferias.cr',
            'password' => 'password',
            'password_confirmation' => 'password',
            'role' => 'facturador',
            'ferias' => [$feria->id, $otraFeria->id],
        ],
        ['X-Feria-Id' => (string) $feria->id]
    )
        ->assertCreated()
        ->assertJsonPath('data.email', 'usuario@ferias.cr')
        ->assertJsonPath('data.role', 'facturador')
        ->assertJsonPath('data.ferias_count', 2);

    $usuario = User::query()->where('email', 'usuario@ferias.cr')->firstOrFail();

    expect($usuario->ferias()->count())->toBe(2);
    expect($usuario->hasRole('facturador'))->toBeTrue();
});

it('deactivates a user and closes all sessions', function (): void {
    $feria = Feria::create(feriaData());
    authenticateForUsuarios(['usuarios.activar'], $feria);

    $usuario = User::factory()->create(['activo' => true]);
    $usuario->ferias()->attach($feria->id);

    DB::table('sessions')->insert([
        [
            'id' => 'sess-uno',
            'user_id' => $usuario->id,
            'ip_address' => '127.0.0.1',
            'user_agent' => 'Mozilla/5.0 Chrome',
            'payload' => 'payload',
            'last_activity' => now()->timestamp,
        ],
        [
            'id' => 'sess-dos',
            'user_id' => $usuario->id,
            'ip_address' => '127.0.0.2',
            'user_agent' => 'Mozilla/5.0 Firefox',
            'payload' => 'payload',
            'last_activity' => now()->subMinute()->timestamp,
        ],
    ]);

    patchJson("/api/v1/usuarios/{$usuario->id}/toggle", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('data.activo', false);

    expect($usuario->fresh()->activo)->toBeFalse();
    expect(DB::table('sessions')->where('user_id', $usuario->id)->count())->toBe(0);
});

it('returns sessions for the user and marks the current session', function (): void {
    $feria = Feria::create(feriaData());
    $usuario = authenticateForUsuarios(['usuarios.sesiones'], $feria);

    $currentSessionId = 'sess-actual';

    DB::table('sessions')->insert([
        [
            'id' => $currentSessionId,
            'user_id' => $usuario->id,
            'ip_address' => '192.168.0.10',
            'user_agent' => 'Mozilla/5.0 (Macintosh) Chrome/135.0',
            'payload' => 'payload',
            'last_activity' => now()->timestamp,
        ],
        [
            'id' => 'sess-secundaria',
            'user_id' => $usuario->id,
            'ip_address' => '192.168.0.11',
            'user_agent' => 'Mozilla/5.0 (Windows NT 10.0) Firefox/124.0',
            'payload' => 'payload',
            'last_activity' => now()->subMinutes(5)->timestamp,
        ],
    ]);

    $this->withCookie(config('session.cookie'), $currentSessionId)
        ->getJson("/api/v1/usuarios/{$usuario->id}/sesiones", [
            'X-Feria-Id' => (string) $feria->id,
            'X-Session-Id' => $currentSessionId,
        ])
        ->assertOk()
        ->assertJsonCount(2, 'data')
        ->assertJsonFragment([
            'id' => $currentSessionId,
            'is_current' => true,
            'browser' => 'Chrome',
        ]);
});

it('soft deletes the user, deactivates it and closes sessions', function (): void {
    $feria = Feria::create(feriaData());
    authenticateForUsuarios(['usuarios.eliminar'], $feria);

    $usuario = User::factory()->create(['activo' => true]);
    $usuario->ferias()->attach($feria->id);
    $usuario->createToken('mobile-app');

    DB::table('sessions')->insert([
        'id' => 'sess-eliminar',
        'user_id' => $usuario->id,
        'ip_address' => '10.0.0.1',
        'user_agent' => 'Mozilla/5.0 Safari',
        'payload' => 'payload',
        'last_activity' => now()->timestamp,
    ]);

    deleteJson("/api/v1/usuarios/{$usuario->id}", [], ['X-Feria-Id' => (string) $feria->id])
        ->assertOk()
        ->assertJsonPath('message', 'Usuario eliminado correctamente.');

    $usuarioEliminado = User::withTrashed()->findOrFail($usuario->id);

    expect($usuarioEliminado->trashed())->toBeTrue();
    expect($usuarioEliminado->activo)->toBeFalse();
    expect(DB::table('sessions')->where('user_id', $usuario->id)->count())->toBe(0);
    expect($usuario->tokens()->count())->toBe(0);
});
