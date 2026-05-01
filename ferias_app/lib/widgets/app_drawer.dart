import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feria_provider.dart';
import 'confirm_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showConfirmDialog(
      context,
      title: 'Cerrar sesión',
      message: '¿Desea cerrar la sesión actual?',
      confirmLabel: 'Cerrar sesión',
    );

    if (!shouldLogout || !context.mounted) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final feriaProvider = context.read<FeriaProvider>();

    await feriaProvider.clear();
    await authProvider.logout();

    if (!context.mounted) {
      return;
    }

    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final role =
        user?.role ?? (user?.roles.isNotEmpty == true ? user!.roles.first : '');

    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppTheme.primaryColor,
                      AppTheme.primaryDarkColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.22),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user?.name ?? 'Usuario',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                          ),
                          if (role.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                role,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                children: <Widget>[
                  ..._buildMainItems(context, authProvider),
                  if (_hasConfigurationItems(authProvider))
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Configuración'),
                        initiallyExpanded: currentRoute.startsWith(
                          '/configuracion',
                        ),
                        children: _buildConfigurationItems(
                          context,
                          authProvider,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.dangerColor,
                  ),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: AppTheme.dangerColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => _confirmLogout(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMainItems(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    const items = <_DrawerItem>[
      _DrawerItem(
        label: 'Dashboard',
        icon: Icons.dashboard,
        route: AppRoutes.dashboard,
        permission: 'dashboard.ver',
      ),
      _DrawerItem(
        label: 'Facturación',
        icon: Icons.receipt_long,
        route: AppRoutes.facturacion,
        permission: 'facturas.ver',
      ),
      _DrawerItem(
        label: 'Parqueo',
        icon: Icons.directions_car,
        route: AppRoutes.parqueos,
        permission: 'parqueos.ver',
      ),
      _DrawerItem(
        label: 'Tarimas',
        icon: Icons.inventory_2,
        route: AppRoutes.tarimas,
        permission: 'tarimas.ver',
      ),
      _DrawerItem(
        label: 'Sanitarios',
        icon: Icons.water_drop,
        route: AppRoutes.sanitarios,
        permission: 'sanitarios.ver',
      ),
    ];

    return items
        .where((item) => authProvider.hasPermission(item.permission))
        .map((item) => _buildNavItem(context, item))
        .toList(growable: false);
  }

  bool _hasConfigurationItems(AuthProvider authProvider) {
    const permissions = <String>[
      'ferias.ver',
      'participantes.ver',
      'productos.ver',
      'configuracion.ver',
      'usuarios.ver',
    ];

    return permissions.any(authProvider.hasPermission);
  }

  List<Widget> _buildConfigurationItems(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    const items = <_DrawerItem>[
      _DrawerItem(
        label: 'Ferias',
        icon: Icons.location_on,
        route: AppRoutes.ferias,
        permission: 'ferias.ver',
      ),
      _DrawerItem(
        label: 'Participantes',
        icon: Icons.people,
        route: AppRoutes.participantes,
        permission: 'participantes.ver',
      ),
      _DrawerItem(
        label: 'Productos',
        icon: Icons.category,
        route: AppRoutes.productos,
        permission: 'productos.ver',
      ),
      _DrawerItem(
        label: 'Items de diagnóstico',
        icon: Icons.playlist_add_check_circle_outlined,
        route: AppRoutes.itemsDiagnostico,
        permission: 'configuracion.ver',
      ),
      _DrawerItem(
        label: 'Usuarios',
        icon: Icons.manage_accounts,
        route: AppRoutes.usuarios,
        permission: 'usuarios.ver',
      ),
      _DrawerItem(
        label: 'Configuración',
        icon: Icons.tune,
        route: AppRoutes.ajustes,
        permission: 'configuracion.ver',
      ),
    ];

    return items
        .where((item) => authProvider.hasPermission(item.permission))
        .map((item) => _buildNavItem(context, item, dense: true))
        .toList(growable: false);
  }

  Widget _buildNavItem(
    BuildContext context,
    _DrawerItem item, {
    bool dense = false,
  }) {
    final selected =
        currentRoute == item.route ||
        (item.route != AppRoutes.dashboard &&
            currentRoute.startsWith(item.route));

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 6 : 10),
      child: ListTile(
        dense: dense,
        selected: selected,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        selectedTileColor: AppTheme.primarySoftColor,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : AppTheme.neutralSoftColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            item.icon,
            color: selected ? Colors.white : AppTheme.mutedTextColor,
            size: 20,
          ),
        ),
        title: Text(
          item.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          context.go(item.route);
        },
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.permission,
  });

  final String label;
  final IconData icon;
  final String route;
  final String permission;
}
