import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'app_bar_custom.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.floatingActionButton,
    this.showBottomNavigation = true,
    this.appBarSubtitle,
    this.showFeriaSwitcher = true,
  });

  final String title;
  final String currentRoute;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showBottomNavigation;
  final String? appBarSubtitle;
  final bool showFeriaSwitcher;

  static const List<_NavigationItem> _mainDestinations = <_NavigationItem>[
    _NavigationItem(
      label: 'Inicio',
      route: AppRoutes.dashboard,
      permission: 'dashboard.ver',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      kind: _NavigationKind.route,
    ),
    _NavigationItem(
      label: 'Facturas',
      route: AppRoutes.facturacion,
      permission: 'facturas.ver',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      kind: _NavigationKind.route,
    ),
    _NavigationItem(
      label: 'Parqueo',
      route: AppRoutes.parqueos,
      permission: 'parqueos.ver',
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car_rounded,
      kind: _NavigationKind.route,
    ),
    _NavigationItem(
      label: 'Tarimas',
      route: AppRoutes.tarimas,
      permission: 'tarimas.ver',
      icon: Icons.pallet,
      selectedIcon: Icons.pallet,
      kind: _NavigationKind.route,
    ),
    _NavigationItem(
      label: 'Inspecciones',
      route: AppRoutes.inspecciones,
      permission: 'inspecciones.ver',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      kind: _NavigationKind.route,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final destinations = _mainDestinations
        .where((item) => authProvider.hasPermission(item.permission))
        .toList(growable: false);
    final bottomNavigationHeight =
        !showBottomNavigation || destinations.length < 2
        ? 0.0
        : kBottomNavigationBarHeight +
              MediaQuery.paddingOf(context).bottom +
              28;

    final selectedIndex = destinations.indexWhere(
      (item) =>
          currentRoute == item.route ||
          (item.route != AppRoutes.dashboard &&
              currentRoute.startsWith(item.route)),
    );

    return Scaffold(
      extendBody: true,
      appBar: AppBarCustom(
        title: title,
        currentRoute: currentRoute,
        subtitle: appBarSubtitle,
        showFeriaSwitcher: showFeriaSwitcher,
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomNavigationHeight),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: !showBottomNavigation || destinations.length < 2
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: const Border(
                  top: BorderSide(color: AppTheme.borderColor),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.shadowColor.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  currentIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  onTap: (index) =>
                      _handleTap(context, destinations[index], currentRoute),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppTheme.surfaceColor,
                  elevation: 0,
                  selectedItemColor: AppTheme.primaryColor,
                  unselectedItemColor: AppTheme.mutedTextColor,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  items: destinations
                      .map(
                        (item) => BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Icon(
                              item.route == currentRoute
                                  ? item.selectedIcon
                                  : item.icon,
                            ),
                          ),
                          label: item.label,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    _NavigationItem destination,
    String currentRoute,
  ) async {
    if (destination.route != currentRoute) {
      context.go(destination.route);
    }
  }
}

enum _NavigationKind { route }

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.route,
    required this.permission,
    required this.icon,
    required this.selectedIcon,
    required this.kind,
  });

  final String label;
  final String route;
  final String permission;
  final IconData icon;
  final IconData selectedIcon;
  final _NavigationKind kind;
}
