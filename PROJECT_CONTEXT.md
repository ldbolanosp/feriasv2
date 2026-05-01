# PROJECT_CONTEXT.md — Ferias del Agricultor

> **Este archivo es la fuente de verdad del proyecto.** Todo agente de AI debe leer este archivo antes de generar código. Contiene la arquitectura, modelo de datos, API, UI y roles del sistema completo.

---

## 1. RESUMEN DEL PROYECTO

Sistema de administración de Ferias del Agricultor para Costa Rica. Permite administrar y alquilar espacios en diferentes ferias del país, gestionar parqueos, tarimas, sanitarios y facturación. Prioridad: agilidad operativa por alto volumen de transacciones en poco tiempo.

---

## 2. STACK TECNOLÓGICO

| Capa | Tecnología |
|------|-----------|
| Backend / API | Laravel 13+ |
| Base de Datos | PostgreSQL 16+ |
| Autenticación | Laravel Sanctum (cookies SPA + tokens móvil) |
| Autorización | Spatie Laravel Permission |
| Frontend Web | React 18+ SPA (Vite) |
| UI Components | shadcn/ui + Tailwind CSS |
| Estado (servidor) | TanStack Query (React Query) |
| Estado (cliente) | Zustand |
| Iconos | Lucide React |
| Gráficos | Recharts |
| PDF / Tiquetes | DOMPDF o Browsershot |
| Build Tool | Vite |
| Hosting | Laravel Cloud |
| App Móvil (Fase 2) | Flutter |

---

## 3. ARQUITECTURA

### 3.1 Tipo
API REST centralizada con clientes desacoplados:
- **Laravel API**: toda la lógica de negocio, validaciones, autorización, PDFs, acceso a BD.
- **React SPA**: interfaz web que consume la API vía HTTP. Archivos estáticos.
- **Flutter (Fase 2)**: app Android que consume la misma API.

### 3.2 Monorepo
Todo vive en un solo repositorio. La SPA React está dentro del proyecto Laravel en `/frontend`.

### 3.3 Principios de Diseño
1. **API-First**: toda funcionalidad se expone como endpoint REST antes de construir la UI.
2. **Soft Delete**: ningún registro crítico se elimina físicamente. SoftDeletes en modelos de auditoría.
3. **Scope por Feria**: toda operación está contextualizada a la feria activa del usuario.
4. **Transacciones Atómicas**: consecutivos de facturación usan DB::transaction con locks.
5. **Validación Doble**: frontend (React Hook Form + Zod) y backend (Form Requests).
6. **Convención sobre Configuración**: seguir convenciones de Laravel y React.

---

## 4. ESTRUCTURA DEL PROYECTO

```
ferias-system/
├── app/
│   ├── Http/
│   │   ├── Controllers/Api/
│   │   │   ├── AuthController.php
│   │   │   ├── FeriaController.php
│   │   │   ├── ParticipanteController.php
│   │   │   ├── ProductoController.php
│   │   │   ├── UsuarioController.php
│   │   │   ├── FacturaController.php
│   │   │   ├── ParqueoController.php
│   │   │   ├── TarimaController.php
│   │   │   ├── SanitarioController.php
│   │   │   ├── ConfiguracionController.php
│   │   │   └── DashboardController.php
│   │   ├── Middleware/
│   │   │   ├── EnsureFeriaSelected.php
│   │   │   └── CheckModulePermission.php
│   │   └── Requests/
│   │       ├── Feria/
│   │       ├── Participante/
│   │       ├── Factura/
│   │       └── ...
│   ├── Models/
│   │   ├── User.php
│   │   ├── Feria.php
│   │   ├── Participante.php
│   │   ├── Producto.php
│   │   ├── ProductoPrecio.php
│   │   ├── Factura.php
│   │   ├── FacturaDetalle.php
│   │   ├── ConsecutivoFeria.php
│   │   ├── Parqueo.php
│   │   ├── Tarima.php
│   │   ├── Sanitario.php
│   │   └── Configuracion.php
│   ├── Services/
│   │   ├── FacturacionService.php
│   │   ├── ConsecutivoService.php
│   │   ├── ParqueoService.php
│   │   └── PdfTicketService.php
│   ├── Policies/
│   └── Enums/
│       ├── EstadoFactura.php
│       ├── TipoIdentificacion.php
│       └── TipoSangre.php
├── database/
│   ├── migrations/
│   ├── seeders/
│   └── factories/
├── routes/
│   └── api.php
├── resources/views/pdf/
│   ├── ticket-factura.blade.php
│   ├── ticket-parqueo.blade.php
│   └── ticket-tarima.blade.php
├── frontend/                    ← SPA React
│   ├── src/
│   │   ├── components/
│   │   │   ├── ui/              ← shadcn/ui
│   │   │   ├── layout/
│   │   │   └── shared/
│   │   ├── pages/
│   │   │   ├── auth/
│   │   │   ├── dashboard/
│   │   │   ├── ferias/
│   │   │   ├── participantes/
│   │   │   ├── productos/
│   │   │   ├── usuarios/
│   │   │   ├── facturacion/
│   │   │   ├── parqueos/
│   │   │   ├── tarimas/
│   │   │   └── sanitarios/
│   │   ├── hooks/
│   │   ├── services/            ← API client (axios)
│   │   ├── stores/              ← Zustand stores
│   │   ├── lib/
│   │   └── types/
│   ├── index.html
│   ├── vite.config.ts
│   ├── tailwind.config.ts
│   ├── tsconfig.json
│   └── package.json
├── .env
├── composer.json
└── README.md
```

---

## 5. CONVENCIONES DE NOMBRADO

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Modelos Laravel | PascalCase, singular, español | Factura, Participante |
| Tablas BD | snake_case, plural, español | facturas, participantes |
| Controllers | PascalCase + Controller | FacturaController |
| Migraciones | snake_case con timestamp | create_facturas_table |
| API Routes | kebab-case, plural, /api/v1 | /api/v1/facturas |
| React Components | PascalCase | FacturaForm.tsx |
| React Pages | PascalCase | FacturacionPage.tsx |
| Hooks | camelCase con use | useFacturas.ts |
| Stores Zustand | camelCase con Store | feriaStore.ts |
| Types/Interfaces | PascalCase | IFactura, FacturaType |
| Enums Laravel | PascalCase | EstadoFactura |
| Services | PascalCase + Service | FacturacionService |

---

## 6. MODELO DE DATOS

### 6.1 ferias
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| codigo | varchar(20) | No | — | Código alfanumérico único |
| descripcion | varchar(255) | No | — | Nombre descriptivo |
| facturacion_publico | boolean | No | false | Permite facturación a público general |
| activa | boolean | No | true | Estado activo/inactivo |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |
| deleted_at | timestamp | Sí | null | Soft delete |

**Unique:** codigo | **Soft Delete:** Sí

### 6.2 participantes
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| nombre | varchar(255) | No | — | Nombre completo |
| tipo_identificacion | varchar(20) | No | — | fisica, juridica, dimex, nite |
| numero_identificacion | varchar(50) | No | — | Número único |
| correo_electronico | varchar(255) | Sí | null | |
| numero_carne | varchar(50) | Sí | null | |
| fecha_emision_carne | date | Sí | null | |
| fecha_vencimiento_carne | date | Sí | null | |
| procedencia | varchar(255) | Sí | null | |
| telefono | varchar(30) | Sí | null | |
| tipo_sangre | varchar(5) | Sí | null | A+, A-, B+, B-, AB+, AB-, O+, O- |
| padecimientos | text | Sí | null | |
| contacto_emergencia_nombre | varchar(255) | Sí | null | |
| contacto_emergencia_telefono | varchar(30) | Sí | null | |
| activo | boolean | No | true | |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |
| deleted_at | timestamp | Sí | null | Soft delete |

**Unique:** numero_identificacion | **Soft Delete:** Sí

### 6.3 feria_participante (pivot)
| Campo | Tipo | Nulo | Descripción |
|-------|------|------|-------------|
| id | bigint | No | PK |
| feria_id | bigint FK | No | → ferias.id |
| participante_id | bigint FK | No | → participantes.id |
| created_at | timestamp | No | |
| updated_at | timestamp | No | |

**Unique compuesto:** (feria_id, participante_id)

### 6.4 productos
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| codigo | varchar(20) | No | — | Código único alfanumérico |
| descripcion | varchar(255) | No | — | |
| activo | boolean | No | true | |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |
| deleted_at | timestamp | Sí | null | Soft delete |

**Unique:** codigo | **Soft Delete:** Sí

### 6.5 producto_precios
| Campo | Tipo | Nulo | Descripción |
|-------|------|------|-------------|
| id | bigint | No | PK |
| producto_id | bigint FK | No | → productos.id |
| feria_id | bigint FK | No | → ferias.id |
| precio | decimal(12,2) | No | Precio en esta feria |
| created_at | timestamp | No | |
| updated_at | timestamp | No | |

**Unique compuesto:** (producto_id, feria_id)

### 6.6 users
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| name | varchar(255) | No | — | |
| email | varchar(255) | No | — | Único |
| password | varchar(255) | No | — | Hasheada |
| email_verified_at | timestamp | Sí | null | |
| activo | boolean | No | true | |
| remember_token | varchar(100) | Sí | null | |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |
| deleted_at | timestamp | Sí | null | Soft delete |

**Unique:** email | **Soft Delete:** Sí

### 6.7 feria_user (pivot)
| Campo | Tipo | Nulo | Descripción |
|-------|------|------|-------------|
| id | bigint | No | PK |
| feria_id | bigint FK | No | → ferias.id |
| user_id | bigint FK | No | → users.id |
| created_at | timestamp | No | |
| updated_at | timestamp | No | |

**Unique compuesto:** (feria_id, user_id)

### 6.8 facturas
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| feria_id | bigint FK | No | — | Feria de la factura |
| participante_id | bigint FK | Sí | null | Null si público general |
| user_id | bigint FK | No | — | Usuario que creó |
| consecutivo | varchar(20) | Sí | null | F400000001, se asigna al facturar |
| es_publico_general | boolean | No | false | |
| nombre_publico | varchar(255) | Sí | null | Nombre manual si público |
| tipo_puesto | varchar(100) | Sí | null | Texto libre |
| numero_puesto | varchar(50) | Sí | null | |
| subtotal | decimal(12,2) | No | 0 | Suma de detalles |
| monto_pago | decimal(12,2) | Sí | null | Monto entregado |
| monto_cambio | decimal(12,2) | Sí | null | Cambio |
| observaciones | text | Sí | null | |
| estado | varchar(20) | No | borrador | borrador, facturado, eliminado |
| fecha_emision | timestamp | Sí | null | Al facturar |
| pdf_path | varchar(500) | Sí | null | Ruta del PDF |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |
| deleted_at | timestamp | Sí | null | |

**Unique:** consecutivo (parcial, no null) | **Soft Delete:** Sí

**Reglas de negocio:**
- Consecutivo solo se genera al ejecutar acción Facturar, no al guardar borrador
- Formato: F + ID feria + secuencial 8 dígitos (F400000001)
- Generación con DB::transaction + lockForUpdate
- Si es_publico_general=true → participante_id=null, nombre_publico requerido
- Si estado=facturado → no se puede editar
- Acción Eliminar cambia estado a 'eliminado'
- Facturador solo ve sus facturas, admin ve todas

### 6.9 factura_detalles
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| factura_id | bigint FK | No | — | → facturas.id (CASCADE) |
| producto_id | bigint FK | No | — | → productos.id |
| descripcion_producto | varchar(255) | No | — | Snapshot |
| cantidad | decimal(10,1) | No | 1 | Mín 1, incrementos 0.5 |
| precio_unitario | decimal(12,2) | No | — | Snapshot del precio |
| subtotal_linea | decimal(12,2) | No | — | cantidad * precio_unitario |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |

### 6.10 consecutivos_feria
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| feria_id | bigint FK | No | — | Único |
| ultimo_consecutivo | integer | No | 0 | Último secuencial usado |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |

**Lógica:**
```php
DB::transaction(function () use ($feriaId) {
    $reg = ConsecutivoFeria::where('feria_id', $feriaId)->lockForUpdate()->first();
    $reg->ultimo_consecutivo++;
    $reg->save();
    return 'F' . $feriaId . str_pad($reg->ultimo_consecutivo, 8, '0', STR_PAD_LEFT);
});
```

### 6.11 parqueos
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| feria_id | bigint FK | No | — | |
| user_id | bigint FK | No | — | |
| placa | varchar(20) | No | — | |
| fecha_hora_ingreso | timestamp | No | now() | |
| fecha_hora_salida | timestamp | Sí | null | Futuro |
| tarifa | decimal(12,2) | No | — | |
| tarifa_tipo | varchar(20) | No | fija | fija, por_hora (futuro) |
| estado | varchar(20) | No | activo | activo, finalizado, cancelado |
| observaciones | text | Sí | null | |
| pdf_path | varchar(500) | Sí | null | |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |

### 6.12 tarimas
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| feria_id | bigint FK | No | — | |
| user_id | bigint FK | No | — | |
| participante_id | bigint FK | No | — | |
| numero_tarima | varchar(50) | Sí | null | Opcional |
| cantidad | integer | No | 1 | |
| precio_unitario | decimal(12,2) | No | — | |
| total | decimal(12,2) | No | — | cantidad * precio |
| estado | varchar(20) | No | facturado | facturado, cancelado |
| observaciones | text | Sí | null | |
| pdf_path | varchar(500) | Sí | null | |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |

### 6.13 sanitarios
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| feria_id | bigint FK | No | — | |
| user_id | bigint FK | No | — | |
| participante_id | bigint FK | Sí | null | Puede ser uso público |
| cantidad | integer | No | 1 | |
| precio_unitario | decimal(12,2) | No | — | |
| total | decimal(12,2) | No | — | |
| estado | varchar(20) | No | facturado | facturado, cancelado |
| observaciones | text | Sí | null | |
| pdf_path | varchar(500) | Sí | null | |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |

### 6.14 configuraciones
| Campo | Tipo | Nulo | Default | Descripción |
|-------|------|------|---------|-------------|
| id | bigint | No | auto | PK |
| feria_id | bigint FK | Sí | null | null = global |
| clave | varchar(100) | No | — | |
| valor | text | No | — | |
| descripcion | varchar(255) | Sí | null | |
| created_at | timestamp | No | now() | |
| updated_at | timestamp | No | now() | |

**Unique compuesto:** (feria_id, clave)

**Configuraciones iniciales:** tarifa_parqueo=1000.00, precio_tarima=5000.00, precio_sanitario=500.00, moneda=CRC

### 6.15 sessions (Laravel)
Tabla estándar de sessions para almacenar sesiones en BD. Campos: id, user_id, ip_address, user_agent, payload, last_activity.

### 6.16 Tablas Spatie Permission
Automáticas: roles, permissions, model_has_roles, model_has_permissions, role_has_permissions.

---

## 7. ENUMS

### EstadoFactura
`borrador` | `facturado` | `eliminado`

### TipoIdentificacion
`fisica` | `juridica` | `dimex` | `nite`

### TipoSangre
`A+` | `A-` | `B+` | `B-` | `AB+` | `AB-` | `O+` | `O-`

### EstadoParqueo
`activo` | `finalizado` | `cancelado`

### TarifaTipo
`fija` | `por_hora`

---

## 8. MODELOS ELOQUENT — RELACIONES

| Modelo | Traits | Relaciones |
|--------|--------|-----------|
| User | HasRoles, SoftDeletes | belongsToMany(Feria), hasMany(Factura), hasMany(Parqueo) |
| Feria | SoftDeletes | belongsToMany(User), belongsToMany(Participante), hasMany(Factura), hasMany(ProductoPrecio) |
| Participante | SoftDeletes | belongsToMany(Feria), hasMany(Factura), hasMany(Tarima) |
| Producto | SoftDeletes | hasMany(ProductoPrecio), hasMany(FacturaDetalle) |
| ProductoPrecio | — | belongsTo(Producto), belongsTo(Feria) |
| Factura | SoftDeletes | belongsTo(Feria), belongsTo(Participante), belongsTo(User), hasMany(FacturaDetalle) |
| FacturaDetalle | — | belongsTo(Factura), belongsTo(Producto) |
| ConsecutivoFeria | — | belongsTo(Feria) |
| Parqueo | — | belongsTo(Feria), belongsTo(User) |
| Tarima | — | belongsTo(Feria), belongsTo(User), belongsTo(Participante) |
| Sanitario | — | belongsTo(Feria), belongsTo(User), belongsTo(Participante) |
| Configuracion | — | belongsTo(Feria) |

---

## 9. ORDEN DE MIGRACIONES

1. create_users_table (extendida con activo y soft delete)
2. create_sessions_table
3. create_ferias_table
4. create_participantes_table
5. create_feria_participante_table
6. create_productos_table
7. create_producto_precios_table
8. create_feria_user_table
9. create_facturas_table
10. create_factura_detalles_table
11. create_consecutivos_feria_table
12. create_parqueos_table
13. create_tarimas_table
14. create_sanitarios_table
15. create_configuraciones_table
16. spatie_permission_tables

---

## 10. API REST

### 10.1 Generalidades
- **Base URL:** `/api/v1`
- **Formato:** JSON
- **Auth:** Laravel Sanctum
- **Headers requeridos:** Content-Type: application/json, Accept: application/json, X-Feria-Id: {id} (post-login)
- **Paginación estándar:** ?page=, ?per_page= (default 15, max 100), ?search=, ?sort=, ?direction=asc|desc

### 10.2 Autenticación
| Método | Endpoint | Descripción |
|--------|---------|-------------|
| GET | /sanctum/csrf-cookie | CSRF cookie (SPA) |
| POST | /api/v1/auth/login | Login → {user, roles, permisos, ferias} |
| POST | /api/v1/auth/logout | Logout |
| GET | /api/v1/auth/user | Usuario autenticado |
| PUT | /api/v1/auth/password | Cambiar contraseña |
| GET | /api/v1/auth/mis-ferias | Ferias del usuario |
| POST | /api/v1/auth/seleccionar-feria | Seleccionar feria activa |

**Post-login:** 1 feria → auto-seleccionar. Múltiples → mostrar selector. 0 → error.

### 10.3 Ferias
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/ferias | ferias.ver |
| POST | /api/v1/ferias | ferias.crear |
| GET | /api/v1/ferias/{id} | ferias.ver |
| PUT | /api/v1/ferias/{id} | ferias.editar |
| PATCH | /api/v1/ferias/{id}/toggle | ferias.activar |

### 10.4 Participantes
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/participantes | participantes.ver |
| POST | /api/v1/participantes | participantes.crear |
| GET | /api/v1/participantes/{id} | participantes.ver |
| PUT | /api/v1/participantes/{id} | participantes.editar |
| PATCH | /api/v1/participantes/{id}/toggle | participantes.activar |
| GET | /api/v1/participantes/{id}/ferias | participantes.ver |
| POST | /api/v1/participantes/{id}/ferias | participantes.asignar_feria |
| DELETE | /api/v1/participantes/{id}/ferias/{feriaId} | participantes.asignar_feria |
| GET | /api/v1/participantes/por-feria | participantes.ver |

### 10.5 Productos
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/productos | productos.ver |
| POST | /api/v1/productos | productos.crear |
| GET | /api/v1/productos/{id} | productos.ver |
| PUT | /api/v1/productos/{id} | productos.editar |
| PATCH | /api/v1/productos/{id}/toggle | productos.activar |
| POST | /api/v1/productos/{id}/precios | productos.editar |
| DELETE | /api/v1/productos/{id}/precios/{feriaId} | productos.editar |
| GET | /api/v1/productos/por-feria | productos.ver |

### 10.6 Usuarios
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/usuarios | usuarios.ver |
| POST | /api/v1/usuarios | usuarios.crear |
| GET | /api/v1/usuarios/{id} | usuarios.ver |
| PUT | /api/v1/usuarios/{id} | usuarios.editar |
| PATCH | /api/v1/usuarios/{id}/toggle | usuarios.activar |
| PATCH | /api/v1/usuarios/{id}/reset-password | usuarios.editar |
| DELETE | /api/v1/usuarios/{id} | usuarios.eliminar |
| POST | /api/v1/usuarios/{id}/roles | usuarios.editar |
| POST | /api/v1/usuarios/{id}/ferias | usuarios.editar |
| GET | /api/v1/usuarios/{id}/sesiones | usuarios.sesiones |
| DELETE | /api/v1/usuarios/{id}/sesiones/{sId} | usuarios.sesiones |

### 10.7 Facturación
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/facturas | facturas.ver |
| POST | /api/v1/facturas | facturas.crear |
| GET | /api/v1/facturas/{id} | facturas.ver |
| PUT | /api/v1/facturas/{id} | facturas.editar |
| POST | /api/v1/facturas/{id}/facturar | facturas.facturar |
| DELETE | /api/v1/facturas/{id} | facturas.eliminar |
| GET | /api/v1/facturas/{id}/pdf | facturas.ver |
| POST | /api/v1/facturas/{id}/reimprimir | facturas.ver |

**Filtros:** ?estado=, ?fecha_desde=, ?fecha_hasta=, ?participante_id=, ?feria_id= (solo admin)
**Visibilidad:** Admin→todas ferias, Supervisor→feria activa todos usuarios, Facturador→feria activa solo sus facturas, Inspector→feria activa solo lectura.

### 10.8 Parqueos
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/parqueos | parqueos.ver |
| POST | /api/v1/parqueos | parqueos.crear |
| GET | /api/v1/parqueos/{id} | parqueos.ver |
| PATCH | /api/v1/parqueos/{id}/salida | parqueos.salida |
| PATCH | /api/v1/parqueos/{id}/cancelar | parqueos.cancelar |
| GET | /api/v1/parqueos/{id}/pdf | parqueos.ver |

### 10.9 Tarimas
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/tarimas | tarimas.ver |
| POST | /api/v1/tarimas | tarimas.crear |
| GET | /api/v1/tarimas/{id} | tarimas.ver |
| PATCH | /api/v1/tarimas/{id}/cancelar | tarimas.cancelar |
| GET | /api/v1/tarimas/{id}/pdf | tarimas.ver |

### 10.10 Sanitarios
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/sanitarios | sanitarios.ver |
| POST | /api/v1/sanitarios | sanitarios.crear |
| GET | /api/v1/sanitarios/{id} | sanitarios.ver |
| PATCH | /api/v1/sanitarios/{id}/cancelar | sanitarios.cancelar |
| GET | /api/v1/sanitarios/{id}/pdf | sanitarios.ver |

### 10.11 Configuraciones
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/configuraciones | configuracion.ver |
| PUT | /api/v1/configuraciones | configuracion.editar |

### 10.12 Dashboard
| Método | Endpoint | Permiso |
|--------|---------|---------|
| GET | /api/v1/dashboard/resumen | dashboard.ver |
| GET | /api/v1/dashboard/facturacion | dashboard.ver |
| GET | /api/v1/dashboard/parqueos | dashboard.ver |
| GET | /api/v1/dashboard/recaudacion-diaria | dashboard.ver |

### 10.13 Middleware Pipeline
1. `auth:sanctum` — autenticación
2. `EnsureFeriaSelected` — valida X-Feria-Id (excepto auth y selección de feria)
3. `permission:xxx.yyy` — verifica permiso Spatie

---

## 11. ROLES Y PERMISOS

### Roles
| Rol | Alcance |
|-----|---------|
| Administrador | Global (todas las ferias) |
| Supervisor | Ferias asignadas (todos los usuarios) |
| Facturador | Feria activa (solo sus registros) |
| Inspector | Feria activa (solo lectura) |

### Matriz de Permisos
✓ = otorgado | ✗ = denegado | ○ = parcial

| Permiso | Admin | Supervisor | Facturador | Inspector |
|---------|-------|-----------|-----------|----------|
| ferias.ver | ✓ | ✓ | ✗ | ✗ |
| ferias.crear | ✓ | ✗ | ✗ | ✗ |
| ferias.editar | ✓ | ✗ | ✗ | ✗ |
| ferias.activar | ✓ | ✗ | ✗ | ✗ |
| participantes.ver | ✓ | ✓ | ○ | ✓ |
| participantes.crear | ✓ | ✓ | ✗ | ✗ |
| participantes.editar | ✓ | ✓ | ✗ | ✗ |
| participantes.activar | ✓ | ✗ | ✗ | ✗ |
| participantes.asignar_feria | ✓ | ✓ | ✗ | ✗ |
| productos.ver | ✓ | ✓ | ○ | ✓ |
| productos.crear | ✓ | ✗ | ✗ | ✗ |
| productos.editar | ✓ | ✗ | ✗ | ✗ |
| productos.activar | ✓ | ✗ | ✗ | ✗ |
| usuarios.ver | ✓ | ✗ | ✗ | ✗ |
| usuarios.crear | ✓ | ✗ | ✗ | ✗ |
| usuarios.editar | ✓ | ✗ | ✗ | ✗ |
| usuarios.activar | ✓ | ✗ | ✗ | ✗ |
| usuarios.eliminar | ✓ | ✗ | ✗ | ✗ |
| usuarios.sesiones | ✓ | ✗ | ✗ | ✗ |
| facturas.ver | ✓ | ✓ | ○ | ✓ |
| facturas.crear | ✓ | ✓ | ✓ | ✗ |
| facturas.editar | ✓ | ✓ | ○ | ✗ |
| facturas.facturar | ✓ | ✓ | ✓ | ✗ |
| facturas.eliminar | ✓ | ✓ | ○ | ✗ |
| parqueos.ver | ✓ | ✓ | ✓ | ✓ |
| parqueos.crear | ✓ | ✓ | ✓ | ✗ |
| parqueos.salida | ✓ | ✓ | ✓ | ✗ |
| parqueos.cancelar | ✓ | ✓ | ✗ | ✗ |
| tarimas.ver | ✓ | ✓ | ✓ | ✓ |
| tarimas.crear | ✓ | ✓ | ✓ | ✗ |
| tarimas.cancelar | ✓ | ✓ | ✗ | ✗ |
| sanitarios.ver | ✓ | ✓ | ✓ | ✓ |
| sanitarios.crear | ✓ | ✓ | ✓ | ✗ |
| sanitarios.cancelar | ✓ | ✓ | ✗ | ✗ |
| configuracion.ver | ✓ | ✓ | ✗ | ✗ |
| configuracion.editar | ✓ | ✗ | ✗ | ✗ |
| dashboard.ver | ✓ | ✓ | ✓ | ✓ |

**Notas parciales (○):**
- Facturador participantes.ver/productos.ver: solo vía dropdown en facturación
- Facturador facturas.ver: solo sus propias facturas
- Facturador facturas.editar/eliminar: solo sus propias facturas en borrador

---

## 12. FRONTEND — RUTAS

| Ruta | Página | Permiso |
|------|--------|---------|
| /login | LoginPage | — |
| /seleccionar-feria | SeleccionFeriaPage | — |
| /dashboard | DashboardPage | dashboard.ver |
| /facturacion | FacturacionListPage | facturas.ver |
| /facturacion/crear | FacturacionFormPage | facturas.crear |
| /facturacion/:id/editar | FacturacionFormPage | facturas.editar |
| /facturacion/:id | FacturaDetallePage | facturas.ver |
| /parqueos | ParqueosPage | parqueos.ver |
| /tarimas | TarimasPage | tarimas.ver |
| /sanitarios | SanitariosPage | sanitarios.ver |
| /configuracion/ferias | FeriasPage | ferias.ver |
| /configuracion/participantes | ParticipantesListPage | participantes.ver |
| /configuracion/participantes/crear | ParticipanteFormPage | participantes.crear |
| /configuracion/participantes/:id/editar | ParticipanteFormPage | participantes.editar |
| /configuracion/productos | ProductosPage | productos.ver |
| /configuracion/usuarios | UsuariosPage | usuarios.ver |

---

## 13. FRONTEND — COMPONENTES REUTILIZABLES

| Componente | Descripción |
|-----------|-------------|
| PageHeader | Título de página + acción principal |
| DataTable | TanStack Table + paginación servidor + ordenamiento |
| SearchInput | Input búsqueda con debounce 300ms |
| FilterBar | Contenedor de filtros con dropdowns |
| StatusBadge | Badge de estado con colores consistentes |
| ConfirmDialog | AlertDialog para confirmaciones destructivas |
| FormField | Wrapper campo con label, error, requerido |
| ComboboxSearch | Combobox shadcn con búsqueda del API |
| MoneyInput | Input numérico con formato moneda CRC |
| DateRangePicker | Selector rango de fechas |
| StatsCard | Tarjeta métrica para dashboard |
| EmptyState | Vista sin datos con ilustración |
| LoadingSkeleton | Skeleton loader para tablas |

---

## 14. SEEDERS REQUERIDOS

1. **RolesAndPermissionsSeeder** — 4 roles + 32 permisos + asignaciones
2. **AdminUserSeeder** — usuario admin inicial
3. **ConfiguracionesSeeder** — configuraciones globales por defecto
4. **FeriaSeeder** (solo desarrollo) — datos de prueba
