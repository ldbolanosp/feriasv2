import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../models/feria.dart';
import '../../../models/paginated_response.dart';
import '../../../services/feria_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_primary_fab.dart';
import '../../../widgets/app_modals.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/form_field_custom.dart';
import '../../../widgets/list_cards.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_badge.dart';

class FeriasScreen extends StatefulWidget {
  const FeriasScreen({super.key});

  @override
  State<FeriasScreen> createState() => _FeriasScreenState();
}

class _FeriasScreenState extends State<FeriasScreen> {
  final FeriaService _feriaService = FeriaService();
  final ScrollController _scrollController = ScrollController();

  List<Feria> _ferias = <Feria>[];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final String _search = '';
  final bool? _statusFilter = null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFerias();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadFerias(page: _currentPage + 1, append: true);
    }
  }

  Future<void> _loadFerias({int page = 1, bool append = false}) async {
    if (append) {
      if (_isLoadingMore || _currentPage >= _lastPage) {
        return;
      }

      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await _feriaService.getFerias(
        search: _search,
        activa: _statusFilter,
        page: page,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (append) {
          _ferias = List<Feria>.unmodifiable(<Feria>[
            ..._ferias,
            ...response.data,
          ]);
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _isLoadingMore = false;
        } else {
          _applyResponse(response);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      setState(() {
        if (append) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
      });
    }
  }

  void _applyResponse(PaginatedResponse<Feria> response) {
    _ferias = response.data;
    _currentPage = response.currentPage;
    _lastPage = response.lastPage;
    _isLoading = false;
  }

  Future<void> _openFeriaDialog({Feria? feria}) async {
    final result = await showAppBottomSheet<bool>(
      context,
      builder: (context) =>
          _FeriaFormDialog(feria: feria, feriaService: _feriaService),
    );

    if (result == true && mounted) {
      await _loadFerias(page: _currentPage);
    }
  }

  Future<void> _toggleFeria(Feria feria) async {
    final confirmed = await showConfirmDialog(
      context,
      title: feria.activa ? 'Desactivar feria' : 'Activar feria',
      message: feria.activa
          ? '¿Desea desactivar la feria ${feria.codigo}?'
          : '¿Desea activar la feria ${feria.codigo}?',
      confirmLabel: feria.activa ? 'Desactivar' : 'Activar',
      isDestructive: feria.activa,
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      final updatedFeria = await _feriaService.toggleFeria(feria.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _ferias = _ferias
            .map((item) => item.id == updatedFeria.id ? updatedFeria : item)
            .toList(growable: false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedFeria.activa
                ? 'Feria activada correctamente.'
                : 'Feria desactivada correctamente.',
          ),
        ),
      );
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
    return AppScaffold(
      title: 'Ferias',
      currentRoute: AppRoutes.ferias,
      floatingActionButton: AppPrimaryFab(
        onPressed: () => _openFeriaDialog(),
        tooltip: 'Nueva feria',
      ),
      body: RefreshIndicator(onRefresh: _loadFerias, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_ferias.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.location_off_outlined,
            subtitle: 'Ajuste los filtros o cree una nueva feria.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _ferias.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _ferias.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final feria = _ferias[index];

        return AdminListCard<String>(
          title: feria.codigo,
          subtitle: feria.descripcion,
          onTap: () => _openFeriaDialog(feria: feria),
          onLongPress: () => _toggleFeria(feria),
          menuActions: <ListMenuAction<String>>[
            const ListMenuAction<String>(value: 'edit', label: 'Editar'),
            ListMenuAction<String>(
              value: 'toggle',
              label: feria.activa ? 'Desactivar' : 'Activar',
            ),
          ],
          onMenuSelected: (value) {
            if (value == 'edit') {
              _openFeriaDialog(feria: feria);
              return;
            }

            _toggleFeria(feria);
          },
          chips: <Widget>[
            StatusBadge(status: feria.activa ? 'Activo' : 'Inactivo'),
            StatusBadge(
              status: feria.facturacionPublico
                  ? 'Facturación pública'
                  : 'Solo participantes',
            ),
          ],
        );
      },
    );
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

class _FeriaFormDialog extends StatefulWidget {
  const _FeriaFormDialog({required this.feriaService, this.feria});

  final FeriaService feriaService;
  final Feria? feria;

  @override
  State<_FeriaFormDialog> createState() => _FeriaFormDialogState();
}

class _FeriaFormDialogState extends State<_FeriaFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _descripcionController;
  late bool _facturacionPublico;
  late bool _activa;
  bool _isSaving = false;

  bool get _isEditing => widget.feria != null;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.feria?.codigo ?? '');
    _descripcionController = TextEditingController(
      text: widget.feria?.descripcion ?? '',
    );
    _facturacionPublico = widget.feria?.facturacionPublico ?? false;
    _activa = widget.feria?.activa ?? true;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await widget.feriaService.updateFeria(
          feriaId: widget.feria!.id,
          codigo: _codigoController.text,
          descripcion: _descripcionController.text,
          facturacionPublico: _facturacionPublico,
          activa: _activa,
        );
      } else {
        await widget.feriaService.createFeria(
          codigo: _codigoController.text,
          descripcion: _descripcionController.text,
          facturacionPublico: _facturacionPublico,
          activa: _activa,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Feria actualizada correctamente.'
                : 'Feria creada correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      scrollable: true,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppSheetHeader(
                title: _isEditing ? 'Editar feria' : 'Nueva feria',
              ),
              const SizedBox(height: 16),
              FormFieldCustom(
                label: 'Código',
                isRequired: true,
                child: TextFormField(
                  controller: _codigoController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ej. SJ-CENTRAL',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'El código es requerido.';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              FormFieldCustom(
                label: 'Descripción',
                isRequired: true,
                child: TextFormField(
                  controller: _descripcionController,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nombre descriptivo de la feria',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'La descripción es requerida.';
                    }

                    return null;
                  },
                ),
              ),
              SwitchListTile.adaptive(
                value: _facturacionPublico,
                contentPadding: EdgeInsets.zero,
                title: const Text('Facturación público general'),
                subtitle: const Text(
                  'Permite facturar a clientes sin participante asociado.',
                ),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _facturacionPublico = value;
                        });
                      },
              ),
              if (_isEditing)
                SwitchListTile.adaptive(
                  value: _activa,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Feria activa'),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _activa = value;
                          });
                        },
                ),
              const SizedBox(height: 16),
              AppSheetActions(
                isSubmitting: _isSaving,
                onSubmit: _submit,
                submitLabel: _isEditing ? 'Guardar' : 'Crear',
                onCancel: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      if (data is Map && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final firstError = errors.values.firstOrNull;

        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }

    return 'No fue posible guardar la feria.';
  }
}
