import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../models/feria.dart';
import '../../../models/paginated_response.dart';
import '../../../models/producto.dart';
import '../../../models/producto_precio.dart';
import '../../../services/feria_service.dart';
import '../../../services/producto_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_primary_fab.dart';
import '../../../widgets/app_modals.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/form_field_custom.dart';
import '../../../widgets/list_cards.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_badge.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoService _productoService = ProductoService();
  final ScrollController _scrollController = ScrollController();

  List<Producto> _productos = <Producto>[];
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
    _loadProductos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadProductos(page: _currentPage + 1, append: true);
    }
  }

  Future<void> _loadProductos({int page = 1, bool append = false}) async {
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
      final response = await _productoService.getProductos(
        search: _search,
        activo: _statusFilter,
        page: page,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (append) {
          _productos = List<Producto>.unmodifiable(<Producto>[
            ..._productos,
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

  void _applyResponse(PaginatedResponse<Producto> response) {
    _productos = response.data;
    _currentPage = response.currentPage;
    _lastPage = response.lastPage;
    _isLoading = false;
  }

  Future<void> _openProductoDialog({Producto? producto}) async {
    final changed = await showAppBottomSheet<bool>(
      context,
      builder: (context) => _ProductoFormDialog(
        productoService: _productoService,
        producto: producto,
      ),
    );

    if (changed == true && mounted) {
      await _loadProductos(page: _currentPage);
    }
  }

  Future<void> _openPreciosDialog(Producto producto) async {
    final changed = await showAppBottomSheet<bool>(
      context,
      builder: (context) => _ProductoPreciosDialog(
        producto: producto,
        productoService: _productoService,
      ),
    );

    if (changed == true && mounted) {
      await _loadProductos(page: _currentPage);
    }
  }

  Future<void> _toggleProducto(Producto producto) async {
    final confirmed = await showConfirmDialog(
      context,
      title: producto.activo ? 'Desactivar producto' : 'Activar producto',
      message: producto.activo
          ? '¿Desea desactivar el producto ${producto.codigo}?'
          : '¿Desea activar el producto ${producto.codigo}?',
      confirmLabel: producto.activo ? 'Desactivar' : 'Activar',
      isDestructive: producto.activo,
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      final updated = await _productoService.toggleProducto(producto.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = _productos
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
      });
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
      title: 'Productos',
      currentRoute: AppRoutes.productos,
      floatingActionButton: AppPrimaryFab(
        onPressed: () => _openProductoDialog(),
        tooltip: 'Nuevo producto',
      ),
      body: RefreshIndicator(onRefresh: _loadProductos, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_productos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.inventory_2_outlined,
            subtitle: 'No hay productos registrados con esos filtros.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _productos.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _productos.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final producto = _productos[index];

        return AdminListCard<String>(
          title: producto.codigo,
          subtitle: producto.descripcion,
          onTap: () => _openProductoDialog(producto: producto),
          onLongPress: () => _openPreciosDialog(producto),
          menuActions: <ListMenuAction<String>>[
            const ListMenuAction<String>(value: 'editar', label: 'Editar'),
            const ListMenuAction<String>(
              value: 'precios',
              label: 'Gestionar precios',
            ),
            ListMenuAction<String>(
              value: 'toggle',
              label: producto.activo ? 'Desactivar' : 'Activar',
            ),
          ],
          onMenuSelected: (value) {
            switch (value) {
              case 'editar':
                _openProductoDialog(producto: producto);
                return;
              case 'precios':
                _openPreciosDialog(producto);
                return;
              case 'toggle':
                _toggleProducto(producto);
                return;
            }
          },
          chips: <Widget>[
            StatusBadge(status: producto.activo ? 'Activo' : 'Inactivo'),
            StatusBadge(
              status:
                  '${producto.preciosCount} feria${producto.preciosCount == 1 ? '' : 's'} con precio',
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

class _ProductoFormDialog extends StatefulWidget {
  const _ProductoFormDialog({required this.productoService, this.producto});

  final ProductoService productoService;
  final Producto? producto;

  @override
  State<_ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<_ProductoFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _descripcionController;
  bool _activo = true;
  bool _isSaving = false;

  bool get _isEditing => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(
      text: widget.producto?.codigo ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.producto?.descripcion ?? '',
    );
    _activo = widget.producto?.activo ?? true;
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
        await widget.productoService.updateProducto(
          productoId: widget.producto!.id,
          codigo: _codigoController.text,
          descripcion: _descripcionController.text,
          activo: _activo,
        );
      } else {
        await widget.productoService.createProducto(
          codigo: _codigoController.text,
          descripcion: _descripcionController.text,
          activo: _activo,
        );
      }

      if (!mounted) {
        return;
      }

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
            children: <Widget>[
              AppSheetHeader(
                title: _isEditing ? 'Editar producto' : 'Nuevo producto',
              ),
              const SizedBox(height: 16),
              FormFieldCustom(
                label: 'Código',
                isRequired: true,
                child: TextFormField(
                  controller: _codigoController,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
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
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'La descripción es requerida.';
                    }

                    return null;
                  },
                ),
              ),
              if (_isEditing)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _activo,
                  title: const Text('Producto activo'),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _activo = value;
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

      if (data is Map && data['errors'] is Map) {
        final first = (data['errors'] as Map).values.firstOrNull;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return 'No fue posible guardar el producto.';
  }
}

class _ProductoPreciosDialog extends StatefulWidget {
  const _ProductoPreciosDialog({
    required this.producto,
    required this.productoService,
  });

  final Producto producto;
  final ProductoService productoService;

  @override
  State<_ProductoPreciosDialog> createState() => _ProductoPreciosDialogState();
}

class _ProductoPreciosDialogState extends State<_ProductoPreciosDialog> {
  final FeriaService _feriaService = FeriaService();
  final TextEditingController _precioController = TextEditingController();
  List<Feria> _ferias = <Feria>[];
  Producto? _producto;
  int? _selectedFeriaId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
    _loadFerias();
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _loadFerias() async {
    try {
      final response = await _feriaService.getFerias(
        perPage: 100,
        sort: 'descripcion',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ferias = response.data;
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

  Future<void> _addPrecio() async {
    final feriaId = _selectedFeriaId;
    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    if (feriaId == null || precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una feria y un precio válido.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await widget.productoService.assignPrecios(
        productoId: widget.producto.id,
        precios: <Map<String, dynamic>>[
          <String, dynamic>{'feria_id': feriaId, 'precio': precio},
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _producto = updated;
        _selectedFeriaId = null;
        _precioController.clear();
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _removePrecio(ProductoPrecio precio) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar precio',
      message:
          '¿Desea eliminar el precio asignado a ${precio.feria?.descripcion ?? 'esta feria'}?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await widget.productoService.removePrecio(
        productoId: widget.producto.id,
        feriaId: precio.feriaId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _producto = updated;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final producto = _producto ?? widget.producto;
    final usedFeriaIds = producto.precios.map((item) => item.feriaId).toSet();
    final availableFerias = _ferias
        .where(
          (item) =>
              !usedFeriaIds.contains(item.id) || item.id == _selectedFeriaId,
        )
        .toList(growable: false);

    return AppSheetContainer(
      scrollable: true,
      child: _isLoading
          ? const SizedBox(height: 120, child: LoadingWidget())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppSheetHeader(title: 'Precios de ${producto.codigo}'),
                const SizedBox(height: 16),
                if (producto.precios.isEmpty)
                  const EmptyState(
                    icon: Icons.sell_outlined,
                    subtitle: 'Aún no hay precios asignados.',
                  )
                else
                  ...producto.precios.map(
                    (precio) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(precio.feria?.descripcion ?? 'Feria'),
                      subtitle: Text(precio.feria?.codigo ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(AppFormatters.formatMoney(precio.precio)),
                          IconButton(
                            tooltip: 'Eliminar precio',
                            onPressed: _isSaving
                                ? null
                                : () => _removePrecio(precio),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 32),
                Text(
                  'Agregar precio',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedFeriaId,
                  decoration: const InputDecoration(
                    labelText: 'Feria',
                    border: OutlineInputBorder(),
                  ),
                  items: availableFerias
                      .map(
                        (feria) => DropdownMenuItem<int>(
                          value: feria.id,
                          child: Text(feria.descripcion),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedFeriaId = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(),
                    prefixText: '₡ ',
                  ),
                ),
                const SizedBox(height: 16),
                AppSheetActions(
                  isSubmitting: _isSaving || _isLoading,
                  submitLabel: 'Agregar',
                  cancelLabel: 'Cerrar',
                  onSubmit: _addPrecio,
                  onCancel: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['errors'] is Map) {
        final first = (data['errors'] as Map).values.firstOrNull;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return 'No fue posible completar la operación.';
  }
}
