# 07 — Prompts de Implementación Flutter

> **Instrucciones de uso:** Estos prompts se ejecutan secuencialmente en Cursor. Antes de ejecutar cualquier prompt, el agente debe tener acceso a `FLUTTER_CONTEXT.md` y `PROJECT_CONTEXT.md` en la raíz del proyecto.
>
> **Pre-requisito:** La API de Laravel debe estar funcionando y accesible. Todos los endpoints definidos en PROJECT_CONTEXT.md ya están implementados.

---

## FASE 1: FUNDACIÓN DEL PROYECTO FLUTTER

### Prompt F1.1 — Crear proyecto Flutter + dependencias

```
Lee los archivos FLUTTER_CONTEXT.md y PROJECT_CONTEXT.md antes de empezar.

Crea un nuevo proyecto Flutter para la app de Ferias del Agricultor:

1. Crear proyecto: flutter create --org com.ferias --platforms android ferias_app
2. Configurar pubspec.yaml con las siguientes dependencias:
   - dio (HTTP client)
   - provider (estado)
   - go_router (navegación)
   - shared_preferences (almacenamiento local)
   - sunmi_printer_plus: ^4.1.1 (impresión SUNMI)
   - pdf: ^3.11.3 (generación PDF)
   - printing: ^5.14.2 (impresión PDF fallback)
   - fl_chart (gráficos para dashboard)
   - intl (formateo de fechas y moneda)
3. Crear la estructura de carpetas según FLUTTER_CONTEXT.md sección 4:
   - lib/config/
   - lib/models/
   - lib/services/
   - lib/providers/
   - lib/screens/ (con subcarpetas por módulo)
   - lib/widgets/
   - lib/utils/
4. Configurar android/app/build.gradle:
   - minSdkVersion: 21
   - targetSdkVersion: última estable
5. Agregar permisos en AndroidManifest.xml: INTERNET, ACCESS_NETWORK_STATE.

No crees screens ni lógica todavía, solo la estructura y configuración.
```

### Prompt F1.2 — Modelos Dart

```
Lee FLUTTER_CONTEXT.md sección 6 y PROJECT_CONTEXT.md sección 6 (Modelo de Datos).

Crea todos los modelos Dart en lib/models/:

1. User — id, name, email, activo, roles (List<String>), permisos (List<String>), ferias (List<Feria>)
2. Feria — id, codigo, descripcion, facturacionPublico, activa, createdAt
3. Participante — todos los campos del modelo de datos (nombre, tipoIdentificacion, numeroIdentificacion, correoElectronico, numeroCarne, fechas de carné, procedencia, telefono, tipoSangre, padecimientos, contacto emergencia, activo)
4. Producto — id, codigo, descripcion, activo, precio (nullable, viene cuando se consulta por feria)
5. ProductoPrecio — id, productoId, feriaId, precio
6. Factura — id, feriaId, participanteId, userId, consecutivo, esPublicoGeneral, nombrePublico, tipoPuesto, numeroPuesto, subtotal, montoPago, montoCambio, observaciones, estado, fechaEmision, pdfPath, detalles (List<FacturaDetalle>), participante (Participante?), user (User?)
7. FacturaDetalle — id, facturaId, productoId, descripcionProducto, cantidad, precioUnitario, subtotalLinea
8. Parqueo — id, feriaId, userId, placa, fechaHoraIngreso, fechaHoraSalida, tarifa, tarifaTipo, estado, observaciones, pdfPath
9. Tarima — id, feriaId, userId, participanteId, numeroTarima, cantidad, precioUnitario, total, estado, observaciones, participante (Participante?)
10. Sanitario — id, feriaId, userId, participanteId, cantidad, precioUnitario, total, estado, observaciones, participante (Participante?)
11. Configuracion — id, feriaId, clave, valor, descripcion
12. DashboardResumen — facturasHoy, facturasBorrador, totalFacturadoHoy, parqueosActivos, parqueosHoy, totalParqueosHoy, tarimasHoy, totalTarimasHoy, sanitariosHoy, totalSanitariosHoy, recaudacionTotalHoy
13. PaginatedResponse<T> — data (List<T>), currentPage, lastPage, perPage, total (modelo genérico para respuestas paginadas)

Cada modelo debe tener:
- Constructor con named required/optional parameters.
- Factory fromJson(Map<String, dynamic>).
- Método toJson() donde se necesite enviar datos al API.
- Campos con tipos correctos (int, String, double, bool, DateTime, etc.). No usar dynamic.
- Conversión correcta de snake_case (JSON) a camelCase (Dart).
```

### Prompt F1.3 — API Service (Dio) + Auth Service

```
Lee FLUTTER_CONTEXT.md secciones 7 y 3.3.

Crea:

1. lib/config/api_config.dart:
   - Constante baseUrl (configurable).
   - Timeouts.

2. lib/services/api_service.dart — Cliente Dio singleton:
   - BaseOptions con baseUrl, headers Content-Type y Accept.
   - Interceptor de request: agregar Authorization Bearer token y X-Feria-Id.
   - Interceptor de error: manejar 401 (limpiar sesión), loguear errores.
   - Métodos: setToken, setFeriaId, clearAuth.
   - Métodos helper: get, post, put, patch, delete que wrappean Dio.

3. lib/services/auth_service.dart:
   - login(email, password): POST /api/v1/auth/login. IMPORTANTE: enviar device_name para que Sanctum genere un token API (no sesión). Retornar token + user data.
   - logout(): POST /api/v1/auth/logout. Revocar token.
   - getUser(): GET /api/v1/auth/user.
   - updatePassword(currentPassword, newPassword): PUT /api/v1/auth/password.
   - getFerias(): GET /api/v1/auth/mis-ferias.
   - seleccionarFeria(feriaId): POST /api/v1/auth/seleccionar-feria.

4. lib/providers/auth_provider.dart — ChangeNotifier:
   - State: user, token, isAuthenticated, isLoading.
   - login(): llamar authService, guardar token en SharedPreferences, configurar ApiService.
   - logout(): limpiar todo, redirigir a login.
   - checkAuth(): al iniciar app, verificar si hay token en SharedPreferences y validarlo.
   - hasPermission(String permiso): verificar si el usuario tiene el permiso.

5. lib/providers/feria_provider.dart — ChangeNotifier:
   - State: feriaActiva, ferias[].
   - setFeriaActiva(): guardar en SharedPreferences, actualizar ApiService header.
   - Al iniciar app, restaurar feria activa de SharedPreferences.

IMPORTANTE sobre autenticación con tokens:
El backend actual puede estar configurado solo para cookies (SPA web). Verificar que el endpoint de login soporte generar tokens con Sanctum. Si no, el agente debe indicar qué cambiar en el backend:
- El AuthController.login() debe detectar si viene device_name en el request.
- Si viene device_name: crear token con $user->createToken($deviceName) y retornarlo.
- Si no viene: usar sesión/cookie (para la web).
```

### Prompt F1.4 — Tema, Config y App base

```
Lee FLUTTER_CONTEXT.md secciones 10.1 y 9.

Crea:

1. lib/config/theme.dart:
   - ThemeData con Material 3.
   - Color primario: Color(0xFF2563EB) (azul, mismo que web).
   - ColorScheme.fromSeed con el primario.
   - Tipografía: usar Roboto (default).
   - Definir colores para badges de estado:
     - Activo/Facturado: Colors.green
     - Borrador: Colors.orange
     - Eliminado/Cancelado: Colors.red
     - Inactivo: Colors.grey

2. lib/config/routes.dart:
   - GoRouter con todas las rutas de FLUTTER_CONTEXT.md sección 9.2.
   - Redirect: si no autenticado → /login.
   - Redirect: si autenticado sin feria → /seleccionar-feria.
   - Rutas protegidas verifican permisos.

3. lib/app.dart:
   - MultiProvider con todos los providers.
   - MaterialApp.router con GoRouter y tema.
   - Inicialización: checkAuth del authProvider al arrancar.

4. lib/main.dart:
   - runApp con la App.
   - Inicializar SharedPreferences.

5. lib/utils/formatters.dart:
   - formatMoney(double): formato "₡1,234,567.00"
   - formatDate(DateTime): formato "dd/MM/yyyy"
   - formatDateTime(DateTime): formato "dd/MM/yyyy HH:mm"
```

---

## FASE 2: AUTENTICACIÓN Y NAVEGACIÓN

### Prompt F2.1 — Login y Selección de Feria

```
Lee FLUTTER_CONTEXT.md secciones 11.1, 11.4.

Crea:

1. lib/screens/auth/login_screen.dart:
   - Pantalla centrada con logo/título "Ferias del Agricultor".
   - Campos: email (TextFormField con validación email) y contraseña (con obscureText).
   - Botón "Iniciar Sesión" con loading state.
   - Manejo de errores: credenciales inválidas, cuenta desactivada.
   - Al login exitoso: si 1 feria → dashboard, si múltiples → selección.

2. lib/screens/auth/seleccion_feria_screen.dart:
   - Título "Seleccione la feria en la que desea trabajar".
   - ListView de Cards, una por feria (código + descripción).
   - Al seleccionar: guardar en feriaProvider, navegar a dashboard.

3. Verificar que el flujo completo funcione:
   Login → Selección de feria (si aplica) → Dashboard (pantalla vacía por ahora).
```

### Prompt F2.2 — Layout: Drawer y AppBar

```
Lee FLUTTER_CONTEXT.md secciones 9.3 y 10.2.

Crea:

1. lib/widgets/app_drawer.dart:
   - Header del drawer: nombre del usuario, email, rol (badge).
   - Items del menú según la tabla de FLUTTER_CONTEXT.md sección 9.3.
   - Cada item tiene icono Material + texto.
   - Items filtrados por permisos del usuario (authProvider.hasPermission).
   - Sección "Configuración" como ExpansionTile con sub-items.
   - Item "Cerrar Sesión" al final con confirmación.

2. lib/widgets/app_bar_custom.dart:
   - Título de la pantalla actual.
   - Subtítulo o acción: nombre de feria activa (tappeable para cambiar).
   - Al tap en feria: mostrar BottomSheet con lista de ferias para cambiar.

3. Crear un Scaffold base que usen todas las screens:
   - AppBarCustom
   - AppDrawer
   - Body: el contenido de cada screen
```

---

## FASE 3: WIDGETS REUTILIZABLES

### Prompt F3.1 — Componentes compartidos

```
Lee FLUTTER_CONTEXT.md sección 10.3.

Crea todos los widgets reutilizables en lib/widgets/:

1. DataTableCustom — Widget que muestra datos en lista/tabla:
   - Recibe: List<T> items, columnas, isLoading, onRefresh (pull-to-refresh).
   - Paginación: botones Anterior/Siguiente o scroll infinito.
   - Muestra LoadingWidget mientras carga.
   - Muestra EmptyState cuando no hay datos.

2. SearchInput — TextField con:
   - Icono de búsqueda.
   - Debounce de 300ms (usar Timer).
   - Botón de limpiar (X).
   - Callback onChanged con el texto después del debounce.

3. StatusBadge — Chip/Container con:
   - Texto del estado.
   - Color según estado: activo/facturado=verde, borrador=naranja, eliminado/cancelado=rojo, inactivo=gris, finalizado=azul.

4. ConfirmDialog — Función o widget que muestra AlertDialog:
   - Título, mensaje, botón cancelar, botón confirmar (rojo si destructivo).
   - Retorna Future<bool>.

5. StatsCard — Card con:
   - Icono (IconData), título (String), valor principal (String), color.
   - Diseño compacto para dashboard.

6. EmptyState — Column centrada con:
   - Icono grande gris.
   - Título "No se encontraron registros".
   - Subtítulo opcional.
   - Botón de acción opcional.

7. LoadingWidget — Center con CircularProgressIndicator.

8. MoneyText — Text widget que formatea un double como moneda CRC: "₡1,234.00".

9. ComboboxSearch — Widget Autocomplete/TypeAhead:
   - TextField de búsqueda.
   - Llama al API con debounce al escribir.
   - Muestra lista de resultados.
   - Al seleccionar, retorna el item.
   - Muestra loading mientras busca.
   - Props: searchCallback (Future<List<T>>), displayStringForOption, onSelected.

10. FormFieldCustom — Column con:
    - Label (con asterisco si required).
    - El widget hijo (TextFormField, dropdown, etc).
    - Texto de error en rojo si hay error.
```

---

## FASE 4: MÓDULOS DE CONFIGURACIÓN

### Prompt F4.1 — Ferias (Service + Screen)

```
Lee PROJECT_CONTEXT.md sección 10.3 (API Ferias) y FLUTTER_CONTEXT.md.

Crea:

1. lib/services/feria_service.dart — CRUD completo llamando al API.
2. lib/screens/configuracion/ferias/ferias_screen.dart:
   - AppBarCustom con título "Ferias".
   - FAB para crear nueva feria (si tiene permiso).
   - SearchInput para buscar.
   - Filtro de estado (DropdownButton: Todas/Activas/Inactivas).
   - ListView de Cards con: código, descripción, badge facturación público, badge estado.
   - Pull-to-refresh.
   - Paginación.
   - Al tap: abrir dialog de edición.
   - Long press o menú: activar/desactivar.
3. Dialog de creación/edición:
   - Campos: Código, Descripción, Switch facturación público.
   - Validación.
   - Loading state.
   - SnackBar de éxito/error.
```

### Prompt F4.2 — Participantes (Service + Screens)

```
Lee PROJECT_CONTEXT.md sección 10.4 y FLUTTER_CONTEXT.md.

Crea:

1. lib/services/participante_service.dart — CRUD + asignación ferias + porFeria.
2. lib/screens/configuracion/participantes/participantes_list_screen.dart:
   - ListView con Cards: nombre, identificación, teléfono, estado.
   - SearchInput + filtros (estado, tipo identificación).
   - FAB crear.
3. lib/screens/configuracion/participantes/participante_form_screen.dart:
   - Formulario scrolleable con secciones (usar ExpansionTile o secciones con títulos):
     - Info Básica: nombre*, tipo identificación* (dropdown), número identificación*, email, teléfono, procedencia.
     - Carné: número, fecha emisión (DatePicker), fecha vencimiento (DatePicker).
     - Info Médica: tipo sangre (dropdown), padecimientos (multiline).
     - Contacto Emergencia: nombre, teléfono.
   - Botones fijos al fondo: Cancelar + Guardar.
   - Después de guardar: sección de asignación de ferias con Chips y botón agregar.
```

### Prompt F4.3 — Productos (Service + Screen)

```
Lee PROJECT_CONTEXT.md sección 10.5.

Crea:

1. lib/services/producto_service.dart — CRUD + precios + porFeria.
2. lib/screens/configuracion/productos/productos_screen.dart:
   - ListView: código, descripción, cantidad de ferias con precio, estado.
   - FAB crear.
   - Dialog de creación/edición (código, descripción).
3. Dialog de gestión de precios:
   - Lista de precios por feria con botón eliminar.
   - Fila para agregar: dropdown feria + input precio + botón agregar.
```

### Prompt F4.4 — Usuarios (Service + Screen)

```
Lee PROJECT_CONTEXT.md sección 10.6.

Crea:

1. lib/services/usuario_service.dart.
2. lib/screens/configuracion/usuarios/usuarios_screen.dart:
   - ListView: nombre, email, rol (badge), ferias (count), estado.
   - Filtros: estado, rol.
   - FAB crear.
   - Dialog creación/edición: nombre, email, contraseña (solo creación), rol (dropdown), ferias (checkboxes).
   - Acciones: activar/desactivar, reset password, ver sesiones, eliminar.
3. Dialog de sesiones activas (similar a la web).
```

---

## FASE 5: SISTEMA DE IMPRESIÓN

### Prompt F5.1 — Implementar sistema de impresión completo

```
Lee FLUTTER_CONTEXT.md sección 8 completa y la documentación de impresión SUNMI proporcionada.

Crea el sistema de impresión completo:

1. lib/services/printer_service.dart — Clase abstracta:
   - PrinterType enum: sunmi, generic.
   - Métodos abstractos: isAvailable, printTicketFactura, printTicketParqueo, printTicketTarima, printTicketSanitario.

2. lib/utils/factura_ticket_layout.dart — Utilidad de layout:
   - Constante ANCHO_LINEA = 32 (para SUNMI V3 rollo 58mm).
   - Método separador(): línea de guiones.
   - Método centrar(texto): centrar en ANCHO_LINEA.
   - Método lineaDoble(izq, der): alinear texto izquierda y derecha.
   - Método wrapText(texto, ancho): envolver texto largo.
   - Método generarLineasFactura(Factura, feriaName): retorna List<TicketLine> con toda la estructura del ticket (encabezado, cliente, productos, totales, footer).
   - Método generarLineasParqueo(Parqueo, feriaName): igual para parqueo.
   - Método generarLineasTarima(Tarima, feriaName): igual para tarima.
   - Método generarLineasSanitario(Sanitario, feriaName): igual para sanitario.
   - Clase TicketLine con: text, isBold, isCenter, isLarge.

3. lib/services/sunmi_printer_service.dart — Implementación SUNMI:
   - Import sunmi_printer_plus.
   - isAvailable(): intentar SunmiPrinter.bindingPrinter(), retornar true si exitoso.
   - Para cada tipo de ticket:
     a) Generar líneas con FacturaTicketLayout.
     b) Iterar líneas y enviar con SunmiPrinter.printText() aplicando SunmiTextStyle según isBold/isCenter/isLarge.
     c) Para parqueo: agregar SunmiPrinter.printQRCode() con la placa.
     d) Al final: SunmiPrinter.lineWrap(3) + SunmiPrinter.cutPaper().

4. lib/services/pdf_printer_service.dart — Fallback PDF:
   - isAvailable(): siempre true.
   - Para cada tipo de ticket:
     a) Generar PDF con package:pdf usando PdfPageFormat.roll80.
     b) Crear contenido equivalente al ticket SUNMI pero en formato PDF.
     c) Mostrar con Printing.layoutPdf().

5. lib/services/printer_factory.dart:
   - Método estático detect():
     a) Intentar SUNMI → retornar SunmiPrinterService si disponible.
     b) Fallback → retornar PdfPrinterService.

6. lib/providers/printer_provider.dart — ChangeNotifier:
   - initialize(): detectar impresora con PrinterFactory.
   - printerType: exponer tipo detectado.
   - Métodos: printFactura, printParqueo, printTarima, printSanitario.
   - Registrar en MultiProvider de app.dart.
```

---

## FASE 6: MÓDULOS TRANSACCIONALES

### Prompt F6.1 — Facturación (Service + Provider)

```
Lee PROJECT_CONTEXT.md sección 10.7 (API Facturación) y FLUTTER_CONTEXT.md sección 11.2.

Crea:

1. lib/services/factura_service.dart:
   - listar(filtros): GET /api/v1/facturas con query params (estado, fecha_desde, fecha_hasta, page).
   - obtener(id): GET /api/v1/facturas/{id}.
   - crear(data): POST /api/v1/facturas.
   - actualizar(id, data): PUT /api/v1/facturas/{id}.
   - facturar(id): POST /api/v1/facturas/{id}/facturar.
   - eliminar(id): DELETE /api/v1/facturas/{id}.

2. lib/providers/factura_provider.dart — ChangeNotifier:
   - State: facturas[], isLoading, currentPage, totalPages, filtros.
   - Métodos que llaman al service y notifican listeners.
```

### Prompt F6.2 — Facturación (Listado Screen)

```
Crea lib/screens/facturacion/facturacion_list_screen.dart:

- AppBarCustom "Facturación".
- SearchInput + filtros (estado, fecha desde/hasta).
- ListView de Cards por factura:
  - Consecutivo (o "Borrador" si no tiene).
  - Nombre participante (o nombre público).
  - Puesto.
  - Total formateado como moneda.
  - StatusBadge con estado.
  - Fecha.
  - Nombre del usuario (solo si admin/supervisor).
- FAB "+" para crear nueva factura.
- Pull-to-refresh.
- Paginación.
- Al tap en una factura: navegar a detalle.
- Menú contextual (PopupMenuButton) por factura con acciones condicionales:
  - Borrador: Editar, Facturar, Eliminar
  - Facturado: Ver, Imprimir, Eliminar
  - Eliminado: Ver
- Al "Facturar": ConfirmDialog → llamar API → imprimir ticket automáticamente con printerProvider.
```

### Prompt F6.3 — Facturación (Formulario Screen)

```
Lee FLUTTER_CONTEXT.md sección 11.2 y PROJECT_CONTEXT.md reglas de facturación.

Crea lib/screens/facturacion/factura_form_screen.dart:

Este es el screen más complejo de la app. Formulario scrolleable con secciones:

1. Sección superior: badge feria activa.
2. Checkbox "Público General" (solo si feria.facturacionPublico).
   - Si activo: ocultar selector participante, mostrar TextField nombre.
   - Si inactivo: mostrar selector participante.
3. ComboboxSearch de Participante: busca en /participantes/por-feria.
4. Campos: Tipo Puesto (TextField), Número Puesto (TextField).
5. Sección Productos:
   - ComboboxSearch de Producto: busca en /productos/por-feria.
   - Al seleccionar: mostrar precio (no editable), cantidad default 1.
   - Campo cantidad: TextFormField numérico (mínimo 1, incrementos 0.5).
   - Botón "Agregar" (ElevatedButton o IconButton).
   - Al agregar: añadir a la lista y excluir producto del selector.
6. Lista de productos agregados (ListView dentro de Card):
   - Por cada línea: nombre producto, cantidad, precio unitario, subtotal, botón eliminar.
   - Total recalculado en tiempo real con setState.
7. Observaciones: TextField multiline.
8. Sección Resumen (Card destacada):
   - Total: MoneyText.
   - Monto Pago: TextField numérico.
   - Cambio: calculado en tiempo real (rojo si negativo).
9. Botones fijos al fondo (BottomAppBar o Padding):
   - Cancelar (OutlinedButton): navegar atrás con confirmación si hay cambios.
   - Guardar (ElevatedButton): guardar borrador → SnackBar éxito.
   - Facturar (ElevatedButton primario): ConfirmDialog → guardar + emitir → imprimir ticket → navegar a listado.
```

### Prompt F6.4 — Facturación (Detalle Screen)

```
Crea lib/screens/facturacion/factura_detail_screen.dart:

- AppBar con título "Factura {consecutivo}" o "Borrador".
- Acciones en AppBar según estado:
  - Borrador: Editar (IconButton), Facturar, Eliminar.
  - Facturado: Imprimir (IconButton).
- Card con info principal: consecutivo, estado (badge), fecha, feria, usuario.
- Card con info cliente: nombre, identificación, puesto.
- Card con detalle de productos: tabla/lista con producto, cantidad, precio, subtotal.
- Card con resumen: total, monto pago, cambio.
- Observaciones si las tiene.
```

### Prompt F6.5 — Parqueos

```
Lee PROJECT_CONTEXT.md sección 10.8 y FLUTTER_CONTEXT.md sección 11.3.

Crea:

1. lib/services/parqueo_service.dart:
   - listar(filtros): GET /api/v1/parqueos con query params:
     - estado
     - placa
     - fecha
     - page
     - per_page
     - sort
     - direction
   - obtener(id): GET /api/v1/parqueos/{id}.
   - crear(data): POST /api/v1/parqueos.
     - payload: placa, observaciones? (opcional)
   - registrarSalida(id, observaciones?): PATCH /api/v1/parqueos/{id}/salida.
   - cancelar(id, observaciones?): PATCH /api/v1/parqueos/{id}/cancelar.
   - obtenerPdf(id): GET /api/v1/parqueos/{id}/pdf.
   - Importante:
     - La respuesta del listado viene paginada.
     - El listado también retorna tarifa_actual en el payload raíz; exponerla para usarla en la UI.
     - Convertir placa a uppercase antes de enviar al API.

2. lib/providers/parqueo_provider.dart — ChangeNotifier:
   - State:
     - parqueos[]
     - parqueoSeleccionado
     - tarifaActual
     - isLoading
     - isSubmitting
     - currentPage
     - totalPages
     - totalItems
     - filtros: estado, placa, fecha
   - Métodos:
     - cargarParqueos({reset = false})
     - buscarPorPlaca(String value)
     - setEstadoFiltro(String? estado)
     - setFechaFiltro(DateTime? fecha)
     - limpiarFiltros()
     - registrarParqueo({required String placa, String? observaciones})
     - registrarSalida(int id, {String? observaciones})
     - cancelarParqueo(int id, {String? observaciones})
     - obtenerParqueo(int id)
   - Después de crear/salida/cancelar:
     - actualizar el listado local o recargar la página actual
     - notificar listeners
     - preservar filtros actuales

3. lib/screens/parqueos/parqueos_screen.dart:
   - Usar el Scaffold base con AppBarCustom título "Parqueos".
   - SearchInput busca por placa con debounce.
   - Barra de filtros compacta:
     - Dropdown estado: Todos / Activo / Finalizado / Cancelado
     - Selector de fecha (DatePicker) para fecha_hora_ingreso
     - Botón limpiar filtros
   - ListView de Cards, cada card muestra:
     - placa en grande y bold
     - fecha/hora ingreso
     - fecha/hora salida si existe
     - tarifa con MoneyText
     - StatusBadge con estado
     - nombre del usuario que registró
     - observaciones si existen
   - Pull-to-refresh.
   - Paginación.
   - EmptyState cuando no hay resultados.
   - LoadingWidget mientras carga.
   - FAB "+" visible solo si authProvider.hasPermission('parqueos.crear').
   - Acciones por card con PopupMenuButton, según permisos y estado:
     - Activo:
       - Registrar salida (si tiene permiso parqueos.salida)
       - Cancelar (si tiene permiso parqueos.cancelar)
       - Imprimir / Reimprimir ticket
     - Finalizado:
       - Ver detalle rápido
       - Imprimir / Reimprimir ticket
     - Cancelado:
       - Ver detalle rápido
       - Imprimir / Reimprimir ticket
   - Al registrar salida:
     - mostrar ConfirmDialog
     - llamar API
     - refrescar listado
     - mostrar SnackBar éxito/error
   - Al cancelar:
     - pedir confirmación y observación opcional
     - llamar API
     - refrescar listado
     - mostrar SnackBar éxito/error
   - Al imprimir:
     - usar printerProvider.printParqueo(parqueo, feriaProvider.feriaActiva!.descripcion)

4. Dialog de registro rápido (showDialog o showModalBottomSheet):
   - Diseño optimizado para uso rápido en SUNMI V3.
   - TextField placa:
     - autofocus
     - auto-uppercase con TextCapitalization.characters
     - maxLength 20
     - action done/send
   - TextField observaciones opcional.
   - Tarifa actual mostrada automáticamente en una Card o Container destacado (no editable).
   - Validación:
     - placa obligatoria
     - trim automático
   - Botones:
     - Cancelar
     - Registrar
   - Al registrar:
     - deshabilitar botón mientras guarda
     - POST API
     - cerrar modal
     - refrescar listado
     - imprimir ticket automáticamente con printerProvider
     - mostrar SnackBar de éxito
   - Debe poder enviarse con Enter desde el campo placa (onFieldSubmitted).

5. Detalles de comportamiento:
   - El backend maneja estados: activo, finalizado, cancelado.
   - Solo los parqueos en estado activo pueden registrar salida o cancelarse.
   - Inspector puede ver listado pero no registrar ni modificar.
   - Facturador solo verá sus propios parqueos; no asumir acceso global en la UI.
   - Si el API devuelve tarifa_actual en el listado, usar ese valor en el modal de registro rápido.
   - Al crear un parqueo exitosamente, el ticket se imprime automáticamente e incluye QR con la placa.
```

### Prompt F6.6 — Tarimas

```
Lee PROJECT_CONTEXT.md sección 10.9.

Crea:

1. lib/services/tarima_service.dart.
2. lib/providers/tarima_provider.dart.
3. lib/screens/tarimas/tarimas_screen.dart:
   - ListView: participante, # tarima, cantidad, total, estado, fecha.
   - FAB crear.
   - Dialog/BottomSheet de facturación:
     - ComboboxSearch participante (filtrado por feria).
     - Cantidad (TextField numérico).
     - Número tarima (opcional).
     - Precio y total calculados automáticamente.
     - Botón "Facturar" → crear + imprimir ticket.
```

### Prompt F6.7 — Sanitarios

```
Lee PROJECT_CONTEXT.md sección 10.10.

Crea:

1. lib/services/sanitario_service.dart.
2. lib/providers/sanitario_provider.dart.
3. lib/screens/sanitarios/sanitarios_screen.dart:
   - Similar a tarimas pero participante es opcional.
   - Dialog: participante (opcional), cantidad, observaciones.
   - Al facturar: crear + imprimir ticket.
```

---

## FASE 7: CONFIGURACIONES Y DASHBOARD

### Prompt F7.1 — Configuraciones

```
Crea:

1. lib/services/configuracion_service.dart.
2. lib/screens/configuraciones/configuraciones_screen.dart:
   - Lista de configuraciones de la feria activa.
   - Campos editables para: tarifa parqueo, precio tarima, precio sanitario.
   - Botón guardar.
   - Solo visible para admin.
```

### Prompt F7.2 — Dashboard

```
Lee PROJECT_CONTEXT.md sección 10.12 y FLUTTER_CONTEXT.md.

Crea:

1. lib/services/dashboard_service.dart.
2. lib/screens/dashboard/dashboard_screen.dart:

Contenido condicional por rol:

Admin/Supervisor:
- 4 StatsCards en grid (2 columnas): Facturas, Parqueos, Tarimas, Sanitarios (monto + cantidad).
- Card grande: Recaudación Total del día.
- Gráfico de línea (fl_chart): tendencia de recaudación últimos 7 días.
- Gráfico de barras: facturación por producto (top 5).
- Lista resumida: últimas 10 facturas.

Facturador:
- StatsCards: mis facturas hoy, mis borradores.
- Lista: mis últimas 10 facturas.

Inspector:
- StatsCards generales (solo lectura).

Todos:
- Pull-to-refresh para actualizar datos.
- Selector de rango de fechas (opcional).
```

---

## FASE 8: PULIDO

### Prompt F8.1 — Manejo de errores y UX

```
Revisa toda la app y:

1. Verificar que todos los errores HTTP muestren SnackBar descriptivos.
2. Verificar que los estados de carga (loading) se muestren en todas las pantallas.
3. Verificar que pull-to-refresh funcione en todos los listados.
4. Verificar que la validación de formularios funcione correctamente.
5. Verificar que el cambio de feria recargue los datos de la pantalla actual.
6. Verificar que cerrar sesión limpie todo (token, feria, providers).
7. Verificar que al perder conexión se muestre mensaje apropiado.
8. Verificar que la detección de impresora funcione al iniciar la app.
9. Verificar que los permisos filtren correctamente menú y acciones.
10. Agregar animaciones sutiles en transiciones de pantalla.
```

### Prompt F8.2 — Optimización para SUNMI V3

```
Optimiza la app para el dispositivo SUNMI V3:

1. Verificar que la UI se vea bien en pantalla 5.5" (probar con emulador de resolución similar).
2. Tamaños de fuente adecuados para pantalla compacta.
3. Botones con tamaño mínimo de 48dp para touch.
4. Formularios scrolleables que no queden cortados.
5. Verificar que la impresión funcione correctamente:
   - Ticket de factura con todos los detalles.
   - Ticket de parqueo con QR.
   - Ticket de tarima.
   - Ticket de sanitario.
6. Verificar el fallback a PDF cuando no hay impresora SUNMI.
7. Configurar el splash screen y el ícono de la app.
8. Configurar el nombre de la app en AndroidManifest.xml: "Ferias del Agricultor".
```

### Prompt F8.3 — Build de producción

```
Prepara la app para producción:

1. Configurar la URL del API de producción en api_config.dart (usar variables de entorno o flavor).
2. Generar el APK de release: flutter build apk --release.
3. Verificar que el APK funcione correctamente en un dispositivo real o emulador.
4. Configurar ProGuard si es necesario para el release.
5. Documentar en README.md:
   - Cómo instalar dependencias.
   - Cómo configurar la URL del API.
   - Cómo compilar para desarrollo y producción.
   - Cómo instalar en un SUNMI V3.
```
