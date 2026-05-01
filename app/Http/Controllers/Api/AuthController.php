<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\UpdatePasswordRequest;
use App\Models\Feria;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    public function login(LoginRequest $request): JsonResponse
    {
        if (! Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['message' => 'Credenciales incorrectas.'], 401);
        }

        $user = Auth::user();

        if (! $user->activo || $user->trashed()) {
            Auth::logout();

            return response()->json(['message' => 'La cuenta está desactivada.'], 403);
        }

        $deviceName = $request->validated('device_name');

        if (is_string($deviceName) && $deviceName !== '') {
            $user->tokens()
                ->where('name', $deviceName)
                ->delete();

            $token = $user->createToken($deviceName)->plainTextToken;

            return response()->json($this->buildUserPayload($user, $token));
        }

        $request->session()->regenerate();

        return response()->json($this->buildUserPayload($user));
    }

    public function logout(Request $request): JsonResponse
    {
        $accessToken = $request->user()?->currentAccessToken();

        if ($accessToken instanceof PersonalAccessToken) {
            $accessToken->delete();
        } else {
            Auth::guard('web')->logout();

            if ($request->hasSession()) {
                $request->session()->invalidate();
                $request->session()->regenerateToken();
            }
        }

        return response()->json(['message' => 'Sesión cerrada correctamente.']);
    }

    public function user(Request $request): JsonResponse
    {
        return response()->json($this->buildUserPayload($request->user()));
    }

    public function updatePassword(UpdatePasswordRequest $request): JsonResponse
    {
        $request->user()->update([
            'password' => bcrypt($request->password),
        ]);

        return response()->json(['message' => 'Contraseña actualizada correctamente.']);
    }

    public function misFerias(Request $request): JsonResponse
    {
        $ferias = $request->user()
            ->ferias()
            ->where('activa', true)
            ->get(['ferias.id', 'ferias.codigo', 'ferias.descripcion', 'ferias.facturacion_publico', 'ferias.activa']);

        return response()->json(['data' => $ferias]);
    }

    public function seleccionarFeria(Request $request): JsonResponse
    {
        $request->validate([
            'feria_id' => ['required', 'integer', 'exists:ferias,id'],
        ]);

        $user = $request->user();
        $tieneAcceso = $user->hasRole('administrador')
            || $user->ferias()->where('ferias.id', $request->feria_id)->exists();

        if (! $tieneAcceso) {
            return response()->json(['message' => 'No tienes acceso a esta feria.'], 403);
        }

        $feria = Feria::find($request->feria_id);

        if (! $feria->activa) {
            return response()->json(['message' => 'La feria seleccionada no está activa.'], 422);
        }

        return response()->json([
            'message' => 'Feria seleccionada correctamente.',
            'feria' => $feria->only(['id', 'codigo', 'descripcion', 'facturacion_publico']),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function buildUserPayload(User $user, ?string $token = null): array
    {
        $payload = [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'activo' => $user->activo,
            ],
            'roles' => $user->getRoleNames(),
            'permisos' => $user->getAllPermissions()->pluck('name'),
            'ferias' => $user->ferias()->where('activa', true)->get(['ferias.id', 'ferias.codigo', 'ferias.descripcion', 'ferias.facturacion_publico']),
        ];

        if ($token !== null) {
            $payload['token'] = $token;
            $payload['token_type'] = 'Bearer';
        }

        return $payload;
    }
}
