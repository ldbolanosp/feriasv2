import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../models/item_diagnostico.dart';
import '../../../models/paginated_response.dart';
import '../../../services/item_diagnostico_service.dart';
import '../../../widgets/app_primary_fab.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_modals.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/items_diagnostico_widgets.dart';
import '../../../widgets/list_cards.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/search_input.dart';

class ItemsDiagnosticoScreen extends StatefulWidget {
  const ItemsDiagnosticoScreen({super.key});

  @override
  State<ItemsDiagnosticoScreen> createState() => _ItemsDiagnosticoScreenState();
}

class _ItemsDiagnosticoScreenState extends State<ItemsDiagnosticoScreen> {
  final ItemDiagnosticoService _itemService = ItemDiagnosticoService();
  final ScrollController _scrollController = ScrollController();

  List<ItemDiagnostico> _items = <ItemDiagnostico>[];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadItems(append: true);
    }
  }

  Future<void> _loadItems({bool append = false}) async {
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
      final response = await _itemService.getItemsDiagnostico(
        search: _search.isEmpty ? null : _search,
        page: append ? _currentPage + 1 : 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (append) {
          _items = List<ItemDiagnostico>.unmodifiable(<ItemDiagnostico>[
            ..._items,
            ...response.data,
          ]);
          _isLoadingMore = false;
        } else {
          _applyResponse(response);
        }

        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
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
        _isLoadingMore = false;
      });
    }
  }

  void _applyResponse(PaginatedResponse<ItemDiagnostico> response) {
    _items = response.data;
    _currentPage = response.currentPage;
    _lastPage = response.lastPage;
    _isLoading = false;
  }

  Future<void> _openFormSheet({ItemDiagnostico? item}) async {
    final changed = await showAppBottomSheet<bool>(
      context,
      builder: (context) => ItemDiagnosticoFormSheet(
        item: item,
        onSubmit: (nombre) async {
          if (item == null) {
            await _itemService.createItemDiagnostico(nombre: nombre);
          } else {
            await _itemService.updateItemDiagnostico(
              id: item.id,
              nombre: nombre,
            );
          }
        },
      ),
    );

    if (changed == true && mounted) {
      await _loadItems();
    }
  }

  Future<void> _deleteItem(ItemDiagnostico item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar item de diagnóstico',
      message:
          'Se eliminará "${item.nombre}" del catálogo. Las inspecciones guardadas conservarán su nombre histórico.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _itemService.deleteItemDiagnostico(item.id);

      if (!mounted) {
        return;
      }

      await _loadItems();
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
      title: 'Items de diagnóstico',
      currentRoute: AppRoutes.itemsDiagnostico,
      floatingActionButton: AppPrimaryFab(
        onPressed: () {
          _openFormSheet();
        },
        icon: Icons.playlist_add_circle_outlined,
        tooltip: 'Nuevo item de diagnóstico',
      ),
      body: RefreshIndicator(
        onRefresh: _loadItems,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchInput(
                hintText: 'Buscar item...',
                onChanged: (value) {
                  _search = value;
                  _loadItems();
                },
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
        children: const <Widget>[
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.playlist_add_check_circle_outlined,
            subtitle: 'No hay items de diagnóstico registrados todavía.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _items[index];

        return AdminListCard<String>(
          title: item.nombre,
          subtitle: item.updatedAt == null
              ? 'Sin fecha de actualización'
              : 'Actualizado ${_formatDate(item.updatedAt!)}',
          onTap: () {
            _openFormSheet(item: item);
          },
          menuActions: <ListMenuAction<String>>[
            const ListMenuAction<String>(value: 'edit', label: 'Editar'),
            const ListMenuAction<String>(value: 'delete', label: 'Eliminar'),
          ],
          onMenuSelected: (value) {
            if (value == 'edit') {
              _openFormSheet(item: item);
              return;
            }

            _deleteItem(item);
          },
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
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
