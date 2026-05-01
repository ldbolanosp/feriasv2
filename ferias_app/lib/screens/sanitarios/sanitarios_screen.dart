import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../models/participante.dart';
import '../../models/sanitario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feria_provider.dart';
import '../../providers/printer_provider.dart';
import '../../providers/sanitario_provider.dart';
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
import '../../widgets/module_ui.dart';
import '../../widgets/status_badge.dart';

class SanitariosScreen extends StatefulWidget {
  const SanitariosScreen({super.key});

  @override
  State<SanitariosScreen> createState() => _SanitariosScreenState();
}

class _SanitariosScreenState extends State<SanitariosScreen> {
  int? _feriaCargadaId;
  final ScrollController _scrollController = ScrollController();
  List<Sanitario> _sanitarios = <Sanitario>[];
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSanitarios(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final feriaId = context.watch<FeriaProvider>().feriaActiva?.id;

    if (feriaId != null && feriaId != _feriaCargadaId) {
      _feriaCargadaId = feriaId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadSanitarios(reset: true);
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadSanitarios(page: _currentPage + 1, append: true);
    }
  }

  Future<void> _loadSanitarios({
    bool reset = false,
    int? page,
    bool append = false,
  }) async {
    if (append) {
      if (_isLoadingMore || _currentPage >= _totalPages) {
        return;
      }

      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      await context.read<SanitarioProvider>().cargarSanitarios(
        reset: reset,
        page: page,
      );

      if (!mounted) {
        return;
      }

      final provider = context.read<SanitarioProvider>();
      setState(() {
        if (append) {
          _sanitarios = List<Sanitario>.unmodifiable(<Sanitario>[
            ..._sanitarios,
            ...provider.sanitarios,
          ]);
          _isLoadingMore = false;
        } else {
          _sanitarios = provider.sanitarios;
        }

        _currentPage = provider.currentPage;
        _totalPages = provider.totalPages;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (append) {
        setState(() {
          _isLoadingMore = false;
        });
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleCrear() async {
    final provider = context.read<SanitarioProvider>();
    final sanitario = await showModalBottomSheet<Sanitario>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ChangeNotifierProvider<SanitarioProvider>.value(
        value: provider,
        child: const _FacturarSanitarioSheet(),
      ),
    );

    if (sanitario == null || !mounted) {
      return;
    }

    try {
      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printSanitario(
        sanitario,
        feriaNombre,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Sanitario facturado e impreso correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleCancelar(Sanitario sanitario) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancelar sanitario',
      message: '¿Desea cancelar este cobro de sanitario?',
      confirmLabel: 'Cancelar sanitario',
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
      final actualizado = await context
          .read<SanitarioProvider>()
          .cancelarSanitario(sanitario.id, observaciones: observaciones);

      if (!mounted) {
        return;
      }

      setState(() {
        _sanitarios = _sanitarios
            .map((item) => item.id == actualizado.id ? actualizado : item)
            .toList(growable: false);
      });

      _showSnackBar('Sanitario cancelado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(_errorMessage(error));
    }
  }

  Future<void> _handleImprimir(Sanitario sanitario) async {
    try {
      final sanitarioCompleto = await context
          .read<SanitarioProvider>()
          .obtenerSanitario(sanitario.id);

      if (!mounted) {
        return;
      }

      final feriaNombre =
          context.read<FeriaProvider>().feriaActiva?.descripcion ??
          'Ferias del Agricultor';

      await context.read<PrinterProvider>().printSanitario(
        sanitarioCompleto,
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

  Future<void> _handleVerDetalle(Sanitario sanitario) async {
    try {
      final sanitarioCompleto = await context
          .read<SanitarioProvider>()
          .obtenerSanitario(sanitario.id);

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) =>
            _SanitarioDetailSheet(sanitario: sanitarioCompleto),
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
      confirmLabel: 'Cancelar sanitario',
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
    final sanitarioProvider = context.watch<SanitarioProvider>();
    final authProvider = context.watch<AuthProvider>();
    final canCreate = authProvider.hasPermission('sanitarios.crear');
    final canCancelar = authProvider.hasPermission('sanitarios.cancelar');

    return AppScaffold(
      title: 'Sanitarios',
      currentRoute: AppRoutes.sanitarios,
      floatingActionButton: canCreate
          ? AppPrimaryFab(
              onPressed: sanitarioProvider.isSubmitting ? null : _handleCrear,
              tooltip: 'Facturar sanitario',
            )
          : null,
      body: sanitarioProvider.isLoading && sanitarioProvider.sanitarios.isEmpty
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () => _loadSanitarios(reset: true),
              child: _sanitarios.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: <Widget>[
                        EmptyState(
                          icon: Icons.water_drop_outlined,
                          title: 'No se encontraron sanitarios',
                          subtitle: 'No hay movimientos registrados.',
                          actionLabel: canCreate ? 'Facturar sanitario' : null,
                          onActionPressed: canCreate ? _handleCrear : null,
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _sanitarios.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _sanitarios.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final sanitario = _sanitarios[index];

                        return OperationListCard<String>(
                          title: sanitario.esPublico
                              ? 'Uso público'
                              : (sanitario.participante?.nombre ??
                                    'Participante no disponible'),
                          amount: MoneyText(
                            sanitario.total,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          metaPrimary: Text(
                            AppFormatters.formatDateTime(
                              sanitario.createdAt ?? DateTime.now(),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          metaSecondary: Text(
                            'Usuario: ${sanitario.user?.name ?? 'No disponible'}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          status: sanitario.estadoLabel ?? sanitario.estado,
                          chips: <Widget>[
                            SoftInfoChip(
                              icon: Icons.confirmation_number,
                              label: 'Cantidad ${sanitario.cantidad}',
                            ),
                            SoftInfoChip(
                              icon: Icons.attach_money,
                              child: MoneyText(
                                sanitario.total,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                          footer:
                              sanitario.observaciones?.trim().isNotEmpty ??
                                  false
                              ? Text(
                                  sanitario.observaciones!.trim(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              : null,
                          menuActions: <ListMenuAction<String>>[
                            if (sanitario.estado == 'facturado' && canCancelar)
                              const ListMenuAction<String>(
                                value: 'cancelar',
                                label: 'Cancelar',
                              ),
                            const ListMenuAction<String>(
                              value: 'ver',
                              label: 'Ver detalle',
                            ),
                            const ListMenuAction<String>(
                              value: 'imprimir',
                              label: 'Imprimir',
                            ),
                          ],
                          onMenuSelected: (value) {
                            switch (value) {
                              case 'cancelar':
                                _handleCancelar(sanitario);
                                return;
                              case 'ver':
                                _handleVerDetalle(sanitario);
                                return;
                              case 'imprimir':
                                _handleImprimir(sanitario);
                                return;
                            }
                          },
                          onTap: () => _handleVerDetalle(sanitario),
                        );
                      },
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

class _FacturarSanitarioSheet extends StatefulWidget {
  const _FacturarSanitarioSheet();

  @override
  State<_FacturarSanitarioSheet> createState() =>
      _FacturarSanitarioSheetState();
}

class _FacturarSanitarioSheetState extends State<_FacturarSanitarioSheet> {
  final ParticipanteService _participanteService = ParticipanteService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidadController = TextEditingController(
    text: '1',
  );
  final TextEditingController _observacionesController =
      TextEditingController();

  Participante? _selectedParticipante;

  @override
  void dispose() {
    _cantidadController.dispose();
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

    try {
      final sanitario = await context.read<SanitarioProvider>().crearSanitario(
        participanteId: _selectedParticipante?.id,
        cantidad: _cantidad,
        observaciones: _observacionesController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(sanitario);
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
    final sanitarioProvider = context.watch<SanitarioProvider>();
    final total = _calcularTotal(sanitarioProvider.precioActual);

    return AppSheetContainer(
      scrollable: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppSheetHeader(title: 'Facturar sanitario'),
            const SizedBox(height: 16),
            AppPriceSummaryCard(
              icon: Icons.price_check,
              label: 'Precio unitario',
              amount: sanitarioProvider.precioActual,
              total: total,
            ),
            const SizedBox(height: 16),
            ComboboxSearch<Participante>(
              onSearch: _searchParticipantes,
              labelText: 'Participante (opcional)',
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
              controller: _observacionesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            AppSheetActions(
              isSubmitting: sanitarioProvider.isSubmitting,
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

    return 'No fue posible facturar el sanitario.';
  }
}

class _SanitarioDetailSheet extends StatelessWidget {
  const _SanitarioDetailSheet({required this.sanitario});

  final Sanitario sanitario;

  @override
  Widget build(BuildContext context) {
    return AppDetailSheet(
      title: sanitario.esPublico
          ? 'Uso público'
          : (sanitario.participante?.nombre ?? 'Participante'),
      status: StatusBadge(status: sanitario.estadoLabel ?? sanitario.estado),
      children: <Widget>[
        AppDetailRow(label: 'Cantidad', value: sanitario.cantidad.toString()),
        AppDetailRow(
          label: 'Precio unitario',
          value: AppFormatters.formatMoney(sanitario.precioUnitario),
        ),
        AppDetailRow(
          label: 'Total',
          value: AppFormatters.formatMoney(sanitario.total),
        ),
        AppDetailRow(
          label: 'Usuario',
          value: sanitario.user?.name ?? 'No disponible',
        ),
        AppDetailRow(
          label: 'Fecha',
          value: AppFormatters.formatDateTime(
            sanitario.createdAt ?? DateTime.now(),
          ),
        ),
        AppDetailRow(
          label: 'Observaciones',
          value: sanitario.observaciones?.trim().isNotEmpty == true
              ? sanitario.observaciones!.trim()
              : 'Sin observaciones',
        ),
      ],
    );
  }
}
