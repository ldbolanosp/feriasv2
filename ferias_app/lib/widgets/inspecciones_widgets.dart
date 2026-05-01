import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/inspeccion.dart';
import '../models/item_diagnostico.dart';
import '../models/participante.dart';
import '../services/item_diagnostico_service.dart';
import '../services/participante_service.dart';
import '../utils/formatters.dart';
import 'app_modals.dart';
import 'app_surfaces.dart';
import 'empty_state.dart';
import 'form_field_custom.dart';
import 'loading_widget.dart';
import 'search_input.dart';
import 'status_badge.dart';

class InspeccionResultBadge extends StatelessWidget {
  const InspeccionResultBadge({super.key, required this.totalIncumplidos});

  final int totalIncumplidos;

  @override
  Widget build(BuildContext context) {
    if (totalIncumplidos > 0) {
      return StatusBadge(
        status:
            '$totalIncumplidos pendiente${totalIncumplidos == 1 ? '' : 's'}',
      );
    }

    return const StatusBadge(status: 'Completa');
  }
}

class InspeccionDetailSheet extends StatelessWidget {
  const InspeccionDetailSheet({super.key, required this.inspeccion});

  final Inspeccion inspeccion;

  @override
  Widget build(BuildContext context) {
    return AppDetailSheet(
      title: inspeccion.esReinspeccion ? 'Reinspección' : 'Inspección',
      status: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          InspeccionResultBadge(totalIncumplidos: inspeccion.totalIncumplidos),
          StatusBadge(
            status: inspeccion.esReinspeccion ? 'Reinspección' : 'Inspección',
          ),
        ],
      ),
      children: <Widget>[
        if (inspeccion.participante != null)
          AppDetailRow(
            label: 'Participante',
            value:
                '${inspeccion.participante!.nombre}\n${inspeccion.participante!.numeroIdentificacion}',
          ),
        if (inspeccion.inspector != null)
          AppDetailRow(
            label: 'Inspector',
            value:
                '${inspeccion.inspector!.name}\n${inspeccion.inspector!.email}',
          ),
        if (inspeccion.createdAt != null)
          AppDetailRow(
            label: 'Fecha',
            value: AppFormatters.formatDateTime(inspeccion.createdAt!),
          ),
        AppDetailRow(
          label: 'Resultado',
          value:
              '${inspeccion.totalItems} item${inspeccion.totalItems == 1 ? '' : 's'} revisados, ${inspeccion.totalIncumplidos} incumplimiento${inspeccion.totalIncumplidos == 1 ? '' : 's'}',
        ),
        if (inspeccion.items.isNotEmpty)
          AppSectionCard(
            title: 'Items evaluados',
            child: Column(
              children: inspeccion.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InspectionItemSummaryCard(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }
}

class ParticipanteCarneSheet extends StatefulWidget {
  const ParticipanteCarneSheet({
    super.key,
    required this.participante,
    required this.onSubmit,
  });

  final Participante participante;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<ParticipanteCarneSheet> createState() => _ParticipanteCarneSheetState();
}

class _ParticipanteCarneSheetState extends State<ParticipanteCarneSheet> {
  late final TextEditingController _numeroCarneController;
  late final TextEditingController _fechaEmisionController;
  late final TextEditingController _fechaVencimientoController;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _numeroCarneController = TextEditingController(
      text: widget.participante.numeroCarne ?? '',
    );
    _fechaEmisionController = TextEditingController(
      text: widget.participante.fechaEmisionCarne == null
          ? ''
          : _toInputDate(widget.participante.fechaEmisionCarne!),
    );
    _fechaVencimientoController = TextEditingController(
      text: widget.participante.fechaVencimientoCarne == null
          ? ''
          : _toInputDate(widget.participante.fechaVencimientoCarne!),
    );
  }

  @override
  void dispose() {
    _numeroCarneController.dispose();
    _fechaEmisionController.dispose();
    _fechaVencimientoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    if (_isSubmitting) {
      return;
    }

    final now = DateTime.now();
    final parsedInitial = DateTime.tryParse(controller.text.trim());
    final selectedDate = await showDatePicker(
      context: context,
      locale: const Locale('es', 'CR'),
      initialDate:
          parsedInitial ??
          initialDate ??
          DateTime(now.year, now.month, now.day),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final month = selectedDate.month.toString().padLeft(2, '0');
    final day = selectedDate.day.toString().padLeft(2, '0');

    setState(() {
      controller.text = '${selectedDate.year}-$month-$day';
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    final numeroCarne = _numeroCarneController.text.trim();
    final fechaEmision = _fechaEmisionController.text.trim();
    final fechaVencimiento = _fechaVencimientoController.text.trim();

    if (fechaEmision.isNotEmpty && fechaVencimiento.isNotEmpty) {
      final emision = DateTime.tryParse(fechaEmision);
      final vencimiento = DateTime.tryParse(fechaVencimiento);

      if (emision != null &&
          vencimiento != null &&
          !vencimiento.isAfter(emision)) {
        setState(() {
          _errorText =
              'La fecha de vencimiento debe ser posterior a la fecha de emisión.';
          _isSubmitting = false;
        });
        return;
      }
    }

    try {
      await widget.onSubmit(<String, dynamic>{
        'numero_carne': numeroCarne.isEmpty ? null : numeroCarne,
        'fecha_emision_carne': fechaEmision.isEmpty ? null : fechaEmision,
        'fecha_vencimiento_carne': fechaVencimiento.isEmpty
            ? null
            : fechaVencimiento,
      });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (error is DioException) {
        final data = error.response?.data;

        if (data is Map && data['message'] != null) {
          setState(() {
            _errorText = data['message'].toString();
          });
          return;
        }
      }

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSheetHeader(title: 'Actualizar carné'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutralSoftColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.participante.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.participante.numeroIdentificacion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FormFieldCustom(
            label: 'Número de carné',
            child: TextField(
              controller: _numeroCarneController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(hintText: 'Ej. CAR-2026-015'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: FormFieldCustom(
                  label: 'Fecha de emisión',
                  child: TextField(
                    controller: _fechaEmisionController,
                    enabled: !_isSubmitting,
                    readOnly: true,
                    onTap: () {
                      _pickDate(
                        controller: _fechaEmisionController,
                        initialDate: widget.participante.fechaEmisionCarne,
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: 'AAAA-MM-DD',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FormFieldCustom(
                  label: 'Fecha de vencimiento',
                  child: TextField(
                    controller: _fechaVencimientoController,
                    enabled: !_isSubmitting,
                    readOnly: true,
                    onTap: () {
                      _pickDate(
                        controller: _fechaVencimientoController,
                        initialDate: widget.participante.fechaVencimientoCarne,
                        firstDate:
                            DateTime.tryParse(
                              _fechaEmisionController.text.trim(),
                            ) ??
                            DateTime(2020),
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: 'AAAA-MM-DD',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorText!),
          ],
          const SizedBox(height: 20),
          AppSheetActions(
            isSubmitting: _isSubmitting,
            submitLabel: 'Guardar carné',
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  String _toInputDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class InspeccionFormSheet extends StatefulWidget {
  const InspeccionFormSheet({
    super.key,
    required this.participanteService,
    required this.itemDiagnosticoService,
    required this.onSubmit,
    this.reinspeccionBase,
  });

  final ParticipanteService participanteService;
  final ItemDiagnosticoService itemDiagnosticoService;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final Inspeccion? reinspeccionBase;

  @override
  State<InspeccionFormSheet> createState() => _InspeccionFormSheetState();
}

class _InspeccionFormSheetState extends State<InspeccionFormSheet> {
  Participante? _selectedParticipante;
  List<_EditableInspeccionItem> _items = <_EditableInspeccionItem>[];
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromBase();
  }

  void _hydrateFromBase() {
    final base = widget.reinspeccionBase;

    if (base?.participante != null) {
      final participantSummary = base!.participante!;
      _selectedParticipante = Participante(
        id: participantSummary.id,
        nombre: participantSummary.nombre,
        tipoIdentificacion: '',
        numeroIdentificacion: participantSummary.numeroIdentificacion,
        numeroCarne: participantSummary.numeroCarne,
        fechaVencimientoCarne: participantSummary.fechaVencimientoCarne,
        activo: true,
      );
    }

    final failedItems =
        base?.items.where((item) => !item.cumple).toList() ??
        const <InspeccionItem>[];
    _items = failedItems.isEmpty
        ? <_EditableInspeccionItem>[]
        : failedItems
              .map(
                (item) => _EditableInspeccionItem(
                  itemDiagnosticoId: item.itemDiagnosticoId,
                  nombre: item.nombreItem,
                  cumple: true,
                  observaciones: '',
                ),
              )
              .toList(growable: true);
  }

  Future<void> _pickParticipante() async {
    final participante = await showAppBottomSheet<Participante>(
      context,
      builder: (context) => ParticipantePickerSheet(
        participanteService: widget.participanteService,
      ),
    );

    if (participante == null || !mounted) {
      return;
    }

    setState(() {
      _selectedParticipante = participante;
    });
  }

  Future<void> _pickItemDiagnostico() async {
    final selectedIds = _items
        .map((item) => item.itemDiagnosticoId)
        .whereType<int>()
        .toSet();
    final item = await showAppBottomSheet<ItemDiagnostico>(
      context,
      builder: (context) => ItemDiagnosticoPickerSheet(
        itemDiagnosticoService: widget.itemDiagnosticoService,
        selectedIds: selectedIds,
      ),
    );

    if (item == null || !mounted) {
      return;
    }

    setState(() {
      _items = <_EditableInspeccionItem>[
        ..._items,
        _EditableInspeccionItem(
          itemDiagnosticoId: item.id,
          nombre: item.nombre,
        ),
      ];
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    if (_selectedParticipante == null) {
      setState(() {
        _errorText = 'Debe seleccionar un participante.';
        _isSubmitting = false;
      });
      return;
    }

    if (_items.isEmpty ||
        _items.any((item) => item.itemDiagnosticoId == null)) {
      setState(() {
        _errorText = 'Debe agregar al menos un item válido para la inspección.';
        _isSubmitting = false;
      });
      return;
    }

    try {
      await widget.onSubmit(<String, dynamic>{
        'participante_id': _selectedParticipante!.id,
        if (widget.reinspeccionBase != null)
          'reinspeccion_de_id': widget.reinspeccionBase!.id,
        'items': _items
            .map(
              (item) => <String, dynamic>{
                'item_diagnostico_id': item.itemDiagnosticoId,
                'cumple': item.cumple,
                'observaciones': item.observaciones.trim().isEmpty
                    ? null
                    : item.observaciones.trim(),
              },
            )
            .toList(growable: false),
      });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (error is DioException) {
        final data = error.response?.data;

        if (data is Map) {
          if (data['errors'] is Map) {
            final errors = Map<String, dynamic>.from(data['errors'] as Map);
            String? firstMessage;

            for (final messages in errors.values) {
              if (messages is List && messages.isNotEmpty) {
                firstMessage = messages.first.toString();
                break;
              }
            }

            if (firstMessage != null) {
              setState(() {
                _errorText = firstMessage.toString();
                _isSubmitting = false;
              });
              return;
            }
          }

          if (data['message'] != null) {
            setState(() {
              _errorText = data['message'].toString();
              _isSubmitting = false;
            });
            return;
          }
        }
      }

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSheetHeader(
            title: widget.reinspeccionBase == null
                ? 'Nueva inspección'
                : 'Nueva reinspección',
          ),
          if (widget.reinspeccionBase?.participante != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DB),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: const Color(0xFFFFD480)),
              ),
              child: Text(
                'Se precargan los items pendientes de la última inspección de ${widget.reinspeccionBase!.participante!.nombre}.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8A5A00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppSectionCard(
            title: 'Participante',
            child: _selectedParticipante == null
                ? _SelectorActionTile(
                    label: '+ Seleccionar participante',
                    icon: Icons.person_search_outlined,
                    onTap: _pickParticipante,
                  )
                : _SelectedParticipanteCard(
                    participante: _selectedParticipante!,
                    onEdit: _pickParticipante,
                  ),
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Items de diagnóstico',
            trailing: TextButton.icon(
              onPressed: _isSubmitting ? null : _pickItemDiagnostico,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar item'),
            ),
            child: _items.isEmpty
                ? _SelectorActionTile(
                    label: '+ Agregar item',
                    icon: Icons.playlist_add_outlined,
                    onTap: _pickItemDiagnostico,
                  )
                : Column(
                    children: _items
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key == _items.length - 1 ? 0 : 12,
                            ),
                            child: _EditableInspectionItemCard(
                              item: entry.value,
                              onChanged: (updated) {
                                setState(() {
                                  _items[entry.key] = updated;
                                });
                              },
                              onDelete: () {
                                setState(() {
                                  _items.removeAt(entry.key);
                                });
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorText!),
          ],
          const SizedBox(height: 20),
          AppSheetActions(
            isSubmitting: _isSubmitting,
            submitLabel: 'Guardar inspección',
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

class ParticipantePickerSheet extends StatefulWidget {
  const ParticipantePickerSheet({super.key, required this.participanteService});

  final ParticipanteService participanteService;

  @override
  State<ParticipantePickerSheet> createState() =>
      _ParticipantePickerSheetState();
}

class _ParticipantePickerSheetState extends State<ParticipantePickerSheet> {
  List<Participante> _participantes = const <Participante>[];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadParticipantes();
  }

  Future<void> _loadParticipantes([String search = '']) async {
    setState(() {
      _isLoading = true;
      _search = search;
    });

    try {
      final participantes = await widget.participanteService
          .getParticipantesPorFeria(search: search.isEmpty ? null : search);

      if (!mounted) {
        return;
      }

      setState(() {
        _participantes = participantes;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSheetHeader(title: 'Seleccionar participante'),
          const SizedBox(height: 16),
          SearchInput(
            hintText: 'Buscar por nombre o identificación...',
            initialValue: _search,
            onChanged: _loadParticipantes,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _isLoading
                ? const LoadingWidget(message: 'Cargando participantes')
                : _participantes.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    subtitle:
                        'No se encontraron participantes en la feria activa.',
                  )
                : ListView.separated(
                    itemCount: _participantes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final participante = _participantes[index];

                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.of(context).pop(participante),
                          title: Text(
                            participante.nombre,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(participante.numeroIdentificacion),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ItemDiagnosticoPickerSheet extends StatefulWidget {
  const ItemDiagnosticoPickerSheet({
    super.key,
    required this.itemDiagnosticoService,
    required this.selectedIds,
  });

  final ItemDiagnosticoService itemDiagnosticoService;
  final Set<int> selectedIds;

  @override
  State<ItemDiagnosticoPickerSheet> createState() =>
      _ItemDiagnosticoPickerSheetState();
}

class _ItemDiagnosticoPickerSheetState
    extends State<ItemDiagnosticoPickerSheet> {
  List<ItemDiagnostico> _items = const <ItemDiagnostico>[];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems([String search = '']) async {
    setState(() {
      _isLoading = true;
      _search = search;
    });

    try {
      final response = await widget.itemDiagnosticoService.getItemsDiagnostico(
        search: search.isEmpty ? null : search,
        page: 1,
        perPage: 100,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = response.data
            .where((item) => !widget.selectedIds.contains(item.id))
            .toList(growable: false);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppSheetHeader(title: 'Agregar item de diagnóstico'),
          const SizedBox(height: 16),
          SearchInput(
            hintText: 'Buscar item...',
            initialValue: _search,
            onChanged: _loadItems,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _isLoading
                ? const LoadingWidget(message: 'Cargando items')
                : _items.isEmpty
                ? const EmptyState(
                    icon: Icons.playlist_add_check_circle_outlined,
                    subtitle: 'No hay items disponibles para agregar.',
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.of(context).pop(item),
                          title: Text(
                            item.nombre,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          trailing: const Icon(Icons.add_rounded),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InspectionItemSummaryCard extends StatelessWidget {
  const _InspectionItemSummaryCard({required this.item});

  final InspeccionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.nombreItem,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              StatusBadge(status: item.cumple ? 'Cumple' : 'No cumple'),
            ],
          ),
          if ((item.observaciones ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(item.observaciones!.trim()),
          ],
        ],
      ),
    );
  }
}

class _SelectedParticipanteCard extends StatelessWidget {
  const _SelectedParticipanteCard({
    required this.participante,
    required this.onEdit,
  });

  final Participante participante;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  participante.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  participante.numeroIdentificacion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if ((participante.numeroCarne ?? '')
                    .trim()
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      StatusBadge(status: 'Carné ${participante.numeroCarne}'),
                      if (participante.fechaVencimientoCarne != null)
                        StatusBadge(
                          status:
                              'Vence ${AppFormatters.formatDate(participante.fechaVencimientoCarne!)}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cambiar participante',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _EditableInspectionItemCard extends StatelessWidget {
  const _EditableInspectionItemCard({
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final _EditableInspeccionItem item;
  final ValueChanged<_EditableInspeccionItem> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  item.nombre,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar item',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('Cumple')),
              ButtonSegment<bool>(value: false, label: Text('No cumple')),
            ],
            selected: <bool>{item.cumple},
            onSelectionChanged: (value) {
              onChanged(item.copyWith(cumple: value.first));
            },
          ),
          const SizedBox(height: 12),
          FormFieldCustom(
            label: 'Observaciones',
            child: TextFormField(
              key: ValueKey<int?>(item.itemDiagnosticoId),
              initialValue: item.observaciones,
              minLines: 2,
              maxLines: 4,
              onChanged: (value) {
                onChanged(item.copyWith(observaciones: value));
              },
              decoration: const InputDecoration(
                hintText: 'Detalle relevante de este item...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorActionTile extends StatelessWidget {
  const _SelectorActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralSoftColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EditableInspeccionItem {
  const _EditableInspeccionItem({
    required this.itemDiagnosticoId,
    required this.nombre,
    this.cumple = true,
    this.observaciones = '',
  });

  final int? itemDiagnosticoId;
  final String nombre;
  final bool cumple;
  final String observaciones;

  _EditableInspeccionItem copyWith({
    int? itemDiagnosticoId,
    String? nombre,
    bool? cumple,
    String? observaciones,
  }) {
    return _EditableInspeccionItem(
      itemDiagnosticoId: itemDiagnosticoId ?? this.itemDiagnosticoId,
      nombre: nombre ?? this.nombre,
      cumple: cumple ?? this.cumple,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
