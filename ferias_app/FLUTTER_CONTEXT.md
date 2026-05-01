# FLUTTER_CONTEXT.md — Ferias del Agricultor (App Android)

> **Este archivo es la fuente de verdad para la app Flutter.** Todo agente de AI debe leer este archivo junto con `PROJECT_CONTEXT.md` (que define la API, modelo de datos y reglas de negocio del backend) antes de generar código Flutter.

---

## 1. RESUMEN

App Android nativa con Flutter que replica la funcionalidad completa de la aplicación web. Consume la misma API REST de Laravel. Optimizada para dispositivos SUNMI V3 con impresora térmica integrada, con fallback a PDF para otros dispositivos.

---

## 2. STACK TECNOLÓGICO

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3.x (última estable) |
| Lenguaje | Dart |
| Plataforma | Solo Android |
| Estado | Provider (ChangeNotifierProvider) |
| HTTP | Dio |
| Almacenamiento local | SharedPreferences (sesión/token) |
| Routing | GoRouter |
| Formularios | Flutter Form Builder + validación manual |
| Gráficos | fl_chart |
| Impresión SUNMI | sunmi_printer_plus ^4.1.1 |
| Impresión fallback | pdf + printing (PdfPageFormat.roll80) |
| Iconos | Material Icons (incluidos en Flutter) |

---

## 3. ARQUITECTURA

### 3.1 Patrón
La app sigue el patrón **Provider + Services**:
- **Services**: clases que encapsulan llamadas HTTP al API y lógica de negocio.
- **Providers**: ChangeNotifiers que mantienen estado reactivo y notifican a la UI.
- **Screens**: widgets que consumen Providers y renderizan la UI.
- **Widgets**: componentes reutilizables.

### 3.2 Flujo de datos
```
Screen → Provider → Service → API (Dio) → Laravel Backend
                                    ↓
Screen ← Provider ← Service ← Response JSON
```

### 3.3 Autenticación
- Se usa **token API de Sanctum** (no cookies).
- Al hacer login, el API retorna un token Bearer.
- El token se almacena en SharedPreferences.
- Dio interceptor agrega el header `Authorization: Bearer {token}` en cada request.
- El header `X-Feria-Id` se agrega automáticamente con la feria activa.

**Nota importante:** A diferencia de la SPA web que usa cookies/sesión, la app Flutter usa tokens API. El endpoint de login del backend debe soportar ambos modos (ya configurado con Sanctum).

---

## 4. ESTRUCTURA DEL PROYECTO

```
ferias_app/
├── lib/
│   ├── main.dart
│   ├── app.dart                      ← MaterialApp + GoRouter + Providers
│   ├── config/
│   │   ├── api_config.dart           ← Base URL, timeouts
│   │   ├── theme.dart                ← Tema Material, colores, tipografía
│   │   └── routes.dart               ← Definición de rutas GoRouter
│   ├── models/
│   │   ├── user.dart
│   │   ├── feria.dart
│   │   ├── participante.dart
│   │   ├── producto.dart
│   │   ├── factura.dart
│   │   ├── factura_detalle.dart
│   │   ├── parqueo.dart
│   │   ├── tarima.dart
│   │   ├── sanitario.dart
│   │   └── configuracion.dart
│   ├── services/
│   │   ├── api_service.dart          ← Dio client con interceptores
│   │   ├── auth_service.dart
│   │   ├── feria_service.dart
│   │   ├── participante_service.dart
│   │   ├── producto_service.dart
│   │   ├── usuario_service.dart
│   │   ├── factura_service.dart
│   │   ├── parqueo_service.dart
│   │   ├── tarima_service.dart
│   │   ├── sanitario_service.dart
│   │   ├── configuracion_service.dart
│   │   ├── dashboard_service.dart
│   │   ├── printer_service.dart       ← Contrato abstracto
│   │   ├── sunmi_printer_service.dart ← Implementación SUNMI
│   │   ├── pdf_printer_service.dart   ← Fallback PDF
│   │   └── printer_factory.dart       ← Detección automática
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── feria_provider.dart
│   │   ├── factura_provider.dart
│   │   ├── parqueo_provider.dart
│   │   ├── tarima_provider.dart
│   │   ├── sanitario_provider.dart
│   │   ├── printer_provider.dart
│   │   └── ...
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── seleccion_feria_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── facturacion/
│   │   │   ├── facturacion_list_screen.dart
│   │   │   ├── factura_form_screen.dart
│   │   │   └── factura_detail_screen.dart
│   │   ├── parqueos/
│   │   │   └── parqueos_screen.dart
│   │   ├── tarimas/
│   │   │   └── tarimas_screen.dart
│   │   ├── sanitarios/
│   │   │   └── sanitarios_screen.dart
│   │   ├── configuracion/
│   │   │   ├── ferias/
│   │   │   ├── participantes/
│   │   │   ├── productos/
│   │   │   └── usuarios/
│   │   └── configuraciones/
│   │       └── configuraciones_screen.dart
│   ├── widgets/
│   │   ├── app_drawer.dart            ← Navegación lateral
│   │   ├── app_bar_custom.dart        ← AppBar con feria activa
│   │   ├── data_table_custom.dart     ← Tabla con paginación/búsqueda
│   │   ├── search_input.dart
│   │   ├── status_badge.dart
│   │   ├── confirm_dialog.dart
│   │   ├── stats_card.dart
│   │   ├── empty_state.dart
│   │   ├── loading_widget.dart
│   │   ├── money_text.dart            ← Formato moneda CRC
│   │   ├── combobox_search.dart       ← Selector con búsqueda async
│   │   └── form_field_custom.dart
│   └── utils/
│       ├── formatters.dart            ← Formato moneda, fechas
│       ├── validators.dart            ← Validaciones de formularios
│       └── factura_ticket_layout.dart ← Layout compartido para tickets
├── android/
│   └── ...
├── pubspec.yaml
└── README.md
```

---

## 5. CONVENCIONES DE NOMBRADO

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Archivos | snake_case | factura_service.dart |
| Clases | PascalCase | FacturaService |
| Variables/funciones | camelCase | getMisFacturas() |
| Constantes | camelCase o UPPER_SNAKE | apiBaseUrl, MAX_RETRIES |
| Modelos | PascalCase, singular | Factura, Participante |
| Screens | PascalCase + Screen | FacturacionListScreen |
| Providers | PascalCase + Provider | FacturaProvider |
| Services | PascalCase + Service | FacturaService |
| Widgets | PascalCase | StatusBadge, StatsCard |

---

## 6. MODELOS DART

Cada modelo debe tener:
- Constructor con named parameters
- Factory `fromJson(Map<String, dynamic>)` para deserializar del API
- Método `toJson()` para serializar al API (donde aplique)
- Campos tipados (no usar dynamic)

### Ejemplo de referencia:
```dart
class Feria {
  final int id;
  final String codigo;
  final String descripcion;
  final bool facturacionPublico;
  final bool activa;
  final DateTime createdAt;

  Feria({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.facturacionPublico,
    required this.activa,
    required this.createdAt,
  });

  factory Feria.fromJson(Map<String, dynamic> json) {
    return Feria(
      id: json['id'],
      codigo: json['codigo'],
      descripcion: json['descripcion'],
      facturacionPublico: json['facturacion_publico'] ?? false,
      activa: json['activa'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

---

## 7. API SERVICE (Dio)

### 7.1 Configuración
```dart
class ApiService {
  late Dio _dio;
  String? _token;
  int? _feriaId;

  // Base URL configurable por ambiente
  static const String baseUrl = 'https://tu-dominio.com/api/v1';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        if (_feriaId != null) {
          options.headers['X-Feria-Id'] = '$_feriaId';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expirado, redirigir a login
        }
        handler.next(error);
      },
    ));
  }

  void setToken(String token) => _token = token;
  void setFeriaId(int id) => _feriaId = id;
  void clearAuth() { _token = null; _feriaId = null; }
}
```

### 7.2 Login con Token
A diferencia de la web (cookies), Flutter usa tokens:
```dart
// POST /api/v1/auth/login
// Response incluye token + user data
final response = await dio.post('/auth/login', data: {
  'email': email,
  'password': password,
  'device_name': 'sunmi_v3',  // Para token API de Sanctum
});
final token = response.data['token'];
```

**Nota:** El backend debe tener un endpoint que genere tokens API con `$user->createToken('device_name')`. Si el login actual solo maneja sesiones, se debe agregar lógica condicional para emitir tokens cuando el request venga de la app móvil (detectar por header o parámetro).

---

## 8. SISTEMA DE IMPRESIÓN

### 8.1 Arquitectura de Impresión

```
PrinterFactory.detect()
       │
       ├── SUNMI detectado? → SunmiPrinterService
       │
       └── No detectado? → PdfPrinterService (fallback)
```

### 8.2 Contrato (PrinterService)
```dart
enum PrinterType { sunmi, generic }

abstract class PrinterService {
  PrinterType get type;
  Future<bool> isAvailable();
  Future<void> printTicketFactura(Factura factura, String feriaName);
  Future<void> printTicketParqueo(Parqueo parqueo, String feriaName);
  Future<void> printTicketTarima(Tarima tarima, String feriaName);
  Future<void> printTicketSanitario(Sanitario sanitario, String feriaName);
}
```

### 8.3 Detección (PrinterFactory)
```dart
class PrinterFactory {
  static Future<PrinterService> detect() async {
    // 1. Intentar SUNMI
    try {
      final status = await SunmiPrinter.bindingPrinter();
      if (status != null) {
        return SunmiPrinterService();
      }
    } catch (_) {}

    // 2. Fallback a PDF
    return PdfPrinterService();
  }
}
```

### 8.4 Implementación SUNMI (SunmiPrinterService)
- Plugin: `sunmi_printer_plus` ^4.1.1
- Usar `SunmiPrinter.printText()` con `SunmiTextStyle` para estilos
- Usar `SunmiPrinter.line()` para separadores
- Usar `SunmiPrinter.printQRCode()` para QR en parqueos (con la placa)
- Usar `SunmiPrinter.cutPaper()` al final
- Ancho de rollo: **32 columnas** para rollo 58mm del SUNMI V3
- Formato del ticket: usar `FacturaTicketLayout` para generar las líneas

### 8.5 Fallback PDF (PdfPrinterService)
- Paquetes: `pdf` + `printing`
- Generar PDF con `PdfPageFormat.roll80`
- Mostrar diálogo de impresión del sistema con `Printing.layoutPdf()`
- Mismo contenido que el ticket SUNMI pero en formato PDF

### 8.6 Layout de Ticket (FacturaTicketLayout)
Clase utilitaria que define el contenido de cada tipo de ticket:
- Ancho de línea: 32 caracteres
- Separadores: línea de guiones
- Encabezado: nombre feria, fecha, consecutivo
- Detalle: productos con cantidad, precio, subtotal
- Totales: subtotal, pago, cambio
- Footer: nombre del usuario, hora

### 8.7 PrinterProvider
```dart
class PrinterProvider extends ChangeNotifier {
  PrinterService? _printerService;
  bool _isInitialized = false;

  Future<void> initialize() async {
    _printerService = await PrinterFactory.detect();
    _isInitialized = true;
    notifyListeners();
  }

  PrinterType get printerType => _printerService?.type ?? PrinterType.generic;
  bool get isReady => _isInitialized;

  Future<void> printFactura(Factura factura, String feriaName) async {
    await _printerService?.printTicketFactura(factura, feriaName);
  }
  // ... otros métodos de impresión
}
```

---

## 9. NAVEGACIÓN

### 9.1 Estructura
La app usa un Drawer (menú lateral) como navegación principal, similar al sidebar de la web.

### 9.2 Rutas
| Ruta | Screen | Permiso |
|------|--------|---------|
| /login | LoginScreen | — |
| /seleccionar-feria | SeleccionFeriaScreen | — |
| /dashboard | DashboardScreen | dashboard.ver |
| /facturacion | FacturacionListScreen | facturas.ver |
| /facturacion/crear | FacturaFormScreen | facturas.crear |
| /facturacion/:id | FacturaDetailScreen | facturas.ver |
| /facturacion/:id/editar | FacturaFormScreen | facturas.editar |
| /parqueos | ParqueosScreen | parqueos.ver |
| /tarimas | TarimasScreen | tarimas.ver |
| /sanitarios | SanitariosScreen | sanitarios.ver |
| /configuracion/ferias | FeriasScreen | ferias.ver |
| /configuracion/participantes | ParticipantesListScreen | participantes.ver |
| /configuracion/participantes/crear | ParticipanteFormScreen | participantes.crear |
| /configuracion/participantes/:id | ParticipanteFormScreen | participantes.editar |
| /configuracion/productos | ProductosScreen | productos.ver |
| /configuracion/usuarios | UsuariosScreen | usuarios.ver |
| /configuracion/ajustes | ConfiguracionesScreen | configuracion.ver |

### 9.3 Drawer (Menú lateral)
Mismos items que el sidebar web, con iconos Material equivalentes:
| Item | Icono Material | Ruta | Permiso |
|------|---------------|------|---------|
| Dashboard | Icons.dashboard | /dashboard | dashboard.ver |
| Facturación | Icons.receipt_long | /facturacion | facturas.ver |
| Parqueo | Icons.directions_car | /parqueos | parqueos.ver |
| Tarimas | Icons.inventory_2 | /tarimas | tarimas.ver |
| Sanitarios | Icons.water_drop | /sanitarios | sanitarios.ver |
| Ferias | Icons.location_on | /configuracion/ferias | ferias.ver |
| Participantes | Icons.people | /configuracion/participantes | participantes.ver |
| Productos | Icons.category | /configuracion/productos | productos.ver |
| Usuarios | Icons.manage_accounts | /configuracion/usuarios | usuarios.ver |
| Configuración | Icons.settings | /configuracion/ajustes | configuracion.ver |

Items se muestran solo si el usuario tiene el permiso correspondiente.

---

## 10. UI / DISEÑO

### 10.1 Tema
- Material Design 3 (Material You)
- Color primario: Azul (#2563EB) — mismo que la web
- Fuente: Roboto (default de Flutter)
- Modo claro por defecto

### 10.2 Patrones de UI

**Listados:**
- ListView con pull-to-refresh
- Paginación infinita (cargar más al hacer scroll al fondo) O paginación con botones
- SearchBar en AppBar o debajo del AppBar
- Filtros en un BottomSheet o DropdownButtons
- FAB (Floating Action Button) para acción de crear

**Formularios:**
- Formularios scrolleables con secciones
- Validación en tiempo real
- Botones en la parte inferior (fixed)
- Loading indicator al enviar

**Detalles:**
- Card con la información principal
- Acciones en AppBar (editar, eliminar, imprimir)
- Secciones expandibles si hay mucha info

### 10.3 Componentes Reutilizables
| Widget | Descripción |
|--------|-------------|
| AppDrawer | Drawer con menú filtrado por permisos |
| AppBarCustom | AppBar con nombre de feria activa |
| DataTableCustom | Tabla/Lista con paginación y búsqueda |
| SearchInput | TextField con debounce para búsqueda |
| StatusBadge | Chip con color según estado |
| ConfirmDialog | AlertDialog para acciones destructivas |
| StatsCard | Card con icono, título y valor para dashboard |
| EmptyState | Widget centrado cuando no hay datos |
| LoadingWidget | CircularProgressIndicator centrado |
| MoneyText | Text formateado como moneda CRC (₡) |
| ComboboxSearch | Autocomplete con búsqueda async al API |
| FormFieldCustom | Wrapper con label, validación y error |

---

## 11. FLUJOS CRÍTICOS

### 11.1 Login
1. Usuario ingresa email y contraseña.
2. POST /api/v1/auth/login con `device_name` para obtener token.
3. Guardar token en SharedPreferences.
4. Configurar Dio con el token.
5. Si tiene 1 feria → auto-seleccionar → dashboard.
6. Si tiene múltiples ferias → pantalla de selección.

### 11.2 Facturación
Mismo flujo que la web (ver PROJECT_CONTEXT.md sección 10.7):
1. Seleccionar participante (Autocomplete filtrado por feria).
2. Checkbox público general (si aplica).
3. Agregar productos con cantidad y precio automático.
4. Calcular totales en tiempo real.
5. Guardar (borrador) o Facturar (emitir + imprimir).
6. Al facturar: el API genera consecutivo → app recibe respuesta → imprime ticket automáticamente vía PrinterProvider.

### 11.3 Parqueo Rápido
1. FAB "+" abre dialog/bottom sheet.
2. Input de placa (auto-uppercase).
3. Tarifa mostrada automáticamente.
4. Al registrar: POST al API → imprime ticket automáticamente.
5. El ticket SUNMI incluye QR con la placa.

### 11.4 Cambio de Feria
1. Tap en el nombre de feria en AppBar.
2. BottomSheet con lista de ferias asignadas.
3. Al seleccionar: actualizar feriaProvider → recargar datos de la pantalla actual.

---

## 12. MANEJO DE ERRORES

- **Sin conexión:** mostrar SnackBar "Sin conexión a internet" y permitir reintentar.
- **401 (token expirado):** limpiar sesión y redirigir a login automáticamente.
- **403 (sin permiso):** SnackBar "No tiene permisos para esta acción".
- **422 (validación):** mostrar errores debajo de cada campo del formulario.
- **500 (error servidor):** SnackBar "Error del servidor, intente de nuevo".
- **Timeout:** SnackBar "La conexión tardó demasiado, intente de nuevo".

---

## 13. ALMACENAMIENTO LOCAL

Solo se almacena en SharedPreferences:
- Token de autenticación
- ID y datos básicos de la feria activa
- Datos básicos del usuario (nombre, email, rol)

**No se cachean datos del API localmente.** Toda la data se consulta en tiempo real. Si en el futuro se necesita modo offline, se evaluará SQLite.

---

## 14. PERMISOS ANDROID

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

No se necesitan permisos adicionales. La impresión SUNMI usa el servicio interno del dispositivo, no requiere permisos de Bluetooth.

---

## 15. CONSIDERACIONES SUNMI V3

- Pantalla: 5.5" — diseñar para pantalla compacta.
- Impresora: térmica integrada, rollo 58mm (32 columnas de texto).
- El plugin `sunmi_printer_plus` maneja la comunicación con la impresora internamente.
- No necesita pairing Bluetooth ni permisos especiales.
- `SunmiPrinter.cutPaper()` al final de cada ticket.
- Para QR: `SunmiPrinter.printQRCode(data, size: 200)`.
