import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/inspeccion.dart';
import '../../models/participante.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspeccion_provider.dart';
import '../../services/item_diagnostico_service.dart';
import '../../services/participante_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_primary_fab.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_modals.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/inspecciones_widgets.dart';
import '../../widgets/list_cards.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/search_input.dart';
import '../../widgets/status_badge.dart';

class InspeccionesScreen extends StatefulWidget {
  const InspeccionesScreen({super.key});

  @override
  State<InspeccionesScreen> createState() => _InspeccionesScreenState();
}

class _InspeccionesScreenState extends State<InspeccionesScreen>
    with SingleTickerProviderStateMixin {
  final ParticipanteService _participanteService = ParticipanteService();
  final ItemDiagnosticoService _itemDiagnosticoService =
      ItemDiagnosticoService();
  final ScrollController _vencimientosController = ScrollController();
  final ScrollController _inspeccionesController = ScrollController();
  final ScrollController _reinspeccionesController = ScrollController();

  late final TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_handleTabChanged);
    _vencimientosController.addListener(_handleVencimientosScroll);
    _inspeccionesController.addListener(_handleInspeccionesScroll);
    _reinspeccionesController.addListener(_handleReinspeccionesScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCurrentTab(force: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    _vencimientosController.dispose();
    _inspeccionesController.dispose();
    _reinspeccionesController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging ||
        _currentTabIndex == _tabController.index) {
      return;
    }

    setState(() {
      _currentTabIndex = _tabController.index;
    });

    _loadCurrentTab();
  }

  Future<void> _loadCurrentTab({bool force = false}) async {
    final provider = context.read<InspeccionProvider>();

    try {
      switch (_currentTabIndex) {
        case 0:
          if (force || provider.vencimientosCarne.isEmpty) {
            await provider.loadVencimientosCarne();
          }
          return;
        case 1:
          if (force || provider.inspecciones.isEmpty) {
            await provider.loadInspecciones();
          }
          return;
        case 2:
          if (force || provider.reinspecciones.isEmpty) {
            await provider.loadReinspecciones();
          }
          return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _refreshCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return context.read<InspeccionProvider>().loadVencimientosCarne(
          search: context.read<InspeccionProvider>().vencimientosSearch,
        );
      case 1:
        return context.read<InspeccionProvider>().loadInspecciones(
          search: context.read<InspeccionProvider>().inspeccionesSearch,
        );
      case 2:
        return context.read<InspeccionProvider>().loadReinspecciones(
          search: context.read<InspeccionProvider>().reinspeccionesSearch,
        );
      default:
        return Future<void>.value();
    }
  }

  void _selectTab(int index) {
    if (_currentTabIndex == index) {
      return;
    }

    _tabController.animateTo(index);
  }

  void _handleVencimientosScroll() {
    if (_vencimientosController.position.pixels >=
        _vencimientosController.position.maxScrollExtent - 200) {
      context.read<InspeccionProvider>().loadVencimientosCarne(append: true);
    }
  }

  void _handleInspeccionesScroll() {
    if (_inspeccionesController.position.pixels >=
        _inspeccionesController.position.maxScrollExtent - 200) {
      context.read<InspeccionProvider>().loadInspecciones(append: true);
    }
  }

  void _handleReinspeccionesScroll() {
    if (_reinspeccionesController.position.pixels >=
        _reinspeccionesController.position.maxScrollExtent - 200) {
      context.read<InspeccionProvider>().loadReinspecciones(append: true);
    }
  }

  Future<void> _openInspeccionSheet({Inspeccion? reinspeccionBase}) async {
    final provider = context.read<InspeccionProvider>();
    final changed = await showAppBottomSheet<bool>(
      context,
      builder: (context) => InspeccionFormSheet(
        participanteService: _participanteService,
        itemDiagnosticoService: _itemDiagnosticoService,
        reinspeccionBase: reinspeccionBase,
        onSubmit: (payload) async {
          await provider.createInspeccion(data: payload);
          await provider.loadInspecciones();
          await provider.loadReinspecciones();
        },
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspección guardada correctamente.')),
      );
      await provider.loadVencimientosCarne();
    }
  }

  Future<void> _openActualizarCarneSheet(Participante participante) async {
    final provider = context.read<InspeccionProvider>();
    final changed = await showAppBottomSheet<bool>(
      context,
      builder: (context) => ParticipanteCarneSheet(
        participante: participante,
        onSubmit: (payload) async {
          final actualizado = await _participanteService
              .updateParticipanteCarne(
                participanteId: participante.id,
                data: payload,
              );
          provider.replaceParticipante(actualizado);
        },
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Carné actualizado para ${participante.nombre}.'),
        ),
      );
      await provider.loadReinspecciones();
    }
  }

  void _openDetalle(Inspeccion inspeccion) {
    showAppBottomSheet<void>(
      context,
      builder: (context) => InspeccionDetailSheet(inspeccion: inspeccion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canCreateInspeccion = authProvider.hasPermission(
      'inspecciones.crear',
    );
    final canUpdateCarne = authProvider.hasPermission('participantes.editar');
    final provider = context.watch<InspeccionProvider>();

    return AppScaffold(
      title: 'Inspecciones',
      currentRoute: AppRoutes.inspecciones,
      floatingActionButton: _currentTabIndex == 1 && canCreateInspeccion
          ? AppPrimaryFab(
              onPressed: () {
                _openInspeccionSheet();
              },
              icon: Icons.fact_check_outlined,
              tooltip: 'Nueva inspección',
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refreshCurrentTab,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchInput(
                key: ValueKey<int>(_currentTabIndex),
                hintText: _searchHint,
                initialValue: _searchValue(provider),
                onChanged: (value) => _handleSearch(provider, value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _InspeccionTabChip(
                      label: 'Vencimientos',
                      isSelected: _currentTabIndex == 0,
                      onTap: () => _selectTab(0),
                    ),
                    const SizedBox(width: 10),
                    _InspeccionTabChip(
                      label: 'Inspecciones',
                      isSelected: _currentTabIndex == 1,
                      onTap: () => _selectTab(1),
                    ),
                    const SizedBox(width: 10),
                    _InspeccionTabChip(
                      label: 'Reinspecciones',
                      isSelected: _currentTabIndex == 2,
                      onTap: () => _selectTab(2),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _tabDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildVencimientosTab(provider, canUpdateCarne),
                  _buildInspeccionesTab(provider),
                  _buildReinspeccionesTab(provider, canCreateInspeccion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSearch(InspeccionProvider provider, String value) async {
    try {
      switch (_currentTabIndex) {
        case 0:
          await provider.loadVencimientosCarne(search: value);
          return;
        case 1:
          await provider.loadInspecciones(search: value);
          return;
        case 2:
          await provider.loadReinspecciones(search: value);
          return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Widget _buildVencimientosTab(
    InspeccionProvider provider,
    bool canUpdateCarne,
  ) {
    if (provider.isLoadingVencimientos && provider.vencimientosCarne.isEmpty) {
      return const LoadingWidget(message: 'Cargando vencimientos');
    }

    if (provider.vencimientosCarne.isEmpty) {
      return _TabEmptyState(
        icon: Icons.badge_outlined,
        message: 'No hay participantes con carné por revisar.',
      );
    }

    return ListView.separated(
      controller: _vencimientosController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount:
          provider.vencimientosCarne.length +
          (provider.isLoadingMoreVencimientos ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == provider.vencimientosCarne.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final participante = provider.vencimientosCarne[index];
        final vencimiento = participante.fechaVencimientoCarne;

        return AdminListCard<String>(
          title: participante.nombre,
          subtitle: participante.numeroIdentificacion,
          extraLines: <Widget>[
            Text(
              (participante.numeroCarne ?? '').trim().isEmpty
                  ? 'Sin número de carné'
                  : 'Carné ${participante.numeroCarne}',
            ),
            Text(
              vencimiento == null
                  ? 'Sin fecha de vencimiento'
                  : 'Vence ${AppFormatters.formatDate(vencimiento)}',
            ),
          ],
          chips: <Widget>[StatusBadge(status: _statusVencimiento(vencimiento))],
          onTap: canUpdateCarne
              ? () {
                  _openActualizarCarneSheet(participante);
                }
              : null,
          menuActions: canUpdateCarne
              ? const <ListMenuAction<String>>[
                  ListMenuAction<String>(
                    value: 'update',
                    label: 'Actualizar carné',
                  ),
                ]
              : const <ListMenuAction<String>>[],
          onMenuSelected: (_) {
            _openActualizarCarneSheet(participante);
          },
        );
      },
    );
  }

  Widget _buildInspeccionesTab(InspeccionProvider provider) {
    if (provider.isLoadingInspecciones && provider.inspecciones.isEmpty) {
      return const LoadingWidget(message: 'Cargando inspecciones');
    }

    if (provider.inspecciones.isEmpty) {
      return _TabEmptyState(
        icon: Icons.fact_check_outlined,
        message: 'Todavía no hay inspecciones registradas.',
      );
    }

    return ListView.separated(
      controller: _inspeccionesController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount:
          provider.inspecciones.length +
          (provider.isLoadingMoreInspecciones ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == provider.inspecciones.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final inspeccion = provider.inspecciones[index];

        return OperationListCard<String>(
          title:
              inspeccion.participante?.nombre ?? 'Participante no disponible',
          amount: _CountPill(value: inspeccion.totalItems),
          metaPrimary: Text(
            inspeccion.createdAt == null
                ? 'Sin fecha'
                : AppFormatters.formatDateTime(inspeccion.createdAt!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          metaSecondary: Text(
            inspeccion.inspector?.name ?? 'Sin inspector',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          status: inspeccion.totalIncumplidos > 0
              ? '${inspeccion.totalIncumplidos} pendientes'
              : 'Completa',
          chips: <Widget>[
            StatusBadge(
              status: inspeccion.esReinspeccion ? 'Reinspección' : 'Inspección',
            ),
          ],
          footer: Text(
            inspeccion.items.take(3).map((item) => item.nombreItem).join(', '),
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _openDetalle(inspeccion),
        );
      },
    );
  }

  Widget _buildReinspeccionesTab(
    InspeccionProvider provider,
    bool canCreateInspeccion,
  ) {
    if (provider.isLoadingReinspecciones && provider.reinspecciones.isEmpty) {
      return const LoadingWidget(message: 'Cargando reinspecciones');
    }

    if (provider.reinspecciones.isEmpty) {
      return _TabEmptyState(
        icon: Icons.rule_folder_outlined,
        message: 'No hay reinspecciones pendientes en este momento.',
      );
    }

    return ListView.separated(
      controller: _reinspeccionesController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount:
          provider.reinspecciones.length +
          (provider.isLoadingMoreReinspecciones ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == provider.reinspecciones.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final reinspeccion = provider.reinspecciones[index];

        return OperationListCard<String>(
          title:
              reinspeccion.participante?.nombre ?? 'Participante no disponible',
          amount: _CountPill(value: reinspeccion.totalIncumplidos),
          metaPrimary: Text(
            reinspeccion.createdAt == null
                ? 'Sin fecha'
                : 'Última ${AppFormatters.formatDateTime(reinspeccion.createdAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          metaSecondary: Text(
            reinspeccion.participante?.numeroIdentificacion ??
                'Sin identificación',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          status: '${reinspeccion.totalIncumplidos} pendientes',
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                reinspeccion.items.map((item) => item.nombreItem).join(', '),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (canCreateInspeccion) ...<Widget>[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _openInspeccionSheet(reinspeccionBase: reinspeccion);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Crear reinspección'),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _openDetalle(reinspeccion),
        );
      },
    );
  }

  String get _searchHint {
    switch (_currentTabIndex) {
      case 0:
        return 'Buscar por nombre, identificación o carné...';
      case 1:
        return 'Buscar inspección...';
      case 2:
        return 'Buscar reinspección...';
      default:
        return 'Buscar...';
    }
  }

  String get _tabDescription {
    switch (_currentTabIndex) {
      case 0:
        return 'Seguimiento de participantes con carné vencido o próximo a vencer.';
      case 1:
        return 'Historial de inspecciones registradas en la feria activa.';
      case 2:
        return 'Participantes cuya última inspección dejó pendientes por corregir.';
      default:
        return '';
    }
  }

  String _searchValue(InspeccionProvider provider) {
    switch (_currentTabIndex) {
      case 0:
        return provider.vencimientosSearch;
      case 1:
        return provider.inspeccionesSearch;
      case 2:
        return provider.reinspeccionesSearch;
      default:
        return '';
    }
  }

  String _statusVencimiento(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha';
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(fecha.year, fecha.month, fecha.day);
    final diff = normalizedDate.difference(normalizedToday).inDays;

    if (diff < 0) {
      return 'Vencido';
    }

    if (diff <= 30) {
      return 'Próximo';
    }

    return 'Vigente';
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      return error.message ?? 'No fue posible completar la operación.';
    }

    return 'No fue posible completar la operación.';
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primarySoftColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value.toString(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InspeccionTabChip extends StatelessWidget {
  const _InspeccionTabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primarySoftColor
                : AppTheme.neutralSoftColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.18)
                  : AppTheme.borderColor,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.mutedTextColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
      children: <Widget>[
        const SizedBox(height: 80),
        EmptyState(icon: icon, subtitle: message),
      ],
    );
  }
}
