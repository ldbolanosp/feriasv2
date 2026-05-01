<?php

use Illuminate\Support\Facades\Route;

/**
 * Sirve la SPA React compilada (npm run build en /frontend → public/spa/).
 * Si aún no hay build, se muestra la vista de bienvenida de Laravel.
 *
 * Rutas /api/* y /sanctum/* las resuelven routes/api.php y Sanctum; no llegan aquí.
 */
Route::fallback(function () {
    $indiceSpa = public_path('spa/index.html');

    if (file_exists($indiceSpa)) {
        return response()->file($indiceSpa);
    }

    return view('welcome');
});
