import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/factura.dart';
import '../../providers/auth_provider.dart';
import '../../providers/factura_provider.dart';
import '../../providers/feria_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/factura_list_item.dart';
import '../../widgets/loading_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _feriaCargadaId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final feriaId = context.watch<FeriaProvider>().feriaActiva?.id;

    if (feriaId != null && feriaId != _feriaCargadaId) {
      _feriaCargadaId = feriaId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _cargarFacturas();
        }
      });
    }
  }

  Future<void> _cargarFacturas() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.hasPermission('facturas.ver')) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final facturaProvider = context.watch<FacturaProvider>();
    final recientes = facturaProvider.facturas.take(3).toList(growable: false);
    final canCrearFactura = authProvider.hasPermission('facturas.crear');
    final canCrearParticipante = authProvider.hasPermission(
      'participantes.crear',
    );

    return AppScaffold(
      title: 'Inicio',
      currentRoute: AppRoutes.dashboard,
      body: RefreshIndicator(
        onRefresh: _cargarFacturas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.note_add_outlined,
                    label: 'Nueva Factura',
                    onTap: canCrearFactura
                        ? () => context.go(AppRoutes.facturacionCrear)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Nuevo Cliente',
                    onTap: canCrearParticipante
                        ? () => context.go(AppRoutes.participantesCrear)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Actividad semanal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _ActividadSemanalCard(facturas: facturaProvider.facturas),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Facturas recientes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (authProvider.hasPermission('facturas.ver'))
                  TextButton(
                    onPressed: () => context.go(AppRoutes.facturacion),
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (facturaProvider.isLoading && recientes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: LoadingWidget(message: 'Cargando facturas recientes'),
              )
            else if (recientes.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Todavia no hay facturas recientes',
                subtitle: 'Cuando existan movimientos, apareceran aqui.',
                actionLabel: canCrearFactura ? 'Crear factura' : null,
                onActionPressed: canCrearFactura
                    ? () => context.go(AppRoutes.facturacionCrear)
                    : null,
              )
            else
              ...recientes.map(
                (factura) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FacturaListItem(
                    factura: factura,
                    onTap: () =>
                        context.go('${AppRoutes.facturacion}/${factura.id}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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

      return error.message ?? 'No se pudo cargar la informacion.';
    }

    return 'No se pudo cargar la informacion.';
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppTheme.primarySoftColor
                      : AppTheme.neutralSoftColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? AppTheme.primaryColor
                      : AppTheme.mutedTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                enabled ? 'Acceso directo' : 'Sin permiso disponible',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActividadSemanalCard extends StatelessWidget {
  const _ActividadSemanalCard({required this.facturas});

  final List<Factura> facturas;

  @override
  Widget build(BuildContext context) {
    final barras = _buildWeekData();
    final maximo = barras.fold<double>(
      0,
      (max, item) => item.valor > max ? item.valor : max,
    );
    final escala = maximo <= 0 ? 1.0 : maximo;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 210,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List<Widget>.generate(
                      3,
                      (index) =>
                          Container(height: 1, color: AppTheme.borderColor),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: barras
                      .map((barra) {
                        final altura = 44 + ((barra.valor / escala) * 96);

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                width: 30,
                                height: altura.clamp(44, 140),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                barra.etiqueta,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_BarraActividad> _buildWeekData() {
    final now = DateTime.now();
    final dias = <String, double>{
      'L': 0,
      'M': 0,
      'X': 0,
      'J': 0,
      'V': 0,
      'S': 0,
      'D': 0,
    };

    for (final factura in facturas) {
      final fecha =
          factura.fechaEmision ?? factura.createdAt ?? factura.updatedAt;
      if (fecha == null) {
        continue;
      }

      final diff = now
          .difference(DateTime(fecha.year, fecha.month, fecha.day))
          .inDays;
      if (diff < 0 || diff > 6) {
        continue;
      }

      final key = _weekdayLabel(fecha.weekday);
      dias[key] = (dias[key] ?? 0) + factura.subtotal;
    }

    return dias.entries
        .map((entry) => _BarraActividad(entry.key, entry.value))
        .toList(growable: false);
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'L';
      case DateTime.tuesday:
        return 'M';
      case DateTime.wednesday:
        return 'X';
      case DateTime.thursday:
        return 'J';
      case DateTime.friday:
        return 'V';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
      default:
        return 'D';
    }
  }
}

class _BarraActividad {
  const _BarraActividad(this.etiqueta, this.valor);

  final String etiqueta;
  final double valor;
}
