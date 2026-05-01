import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/parqueo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feria_provider.dart';
import '../../providers/parqueo_provider.dart';
import '../../providers/printer_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_primary_fab.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/app_modals.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/list_cards.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/money_text.dart';
import '../../widgets/status_badge.dart';

class ParqueosScreen extends StatefulWidget {
  const ParqueosScreen({super.key});

  @override
  State<ParqueosScreen> createState() => _ParqueosScreenState();
}

class _ParqueosScreenState extends State<ParqueosScreen> {
  int? _feriaCargadaId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParqueos(reset: true);
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
          _loadParqueos(reset: true);
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
      context.read<ParqueoProvider>().cargarMas();
    }
  }

  Future<void> _loadParqueos({bool reset = false}) async {
    try {
      await context.read<ParqueoProvider>().cargarParqueos(reset: reset);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleCrear() async {
    final provider = context.read<ParqueoProvider>();
    final parqueo = await showModalBottomSheet<Parqueo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ChangeNotifierProvider<ParqueoProvider>.value(
        value: provider,
        child: const _RegistroParqueoSheet(),
      ),
    );

    if (parqueo == null || !mounted) {
      return;
    }

    try {
      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printParqueo(parqueo, feriaNombre);

      if (!mounted) {
        return;
      }

      _showSnackBar('Parqueo registrado e impreso correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleRegistrarSalida(Parqueo parqueo) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Registrar salida',
      message: '¿Desea marcar la salida del vehículo ${parqueo.placa}?',
      confirmLabel: 'Registrar salida',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final observaciones = await _showObservacionesDialog(
      title: 'Observaciones de salida',
      hintText: 'Opcional',
      confirmLabel: 'Guardar',
    );

    if (observaciones == null || !mounted) {
      return;
    }

    try {
      await context.read<ParqueoProvider>().registrarSalida(
        parqueo.id,
        observaciones: observaciones,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Salida registrada correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleCancelar(Parqueo parqueo) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancelar parqueo',
      message: '¿Desea cancelar el parqueo de ${parqueo.placa}?',
      confirmLabel: 'Cancelar parqueo',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    final observaciones = await _showObservacionesDialog(
      title: 'Motivo de cancelación',
      hintText: 'Opcional',
      confirmLabel: 'Cancelar parqueo',
      isDestructive: true,
    );

    if (observaciones == null || !mounted) {
      return;
    }

    try {
      await context.read<ParqueoProvider>().cancelarParqueo(
        parqueo.id,
        observaciones: observaciones,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Parqueo cancelado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleImprimir(Parqueo parqueo) async {
    try {
      final parqueoCompleto = await context
          .read<ParqueoProvider>()
          .obtenerParqueo(parqueo.id);

      if (!mounted) {
        return;
      }

      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printParqueo(
        parqueoCompleto,
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

  Future<void> _handleVerDetalle(Parqueo parqueo) async {
    try {
      final parqueoCompleto = await context
          .read<ParqueoProvider>()
          .obtenerParqueo(parqueo.id);

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _ParqueoDetailSheet(parqueo: parqueoCompleto),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<String?> _showObservacionesDialog({
    required String title,
    required String hintText,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showTextEntryDialog(
      context,
      title: title,
      hintText: hintText,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final parqueoProvider = context.watch<ParqueoProvider>();
    final authProvider = context.watch<AuthProvider>();
    final canCreate = authProvider.hasPermission('parqueos.crear');
    final canSalida = authProvider.hasPermission('parqueos.salida');
    final canCancelar = authProvider.hasPermission('parqueos.cancelar');

    return AppScaffold(
      title: 'Parqueos',
      currentRoute: AppRoutes.parqueos,
      floatingActionButton: canCreate
          ? AppPrimaryFab(
              onPressed: parqueoProvider.isSubmitting ? null : _handleCrear,
              tooltip: 'Registrar parqueo',
            )
          : null,
      body: parqueoProvider.isLoading && parqueoProvider.parqueos.isEmpty
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () => _loadParqueos(reset: true),
              child: parqueoProvider.parqueos.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const <Widget>[
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.directions_car_outlined,
                          subtitle: 'No se encontraron parqueos.',
                        ),
                      ],
                    )
                  : ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: <Widget>[
                        ...parqueoProvider.parqueos.map(
                          (parqueo) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OperationListCard<String>(
                              title: parqueo.placa,
                              amount: MoneyText(
                                parqueo.tarifa,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              metaPrimary: Text(
                                'Ingreso ${AppFormatters.formatDateTime(parqueo.fechaHoraIngreso)}',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              metaSecondary: parqueo.fechaHoraSalida != null
                                  ? Text(
                                      'Salida ${AppFormatters.formatDateTime(parqueo.fechaHoraSalida!)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              status: parqueo.estadoLabel ?? parqueo.estado,
                              inlineActions: <Widget>[
                                if (canSalida && parqueo.estado == 'activo')
                                  _InlineCardAction(
                                    label: 'Registrar salida',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    onTap: () =>
                                        _handleRegistrarSalida(parqueo),
                                  ),
                                if (canCancelar && parqueo.estado == 'activo')
                                  _InlineCardAction(
                                    label: 'Cancelar',
                                    color: Theme.of(context).colorScheme.error,
                                    onTap: () => _handleCancelar(parqueo),
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
                                    _handleVerDetalle(parqueo);
                                    return;
                                  case 'imprimir':
                                    _handleImprimir(parqueo);
                                    return;
                                }
                              },
                              onTap: () => _handleVerDetalle(parqueo),
                            ),
                          ),
                        ),
                        if (parqueoProvider.isLoadingMore)
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
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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

class _RegistroParqueoSheet extends StatefulWidget {
  const _RegistroParqueoSheet();

  @override
  State<_RegistroParqueoSheet> createState() => _RegistroParqueoSheetState();
}

class _RegistroParqueoSheetState extends State<_RegistroParqueoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _observacionesController = TextEditingController();

  @override
  void dispose() {
    _placaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final parqueo = await context.read<ParqueoProvider>().registrarParqueo(
        placa: _placaController.text,
        observaciones: _observacionesController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(parqueo);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = _errorMessage(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parqueoProvider = context.watch<ParqueoProvider>();
    return AppSheetContainer(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppSheetHeader(title: 'Registro rápido de parqueo'),
            const SizedBox(height: 16),
            AppPriceSummaryCard(
              icon: Icons.local_parking_rounded,
              label: 'Tarifa actual',
              amount: parqueoProvider.tarifaActual,
              highlightColor: AppTheme.primarySoftColor,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placaController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.send,
              maxLength: 20,
              decoration: const InputDecoration(labelText: 'Placa'),
              onChanged: (value) {
                final uppercased = value.toUpperCase();
                if (uppercased != value) {
                  _placaController.value = _placaController.value.copyWith(
                    text: uppercased,
                    selection: TextSelection.collapsed(
                      offset: uppercased.length,
                    ),
                  );
                }
              },
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La placa es obligatoria.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacionesController,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            const SizedBox(height: 16),
            AppSheetActions(
              isSubmitting: parqueoProvider.isSubmitting,
              submitLabel: 'Registrar',
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

    return 'No fue posible registrar el parqueo.';
  }
}

class _ParqueoDetailSheet extends StatelessWidget {
  const _ParqueoDetailSheet({required this.parqueo});

  final Parqueo parqueo;

  @override
  Widget build(BuildContext context) {
    return AppDetailSheet(
      title: parqueo.placa,
      status: StatusBadge(status: parqueo.estadoLabel ?? parqueo.estado),
      children: <Widget>[
        AppDetailRow(
          label: 'Ingreso',
          value: AppFormatters.formatDateTime(parqueo.fechaHoraIngreso),
        ),
        AppDetailRow(
          label: 'Salida',
          value: parqueo.fechaHoraSalida == null
              ? 'Pendiente'
              : AppFormatters.formatDateTime(parqueo.fechaHoraSalida!),
        ),
        AppDetailRow(
          label: 'Tarifa',
          value: AppFormatters.formatMoney(parqueo.tarifa),
        ),
        AppDetailRow(
          label: 'Tipo tarifa',
          value: parqueo.tarifaTipoLabel ?? parqueo.tarifaTipo,
        ),
        AppDetailRow(
          label: 'Usuario',
          value: parqueo.user?.name ?? 'No disponible',
        ),
        AppDetailRow(
          label: 'Feria',
          value: parqueo.feria?.descripcion ?? 'No disponible',
        ),
        AppDetailRow(
          label: 'Observaciones',
          value: parqueo.observaciones?.trim().isNotEmpty == true
              ? parqueo.observaciones!.trim()
              : 'Sin observaciones',
        ),
      ],
    );
  }
}
