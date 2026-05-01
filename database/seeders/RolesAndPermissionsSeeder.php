<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            'ferias.ver',
            'ferias.crear',
            'ferias.editar',
            'ferias.activar',
            'participantes.ver',
            'participantes.crear',
            'participantes.editar',
            'participantes.activar',
            'participantes.asignar_feria',
            'productos.ver',
            'productos.crear',
            'productos.editar',
            'productos.activar',
            'usuarios.ver',
            'usuarios.crear',
            'usuarios.editar',
            'usuarios.activar',
            'usuarios.eliminar',
            'usuarios.sesiones',
            'facturas.ver',
            'facturas.crear',
            'facturas.editar',
            'facturas.facturar',
            'facturas.eliminar',
            'parqueos.ver',
            'parqueos.crear',
            'parqueos.salida',
            'parqueos.cancelar',
            'tarimas.ver',
            'tarimas.crear',
            'tarimas.cancelar',
            'sanitarios.ver',
            'sanitarios.crear',
            'sanitarios.cancelar',
            'inspecciones.ver',
            'inspecciones.crear',
            'configuracion.ver',
            'configuracion.editar',
            'dashboard.ver',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        $administrador = Role::firstOrCreate(['name' => 'administrador']);
        $administrador->syncPermissions($permissions);

        $supervisor = Role::firstOrCreate(['name' => 'supervisor']);
        $supervisor->syncPermissions([
            'ferias.ver',
            'participantes.ver',
            'participantes.crear',
            'participantes.editar',
            'participantes.asignar_feria',
            'productos.ver',
            'facturas.ver',
            'facturas.crear',
            'facturas.editar',
            'facturas.facturar',
            'facturas.eliminar',
            'parqueos.ver',
            'parqueos.crear',
            'parqueos.salida',
            'parqueos.cancelar',
            'tarimas.ver',
            'tarimas.crear',
            'tarimas.cancelar',
            'sanitarios.ver',
            'sanitarios.crear',
            'sanitarios.cancelar',
            'inspecciones.ver',
            'inspecciones.crear',
            'configuracion.ver',
            'dashboard.ver',
        ]);

        $facturador = Role::firstOrCreate(['name' => 'facturador']);
        $facturador->syncPermissions([
            'participantes.ver',
            'productos.ver',
            'facturas.ver',
            'facturas.crear',
            'facturas.editar',
            'facturas.facturar',
            'facturas.eliminar',
            'parqueos.ver',
            'parqueos.crear',
            'parqueos.salida',
            'tarimas.ver',
            'tarimas.crear',
            'sanitarios.ver',
            'sanitarios.crear',
            'dashboard.ver',
        ]);

        $inspector = Role::firstOrCreate(['name' => 'inspector']);
        $inspector->syncPermissions([
            'participantes.ver',
            'productos.ver',
            'facturas.ver',
            'parqueos.ver',
            'tarimas.ver',
            'sanitarios.ver',
            'inspecciones.ver',
            'inspecciones.crear',
            'dashboard.ver',
        ]);
    }
}
