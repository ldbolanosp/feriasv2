<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Usuario\AsignarFeriasUsuarioRequest;
use App\Http\Requests\Usuario\AsignarRolUsuarioRequest;
use App\Http\Requests\Usuario\ResetPasswordUsuarioRequest;
use App\Http\Requests\Usuario\StoreUsuarioRequest;
use App\Http\Requests\Usuario\UpdateUsuarioRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class UsuarioController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = User::query()
            ->with(['ferias', 'roles'])
            ->withCount('ferias');

        if ($request->filled('search')) {
            $search = $request->string('search');

            $query->where(function ($innerQuery) use ($search): void {
                $innerQuery->where('name', 'ilike', "%{$search}%")
                    ->orWhere('email', 'ilike', "%{$search}%");
            });
        }

        if ($request->filled('activo')) {
            $query->where('activo', filter_var($request->activo, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('role')) {
            $query->role($request->string('role')->value());
        }

        $allowedSortFields = ['id', 'name', 'email', 'activo', 'created_at', 'updated_at', 'ferias_count'];
        $sortField = in_array($request->sort, $allowedSortFields) ? $request->sort : 'name';
        $direction = $request->direction === 'desc' ? 'desc' : 'asc';

        $query->orderBy($sortField, $direction);

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return UserResource::collection($query->paginate($perPage));
    }

    public function store(StoreUsuarioRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $role = $validated['role'] ?? null;
        $ferias = $validated['ferias'] ?? [];
        unset($validated['role'], $validated['ferias']);

        $user = User::create($validated);

        if ($role !== null) {
            $user->syncRoles([$role]);
        }

        if ($ferias !== []) {
            $user->ferias()->sync($ferias);
        }

        return response()->json([
            'data' => new UserResource($user->load(['ferias', 'roles'])->loadCount('ferias')),
        ], 201);
    }

    public function show(User $user): UserResource
    {
        return new UserResource($user->load(['ferias', 'roles', 'permissions'])->loadCount('ferias'));
    }

    public function update(UpdateUsuarioRequest $request, User $user): UserResource
    {
        $validated = $request->validated();
        $role = $validated['role'] ?? null;
        $ferias = $validated['ferias'] ?? null;
        unset($validated['role'], $validated['ferias']);

        $user->update($validated);

        if ($role !== null) {
            $user->syncRoles([$role]);
        }

        if (is_array($ferias)) {
            $user->ferias()->sync($ferias);
        }

        if (! $user->activo) {
            $this->cerrarTodasLasSesiones($user);
        }

        return new UserResource($user->load(['ferias', 'roles', 'permissions'])->loadCount('ferias'));
    }

    public function toggle(User $user): JsonResponse
    {
        $user->update(['activo' => ! $user->activo]);

        if (! $user->activo) {
            $this->cerrarTodasLasSesiones($user);
        }

        return response()->json([
            'message' => $user->activo ? 'Usuario activado correctamente.' : 'Usuario desactivado correctamente.',
            'data' => new UserResource($user->load(['ferias', 'roles'])->loadCount('ferias')),
        ]);
    }

    public function delete(User $user): JsonResponse
    {
        DB::transaction(function () use ($user): void {
            $user->update(['activo' => false]);
            $this->cerrarTodasLasSesiones($user);
            $this->revocarTokens($user);
            $user->delete();
        });

        return response()->json(['message' => 'Usuario eliminado correctamente.']);
    }

    public function resetPassword(ResetPasswordUsuarioRequest $request, User $user): JsonResponse
    {
        $user->update([
            'password' => $request->validated('password'),
        ]);

        $this->revocarTokens($user);

        return response()->json(['message' => 'Contraseña restablecida correctamente.']);
    }

    public function asignarRol(AsignarRolUsuarioRequest $request, User $user): JsonResponse
    {
        $user->syncRoles([$request->validated('role')]);

        return response()->json([
            'message' => 'Rol asignado correctamente.',
            'data' => new UserResource($user->load(['ferias', 'roles'])->loadCount('ferias')),
        ]);
    }

    public function asignarFerias(AsignarFeriasUsuarioRequest $request, User $user): JsonResponse
    {
        $user->ferias()->sync($request->validated('ferias'));

        return response()->json([
            'message' => 'Ferias asignadas correctamente.',
            'data' => new UserResource($user->load(['ferias', 'roles'])->loadCount('ferias')),
        ]);
    }

    public function sesiones(Request $request, User $user): JsonResponse
    {
        $currentSessionId = $request->header('X-Session-Id')
            ?? ($request->hasSession() ? $request->session()->getId() : $request->cookie(config('session.cookie')));

        $sessions = DB::table('sessions')
            ->where('user_id', $user->id)
            ->orderByDesc('last_activity')
            ->get()
            ->map(function (object $session) use ($currentSessionId): array {
                $parsed = $this->parseUserAgent($session->user_agent);

                return [
                    'id' => $session->id,
                    'ip_address' => $session->ip_address,
                    'user_agent' => $session->user_agent,
                    'browser' => $parsed['browser'],
                    'platform' => $parsed['platform'],
                    'device' => $parsed['device'],
                    'last_activity' => Carbon::createFromTimestamp($session->last_activity)->toIso8601String(),
                    'is_current' => $session->id === $currentSessionId,
                ];
            })
            ->values()
            ->all();

        return response()->json(['data' => $sessions]);
    }

    public function cerrarSesion(User $user, string $sessionId): JsonResponse
    {
        $query = DB::table('sessions')->where('user_id', $user->id);

        if ($sessionId === 'all') {
            $deleted = $query->delete();

            return response()->json([
                'message' => 'Todas las sesiones fueron cerradas correctamente.',
                'deleted' => $deleted,
            ]);
        }

        $deleted = (clone $query)->where('id', $sessionId)->delete();

        if ($deleted === 0) {
            abort(404, 'La sesión solicitada no existe.');
        }

        return response()->json(['message' => 'Sesión cerrada correctamente.']);
    }

    private function cerrarTodasLasSesiones(User $user): void
    {
        DB::table('sessions')->where('user_id', $user->id)->delete();
    }

    private function revocarTokens(User $user): void
    {
        if (method_exists($user, 'tokens')) {
            $user->tokens()->delete();
        }
    }

    /**
     * @return array{browser:string, platform:string, device:string}
     */
    private function parseUserAgent(?string $userAgent): array
    {
        $agent = strtolower($userAgent ?? '');

        $browser = match (true) {
            str_contains($agent, 'edg') => 'Edge',
            str_contains($agent, 'chrome') => 'Chrome',
            str_contains($agent, 'firefox') => 'Firefox',
            str_contains($agent, 'safari') && ! str_contains($agent, 'chrome') => 'Safari',
            default => 'Desconocido',
        };

        $platform = match (true) {
            str_contains($agent, 'windows') => 'Windows',
            str_contains($agent, 'mac os') || str_contains($agent, 'macintosh') => 'macOS',
            str_contains($agent, 'android') => 'Android',
            str_contains($agent, 'iphone') || str_contains($agent, 'ipad') || str_contains($agent, 'ios') => 'iOS',
            str_contains($agent, 'linux') => 'Linux',
            default => 'Desconocido',
        };

        $device = match (true) {
            str_contains($agent, 'ipad') || str_contains($agent, 'tablet') => 'Tablet',
            str_contains($agent, 'mobile') || str_contains($agent, 'iphone') || str_contains($agent, 'android') => 'Móvil',
            default => 'Escritorio',
        };

        return [
            'browser' => $browser,
            'platform' => $platform,
            'device' => $device,
        ];
    }
}
