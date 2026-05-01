import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../models/feria.dart';
import '../../../models/participante.dart';
import '../../../services/feria_service.dart';
import '../../../services/participante_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/form_field_custom.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_badge.dart';

class ParticipanteFormScreen extends StatefulWidget {
  const ParticipanteFormScreen({super.key, this.participanteId});

  final int? participanteId;

  @override
  State<ParticipanteFormScreen> createState() => _ParticipanteFormScreenState();
}

class _ParticipanteFormScreenState extends State<ParticipanteFormScreen> {
  static const Map<String, String> _tipoIdentificacionOptions =
      <String, String>{
        'fisica': 'Cédula Física',
        'juridica': 'Cédula Jurídica',
        'dimex': 'DIMEX',
        'nite': 'NITE',
      };

  static const List<String> _tipoSangreOptions = <String>[
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ParticipanteService _participanteService = ParticipanteService();
  final FeriaService _feriaService = FeriaService();

  late final TextEditingController _nombreController;
  late final TextEditingController _numeroIdentificacionController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _procedenciaController;
  late final TextEditingController _numeroCarneController;
  late final TextEditingController _padecimientosController;
  late final TextEditingController _contactoNombreController;
  late final TextEditingController _contactoTelefonoController;

  Participante? _participante;
  List<Feria> _availableFerias = <Feria>[];
  Map<String, String> _fieldErrors = <String, String>{};
  String? _tipoIdentificacion;
  String? _tipoSangre;
  DateTime? _fechaEmisionCarne;
  DateTime? _fechaVencimientoCarne;
  bool _activo = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAssigningFerias = false;

  bool get _isEditing => widget.participanteId != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _numeroIdentificacionController = TextEditingController();
    _correoController = TextEditingController();
    _telefonoController = TextEditingController();
    _procedenciaController = TextEditingController();
    _numeroCarneController = TextEditingController();
    _padecimientosController = TextEditingController();
    _contactoNombreController = TextEditingController();
    _contactoTelefonoController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroIdentificacionController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _procedenciaController.dispose();
    _numeroCarneController.dispose();
    _padecimientosController.dispose();
    _contactoNombreController.dispose();
    _contactoTelefonoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availableFeriasFuture = _feriaService.getFerias(
        perPage: 100,
        sort: 'descripcion',
      );
      final participanteFuture = _isEditing
          ? _participanteService.getParticipante(widget.participanteId!)
          : Future<Participante?>.value(null);

      final availableFerias = await availableFeriasFuture;
      final participante = await participanteFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _availableFerias = availableFerias.data;
        _participante = participante;
        _hydrateForm(participante);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _hydrateForm(Participante? participante) {
    _nombreController.text = participante?.nombre ?? '';
    _numeroIdentificacionController.text =
        participante?.numeroIdentificacion ?? '';
    _correoController.text = participante?.correoElectronico ?? '';
    _telefonoController.text = participante?.telefono ?? '';
    _procedenciaController.text = participante?.procedencia ?? '';
    _numeroCarneController.text = participante?.numeroCarne ?? '';
    _padecimientosController.text = participante?.padecimientos ?? '';
    _contactoNombreController.text =
        participante?.contactoEmergenciaNombre ?? '';
    _contactoTelefonoController.text =
        participante?.contactoEmergenciaTelefono ?? '';
    _tipoIdentificacion = _normalizeDropdownValue(
      participante?.tipoIdentificacion,
      _tipoIdentificacionOptions.keys,
    );
    _tipoSangre = _normalizeDropdownValue(
      participante?.tipoSangre,
      _tipoSangreOptions,
    );
    _fechaEmisionCarne = participante?.fechaEmisionCarne;
    _fechaVencimientoCarne = participante?.fechaVencimientoCarne;
    _activo = participante?.activo ?? true;
  }

  String? _normalizeDropdownValue(String? value, Iterable<String> validValues) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return validValues.contains(normalized) ? normalized : null;
  }

  Future<void> _submit() async {
    setState(() {
      _fieldErrors = <String, String>{};
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoIdentificacion == null) {
      setState(() {
        _fieldErrors['tipo_identificacion'] =
            'El tipo de identificación es requerido.';
      });
      return;
    }

    if (_fechaEmisionCarne != null &&
        _fechaVencimientoCarne != null &&
        !_fechaVencimientoCarne!.isAfter(_fechaEmisionCarne!)) {
      setState(() {
        _fieldErrors['fecha_vencimiento_carne'] =
            'La fecha de vencimiento debe ser posterior a la emisión.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = _payload();
      final participante = _isEditing
          ? await _participanteService.updateParticipante(
              participanteId: widget.participanteId!,
              data: payload,
            )
          : await _participanteService.createParticipante(data: payload);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Participante actualizado correctamente.'
                : 'Participante creado correctamente.',
          ),
        ),
      );

      if (_isEditing) {
        setState(() {
          _participante = participante;
          _hydrateForm(participante);
          _isSaving = false;
        });
        return;
      }

      context.go('${AppRoutes.participantes}/${participante.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _fieldErrors = _extractFieldErrors(error);
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Map<String, dynamic> _payload() {
    return <String, dynamic>{
      'nombre': _nombreController.text.trim(),
      'tipo_identificacion': _tipoIdentificacion,
      'numero_identificacion': _numeroIdentificacionController.text.trim(),
      'correo_electronico': _emptyToNull(_correoController.text),
      'numero_carne': _emptyToNull(_numeroCarneController.text),
      'fecha_emision_carne': _fechaEmisionCarne
          ?.toIso8601String()
          .split('T')
          .first,
      'fecha_vencimiento_carne': _fechaVencimientoCarne
          ?.toIso8601String()
          .split('T')
          .first,
      'procedencia': _emptyToNull(_procedenciaController.text),
      'telefono': _emptyToNull(_telefonoController.text),
      'tipo_sangre': _tipoSangre,
      'padecimientos': _emptyToNull(_padecimientosController.text),
      'contacto_emergencia_nombre': _emptyToNull(
        _contactoNombreController.text,
      ),
      'contacto_emergencia_telefono': _emptyToNull(
        _contactoTelefonoController.text,
      ),
      'activo': _activo,
    }..removeWhere((key, value) => value == null);
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        onSelected(selectedDate);
        _fieldErrors.remove('fecha_vencimiento_carne');
      });
    }
  }

  Future<void> _showAssignFeriasDialog() async {
    final participante = _participante;

    if (participante == null) {
      return;
    }

    final assignedIds = participante.ferias.map((item) => item.id).toSet();
    final selectedIds = <int>{};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Asignar ferias',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: _availableFerias
                            .map((feria) {
                              final alreadyAssigned = assignedIds.contains(
                                feria.id,
                              );
                              final selected = selectedIds.contains(feria.id);

                              return CheckboxListTile(
                                value: alreadyAssigned || selected,
                                onChanged: alreadyAssigned
                                    ? null
                                    : (value) {
                                        setModalState(() {
                                          if (value == true) {
                                            selectedIds.add(feria.id);
                                          } else {
                                            selectedIds.remove(feria.id);
                                          }
                                        });
                                      },
                                title: Text(feria.descripcion),
                                subtitle: Text(feria.codigo),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () => Navigator.of(context).pop(true),
                          child: const Text('Asignar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isAssigningFerias = true;
    });

    try {
      final updatedParticipante = await _participanteService.assignFerias(
        participanteId: participante.id,
        feriaIds: selectedIds.toList(growable: false),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _participante = updatedParticipante;
        _isAssigningFerias = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAssigningFerias = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _removeFeria(Feria feria) async {
    final participante = _participante;

    if (participante == null) {
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Desasignar feria',
      message: '¿Desea desasignar la feria ${feria.descripcion}?',
      confirmLabel: 'Desasignar',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isAssigningFerias = true;
    });

    try {
      final updatedParticipante = await _participanteService.removeFeria(
        participanteId: participante.id,
        feriaId: feria.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _participante = updatedParticipante;
        _isAssigningFerias = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAssigningFerias = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar participante' : 'Nuevo participante',
      currentRoute: AppRoutes.participantes,
      body: _isLoading
          ? const LoadingWidget()
          : Scaffold(
              backgroundColor: Colors.transparent,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSectionCard(
                        title: 'Información básica',
                        child: Column(
                          children: <Widget>[
                            FormFieldCustom(
                              label: 'Nombre',
                              isRequired: true,
                              errorText: _fieldErrors['nombre'],
                              child: TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'El nombre es requerido.';
                                  }

                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            FormFieldCustom(
                              label: 'Tipo de identificación',
                              isRequired: true,
                              errorText: _fieldErrors['tipo_identificacion'],
                              child: DropdownButtonFormField<String>(
                                initialValue: _tipoIdentificacion,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: _tipoIdentificacionOptions.entries
                                    .map(
                                      (entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  setState(() {
                                    _tipoIdentificacion = value;
                                    _fieldErrors.remove('tipo_identificacion');
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            FormFieldCustom(
                              label: 'Número de identificación',
                              isRequired: true,
                              errorText: _fieldErrors['numero_identificacion'],
                              child: TextFormField(
                                controller: _numeroIdentificacionController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'El número de identificación es requerido.';
                                  }

                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            FormFieldCustom(
                              label: 'Correo electrónico',
                              errorText: _fieldErrors['correo_electronico'],
                              child: TextFormField(
                                controller: _correoController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FormFieldCustom(
                              label: 'Teléfono',
                              errorText: _fieldErrors['telefono'],
                              child: TextFormField(
                                controller: _telefonoController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FormFieldCustom(
                              label: 'Procedencia',
                              errorText: _fieldErrors['procedencia'],
                              child: TextFormField(
                                controller: _procedenciaController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppSectionCard(
                        title: 'Carné',
                        child: Column(
                          children: <Widget>[
                            FormFieldCustom(
                              label: 'Número de carné',
                              errorText: _fieldErrors['numero_carne'],
                              child: TextFormField(
                                controller: _numeroCarneController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final stacked = constraints.maxWidth < 520;

                                final fechaEmision = _DateField(
                                  label: 'Fecha emisión',
                                  value: _fechaEmisionCarne,
                                  errorText:
                                      _fieldErrors['fecha_emision_carne'],
                                  onTap: () => _pickDate(
                                    initialDate: _fechaEmisionCarne,
                                    onSelected: (value) {
                                      _fechaEmisionCarne = value;
                                    },
                                  ),
                                );
                                final fechaVencimiento = _DateField(
                                  label: 'Fecha vencimiento',
                                  value: _fechaVencimientoCarne,
                                  errorText:
                                      _fieldErrors['fecha_vencimiento_carne'],
                                  onTap: () => _pickDate(
                                    initialDate: _fechaVencimientoCarne,
                                    onSelected: (value) {
                                      _fechaVencimientoCarne = value;
                                    },
                                  ),
                                );

                                if (stacked) {
                                  return Column(
                                    children: <Widget>[
                                      fechaEmision,
                                      const SizedBox(height: 12),
                                      fechaVencimiento,
                                    ],
                                  );
                                }

                                return Row(
                                  children: <Widget>[
                                    Expanded(child: fechaEmision),
                                    const SizedBox(width: 12),
                                    Expanded(child: fechaVencimiento),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppSectionCard(
                        title: 'Información médica',
                        child: Column(
                          children: <Widget>[
                            FormFieldCustom(
                              label: 'Tipo de sangre',
                              errorText: _fieldErrors['tipo_sangre'],
                              child: DropdownButtonFormField<String>(
                                initialValue: _tipoSangre,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: _tipoSangreOptions
                                    .map(
                                      (value) => DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  setState(() {
                                    _tipoSangre = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            FormFieldCustom(
                              label: 'Padecimientos',
                              errorText: _fieldErrors['padecimientos'],
                              child: TextFormField(
                                controller: _padecimientosController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppSectionCard(
                        title: 'Contacto de emergencia',
                        child: Column(
                          children: <Widget>[
                            FormFieldCustom(
                              label: 'Nombre',
                              errorText:
                                  _fieldErrors['contacto_emergencia_nombre'],
                              child: TextFormField(
                                controller: _contactoNombreController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FormFieldCustom(
                              label: 'Teléfono',
                              errorText:
                                  _fieldErrors['contacto_emergencia_telefono'],
                              child: TextFormField(
                                controller: _contactoTelefonoController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isEditing && _participante != null) ...<Widget>[
                        const SizedBox(height: 16),
                        AppSectionCard(
                          title: 'Asignación de ferias',
                          trailing: FilledButton.tonalIcon(
                            onPressed: _isAssigningFerias
                                ? null
                                : _showAssignFeriasDialog,
                            icon: const Icon(Icons.add_business),
                            label: const Text('Agregar'),
                          ),
                          child: _isAssigningFerias
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: LoadingWidget(),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _participante!.ferias.isEmpty
                                      ? const <Widget>[
                                          StatusBadge(
                                            status: 'Sin ferias asignadas',
                                          ),
                                        ]
                                      : _participante!.ferias
                                            .map(
                                              (feria) => InputChip(
                                                label: Text(feria.descripcion),
                                                onDeleted: () =>
                                                    _removeFeria(feria),
                                              ),
                                            )
                                            .toList(growable: false),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 420;

                      final cancelButton = OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => context.go(AppRoutes.participantes),
                        child: const Text('Cancelar'),
                      );
                      final saveButton = FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar'),
                      );

                      if (stacked) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(width: double.infinity, child: saveButton),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: cancelButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: <Widget>[
                          Expanded(child: cancelButton),
                          const SizedBox(width: 12),
                          Expanded(child: saveButton),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, String> _extractFieldErrors(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['errors'] is Map) {
        final errors = <String, String>{};

        for (final entry in (data['errors'] as Map).entries) {
          final key = entry.key.toString();
          final value = entry.value;

          if (value is List && value.isNotEmpty) {
            errors[key] = value.first.toString();
          }
        }

        return errors;
      }
    }

    return <String, String>{};
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return 'No fue posible completar la operación.';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.onTap,
    this.value,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FormFieldCustom(
      label: label,
      errorText: errorText,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            value == null
                ? 'Seleccionar fecha'
                : AppFormatters.formatDate(value!),
          ),
        ),
      ),
    );
  }
}
