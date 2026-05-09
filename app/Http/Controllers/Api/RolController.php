<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Rol\UpdateRolePermissionsRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolController extends Controller
{
    /**
     * @var list<string>
     */
    private const ROLE_ORDER = [
        'administrador',
        'supervisor',
        'facturador',
        'inspector',
    ];

    public function index(Request $request): JsonResponse
    {
        $this->ensureAdministrator($request);

        $allPermissions = Permission::query()
            ->orderBy('name')
            ->pluck('name');

        $this->syncAdministratorPermissions($allPermissions->all());

        $roles = Role::query()
            ->with('permissions:id,name')
            ->whereIn('name', self::ROLE_ORDER)
            ->get()
            ->sortBy(function (Role $role): int {
                $position = array_search($role->name, self::ROLE_ORDER, true);

                return $position === false ? PHP_INT_MAX : $position;
            })
            ->values()
            ->map(fn (Role $role): array => $this->serializeRole($role, $allPermissions))
            ->all();

        $permissionCatalog = $allPermissions
            ->map(function (string $permission): array {
                [$module, $action] = explode('.', $permission, 2);

                return [
                    'name' => $permission,
                    'module' => $module,
                    'action' => $action,
                ];
            })
            ->all();

        return response()->json([
            'data' => $roles,
            'meta' => [
                'permissions' => $permissionCatalog,
            ],
        ]);
    }

    public function update(UpdateRolePermissionsRequest $request, string $role): JsonResponse
    {
        $this->ensureAdministrator($request);

        if ($role === 'administrador') {
            return response()->json([
                'message' => 'El rol administrador siempre conserva todos los permisos.',
            ], 422);
        }

        $roleModel = Role::query()->where('name', $role)->first();

        if ($roleModel === null) {
            abort(404, 'El rol solicitado no existe.');
        }

        $roleModel->syncPermissions($request->validated('permissions'));

        $allPermissions = Permission::query()
            ->orderBy('name')
            ->pluck('name');

        $this->syncAdministratorPermissions($allPermissions->all());

        return response()->json([
            'message' => 'Permisos del rol actualizados correctamente.',
            'data' => $this->serializeRole($roleModel->load('permissions:id,name'), $allPermissions),
        ]);
    }

    private function ensureAdministrator(Request $request): void
    {
        abort_unless(
            $request->user()?->hasRole('administrador'),
            403,
            'Solo los administradores pueden administrar roles y permisos.'
        );
    }

    /**
     * @param  list<string>  $allPermissions
     */
    private function syncAdministratorPermissions(array $allPermissions): void
    {
        $adminRole = Role::findOrCreate('administrador', 'web');
        $adminRole->syncPermissions($allPermissions);
    }

    /**
     * @param  Collection<int, string>  $allPermissions
     * @return array{name:string, editable:bool, permissions:list<string>, permissions_count:int}
     */
    private function serializeRole(Role $role, $allPermissions): array
    {
        $permissions = $role->name === 'administrador'
            ? $allPermissions->values()->all()
            : $role->permissions->pluck('name')->sort()->values()->all();

        return [
            'name' => $role->name,
            'editable' => $role->name !== 'administrador',
            'permissions' => $permissions,
            'permissions_count' => count($permissions),
        ];
    }
}
