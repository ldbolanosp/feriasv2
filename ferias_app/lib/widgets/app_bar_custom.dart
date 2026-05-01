import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feria_provider.dart';
import 'confirm_dialog.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  const AppBarCustom({
    super.key,
    required this.title,
    required this.currentRoute,
    this.subtitle,
    this.showFeriaSwitcher = true,
  });

  final String title;
  final String currentRoute;
  final String? subtitle;
  final bool showFeriaSwitcher;

  @override
  Size get preferredSize => Size.fromHeight(
    currentRoute == AppRoutes.dashboard
        ? 114
        : showFeriaSwitcher
        ? 120
        : subtitle == null
        ? 88
        : 102,
  );

  Future<void> _showFeriaSelector(BuildContext context) async {
    final feriaProvider = context.read<FeriaProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        final ferias = feriaProvider.ferias;
        final feriaActiva = feriaProvider.feriaActiva;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Cambiar feria',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Seleccione la feria con la que desea trabajar.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: ferias.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final feria = ferias[index];
                      final isActive = feria.id == feriaActiva?.id;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          onTap: feriaProvider.isLoading
                              ? null
                              : () async {
                                  Navigator.of(bottomSheetContext).pop();
                                  try {
                                    await feriaProvider.setFeriaActiva(feria);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.go(currentRoute);
                                  } catch (_) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No fue posible cambiar la feria activa.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primarySoftColor
                                  : AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppTheme.primaryColor
                                        : AppTheme.neutralSoftColor,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusXs,
                                    ),
                                  ),
                                  child: Icon(
                                    isActive
                                        ? Icons.check_rounded
                                        : Icons.storefront_outlined,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        feria.descripcion,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        feria.codigo,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSettingsMenu(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final feriaProvider = context.read<FeriaProvider>();

    const items = <_ConfigItem>[
      _ConfigItem(
        label: 'Ferias',
        icon: Icons.storefront_outlined,
        route: AppRoutes.ferias,
        permission: 'ferias.ver',
      ),
      _ConfigItem(
        label: 'Participantes',
        icon: Icons.people_outline,
        route: AppRoutes.participantes,
        permission: 'participantes.ver',
      ),
      _ConfigItem(
        label: 'Productos',
        icon: Icons.category_outlined,
        route: AppRoutes.productos,
        permission: 'productos.ver',
      ),
      _ConfigItem(
        label: 'Usuarios',
        icon: Icons.manage_accounts_outlined,
        route: AppRoutes.usuarios,
        permission: 'usuarios.ver',
      ),
      _ConfigItem(
        label: 'Ajustes',
        icon: Icons.tune_outlined,
        route: AppRoutes.ajustes,
        permission: 'configuracion.ver',
      ),
    ];

    final visibles = items
        .where((item) => authProvider.hasPermission(item.permission))
        .toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Configuracion',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accesos administrativos y cambios de sesion.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    ...visibles.map((item) {
                      final selected =
                          currentRoute == item.route ||
                          currentRoute.startsWith(item.route);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          tileColor: selected
                              ? AppTheme.primarySoftColor
                              : AppTheme.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : AppTheme.borderColor,
                            ),
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : AppTheme.neutralSoftColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXs,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.mutedTextColor,
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            context.go(item.route);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final shouldLogout = await showConfirmDialog(
                          context,
                          title: 'Cerrar sesión',
                          message: '¿Desea cerrar la sesión actual?',
                          confirmLabel: 'Cerrar sesión',
                        );

                        if (!shouldLogout || !context.mounted) {
                          return;
                        }

                        await feriaProvider.clear();
                        await authProvider.logout();

                        if (!context.mounted) {
                          return;
                        }

                        context.go(AppRoutes.login);
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.dangerColor,
                      ),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppTheme.dangerColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final feriaActiva = context.watch<FeriaProvider>().feriaActiva;
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name.trim();
    final userInitial = userName != null && userName.isNotEmpty
        ? userName.characters.first.toUpperCase()
        : '?';

    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppTheme.backgroundColor,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: currentRoute == AppRoutes.dashboard
            ? Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primarySoftColor,
                    child: Text(
                      userInitial,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Buen dia',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName?.isNotEmpty == true ? userName! : 'Usuario',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _ActionCircleButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Configuracion',
                    onPressed: () => _showSettingsMenu(context),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ActionCircleButton(
                        icon: Icons.settings_outlined,
                        tooltip: 'Configuracion',
                        onPressed: () => _showSettingsMenu(context),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (showFeriaSwitcher) ...<Widget>[
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: feriaActiva == null
                          ? null
                          : () => _showFeriaSelector(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.storefront_outlined,
                              size: 16,
                              color: AppTheme.mutedTextColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                feriaActiva?.descripcion ?? 'Sin feria activa',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppTheme.mutedTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ConfigItem {
  const _ConfigItem({
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

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onPressed,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: AppTheme.textColor),
        ),
      ),
    );
  }
}
