import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/feria_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/seleccion_feria_screen.dart';
import '../screens/configuracion/ferias/ferias_screen.dart';
import '../screens/configuracion/items_diagnostico/items_diagnostico_screen.dart';
import '../screens/configuracion/participantes/participante_form_screen.dart';
import '../screens/configuracion/participantes/participantes_list_screen.dart';
import '../screens/configuracion/productos/productos_screen.dart';
import '../screens/configuracion/usuarios/usuarios_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/facturacion/factura_detail_screen.dart';
import '../screens/facturacion/factura_form_screen.dart';
import '../screens/facturacion/facturacion_list_screen.dart';
import '../screens/inspecciones/inspecciones_screen.dart';
import '../screens/parqueos/parqueos_screen.dart';
import '../screens/sanitarios/sanitarios_screen.dart';
import '../screens/tarimas/tarimas_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String seleccionarFeria = '/seleccionar-feria';
  static const String dashboard = '/dashboard';
  static const String facturacion = '/facturacion';
  static const String facturacionCrear = '/facturacion/crear';
  static const String parqueos = '/parqueos';
  static const String tarimas = '/tarimas';
  static const String sanitarios = '/sanitarios';
  static const String inspecciones = '/inspecciones';
  static const String ferias = '/configuracion/ferias';
  static const String participantes = '/configuracion/participantes';
  static const String participantesCrear = '/configuracion/participantes/crear';
  static const String productos = '/configuracion/productos';
  static const String itemsDiagnostico = '/configuracion/items-diagnostico';
  static const String usuarios = '/configuracion/usuarios';
  static const String ajustes = '/configuracion/ajustes';

  static final Map<String, String> _permissions = <String, String>{
    dashboard: 'dashboard.ver',
    facturacion: 'facturas.ver',
    facturacionCrear: 'facturas.crear',
    parqueos: 'parqueos.ver',
    tarimas: 'tarimas.ver',
    sanitarios: 'sanitarios.ver',
    inspecciones: 'inspecciones.ver',
    ferias: 'ferias.ver',
    participantes: 'participantes.ver',
    participantesCrear: 'participantes.crear',
    productos: 'productos.ver',
    itemsDiagnostico: 'configuracion.ver',
    usuarios: 'usuarios.ver',
    ajustes: 'configuracion.ver',
  };

  static GoRouter createRouter({
    required AuthProvider authProvider,
    required FeriaProvider feriaProvider,
  }) {
    return GoRouter(
      initialLocation: dashboard,
      refreshListenable: Listenable.merge(<Listenable>[
        authProvider,
        feriaProvider,
      ]),
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isLoggingIn = location == login;
        final isSelectingFeria = location == seleccionarFeria;

        if (authProvider.isLoading || feriaProvider.isLoading) {
          return null;
        }

        if (!authProvider.isAuthenticated) {
          return isLoggingIn ? null : login;
        }

        if (feriaProvider.feriaActiva == null) {
          return isSelectingFeria ? null : seleccionarFeria;
        }

        if (isLoggingIn || isSelectingFeria) {
          return _firstAccessibleRoute(authProvider);
        }

        final requiredPermission = _permissionForLocation(location);

        if (requiredPermission == null) {
          return null;
        }

        if (!authProvider.hasPermission(requiredPermission)) {
          final fallbackRoute = _firstAccessibleRoute(authProvider);
          return fallbackRoute == location ? null : fallbackRoute;
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: seleccionarFeria,
          builder: (context, state) => const SeleccionFeriaScreen(),
        ),
        GoRoute(
          path: dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: facturacion,
          builder: (context, state) => const FacturacionListScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'crear',
              builder: (context, state) => const FacturaFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => FacturaDetailScreen(
                facturaId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: 'editar',
                  builder: (context, state) => FacturaFormScreen(
                    facturaId: int.tryParse(state.pathParameters['id'] ?? ''),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: parqueos,
          builder: (context, state) => const ParqueosScreen(),
        ),
        GoRoute(
          path: tarimas,
          builder: (context, state) => const TarimasScreen(),
        ),
        GoRoute(
          path: sanitarios,
          builder: (context, state) => const SanitariosScreen(),
        ),
        GoRoute(
          path: inspecciones,
          builder: (context, state) => const InspeccionesScreen(),
        ),
        GoRoute(
          path: ferias,
          builder: (context, state) => const FeriasScreen(),
        ),
        GoRoute(
          path: participantes,
          builder: (context, state) => const ParticipantesListScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'crear',
              builder: (context, state) => const ParticipanteFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => ParticipanteFormScreen(
                participanteId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: productos,
          builder: (context, state) => const ProductosScreen(),
        ),
        GoRoute(
          path: itemsDiagnostico,
          builder: (context, state) => const ItemsDiagnosticoScreen(),
        ),
        GoRoute(
          path: usuarios,
          builder: (context, state) => const UsuariosScreen(),
        ),
        GoRoute(
          path: ajustes,
          builder: (context, state) =>
              const _RoutePlaceholderScreen(title: 'Configuraciones'),
        ),
      ],
    );
  }

  static String? _permissionForLocation(String location) {
    if (location.startsWith('/facturacion/') && location.endsWith('/editar')) {
      return 'facturas.editar';
    }

    if (location.startsWith('/facturacion/')) {
      return 'facturas.ver';
    }

    if (location.startsWith('/configuracion/participantes/') &&
        !location.endsWith('/crear')) {
      return 'participantes.editar';
    }

    return _permissions[location];
  }

  static String _firstAccessibleRoute(AuthProvider authProvider) {
    const priorityRoutes = <String>[
      dashboard,
      facturacion,
      parqueos,
      tarimas,
      sanitarios,
      inspecciones,
      ferias,
      participantes,
      productos,
      itemsDiagnostico,
      usuarios,
      ajustes,
    ];

    for (final route in priorityRoutes) {
      final permission = _permissions[route];
      if (permission == null || authProvider.hasPermission(permission)) {
        return route;
      }
    }

    return dashboard;
  }
}

class _RoutePlaceholderScreen extends StatelessWidget {
  const _RoutePlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      currentRoute: _routeForTitle(title),
      body: Center(
        child: Text(
          '$title pendiente de implementacion',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _routeForTitle(String value) {
    if (value.startsWith('Crear factura') ||
        value.startsWith('Detalle factura') ||
        value.startsWith('Editar factura')) {
      return AppRoutes.facturacion;
    }

    if (value.startsWith('Crear participante') ||
        value.startsWith('Editar participante')) {
      return AppRoutes.participantes;
    }

    switch (value) {
      case 'Facturacion':
        return AppRoutes.facturacion;
      case 'Parqueos':
        return AppRoutes.parqueos;
      case 'Tarimas':
        return AppRoutes.tarimas;
      case 'Sanitarios':
        return AppRoutes.sanitarios;
      case 'Inspecciones':
        return AppRoutes.inspecciones;
      case 'Ferias':
        return AppRoutes.ferias;
      case 'Participantes':
        return AppRoutes.participantes;
      case 'Productos':
        return AppRoutes.productos;
      case 'Items de Diagnostico':
        return AppRoutes.itemsDiagnostico;
      case 'Usuarios':
        return AppRoutes.usuarios;
      case 'Configuraciones':
        return AppRoutes.ajustes;
      default:
        return AppRoutes.dashboard;
    }
  }
}
