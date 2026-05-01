<?php

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    // Grupo público
    Route::prefix('auth')->group(function (): void {
        Route::post('login', [\App\Http\Controllers\Api\AuthController::class, 'login']);

        // Grupo auth (auth:sanctum)
        Route::middleware('auth:sanctum')->group(function (): void {
            Route::post('logout', [\App\Http\Controllers\Api\AuthController::class, 'logout']);
            Route::get('user', [\App\Http\Controllers\Api\AuthController::class, 'user']);
            Route::put('password', [\App\Http\Controllers\Api\AuthController::class, 'updatePassword']);
            Route::get('mis-ferias', [\App\Http\Controllers\Api\AuthController::class, 'misFerias']);
            Route::post('seleccionar-feria', [\App\Http\Controllers\Api\AuthController::class, 'seleccionarFeria']);
        });
    });

    // Grupo protegido (auth:sanctum + feria.selected)
    Route::middleware(['auth:sanctum', 'feria.selected'])->group(function (): void {
        // Ferias
        Route::prefix('ferias')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\FeriaController::class, 'index'])->middleware('permission:ferias.ver');
            Route::post('/', [\App\Http\Controllers\Api\FeriaController::class, 'store'])->middleware('permission:ferias.crear');
            Route::get('/{feria}', [\App\Http\Controllers\Api\FeriaController::class, 'show'])->middleware('permission:ferias.ver');
            Route::put('/{feria}', [\App\Http\Controllers\Api\FeriaController::class, 'update'])->middleware('permission:ferias.editar');
            Route::patch('/{feria}/toggle', [\App\Http\Controllers\Api\FeriaController::class, 'toggle'])->middleware('permission:ferias.activar');
        });

        // Participantes
        Route::prefix('participantes')->group(function (): void {
            Route::get('/por-feria', [\App\Http\Controllers\Api\ParticipanteController::class, 'porFeria'])->middleware('permission:participantes.ver');
            Route::get('/', [\App\Http\Controllers\Api\ParticipanteController::class, 'index'])->middleware('permission:participantes.ver');
            Route::post('/', [\App\Http\Controllers\Api\ParticipanteController::class, 'store'])->middleware('permission:participantes.crear');
            Route::get('/{participante}', [\App\Http\Controllers\Api\ParticipanteController::class, 'show'])->middleware('permission:participantes.ver');
            Route::put('/{participante}', [\App\Http\Controllers\Api\ParticipanteController::class, 'update'])->middleware('permission:participantes.editar');
            Route::patch('/{participante}/carne', [\App\Http\Controllers\Api\ParticipanteController::class, 'actualizarCarne'])->middleware('permission:participantes.editar');
            Route::patch('/{participante}/toggle', [\App\Http\Controllers\Api\ParticipanteController::class, 'toggle'])->middleware('permission:participantes.activar');
            Route::get('/{participante}/ferias', [\App\Http\Controllers\Api\ParticipanteController::class, 'ferias'])->middleware('permission:participantes.ver');
            Route::post('/{participante}/ferias', [\App\Http\Controllers\Api\ParticipanteController::class, 'asignarFerias'])->middleware('permission:participantes.asignar_feria');
            Route::delete('/{participante}/ferias/{feria}', [\App\Http\Controllers\Api\ParticipanteController::class, 'desasignarFeria'])->middleware('permission:participantes.asignar_feria');
        });

        // Productos
        Route::prefix('productos')->group(function (): void {
            Route::get('/por-feria', [\App\Http\Controllers\Api\ProductoController::class, 'porFeria'])->middleware('permission:productos.ver');
            Route::get('/', [\App\Http\Controllers\Api\ProductoController::class, 'index'])->middleware('permission:productos.ver');
            Route::post('/', [\App\Http\Controllers\Api\ProductoController::class, 'store'])->middleware('permission:productos.crear');
            Route::get('/{producto}', [\App\Http\Controllers\Api\ProductoController::class, 'show'])->middleware('permission:productos.ver');
            Route::put('/{producto}', [\App\Http\Controllers\Api\ProductoController::class, 'update'])->middleware('permission:productos.editar');
            Route::patch('/{producto}/toggle', [\App\Http\Controllers\Api\ProductoController::class, 'toggle'])->middleware('permission:productos.activar');
            Route::post('/{producto}/precios', [\App\Http\Controllers\Api\ProductoController::class, 'asignarPrecios'])->middleware('permission:productos.editar');
            Route::delete('/{producto}/precios/{feriaId}', [\App\Http\Controllers\Api\ProductoController::class, 'eliminarPrecio'])->middleware('permission:productos.editar');
        });

        // Usuarios
        Route::prefix('usuarios')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\UsuarioController::class, 'index'])->middleware('permission:usuarios.ver');
            Route::post('/', [\App\Http\Controllers\Api\UsuarioController::class, 'store'])->middleware('permission:usuarios.crear');
            Route::get('/{user}', [\App\Http\Controllers\Api\UsuarioController::class, 'show'])->middleware('permission:usuarios.ver');
            Route::put('/{user}', [\App\Http\Controllers\Api\UsuarioController::class, 'update'])->middleware('permission:usuarios.editar');
            Route::patch('/{user}/toggle', [\App\Http\Controllers\Api\UsuarioController::class, 'toggle'])->middleware('permission:usuarios.activar');
            Route::patch('/{user}/reset-password', [\App\Http\Controllers\Api\UsuarioController::class, 'resetPassword'])->middleware('permission:usuarios.editar');
            Route::delete('/{user}', [\App\Http\Controllers\Api\UsuarioController::class, 'delete'])->middleware('permission:usuarios.eliminar');
            Route::post('/{user}/roles', [\App\Http\Controllers\Api\UsuarioController::class, 'asignarRol'])->middleware('permission:usuarios.editar');
            Route::post('/{user}/ferias', [\App\Http\Controllers\Api\UsuarioController::class, 'asignarFerias'])->middleware('permission:usuarios.editar');
            Route::get('/{user}/sesiones', [\App\Http\Controllers\Api\UsuarioController::class, 'sesiones'])->middleware('permission:usuarios.sesiones');
            Route::delete('/{user}/sesiones/{sessionId}', [\App\Http\Controllers\Api\UsuarioController::class, 'cerrarSesion'])->middleware('permission:usuarios.sesiones');
        });

        // Facturas
        Route::prefix('facturas')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\FacturaController::class, 'index'])->middleware('permission:facturas.ver');
            Route::post('/', [\App\Http\Controllers\Api\FacturaController::class, 'store'])->middleware('permission:facturas.crear');
            Route::get('/{factura}', [\App\Http\Controllers\Api\FacturaController::class, 'show'])->middleware('permission:facturas.ver');
            Route::put('/{factura}', [\App\Http\Controllers\Api\FacturaController::class, 'update'])->middleware('permission:facturas.editar');
            Route::post('/{factura}/facturar', [\App\Http\Controllers\Api\FacturaController::class, 'facturar'])->middleware('permission:facturas.facturar');
            Route::delete('/{factura}', [\App\Http\Controllers\Api\FacturaController::class, 'destroy'])->middleware('permission:facturas.eliminar');
            Route::get('/{factura}/pdf', [\App\Http\Controllers\Api\FacturaController::class, 'pdf'])->middleware('permission:facturas.ver');
            Route::post('/{factura}/reimprimir', [\App\Http\Controllers\Api\FacturaController::class, 'reimprimir'])->middleware('permission:facturas.ver');
        });

        // Parqueos
        Route::prefix('parqueos')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\ParqueoController::class, 'index'])->middleware('permission:parqueos.ver');
            Route::post('/', [\App\Http\Controllers\Api\ParqueoController::class, 'store'])->middleware('permission:parqueos.crear');
            Route::get('/{parqueo}', [\App\Http\Controllers\Api\ParqueoController::class, 'show'])->middleware('permission:parqueos.ver');
            Route::patch('/{parqueo}/salida', [\App\Http\Controllers\Api\ParqueoController::class, 'salida'])->middleware('permission:parqueos.salida');
            Route::patch('/{parqueo}/cancelar', [\App\Http\Controllers\Api\ParqueoController::class, 'cancelar'])->middleware('permission:parqueos.cancelar');
            Route::get('/{parqueo}/pdf', [\App\Http\Controllers\Api\ParqueoController::class, 'pdf'])->middleware('permission:parqueos.ver');
        });

        // Tarimas
        Route::prefix('tarimas')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\TarimaController::class, 'index'])->middleware('permission:tarimas.ver');
            Route::post('/', [\App\Http\Controllers\Api\TarimaController::class, 'store'])->middleware('permission:tarimas.crear');
            Route::get('/{tarima}', [\App\Http\Controllers\Api\TarimaController::class, 'show'])->middleware('permission:tarimas.ver');
            Route::patch('/{tarima}/cancelar', [\App\Http\Controllers\Api\TarimaController::class, 'cancelar'])->middleware('permission:tarimas.cancelar');
            Route::get('/{tarima}/pdf', [\App\Http\Controllers\Api\TarimaController::class, 'pdf'])->middleware('permission:tarimas.ver');
        });

        // Sanitarios
        Route::prefix('sanitarios')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\SanitarioController::class, 'index'])->middleware('permission:sanitarios.ver');
            Route::post('/', [\App\Http\Controllers\Api\SanitarioController::class, 'store'])->middleware('permission:sanitarios.crear');
            Route::get('/{sanitario}', [\App\Http\Controllers\Api\SanitarioController::class, 'show'])->middleware('permission:sanitarios.ver');
            Route::patch('/{sanitario}/cancelar', [\App\Http\Controllers\Api\SanitarioController::class, 'cancelar'])->middleware('permission:sanitarios.cancelar');
            Route::get('/{sanitario}/pdf', [\App\Http\Controllers\Api\SanitarioController::class, 'pdf'])->middleware('permission:sanitarios.ver');
        });

        // Items de diagnóstico
        Route::prefix('items-diagnostico')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\ItemDiagnosticoController::class, 'index'])->middleware('permission:configuracion.ver');
            Route::post('/', [\App\Http\Controllers\Api\ItemDiagnosticoController::class, 'store'])->middleware('permission:configuracion.editar');
            Route::get('/{itemDiagnostico}', [\App\Http\Controllers\Api\ItemDiagnosticoController::class, 'show'])->middleware('permission:configuracion.ver');
            Route::put('/{itemDiagnostico}', [\App\Http\Controllers\Api\ItemDiagnosticoController::class, 'update'])->middleware('permission:configuracion.editar');
            Route::delete('/{itemDiagnostico}', [\App\Http\Controllers\Api\ItemDiagnosticoController::class, 'destroy'])->middleware('permission:configuracion.editar');
        });

        // Inspecciones
        Route::prefix('inspecciones')->group(function (): void {
            Route::get('/vencimientos-carne', [\App\Http\Controllers\Api\InspeccionController::class, 'vencimientosCarne'])->middleware('permission:inspecciones.ver');
            Route::get('/reinspecciones', [\App\Http\Controllers\Api\InspeccionController::class, 'reinspecciones'])->middleware('permission:inspecciones.ver');
            Route::get('/', [\App\Http\Controllers\Api\InspeccionController::class, 'index'])->middleware('permission:inspecciones.ver');
            Route::post('/', [\App\Http\Controllers\Api\InspeccionController::class, 'store'])->middleware('permission:inspecciones.crear');
        });

        // Configuraciones
        Route::prefix('configuraciones')->group(function (): void {
            Route::get('/', [\App\Http\Controllers\Api\ConfiguracionController::class, 'index'])->middleware('permission:configuracion.ver');
            Route::put('/', [\App\Http\Controllers\Api\ConfiguracionController::class, 'update'])->middleware('permission:configuracion.editar');
        });

        // Dashboard
        Route::prefix('dashboard')->group(function (): void {
            Route::get('/resumen', [\App\Http\Controllers\Api\DashboardController::class, 'resumen'])->middleware('permission:dashboard.ver');
            Route::get('/facturacion', [\App\Http\Controllers\Api\DashboardController::class, 'facturacion'])->middleware('permission:dashboard.ver');
            Route::get('/parqueos', [\App\Http\Controllers\Api\DashboardController::class, 'parqueos'])->middleware('permission:dashboard.ver');
            Route::get('/recaudacion-diaria', [\App\Http\Controllers\Api\DashboardController::class, 'recaudacionDiaria'])->middleware('permission:dashboard.ver');
        });
    });
});
