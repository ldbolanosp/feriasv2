# 06 — Prompts de Implementación

> **Instrucciones de uso:** Estos prompts están diseñados para ejecutarse secuencialmente en Cursor con AI agents. Cada prompt construye sobre el trabajo del anterior. Antes de ejecutar cualquier prompt, asegurate de que el agente tenga acceso al archivo `PROJECT_CONTEXT.md` en la raíz del proyecto.
>
> **Flujo recomendado:**
> 1. Creá el proyecto y copiá `PROJECT_CONTEXT.md` a la raíz.
> 2. Ejecutá cada prompt en orden (Fase 1 → Fase 2 → ...).
> 3. Verificá que cada paso funcione antes de pasar al siguiente.
> 4. Si algo falla, pedile al agente que lo corrija antes de avanzar.

---

## FASE 1: FUNDACIÓN DEL PROYECTO

### Prompt 1.1 — Crear proyecto Laravel + configuración base

```
Lee el archivo PROJECT_CONTEXT.md completo antes de empezar.

Crea un nuevo proyecto Laravel 13 llamado "feriasv2r". Configura lo siguiente:

1. Instalar Laravel 13 con composer create-project.
2. Configurar PostgreSQL como base de datos en .env (DB_CONNECTION=pgsql).
3. Instalar las dependencias de backend:
   - laravel/sanctum (autenticación)
   - spatie/laravel-permission (roles y permisos)
   - barryvdh/laravel-dompdf (generación de PDFs)
4. Publicar las configuraciones de Sanctum y Spatie.
5. Configurar Sanctum para autenticación SPA:
   - Agregar el middleware de Sanctum al grupo api.
   - Configurar SANCTUM_STATEFUL_DOMAINS en .env.
   - Configurar SESSION_DRIVER=database en .env.
6. Configurar CORS para permitir requests desde el frontend (localhost:5173 en desarrollo).
7. Crear la estructura de carpetas según PROJECT_CONTEXT.md sección 4:
   - app/Http/Controllers/Api/
   - app/Http/Middleware/
   - app/Http/Requests/
   - app/Services/
   - app/Enums/
   - resources/views/pdf/

No crees migraciones, modelos ni controllers todavía. Solo la estructura base y configuración.
```

### Prompt 1.2 — Crear frontend React + SPA

```
Lee el archivo PROJECT_CONTEXT.md, secciones 2, 4 y convenciones de nombrado.

Dentro del proyecto ferias-system, crea la SPA React en la carpeta /frontend:

1. Inicializar con: npm create vite@latest frontend -- --template react-ts
2. Instalar dependencias:
   - tailwindcss @tailwindcss/vite (v4)
   - react-router-dom (routing)
   - axios (HTTP client)
   - @tanstack/react-query (estado del servidor)
   - zustand (estado del cliente)
   - react-hook-form + @hookform/resolvers + zod (formularios)
   - lucide-react (iconos)
   - recharts (gráficos)
   - sonner (toast notifications)
3. Configurar Tailwind CSS v4.
4. Inicializar shadcn/ui con: npx shadcn@latest init. Usar tema "New York", color base slate.
5. Instalar componentes shadcn necesarios: button, input, select, dialog, alert-dialog, dropdown-menu, table, badge, card, separator, command, popover, calendar, switch, textarea, label, toast (sonner), skeleton, tabs, sheet.
6. Crear la estructura de carpetas frontend según PROJECT_CONTEXT.md:
   - src/components/ui/ (shadcn)
   - src/components/layout/
   - src/components/shared/
   - src/pages/ (con subcarpetas por módulo)
   - src/hooks/
   - src/services/
   - src/stores/
   - src/lib/
   - src/types/
7. Configurar vite.config.ts con proxy al API Laravel (localhost:8000) para desarrollo.
8. Configurar path alias @ para imports.

No crees componentes todavía, solo la estructura y configuración.
```

### Prompt 1.3 — Enums de PHP

```
Lee PROJECT_CONTEXT.md sección 7 (Enums).

Crea los siguientes PHP Enums nativos en app/Enums/:

1. EstadoFactura.php — backed enum string: borrador, facturado, eliminado
2. TipoIdentificacion.php — backed enum string: fisica, juridica, dimex, nite (con labels en español para mostrar en UI)
3. TipoSangre.php — backed enum string: A+, A-, B+, B-, AB+, AB-, O+, O-
4. EstadoParqueo.php — backed enum string: activo, finalizado, cancelado
5. TarifaTipo.php — backed enum string: fija, por_hora

Cada enum debe tener:
- Un método label() que retorne el nombre legible en español.
- Un método static values() que retorne todos los valores.
- Un método static options() que retorne array de ['value' => ..., 'label' => ...] para usar en selects del frontend.
```

### Prompt 1.4 — Migraciones

```
Lee PROJECT_CONTEXT.md sección 6 (Modelo de Datos) y sección 9 (Orden de Migraciones).

Crea TODAS las migraciones en el orden exacto especificado. Para cada tabla, sigue estrictamente los campos, tipos, nullables, defaults, foreign keys, índices y unique constraints documentados.

Orden:
1. Modificar la migración existente de users para agregar: campo 'activo' (boolean, default true) y softDeletes.
2. create_sessions_table (para almacenar sesiones en BD).
3. create_ferias_table
4. create_participantes_table
5. create_feria_participante_table (pivot con unique compuesto)
6. create_productos_table
7. create_producto_precios_table (unique compuesto producto_id + feria_id)
8. create_feria_user_table (pivot con unique compuesto)
9. create_facturas_table (con partial unique en consecutivo)
10. create_factura_detalles_table (con ON DELETE CASCADE en factura_id)
11. create_consecutivos_feria_table (unique en feria_id)
12. create_parqueos_table
13. create_tarimas_table
14. create_sanitarios_table
15. create_configuraciones_table (unique compuesto feria_id + clave)

Después ejecuta las migraciones de Spatie Permission según su documentación.

Verifica que todas las foreign keys, índices y constraints estén correctos. Ejecuta php artisan migrate para verificar.
```

### Prompt 1.5 — Modelos Eloquent

```
Lee PROJECT_CONTEXT.md sección 8 (Modelos Eloquent — Relaciones) y sección 6 (campos de cada tabla).

Crea todos los modelos en app/Models/ con:

1. $fillable con todos los campos asignables (no incluir id, timestamps).
2. $casts para campos que lo necesiten (fechas, booleans, decimals, enums).
3. SoftDeletes trait donde corresponda según la documentación.
4. HasRoles trait de Spatie en el modelo User.
5. Todas las relaciones especificadas en la tabla de relaciones del PROJECT_CONTEXT.md.
6. Scopes útiles:
   - Feria: scopeActivas()
   - Participante: scopeActivos(), scopePorFeria($feriaId)
   - Producto: scopeActivos(), scopeConPrecioEnFeria($feriaId)
   - Factura: scopePorFeria($feriaId), scopePorUsuario($userId), scopePorEstado($estado)
   - Parqueo: scopePorFeria($feriaId), scopeActivos()

Modelos a crear: User (modificar existente), Feria, Participante, Producto, ProductoPrecio, Factura, FacturaDetalle, ConsecutivoFeria, Parqueo, Tarima, Sanitario, Configuracion.
```

### Prompt 1.6 — Seeders

```
Lee PROJECT_CONTEXT.md sección 14 (Seeders) y sección 11 (Roles y Permisos — Matriz completa).

Crea los siguientes seeders:

1. RolesAndPermissionsSeeder:
   - Crear los 4 roles: administrador, supervisor, facturador, inspector.
   - Crear TODOS los 32 permisos listados en la matriz de permisos del PROJECT_CONTEXT.md.
   - Asignar permisos a cada rol exactamente como dice la matriz. Para los permisos parciales (○), asignar el permiso (la restricción se maneja en código con scopes, no con permisos).
   - Debe ser idempotente (usar firstOrCreate).

2. AdminUserSeeder:
   - Crear usuario: name="Administrador", email="admin@ferias.cr", password="password"
   - Asignar rol "administrador".

3. ConfiguracionesSeeder:
   - Crear configuraciones globales (feria_id=null): tarifa_parqueo=1000.00, precio_tarima=5000.00, precio_sanitario=500.00, moneda=CRC

4. FeriaSeeder (para desarrollo):
   - Crear 2 ferias de prueba con datos realistas de Costa Rica.
   - Crear 5 participantes de prueba con datos variados.
   - Asignar participantes a ferias.
   - Crear 3 productos con precios diferentes por feria.
   - Crear un usuario facturador y un supervisor de prueba asignados a las ferias.
   - Crear consecutivos_feria para cada feria.
   - Crear configuraciones por feria.

5. Actualizar DatabaseSeeder para ejecutar en orden: Roles → Admin → Configuraciones → Feria (solo si APP_ENV=local).

Ejecutar php artisan db:seed para verificar.
```

---

## FASE 2: AUTENTICACIÓN Y LAYOUT

### Prompt 2.1 — API de Autenticación

```
Lee PROJECT_CONTEXT.md sección 10.2 (Autenticación).

Crea el AuthController en app/Http/Controllers/Api/ con los siguientes endpoints:

1. login(Request) — POST /api/v1/auth/login
   - Validar email y password.
   - Verificar que la cuenta esté activa y no eliminada.
   - Autenticar con Auth::attempt.
   - Retornar: user data + roles + permisos + ferias asignadas.

2. logout(Request) — POST /api/v1/auth/logout
   - Cerrar la sesión actual.

3. user(Request) — GET /api/v1/auth/user
   - Retornar usuario autenticado con roles, permisos y ferias.

4. updatePassword(Request) — PUT /api/v1/auth/password
   - Validar current_password, nuevo password con confirmación.
   - Actualizar contraseña.

5. misFerias(Request) — GET /api/v1/auth/mis-ferias
   - Retornar ferias asignadas al usuario autenticado.

6. seleccionarFeria(Request) — POST /api/v1/auth/seleccionar-feria
   - Validar que feria_id existe y el usuario tiene acceso.
   - Retornar confirmación.

Crea las rutas en routes/api.php con prefijo v1/auth.
Crea Form Requests para login y password update.
```

### Prompt 2.2 — Middleware personalizado

```
Lee PROJECT_CONTEXT.md sección 10.13 (Middleware Pipeline).

Crea los siguientes middleware en app/Http/Middleware/:

1. EnsureFeriaSelected:
   - Verificar que el header X-Feria-Id esté presente en el request.
   - Verificar que el valor sea un ID de feria válido y existente.
   - Verificar que el usuario autenticado tenga acceso a esa feria (exista en feria_user).
   - Si falla, retornar 403 con mensaje descriptivo.
   - Excluir rutas de auth y selección de feria.

2. Registrar ambos middleware en el bootstrap/app.php o en un ServiceProvider.

3. Configurar las rutas en routes/api.php con la estructura de grupos:
   - Grupo público: login, csrf-cookie
   - Grupo auth (auth:sanctum): user, logout, password, mis-ferias, seleccionar-feria
   - Grupo protegido (auth:sanctum + feria.selected): todos los demás endpoints
```

### Prompt 2.3 — Frontend: API Client, Stores y Auth

```
Lee PROJECT_CONTEXT.md secciones 2, 10.2, 12 (Rutas frontend).

Crea la infraestructura base del frontend:

1. src/services/api.ts — Cliente Axios configurado:
   - baseURL: /api/v1 (con proxy en Vite en desarrollo)
   - Interceptor request: agregar header X-Feria-Id desde el store.
   - Interceptor response: manejar 401 (redirect login), 403 (toast error permiso), 422 (retornar errores de validación), 500 (toast error genérico).
   - Función para obtener CSRF cookie antes del login.

2. src/stores/authStore.ts — Zustand store:
   - State: user, roles, permisos, ferias, isAuthenticated, isLoading
   - Actions: login, logout, fetchUser, setUser
   - Método hasPermission(permiso: string): boolean
   - Persistir en sessionStorage.

3. src/stores/feriaStore.ts — Zustand store:
   - State: feriaActiva (id, codigo, descripcion), ferias[]
   - Actions: setFeriaActiva, setFerias
   - Persistir en sessionStorage.

4. src/hooks/usePermission.ts:
   - Hook que retorna hasPermission(permiso) desde authStore.

5. src/types/auth.ts — TypeScript interfaces:
   - IUser, IFeria, ILoginRequest, ILoginResponse

6. src/services/authService.ts:
   - Funciones: login, logout, getUser, updatePassword, getFerias, seleccionarFeria
   - Cada una llama al endpoint correspondiente usando el api client.
```

### Prompt 2.4 — Frontend: Layout principal, Routing y páginas Auth

```
Lee PROJECT_CONTEXT.md secciones 12 (Rutas), y la información del documento de UI (layout principal, sidebar, top bar, login, selector de feria).

Implementa:

1. src/components/layout/Sidebar.tsx:
   - Logo en la parte superior.
   - Items de menú con iconos de Lucide según la tabla del documento de UI: Dashboard (LayoutDashboard), Facturación (Receipt), Parqueo (Car), Tarimas (Box), Sanitarios (Droplets), Configuración (Settings) con submenú: Ferias (MapPin), Participantes (Users), Productos (Package), Usuarios (UserCog).
   - Items se muestran solo si el usuario tiene el permiso correspondiente (usar usePermission).
   - Indicador visual del item activo.
   - Colapsable en pantallas pequeñas.

2. src/components/layout/TopBar.tsx:
   - Izquierda: título de la página actual.
   - Centro-derecha: badge con nombre de feria activa, clic para cambiar.
   - Derecha: avatar con dropdown (nombre, rol, cambiar contraseña, cerrar sesión).

3. src/components/layout/AppLayout.tsx:
   - Layout que combina Sidebar + TopBar + área de contenido.
   - Solo se muestra para usuarios autenticados.

4. src/pages/auth/LoginPage.tsx:
   - Formulario centrado con email y contraseña.
   - Validación con React Hook Form + Zod.
   - Loading state en botón.
   - Manejo de errores (credenciales inválidas, cuenta desactivada).
   - Post-login: si 1 feria → dashboard, si múltiples → selector.

5. src/pages/auth/SeleccionFeriaPage.tsx:
   - Tarjetas (Card) clickeables para cada feria.
   - Al seleccionar, guardar en feriaStore y redirigir a dashboard.

6. src/App.tsx con React Router:
   - Rutas públicas: /login
   - Rutas protegidas (requieren auth): todas las demás según tabla de rutas.
   - ProtectedRoute component que verifica autenticación y permisos.
   - Redirect a login si no autenticado.
   - Redirect a selección de feria si no hay feria activa.

7. Configurar React Query provider en main.tsx.

Usa los componentes de shadcn/ui para todo. No inventes componentes de UI desde cero.
```

---

## FASE 3: COMPONENTES REUTILIZABLES

### Prompt 3.1 — Componentes shared

```
Lee PROJECT_CONTEXT.md sección 13 (Componentes Reutilizables) y la información del documento de UI sobre patrones comunes.

Crea los siguientes componentes reutilizables en src/components/shared/:

1. PageHeader.tsx — Props: title, description?, action? (botón con texto e icono), backUrl?
2. DataTable.tsx — Componente genérico basado en TanStack Table:
   - Recibe: columns (TanStack ColumnDef[]), data, isLoading, pagination (page, pageSize, total), onPaginationChange, onSortChange.
   - Paginación del servidor (no carga todo en memoria).
   - Columnas ordenables (clic en header).
   - Skeleton loader mientras carga.
   - Texto "No se encontraron registros" cuando está vacío.
3. SearchInput.tsx — Input con icono Search, debounce 300ms, props: value, onChange, placeholder.
4. FilterBar.tsx — Contenedor flex con gap para filtros. Recibe children.
5. StatusBadge.tsx — Props: status (string), mapa de colores según tabla de badges del documento UI (activo=verde, borrador=amarillo, eliminado=rojo, inactivo=gris, finalizado=azul).
6. ConfirmDialog.tsx — Wrapper de AlertDialog de shadcn. Props: open, onConfirm, onCancel, title, description, confirmText, variant (default | destructive).
7. FormField.tsx — Wrapper que recibe: label, error?, required?, children (el input).
8. ComboboxSearch.tsx — Basado en Command de shadcn. Props: options[], onSelect, onSearch (debounced), placeholder, value, isLoading. Búsqueda asíncrona contra el API.
9. MoneyInput.tsx — Input numérico que formatea como moneda CRC (₡). Props: value, onChange.
10. DateRangePicker.tsx — Dos date pickers (desde/hasta) basados en Calendar de shadcn.
11. StatsCard.tsx — Card con: icono (LucideIcon), título, valor principal (formateado), subtítulo opcional.
12. EmptyState.tsx — Mensaje centrado con icono, título, descripción y acción opcional.
13. LoadingSkeleton.tsx — Skeleton de tabla con filas configurables.

Todos los componentes deben usar TypeScript con interfaces tipadas para sus props.
```

---

## FASE 4: MÓDULOS DE CONFIGURACIÓN

### Prompt 4.1 — API de Ferias (Backend)

```
Lee PROJECT_CONTEXT.md secciones 10.3 (API Ferias), 6.1 (tabla ferias).

Crea:
1. FeriaController con: index (paginado, search, filtro activa), store, show, update, toggle.
2. Form Requests: StoreFeriaRequest, UpdateFeriaRequest con validaciones según la documentación.
3. FeriaResource para transformar el modelo a JSON.
4. Rutas en api.php con middleware de permisos.
5. Implementar búsqueda por codigo y descripcion.
6. Implementar filtro por ?activa=true|false.
7. Implementar ordenamiento por cualquier campo.

Sigue el patrón: Controller delgado → FormRequest → Model.
```

### Prompt 4.2 — Frontend Ferias

```
Lee la información del documento de UI sección 6 (Módulo de Ferias) y PROJECT_CONTEXT.md sección 12 (rutas).

Crea la página de Ferias:

1. src/services/feriaService.ts — funciones CRUD llamando al API.
2. src/hooks/useFerias.ts — hook con TanStack Query para listar, crear, actualizar, toggle.
3. src/types/feria.ts — interfaces IFeria, IFeriaForm.
4. src/pages/ferias/FeriasPage.tsx:
   - PageHeader con título "Ferias" y botón "+ Nueva Feria" (si tiene permiso ferias.crear).
   - SearchInput + FilterBar con filtro de estado (Todas/Activas/Inactivas).
   - DataTable con columnas: Código, Descripción, Fact. Público (badge Sí/No), Estado (StatusBadge), Acciones.
   - ActionMenu por fila: Editar, Activar/Desactivar.
5. src/pages/ferias/FeriaFormDialog.tsx:
   - Dialog (modal) de shadcn para crear/editar.
   - Campos: Código (Input), Descripción (Input), Facturación a público general (Switch).
   - Validación con Zod.
   - Loading state en botón guardar.
   - Toast de éxito/error.
```

### Prompt 4.3 — API de Participantes (Backend)

```
Lee PROJECT_CONTEXT.md secciones 10.4 (API Participantes), 6.2 y 6.3 (tablas).

Crea:
1. ParticipanteController con: index, store, show, update, toggle, ferias (ver ferias asignadas), asignarFerias, desasignarFeria, porFeria.
2. Form Requests con todas las validaciones documentadas (numero_identificacion único, fecha_vencimiento after fecha_emision, tipo_identificacion in enum, etc.).
3. ParticipanteResource.
4. Rutas con middleware de permisos.
5. El endpoint porFeria debe filtrar participantes de la feria activa (del header X-Feria-Id) y retornar datos simplificados (id, nombre, numero_identificacion) para el dropdown de facturación.
6. Búsqueda por nombre y numero_identificacion.
```

### Prompt 4.4 — Frontend Participantes

```
Lee la información del documento de UI sección 7 (Módulo de Participantes).

Crea:
1. src/services/participanteService.ts
2. src/hooks/useParticipantes.ts
3. src/types/participante.ts
4. src/pages/participantes/ParticipantesListPage.tsx:
   - DataTable con columnas: Nombre, Identificación (tipo + número), Teléfono, Carné, Venc. Carné (warning si próximo a vencer), Estado, Acciones.
   - Filtros: Estado, Tipo Identificación, Feria.
5. src/pages/participantes/ParticipanteFormPage.tsx:
   - Formulario en página completa (no modal, es extenso).
   - 4 secciones: Info Básica, Carné, Info Médica, Contacto Emergencia.
   - Validación con Zod reflejando las validaciones del backend.
   - Al guardar, mostrar sección de asignación de ferias.
6. Sección de asignación de ferias: lista de ferias con checkbox, badges de ferias asignadas con botón X para desasignar.
```

### Prompt 4.5 — API de Productos (Backend)

```
Lee PROJECT_CONTEXT.md secciones 10.5 (API Productos), 6.4 y 6.5 (tablas).

Crea:
1. ProductoController con: index, store, show, update, toggle, asignarPrecios, eliminarPrecio, porFeria.
2. Form Requests con validaciones (codigo único, precios array con feria_id y precio).
3. ProductoResource (incluir count de precios y detalle de precios por feria).
4. El endpoint porFeria retorna solo productos con precio en la feria activa, incluyendo el precio.
5. El endpoint asignarPrecios hace upsert (si ya existe precio para esa feria, actualiza).
```

### Prompt 4.6 — Frontend Productos

```
Lee la información del documento de UI sección 8 (Módulo de Productos).

Crea:
1. Services, hooks, types para productos.
2. ProductosPage con DataTable: Código, Descripción, Precios (count ferias), Estado, Acciones (Editar, Precios, Toggle).
3. ProductoFormDialog (modal) para crear/editar producto.
4. ProductoPreciosDialog (modal/panel) para gestionar precios por feria:
   - Lista de precios actuales con botón eliminar.
   - Fila para agregar: dropdown de ferias (sin precio asignado) + input precio + botón agregar.
```

### Prompt 4.7 — API de Usuarios (Backend)

```
Lee PROJECT_CONTEXT.md secciones 10.6 (API Usuarios), 6.6 y 6.7 (tablas).

Crea:
1. UsuarioController con: index, store, show, update, toggle, delete, resetPassword, asignarRol, asignarFerias, sesiones, cerrarSesion.
2. Form Requests.
3. UserResource.
4. La acción delete: soft delete + desactivar + cerrar sesiones + revocar tokens.
5. La acción toggle: alternar activo, si desactiva cerrar sesiones.
6. Sesiones: leer de tabla sessions, parsear user_agent, marcar sesión actual.
7. CerrarSesion: eliminar sesión específica de la tabla.
```

### Prompt 4.8 — Frontend Usuarios

```
Lee la información del documento de UI sección 9 (Módulo de Usuarios).

Crea:
1. Services, hooks, types para usuarios.
2. UsuariosPage con DataTable: Nombre, Email, Rol (badge), Ferias (count), Estado, Acciones.
3. Filtros: Estado, Rol.
4. UsuarioFormDialog para crear/editar con campos: Nombre, Email, Contraseña (solo creación), Rol (select), Ferias (multiselect checkboxes).
5. SesionesDialog: lista sesiones activas con IP, navegador, última actividad, badge "Actual", botones cerrar sesión y cerrar todas.
```

---

## FASE 5: MÓDULOS TRANSACCIONALES

### Prompt 5.1 — Services de backend (Facturación, Consecutivo, PDF)

```
Lee PROJECT_CONTEXT.md secciones 6.8-6.10 (facturas, detalles, consecutivos) y reglas de negocio.

Crea los Services en app/Services/:

1. ConsecutivoService:
   - Método generarConsecutivo($feriaId): string
   - Dentro de DB::transaction con lockForUpdate en consecutivos_feria.
   - Formato: F + feriaId + str_pad(8, '0', STR_PAD_LEFT)

2. FacturacionService:
   - Método crearFactura(array $data, int $feriaId, int $userId): Factura
     - Validar participante pertenece a feria si no es público general.
     - Obtener precios de producto_precios para la feria.
     - Calcular subtotales por línea y total.
     - Guardar factura en estado borrador + detalles con snapshots.
   - Método actualizarFactura(Factura, array $data): Factura
     - Solo si estado = borrador.
     - Eliminar detalles existentes y recrear.
   - Método facturar(Factura): Factura
     - Solo si estado = borrador.
     - Generar consecutivo con ConsecutivoService.
     - Cambiar estado a facturado, fecha_emision = now().
     - Generar PDF con PdfTicketService.
   - Método eliminar(Factura): void
     - Cambiar estado a eliminado + soft delete.

3. PdfTicketService:
   - Método generarTicketFactura(Factura): string (retorna path)
     - Usa dompdf con vista blade ticket-factura.
     - Ancho 80mm para impresora POS.
     - Guarda en storage/app/tickets/{feria_id}/{fecha}/{consecutivo}.pdf
   - Método generarTicketParqueo(Parqueo): string
   - Método generarTicketTarima(Tarima): string

4. Crear las vistas Blade en resources/views/pdf/:
   - ticket-factura.blade.php
   - ticket-parqueo.blade.php
   - ticket-tarima.blade.php
   Diseño simple, ancho 80mm, datos principales, sin imágenes pesadas.
```

### Prompt 5.2 — API de Facturación

```
Lee PROJECT_CONTEXT.md sección 10.7 (Facturación).

Crea:
1. FacturaController usando FacturacionService para la lógica.
   - index: paginado con filtros (estado, fecha_desde, fecha_hasta, participante_id, feria_id).
   - IMPLEMENTAR reglas de visibilidad por rol:
     - Admin: todas las facturas, todas las ferias (filtrable por feria_id).
     - Supervisor: todas las facturas de la feria activa.
     - Facturador: solo sus facturas (user_id = auth) de la feria activa.
     - Inspector: todas las facturas de la feria activa (solo lectura).
   - store: crear borrador.
   - show: detalle con detalles y relaciones.
   - update: solo si borrador.
   - facturar: emitir con consecutivo y PDF.
   - destroy: marcar como eliminado.
   - pdf: retornar el PDF para descarga.
   - reimprimir: regenerar PDF.
2. Form Requests: StoreFacturaRequest, UpdateFacturaRequest con todas las validaciones (participante en feria, producto con precio en feria, cantidad mínimo 1 incrementos 0.5, etc.).
3. FacturaResource con detalles incluidos.
```

### Prompt 5.3 — Frontend Facturación (Listado)

```
Lee la información del documento de UI sección 10.1 (Listado de Facturación).

Crea:
1. src/services/facturaService.ts
2. src/hooks/useFacturas.ts
3. src/types/factura.ts (IFactura, IFacturaDetalle, IFacturaForm)
4. src/pages/facturacion/FacturacionListPage.tsx:
   - PageHeader "Facturación" + botón "+ Nueva Factura".
   - Filtros: Estado (Todos/Borrador/Facturado/Eliminado), Fecha desde/hasta, Feria (solo admin).
   - DataTable columnas: Consecutivo (vacío si borrador), Participante, Puesto, Total (₡), Estado (badge), Fecha, Usuario (solo admin/supervisor), Acciones.
   - Acciones condicionales por estado:
     - Borrador: Ver, Editar, Facturar, Eliminar
     - Facturado: Ver, PDF, Eliminar
     - Eliminado: Ver
   - La acción Facturar muestra ConfirmDialog antes de proceder.
   - La acción PDF abre nueva ventana con el PDF.
```

### Prompt 5.4 — Frontend Facturación (Formulario)

```
Lee la información del documento de UI sección 10.2 (Formulario de Facturación) con todos los 10 comportamientos detallados.

Crea src/pages/facturacion/FacturacionFormPage.tsx:

Este es el formulario más complejo del sistema. Debe estar en página completa (/facturacion/crear y /facturacion/:id/editar).

Implementar TODOS los comportamientos descritos:

1. Header con "Nueva Factura" o "Editar Factura" + badge de feria activa.
2. Checkbox "Público General" (solo visible si feria.facturacion_publico = true). Al activar: ocultar dropdown participante, mostrar input nombre_publico. Al desactivar: restaurar dropdown.
3. ComboboxSearch de Participante: busca en participantes de la feria activa (endpoint /participantes/por-feria). Muestra nombre + identificación.
4. Campos: Tipo Puesto (input texto), Número Puesto (input texto).
5. Sección Productos:
   - ComboboxSearch de Producto: busca en productos con precio en feria activa (endpoint /productos/por-feria). Al seleccionar, autocompletar precio (no editable), cantidad default 1.
   - Campo Cantidad: input numérico, mínimo 1, incrementos 0.5.
   - Subtotal de línea calculado en tiempo real: cantidad × precio.
   - Botón Agregar (+): agrega a tabla de detalles, limpia campos, excluir producto ya agregado del dropdown.
6. Tabla de detalles: Producto, Cantidad, Precio Unitario, Subtotal, botón eliminar (✖). Total recalculado en tiempo real.
7. Observaciones: textarea.
8. Resumen: Total, Monto de Pago (input), Cambio (calculado en tiempo real, rojo si negativo).
9. Botones:
   - Cancelar: redirige a listado (confirmar si hay cambios).
   - Guardar: guarda borrador, toast éxito.
   - Facturar: ConfirmDialog → guarda + emite + abre PDF → redirige a listado.

Usar React Hook Form para el formulario principal y estado local para la tabla de detalles.
```

### Prompt 5.5 — API y Frontend de Parqueos

```
Lee PROJECT_CONTEXT.md secciones 10.8 (API Parqueos), 6.11 (tabla parqueos), y la información del documento de UI sección 11 (Módulo Parqueos).

Backend:
1. ParqueoService con lógica de creación (obtener tarifa de configuraciones, crear registro, generar PDF).
2. ParqueoController: index (paginado, filtros estado/fecha/placa), store, show, salida, cancelar, pdf.
3. Form Requests.

Frontend:
1. Services, hooks, types.
2. ParqueosPage: DataTable con columnas (Placa, Ingreso, Salida, Tarifa, Estado, Usuario, Acciones).
3. Filtros: Estado, Fecha, Búsqueda por placa.
4. ParqueoRegistroDialog (modal ultra rápido):
   - Input placa con auto-uppercase y autofocus.
   - Tarifa mostrada automáticamente (no editable).
   - Envío con Enter.
   - Al registrar: crear + abrir PDF.
```

### Prompt 5.6 — API y Frontend de Tarimas

```
Lee PROJECT_CONTEXT.md secciones 10.9 (API Tarimas), 6.12 (tabla), y la información del documento de UI sección 12.

Backend:
1. TarimaController: index, store, show, cancelar, pdf.
2. Lógica: obtener precio de configuraciones, calcular total, generar PDF al facturar.

Frontend:
1. TarimasPage con DataTable.
2. TarimaFormDialog (modal):
   - ComboboxSearch participante (filtrado por feria).
   - Cantidad (input numérico), Número tarima (opcional).
   - Precio y total calculados automáticamente.
   - Al facturar: crear + PDF.
```

### Prompt 5.7 — API y Frontend de Sanitarios

```
Lee PROJECT_CONTEXT.md secciones 10.10 (API Sanitarios), 6.13 (tabla), y la información del documento de UI sección 13.

Backend y Frontend similar a Tarimas pero:
- Participante es opcional (puede ser uso público).
- Sin número de tarima.
- Precio viene de configuración precio_sanitario.
```

---

## FASE 6: CONFIGURACIONES Y DASHBOARD

### Prompt 6.1 — API y Frontend de Configuraciones

```
Lee PROJECT_CONTEXT.md secciones 10.11 (API Configuraciones), 6.14 (tabla).

Backend:
1. ConfiguracionController: index (retorna config feria activa + globales), update.

Frontend:
1. Sección en la página de configuración o vista dedicada.
2. Formulario con campos editables para: tarifa_parqueo, precio_tarima, precio_sanitario.
3. Solo visible para admin (configuracion.editar).
```

### Prompt 6.2 — API y Frontend de Dashboard

```
Lee PROJECT_CONTEXT.md sección 10.12 (API Dashboard), y la información del documento de UI sección 5 (Dashboard por rol).

Backend:
1. DashboardController con: resumen, facturacion, parqueos, recaudacionDiaria.
2. Cada endpoint agrega datos según la feria activa y filtro de fechas.
3. Facturador: filtrar solo sus datos.

Frontend:
1. DashboardPage con contenido condicional por rol:
   - Admin/Supervisor: 4 StatsCards (Facturas, Parqueos, Tarimas, Sanitarios) + Recaudación Total + LineChart tendencia diaria (Recharts) + BarChart facturas por producto + BarChart por usuario + tabla últimas facturas.
   - Facturador: StatsCards propias (mis facturas hoy, mis borradores) + tabla mis últimas facturas.
   - Inspector: StatsCards generales (solo lectura).
2. DateRangePicker para filtrar por fechas.
```

---

## FASE 7: PULIDO Y PRODUCCIÓN

### Prompt 7.1 — Manejo de errores y edge cases

```
Revisa todo el sistema implementado y:

1. Verificar que todos los endpoints retornen respuestas consistentes (formato JSON estándar).
2. Verificar que los Form Requests tengan mensajes de error en español.
3. Verificar que el manejo de errores del frontend muestre toasts descriptivos.
4. Verificar que los estados de carga (loading) funcionen en todas las tablas y formularios.
5. Verificar que los empty states se muestren cuando no hay datos.
6. Verificar que la navegación por teclado funcione en formularios.
7. Verificar que el cambio de feria actualice todos los datos en pantalla.
8. Verificar que el cierre de sesión limpie todos los stores.
9. Agregar error boundaries de React para errores inesperados.
10. Verificar que las rutas protegidas redirijan correctamente.
```

### Prompt 7.2 — Responsive y ajustes finales

```
Revisa y ajusta:

1. Sidebar colapsable en tablets (solo iconos).
2. Sidebar como drawer en móvil (botón hamburguesa).
3. Tablas con scroll horizontal en pantallas pequeñas.
4. Formularios que se adapten a anchos menores.
5. Verificar que los modales se vean bien en todas las resoluciones.
6. Ajustar espaciado y tipografía según la paleta definida (Inter, tamaños 13-24px).
7. Verificar contraste de colores para accesibilidad.
```

### Prompt 7.3 — Build de producción

```
Configura el proyecto para producción:

1. Configurar Vite para build de producción (npm run build en /frontend).
2. Configurar Laravel para servir los assets estáticos del build de React desde public/.
3. Crear un script o configuración para que el build de frontend se copie automáticamente a public/.
4. Verificar que las rutas del frontend funcionen con el fallback a index.html (SPA routing).
5. Configurar variables de entorno para producción en .env.production.
6. Verificar que CORS esté correctamente configurado para el dominio de producción.
7. Optimizar: php artisan config:cache, route:cache, view:cache.
8. Documentar en README.md: cómo instalar, configurar, ejecutar en desarrollo y hacer deploy.
```
