<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ConfiguracionController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\FacturaController;
use App\Http\Controllers\Api\FeriaController;
use App\Http\Controllers\Api\InspeccionController;
use App\Http\Controllers\Api\ItemDiagnosticoController;
use App\Http\Controllers\Api\MetodoPagoController;
use App\Http\Controllers\Api\MobileDiagnosticLogController;
use App\Http\Controllers\Api\ParqueoController;
use App\Http\Controllers\Api\ParticipanteController;
use App\Http\Controllers\Api\ProductoController;
use App\Http\Controllers\Api\ReporteController;
use App\Http\Controllers\Api\RolController;
use App\Http\Controllers\Api\SanitarioController;
use App\Http\Controllers\Api\TarimaController;
use App\Http\Controllers\Api\UsuarioController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    // Grupo público
    Route::prefix('auth')->group(function (): void {
        Route::post('login', [AuthController::class, 'login']);

        // Grupo auth (auth:sanctum)
        Route::middleware('auth:sanctum')->group(function (): void {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('user', [AuthController::class, 'user']);
            Route::put('password', [AuthController::class, 'updatePassword']);
            Route::get('mis-ferias', [AuthController::class, 'misFerias']);
            Route::post('seleccionar-feria', [AuthController::class, 'seleccionarFeria']);
            Route::get('mobile-diagnostic-logs', [MobileDiagnosticLogController::class, 'index'])->middleware('permission:configuracion.ver');
            Route::post('mobile-diagnostic-logs', [MobileDiagnosticLogController::class, 'store']);
        });
    });

    // Grupo protegido (auth:sanctum + feria.selected)
    Route::middleware(['auth:sanctum', 'feria.selected'])->group(function (): void {
        // Ferias
        Route::prefix('ferias')->group(function (): void {
            Route::get('/', [FeriaController::class, 'index'])->middleware('permission:ferias.ver');
            Route::post('/', [FeriaController::class, 'store'])->middleware('permission:ferias.crear');
            Route::get('/{feria}', [FeriaController::class, 'show'])->middleware('permission:ferias.ver');
            Route::put('/{feria}', [FeriaController::class, 'update'])->middleware('permission:ferias.editar');
            Route::patch('/{feria}/toggle', [FeriaController::class, 'toggle'])->middleware('permission:ferias.activar');
        });

        // Participantes
        Route::prefix('participantes')->group(function (): void {
            Route::get('/por-feria', [ParticipanteController::class, 'porFeria'])->middleware('permission:participantes.ver');
            Route::get('/', [ParticipanteController::class, 'index'])->middleware('permission:participantes.ver');
            Route::post('/', [ParticipanteController::class, 'store'])->middleware('permission:participantes.crear');
            Route::get('/{participante}', [ParticipanteController::class, 'show'])->middleware('permission:participantes.ver');
            Route::put('/{participante}', [ParticipanteController::class, 'update'])->middleware('permission:participantes.editar');
            Route::patch('/{participante}/carne', [ParticipanteController::class, 'actualizarCarne'])->middleware('permission:participantes.editar');
            Route::patch('/{participante}/toggle', [ParticipanteController::class, 'toggle'])->middleware('permission:participantes.activar');
            Route::get('/{participante}/ferias', [ParticipanteController::class, 'ferias'])->middleware('permission:participantes.ver');
            Route::post('/{participante}/ferias', [ParticipanteController::class, 'asignarFerias'])->middleware('permission:participantes.asignar_feria');
            Route::delete('/{participante}/ferias/{feria}', [ParticipanteController::class, 'desasignarFeria'])->middleware('permission:participantes.asignar_feria');
        });

        // Productos
        Route::prefix('productos')->group(function (): void {
            Route::get('/por-feria', [ProductoController::class, 'porFeria'])->middleware('permission:productos.ver');
            Route::get('/', [ProductoController::class, 'index'])->middleware('permission:productos.ver');
            Route::post('/', [ProductoController::class, 'store'])->middleware('permission:productos.crear');
            Route::get('/{producto}', [ProductoController::class, 'show'])->middleware('permission:productos.ver');
            Route::put('/{producto}', [ProductoController::class, 'update'])->middleware('permission:productos.editar');
            Route::patch('/{producto}/toggle', [ProductoController::class, 'toggle'])->middleware('permission:productos.activar');
            Route::post('/{producto}/precios', [ProductoController::class, 'asignarPrecios'])->middleware('permission:productos.editar');
            Route::delete('/{producto}/precios/{feriaId}', [ProductoController::class, 'eliminarPrecio'])->middleware('permission:productos.editar');
        });

        // Usuarios
        Route::prefix('usuarios')->group(function (): void {
            Route::get('/', [UsuarioController::class, 'index'])->middleware('permission:usuarios.ver');
            Route::post('/', [UsuarioController::class, 'store'])->middleware('permission:usuarios.crear');
            Route::prefix('roles')->group(function (): void {
                Route::get('/', [RolController::class, 'index']);
                Route::put('/{role}', [RolController::class, 'update']);
            });
            Route::get('/{user}', [UsuarioController::class, 'show'])->middleware('permission:usuarios.ver');
            Route::put('/{user}', [UsuarioController::class, 'update'])->middleware('permission:usuarios.editar');
            Route::patch('/{user}/toggle', [UsuarioController::class, 'toggle'])->middleware('permission:usuarios.activar');
            Route::patch('/{user}/reset-password', [UsuarioController::class, 'resetPassword'])->middleware('permission:usuarios.editar');
            Route::delete('/{user}', [UsuarioController::class, 'delete'])->middleware('permission:usuarios.eliminar');
            Route::post('/{user}/roles', [UsuarioController::class, 'asignarRol'])->middleware('permission:usuarios.editar');
            Route::post('/{user}/ferias', [UsuarioController::class, 'asignarFerias'])->middleware('permission:usuarios.editar');
            Route::get('/{user}/sesiones', [UsuarioController::class, 'sesiones'])->middleware('permission:usuarios.sesiones');
            Route::delete('/{user}/sesiones/{sessionId}', [UsuarioController::class, 'cerrarSesion'])->middleware('permission:usuarios.sesiones');
        });

        // Facturas
        Route::prefix('facturas')->group(function (): void {
            Route::get('/', [FacturaController::class, 'index'])->middleware('permission:facturas.ver');
            Route::get('/catalogo/metodos-pago', [MetodoPagoController::class, 'catalogoFacturacion'])->middleware('permission:facturas.ver');
            Route::post('/', [FacturaController::class, 'store'])->middleware('permission:facturas.crear');
            Route::get('/{factura}', [FacturaController::class, 'show'])->middleware('permission:facturas.ver');
            Route::put('/{factura}', [FacturaController::class, 'update'])->middleware('permission:facturas.editar');
            Route::post('/{factura}/facturar', [FacturaController::class, 'facturar'])->middleware('permission:facturas.facturar');
            Route::delete('/{factura}', [FacturaController::class, 'destroy'])->middleware('permission:facturas.eliminar');
            Route::get('/{factura}/pdf', [FacturaController::class, 'pdf'])->middleware('permission:facturas.ver');
            Route::post('/{factura}/reimprimir', [FacturaController::class, 'reimprimir'])->middleware('permission:facturas.ver');
        });

        // Parqueos
        Route::prefix('parqueos')->group(function (): void {
            Route::get('/', [ParqueoController::class, 'index'])->middleware('permission:parqueos.ver');
            Route::post('/', [ParqueoController::class, 'store'])->middleware('permission:parqueos.crear');
            Route::get('/{parqueo}', [ParqueoController::class, 'show'])->middleware('permission:parqueos.ver');
            Route::patch('/{parqueo}/salida', [ParqueoController::class, 'salida'])->middleware('permission:parqueos.salida');
            Route::patch('/{parqueo}/cancelar', [ParqueoController::class, 'cancelar'])->middleware('permission:parqueos.cancelar');
            Route::get('/{parqueo}/pdf', [ParqueoController::class, 'pdf'])->middleware('permission:parqueos.ver');
        });

        // Tarimas
        Route::prefix('tarimas')->group(function (): void {
            Route::get('/', [TarimaController::class, 'index'])->middleware('permission:tarimas.ver');
            Route::post('/', [TarimaController::class, 'store'])->middleware('permission:tarimas.crear');
            Route::get('/{tarima}', [TarimaController::class, 'show'])->middleware('permission:tarimas.ver');
            Route::patch('/{tarima}/cancelar', [TarimaController::class, 'cancelar'])->middleware('permission:tarimas.cancelar');
            Route::get('/{tarima}/pdf', [TarimaController::class, 'pdf'])->middleware('permission:tarimas.ver');
        });

        // Sanitarios
        Route::prefix('sanitarios')->group(function (): void {
            Route::get('/', [SanitarioController::class, 'index'])->middleware('permission:sanitarios.ver');
            Route::post('/', [SanitarioController::class, 'store'])->middleware('permission:sanitarios.crear');
            Route::get('/{sanitario}', [SanitarioController::class, 'show'])->middleware('permission:sanitarios.ver');
            Route::patch('/{sanitario}/cancelar', [SanitarioController::class, 'cancelar'])->middleware('permission:sanitarios.cancelar');
            Route::get('/{sanitario}/pdf', [SanitarioController::class, 'pdf'])->middleware('permission:sanitarios.ver');
        });

        // Items de diagnóstico
        Route::prefix('items-diagnostico')->group(function (): void {
            Route::get('/', [ItemDiagnosticoController::class, 'index'])->middleware('permission:configuracion.ver');
            Route::post('/', [ItemDiagnosticoController::class, 'store'])->middleware('permission:configuracion.editar');
            Route::get('/{itemDiagnostico}', [ItemDiagnosticoController::class, 'show'])->middleware('permission:configuracion.ver');
            Route::put('/{itemDiagnostico}', [ItemDiagnosticoController::class, 'update'])->middleware('permission:configuracion.editar');
            Route::delete('/{itemDiagnostico}', [ItemDiagnosticoController::class, 'destroy'])->middleware('permission:configuracion.editar');
        });

        // Métodos de pago
        Route::prefix('metodos-pago')->group(function (): void {
            Route::get('/', [MetodoPagoController::class, 'index'])->middleware('permission:configuracion.ver');
            Route::post('/', [MetodoPagoController::class, 'store'])->middleware('permission:configuracion.editar');
            Route::put('/{metodoPago}', [MetodoPagoController::class, 'update'])->middleware('permission:configuracion.editar');
            Route::patch('/{metodoPago}/toggle', [MetodoPagoController::class, 'toggle'])->middleware('permission:configuracion.editar');
        });

        // Inspecciones
        Route::prefix('inspecciones')->group(function (): void {
            Route::get('/vencimientos-carne', [InspeccionController::class, 'vencimientosCarne'])->middleware('permission:inspecciones.ver');
            Route::get('/reinspecciones', [InspeccionController::class, 'reinspecciones'])->middleware('permission:inspecciones.ver');
            Route::get('/', [InspeccionController::class, 'index'])->middleware('permission:inspecciones.ver');
            Route::post('/', [InspeccionController::class, 'store'])->middleware('permission:inspecciones.crear');
        });

        // Configuraciones
        Route::prefix('configuraciones')->group(function (): void {
            Route::get('/', [ConfiguracionController::class, 'index'])->middleware('permission:configuracion.ver');
            Route::put('/', [ConfiguracionController::class, 'update'])->middleware('permission:configuracion.editar');
        });

        // Dashboard
        Route::prefix('dashboard')->group(function (): void {
            Route::get('/resumen', [DashboardController::class, 'resumen'])->middleware('permission:dashboard.ver');
            Route::get('/facturacion', [DashboardController::class, 'facturacion'])->middleware('permission:dashboard.ver');
            Route::get('/parqueos', [DashboardController::class, 'parqueos'])->middleware('permission:dashboard.ver');
            Route::get('/recaudacion-diaria', [DashboardController::class, 'recaudacionDiaria'])->middleware('permission:dashboard.ver');
        });

        // Reportes
        Route::prefix('reportes')->group(function (): void {
            Route::get('/facturacion', [ReporteController::class, 'facturacion'])->middleware('permission:facturas.ver');
            Route::get('/parqueos', [ReporteController::class, 'parqueos'])->middleware('permission:parqueos.ver');
        });
    });
});
