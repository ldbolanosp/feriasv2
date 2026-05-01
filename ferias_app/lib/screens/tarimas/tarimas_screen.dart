import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../models/participante.dart';
import '../../models/tarima.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feria_provider.dart';
import '../../providers/printer_provider.dart';
import '../../providers/tarima_provider.dart';
import '../../services/participante_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_primary_fab.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/app_modals.dart';
import '../../widgets/combobox_search.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/list_cards.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/money_text.dart';
import '../../widgets/status_badge.dart';

class TarimasScreen extends StatefulWidget {
  const TarimasScreen({super.key});

  @override
  State<TarimasScreen> createState() => _TarimasScreenState();
}

class _TarimasScreenState extends State<TarimasScreen> {
  int? _feriaCargadaId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTarimas(reset: true);
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
          _loadTarimas(reset: true);
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
      context.read<TarimaProvider>().cargarMas();
    }
  }

  Future<void> _loadTarimas({bool reset = false}) async {
    try {
      await context.read<TarimaProvider>().cargarTarimas(reset: reset);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleCrear() async {
    final provider = context.read<TarimaProvider>();
    final tarima = await showModalBottomSheet<Tarima>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ChangeNotifierProvider<TarimaProvider>.value(
        value: provider,
        child: const _FacturarTarimaSheet(),
      ),
    );

    if (tarima == null || !mounted) {
      return;
    }

    try {
      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printTarima(tarima, feriaNombre);

      if (!mounted) {
        return;
      }

      _showSnackBar('Tarima facturada e impresa correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleCancelar(Tarima tarima) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancelar tarima',
      message: '¿Desea cancelar este cobro de tarima?',
      confirmLabel: 'Cancelar tarima',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    final observaciones = await _showObservacionesDialog();

    if (observaciones == null || !mounted) {
      return;
    }

    try {
      await context.read<TarimaProvider>().cancelarTarima(
        tarima.id,
        observaciones: observaciones,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Tarima cancelada correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleImprimir(Tarima tarima) async {
    try {
      final tarimaCompleta = await context.read<TarimaProvider>().obtenerTarima(
        tarima.id,
      );

      if (!mounted) {
        return;
      }

      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printTarima(
        tarimaCompleta,
        feriaNombre,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Ticket reenviado a la impresora.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleVerDetalle(Tarima tarima) async {
    try {
      final tarimaCompleta = await context.read<TarimaProvider>().obtenerTarima(
        tarima.id,
      );

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _TarimaDetailSheet(tarima: tarimaCompleta),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<String?> _showObservacionesDialog() {
    return showTextEntryDialog(
      context,
      title: 'Motivo de cancelación',
      hintText: 'Opcional',
      cancelLabel: 'Volver',
      confirmLabel: 'Cancelar tarima',
      isDestructive: true,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tarimaProvider = context.watch<TarimaProvider>();
    final authProvider = context.watch<AuthProvider>();
    final canCreate = authProvider.hasPermission('tarimas.crear');
    final canCancelar = authProvider.hasPermission('tarimas.cancelar');

    return AppScaffold(
      title: 'Tarimas',
      currentRoute: AppRoutes.tarimas,
      floatingActionButton: canCreate
          ? AppPrimaryFab(
              onPressed: tarimaProvider.isSubmitting ? null : _handleCrear,
              tooltip: 'Facturar tarima',
            )
          : null,
      body: tarimaProvider.isLoading && tarimaProvider.tarimas.isEmpty
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () => _loadTarimas(reset: true),
              child: tarimaProvider.tarimas.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const <Widget>[
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.inventory_2_outlined,
                          subtitle: 'No se encontraron tarimas.',
                        ),
                      ],
                    )
                  : ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: <Widget>[
                        ...tarimaProvider.tarimas.map(
                          (tarima) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OperationListCard<String>(
                              title:
                                  tarima.participante?.nombre ?? 'Participante',
                              amount: MoneyText(
                                tarima.total,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              metaPrimary: Text(
                                [
                                  if (tarima.numeroTarima?.trim().isNotEmpty ??
                                      false)
                                    'Tarima ${tarima.numeroTarima!.trim()}',
                                  'x${tarima.cantidad}',
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              metaSecondary: Text(
                                AppFormatters.formatDateTime(
                                  tarima.createdAt ?? DateTime.now(),
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              status: tarima.estadoLabel ?? tarima.estado,
                              inlineActions: <Widget>[
                                if (canCancelar && tarima.estado == 'facturado')
                                  _InlineCardAction(
                                    label: 'Cancelar',
                                    color: Theme.of(context).colorScheme.error,
                                    onTap: () => _handleCancelar(tarima),
                                  ),
                              ],
                              menuActions: const <ListMenuAction<String>>[
                                ListMenuAction<String>(
                                  value: 'ver',
                                  label: 'Ver detalle',
                                ),
                                ListMenuAction<String>(
                                  value: 'imprimir',
                                  label: 'Imprimir',
                                ),
                              ],
                              onMenuSelected: (value) {
                                switch (value) {
                                  case 'ver':
                                    _handleVerDetalle(tarima);
                                    return;
                                  case 'imprimir':
                                    _handleImprimir(tarima);
                                    return;
                                }
                              },
                              onTap: () => _handleVerDetalle(tarima),
                            ),
                          ),
                        ),
                        if (tarimaProvider.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
            ),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }

      if (data is Map && data['errors'] is Map) {
        final errors = (data['errors'] as Map).values;
        for (final value in errors) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }

      return error.message ?? 'Ocurrió un error al procesar la solicitud.';
    }

    return 'Ocurrió un error inesperado.';
  }
}

class _InlineCardAction extends StatelessWidget {
  const _InlineCardAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FacturarTarimaSheet extends StatefulWidget {
  const _FacturarTarimaSheet();

  @override
  State<_FacturarTarimaSheet> createState() => _FacturarTarimaSheetState();
}

class _FacturarTarimaSheetState extends State<_FacturarTarimaSheet> {
  final ParticipanteService _participanteService = ParticipanteService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidadController = TextEditingController(
    text: '1',
  );
  final TextEditingController _numeroTarimaController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  Participante? _selectedParticipante;

  @override
  void dispose() {
    _cantidadController.dispose();
    _numeroTarimaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  int get _cantidad {
    return int.tryParse(_cantidadController.text.trim()) ?? 0;
  }

  double _calcularTotal(double precioActual) {
    return precioActual * _cantidad;
  }

  Future<List<Participante>> _searchParticipantes(String query) {
    return _participanteService.getParticipantesPorFeria(search: query);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedParticipante == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un participante.')),
      );
      return;
    }

    try {
      final tarima = await context.read<TarimaProvider>().crearTarima(
        participanteId: _selectedParticipante!.id,
        numeroTarima: _numeroTarimaController.text,
        cantidad: _cantidad,
        observaciones: _observacionesController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(tarima);
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
    final tarimaProvider = context.watch<TarimaProvider>();
    final total = _calcularTotal(tarimaProvider.precioActual);

    return AppSheetContainer(
      scrollable: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppSheetHeader(title: 'Facturar tarima'),
            const SizedBox(height: 16),
            AppPriceSummaryCard(
              icon: Icons.price_check,
              label: 'Precio unitario',
              amount: tarimaProvider.precioActual,
              total: total,
            ),
            const SizedBox(height: 16),
            ComboboxSearch<Participante>(
              onSearch: _searchParticipantes,
              labelText: 'Participante',
              hintText: 'Buscar participante',
              minSearchLength: 1,
              displayStringForOption: (participante) => participante.nombre,
              onSelected: (participante) {
                setState(() {
                  _selectedParticipante = participante;
                });
              },
              itemBuilder: (context, participante, isSelected) => ListTile(
                title: Text(participante.nombre),
                subtitle: Text(participante.numeroIdentificacion),
              ),
            ),
            if (_selectedParticipante != null) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Seleccionado: ${_selectedParticipante!.nombre}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedParticipante = null;
                      });
                    },
                    child: const Text('Quitar'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final cantidad = int.tryParse((value ?? '').trim());

                if (cantidad == null) {
                  return 'La cantidad debe ser numérica.';
                }

                if (cantidad < 1) {
                  return 'La cantidad mínima es 1.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numeroTarimaController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Número de tarima (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacionesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            AppSheetActions(
              isSubmitting: tarimaProvider.isSubmitting,
              submitLabel: 'Facturar',
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }

      if (data is Map && data['errors'] is Map) {
        final errors = (data['errors'] as Map).values;
        for (final value in errors) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }
    }

    return 'No fue posible facturar la tarima.';
  }
}

class _TarimaDetailSheet extends StatelessWidget {
  const _TarimaDetailSheet({required this.tarima});

  final Tarima tarima;

  @override
  Widget build(BuildContext context) {
    return AppDetailSheet(
      title: tarima.participante?.nombre ?? 'Participante',
      status: StatusBadge(status: tarima.estadoLabel ?? tarima.estado),
      children: <Widget>[
        AppDetailRow(
          label: 'Número de tarima',
          value: tarima.numeroTarima?.trim().isNotEmpty == true
              ? tarima.numeroTarima!.trim()
              : 'No indicado',
        ),
        AppDetailRow(label: 'Cantidad', value: tarima.cantidad.toString()),
        AppDetailRow(
          label: 'Precio unitario',
          value: AppFormatters.formatMoney(tarima.precioUnitario),
        ),
        AppDetailRow(
          label: 'Total',
          value: AppFormatters.formatMoney(tarima.total),
        ),
        AppDetailRow(
          label: 'Usuario',
          value: tarima.user?.name ?? 'No disponible',
        ),
        AppDetailRow(
          label: 'Fecha',
          value: AppFormatters.formatDateTime(
            tarima.createdAt ?? DateTime.now(),
          ),
        ),
        AppDetailRow(
          label: 'Observaciones',
          value: tarima.observaciones?.trim().isNotEmpty == true
              ? tarima.observaciones!.trim()
              : 'Sin observaciones',
        ),
      ],
    );
  }
}
