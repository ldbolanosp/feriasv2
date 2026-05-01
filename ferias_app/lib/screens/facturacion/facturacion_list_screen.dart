import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../models/factura.dart';
import '../../providers/auth_provider.dart';
import '../../providers/factura_provider.dart';
import '../../providers/feria_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_primary_fab.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/factura_list_item.dart';
import '../../widgets/loading_widget.dart';

class FacturacionListScreen extends StatefulWidget {
  const FacturacionListScreen({super.key});

  @override
  State<FacturacionListScreen> createState() => _FacturacionListScreenState();
}

class _FacturacionListScreenState extends State<FacturacionListScreen> {
  final String _search = '';
  int? _feriaCargadaId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFacturas();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final feriaId = context.watch<FeriaProvider>().feriaActiva?.id;

    if (feriaId != null && feriaId != _feriaCargadaId) {
      _feriaCargadaId = feriaId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFacturas();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FacturaProvider>().cargarMas();
    }
  }

  Future<void> _loadFacturas() async {
    try {
      await context.read<FacturaProvider>().listar();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  List<Factura> _applyLocalSearch(List<Factura> facturas) {
    final normalizedSearch = _search.trim().toLowerCase();

    if (normalizedSearch.isEmpty) {
      return facturas;
    }

    return facturas
        .where((factura) {
          final candidateValues = <String>[
            factura.consecutivo ?? '',
            factura.nombrePublico ?? '',
            factura.participante?.nombre ?? '',
            factura.tipoPuesto ?? '',
            factura.numeroPuesto ?? '',
            factura.user?.name ?? '',
          ];

          return candidateValues.any(
            (value) => value.toLowerCase().contains(normalizedSearch),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final facturaProvider = context.watch<FacturaProvider>();
    final authProvider = context.watch<AuthProvider>();
    final facturas = _applyLocalSearch(facturaProvider.facturas);
    final canCreate = authProvider.hasPermission('facturas.crear');
    final showUserName = _hasPrivilegedRole(authProvider);

    return AppScaffold(
      title: 'Facturas',
      currentRoute: AppRoutes.facturacion,
      floatingActionButton: canCreate
          ? AppPrimaryFab(
              onPressed: () => context.go(AppRoutes.facturacionCrear),
              tooltip: 'Nueva factura',
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadFacturas,
        child: _buildContent(
          facturas: facturas,
          isLoading: facturaProvider.isLoading,
          isLoadingMore: facturaProvider.isLoadingMore,
          showUserName: showUserName,
        ),
      ),
    );
  }

  Widget _buildContent({
    required List<Factura> facturas,
    required bool isLoading,
    required bool isLoadingMore,
    required bool showUserName,
  }) {
    if (isLoading && facturas.isEmpty) {
      return const LoadingWidget();
    }

    if (facturas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.receipt_long_outlined,
            subtitle: 'No hay facturas con los filtros seleccionados.',
          ),
        ],
      );
    }

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
      children: <Widget>[
        ...facturas.map(
          (factura) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FacturaListItem(
              factura: factura,
              showUserName: showUserName,
              onTap: () => context.go('${AppRoutes.facturacion}/${factura.id}'),
            ),
          ),
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  bool _hasPrivilegedRole(AuthProvider authProvider) {
    final roles =
        authProvider.user?.roles.map((role) => role.toLowerCase()) ??
        const Iterable<String>.empty();

    return roles.contains('admin') ||
        roles.contains('administrador') ||
        roles.contains('supervisor');
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }

      return error.message ?? 'No se pudo completar la operación.';
    }

    return 'No se pudo completar la operación.';
  }
}
