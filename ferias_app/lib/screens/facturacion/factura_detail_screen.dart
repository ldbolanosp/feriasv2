import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../models/factura.dart';
import '../../models/factura_detalle.dart';
import '../../providers/factura_provider.dart';
import '../../providers/feria_provider.dart';
import '../../providers/printer_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/money_text.dart';
import '../../widgets/status_badge.dart';

class FacturaDetailScreen extends StatefulWidget {
  const FacturaDetailScreen({super.key, required this.facturaId});

  final int? facturaId;

  @override
  State<FacturaDetailScreen> createState() => _FacturaDetailScreenState();
}

class _FacturaDetailScreenState extends State<FacturaDetailScreen> {
  Factura? _factura;
  bool _isLoading = true;
  bool _isActing = false;

  bool get _canEdit => _factura?.estado == 'borrador';
  bool get _canFacturar => _factura?.estado == 'borrador';
  bool get _canDelete =>
      _factura?.estado == 'borrador' || _factura?.estado == 'facturado';
  bool get _canPrint => _factura?.estado == 'facturado';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFactura();
    });
  }

  Future<void> _loadFactura() async {
    final facturaId = widget.facturaId;

    if (facturaId == null) {
      setState(() {
        _factura = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final factura = await context.read<FacturaProvider>().obtener(facturaId);

      if (!mounted) {
        return;
      }

      setState(() {
        _factura = factura;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacturar() async {
    final factura = _factura;

    if (factura == null) {
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Facturar borrador',
      message: '¿Desea emitir esta factura y generar el consecutivo?',
      confirmLabel: 'Facturar',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isActing = true;
    });

    try {
      final facturaEmitida = await context.read<FacturaProvider>().facturar(
        factura.id,
      );

      if (!mounted) {
        return;
      }

      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printFactura(
        facturaEmitida,
        feriaNombre,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _factura = facturaEmitida;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factura emitida e impresa correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isActing = false;
        });
      }
    }
  }

  Future<void> _handleEliminar() async {
    final factura = _factura;

    if (factura == null) {
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar factura',
      message: '¿Desea eliminar esta factura?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isActing = true;
    });

    try {
      await context.read<FacturaProvider>().eliminar(factura.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura eliminada correctamente.')),
      );
      context.go(AppRoutes.facturacion);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isActing = false;
        });
      }
    }
  }

  Future<void> _handleImprimir() async {
    final factura = _factura;

    if (factura == null) {
      return;
    }

    setState(() {
      _isActing = true;
    });

    try {
      final facturaCompleta = await context.read<FacturaProvider>().obtener(
        factura.id,
      );

      if (!mounted) {
        return;
      }

      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printFactura(
        facturaCompleta,
        feriaNombre,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _factura = facturaCompleta;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket reenviado a la impresora.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isActing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final factura = _factura;
    final title = factura == null
        ? 'Borrador'
        : (factura.consecutivo?.trim().isNotEmpty ?? false)
        ? 'Factura ${factura.consecutivo}'
        : 'Borrador';

    return AppScaffold(
      title: title,
      currentRoute: AppRoutes.facturacion,
      body: _isLoading
          ? const LoadingWidget()
          : factura == null
          ? ListView(
              children: const <Widget>[
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  subtitle: 'No fue posible cargar la factura solicitada.',
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadFactura,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: <Widget>[
                  _ActionPanel(
                    canEdit: _canEdit,
                    canFacturar: _canFacturar,
                    canDelete: _canDelete,
                    canPrint: _canPrint,
                    isLoading: _isActing,
                    onEdit: () => context.go(
                      '${AppRoutes.facturacion}/${factura.id}/editar',
                    ),
                    onFacturar: _handleFacturar,
                    onDelete: _handleEliminar,
                    onPrint: _handleImprimir,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 820;

                      final infoCard = _InfoCard(factura: factura);
                      final resumenCard = _ResumenPagoCard(factura: factura);

                      if (stacked) {
                        return Column(
                          children: <Widget>[
                            infoCard,
                            const SizedBox(height: 16),
                            resumenCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 3, child: infoCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: resumenCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _DetallesCard(detalles: factura.detalles),
                ],
              ),
            ),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();

        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }

      return error.message ?? 'No se pudo completar la operación.';
    }

    return 'No se pudo completar la operación.';
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.canEdit,
    required this.canFacturar,
    required this.canDelete,
    required this.canPrint,
    required this.isLoading,
    required this.onEdit,
    required this.onFacturar,
    required this.onDelete,
    required this.onPrint,
  });

  final bool canEdit;
  final bool canFacturar;
  final bool canDelete;
  final bool canPrint;
  final bool isLoading;
  final VoidCallback onEdit;
  final Future<void> Function() onFacturar;
  final Future<void> Function() onDelete;
  final Future<void> Function() onPrint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            if (canEdit)
              OutlinedButton.icon(
                onPressed: isLoading ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            if (canFacturar)
              FilledButton.icon(
                onPressed: isLoading ? null : onFacturar,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Facturar'),
              ),
            if (canPrint)
              FilledButton.tonalIcon(
                onPressed: isLoading ? null : onPrint,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir'),
              ),
            if (canDelete)
              OutlinedButton.icon(
                onPressed: isLoading ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.factura});

  final Factura factura;

  @override
  Widget build(BuildContext context) {
    final cliente = factura.esPublicoGeneral
        ? (factura.nombrePublico?.trim().isNotEmpty ?? false)
              ? factura.nombrePublico!.trim()
              : 'Público general'
        : factura.participante?.nombre ?? 'Sin participante';
    final fecha = factura.fechaEmision ?? factura.createdAt;
    final puesto = [
      factura.tipoPuesto?.trim(),
      factura.numeroPuesto?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' #');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Información general',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Estado',
              valueWidget: StatusBadge(
                status: factura.estadoLabel ?? factura.estado,
              ),
            ),
            _InfoRow(label: 'Cliente', value: cliente),
            _InfoRow(
              label: 'Fecha',
              value: fecha == null
                  ? 'Sin fecha'
                  : AppFormatters.formatDateTime(fecha),
            ),
            _InfoRow(label: 'Usuario', value: factura.user?.name ?? 'N/A'),
            if (puesto.isNotEmpty) _InfoRow(label: 'Puesto', value: puesto),
            _InfoRow(
              label: 'Total',
              valueWidget: MoneyText(
                factura.subtotal,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (factura.observaciones?.trim().isNotEmpty ?? false) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Observaciones',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(factura.observaciones!.trim()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumenPagoCard extends StatelessWidget {
  const _ResumenPagoCard({required this.factura});

  final Factura factura;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumen de pago',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Subtotal',
              valueWidget: MoneyText(factura.subtotal),
            ),
            _InfoRow(
              label: 'Pago recibido',
              valueWidget: MoneyText(factura.montoPago ?? 0),
            ),
            _InfoRow(
              label: 'Cambio',
              valueWidget: MoneyText(factura.montoCambio ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetallesCard extends StatelessWidget {
  const _DetallesCard({required this.detalles});

  final List<FacturaDetalle> detalles;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Detalle de líneas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (detalles.isEmpty)
              const EmptyState(
                icon: Icons.list_alt_outlined,
                subtitle: 'La factura no tiene líneas registradas.',
              )
            else
              ...detalles.map(
                (detalle) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(detalle.descripcionProducto),
                    subtitle: Text(
                      '${detalle.cantidad.toStringAsFixed(1)} x ${AppFormatters.formatMoney(detalle.precioUnitario)}',
                    ),
                    trailing: MoneyText(
                      detalle.subtotalLinea,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child:
                valueWidget ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
          ),
        ],
      ),
    );
  }
}
