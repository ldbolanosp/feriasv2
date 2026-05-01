<?php

namespace App\Http\Middleware;

use App\Models\Feria;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureFeriaSelected
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $feriaId = $request->header('X-Feria-Id');

        if (! $feriaId) {
            return response()->json(['message' => 'El encabezado X-Feria-Id es requerido.'], 403);
        }

        $feria = Feria::find($feriaId);

        if (! $feria) {
            return response()->json(['message' => 'La feria especificada no existe.'], 403);
        }

        $user = $request->user();

        $tieneAcceso = $user->hasRole('administrador')
            || $user->ferias()->where('ferias.id', $feriaId)->exists();

        if (! $tieneAcceso) {
            return response()->json(['message' => 'No tienes acceso a esta feria.'], 403);
        }

        return $next($request);
    }
}
