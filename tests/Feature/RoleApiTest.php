<?php

use App\Models\Feria;
use App\Models\User;
use Database\Seeders\RolesAndPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\getJson;
use function Pest\Laravel\putJson;

uses(RefreshDatabase::class);

beforeEach(function (): void {
    app(PermissionRegistrar::class)->forgetCachedPermissions();
    $this->seed(RolesAndPermissionsSeeder::class);
});

function rolesFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('ROL-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

function authenticateAdministrator(Feria $feria): User
{
    $user = User::factory()->create();
    $user->assignRole('administrador');
    $user->ferias()->attach($feria->id);

    actingAs($user, 'web');

    return $user;
}

function authenticateNonAdminRoleManager(Feria $feria): User
{
    $user = User::factory()->create();
    $user->assignRole('facturador');
    $user->givePermissionTo(['usuarios.ver', 'usuarios.editar']);
    $user->ferias()->attach($feria->id);

    actingAs($user, 'web');

    return $user;
}

it('lists roles and restores all permissions for administrador', function (): void {
    $feria = rolesFeria();
    authenticateAdministrator($feria);

    $adminRole = Role::findByName('administrador', 'web');
    $adminRole->syncPermissions(['dashboard.ver']);

    $response = getJson('/api/v1/usuarios/roles', ['X-Feria-Id' => (string) $feria->id])
        ->assertSuccessful();

    $administrator = collect($response->json('data'))->firstWhere('name', 'administrador');
    $allPermissions = Permission::query()->pluck('name')->sort()->values()->all();

    expect($administrator)->not->toBeNull();
    expect($administrator['editable'])->toBeFalse();
    expect($administrator['permissions'])->toEqualCanonicalizing($allPermissions);
    expect($adminRole->fresh()->permissions->pluck('name')->all())->toEqualCanonicalizing($allPermissions);
});

it('updates permissions for a non admin role', function (): void {
    $feria = rolesFeria();
    authenticateAdministrator($feria);

    putJson(
        '/api/v1/usuarios/roles/facturador',
        [
            'permissions' => [
                'dashboard.ver',
                'facturas.ver',
                'facturas.crear',
                'parqueos.ver',
            ],
        ],
        ['X-Feria-Id' => (string) $feria->id]
    )
        ->assertSuccessful()
        ->assertJsonPath('data.name', 'facturador')
        ->assertJsonPath('data.editable', true)
        ->assertJsonPath('data.permissions_count', 4);

    $facturador = Role::findByName('facturador', 'web');
    $allPermissions = Permission::query()->pluck('name')->sort()->values()->all();

    expect($facturador->permissions->pluck('name')->all())->toEqualCanonicalizing([
        'dashboard.ver',
        'facturas.ver',
        'facturas.crear',
        'parqueos.ver',
    ]);
    expect(Role::findByName('administrador', 'web')->permissions->pluck('name')->all())
        ->toEqualCanonicalizing($allPermissions);
});

it('forbids non administrators from updating role permissions', function (): void {
    $feria = rolesFeria();
    authenticateNonAdminRoleManager($feria);

    putJson(
        '/api/v1/usuarios/roles/supervisor',
        [
            'permissions' => ['dashboard.ver'],
        ],
        ['X-Feria-Id' => (string) $feria->id]
    )->assertForbidden();
});

it('does not allow editing the administrador role', function (): void {
    $feria = rolesFeria();
    authenticateAdministrator($feria);

    putJson(
        '/api/v1/usuarios/roles/administrador',
        [
            'permissions' => ['dashboard.ver'],
        ],
        ['X-Feria-Id' => (string) $feria->id]
    )
        ->assertUnprocessable()
        ->assertJsonPath('message', 'El rol administrador siempre conserva todos los permisos.');
});
