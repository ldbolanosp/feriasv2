import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../models/paginated_response.dart';
import '../../../models/participante.dart';
import '../../../services/participante_service.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_primary_fab.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/list_cards.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_badge.dart';

class ParticipantesListScreen extends StatefulWidget {
  const ParticipantesListScreen({super.key});

  @override
  State<ParticipantesListScreen> createState() =>
      _ParticipantesListScreenState();
}

class _ParticipantesListScreenState extends State<ParticipantesListScreen> {
  static const Map<String, String> _tipoIdentificacionOptions =
      <String, String>{
        'fisica': 'Cédula Física',
        'juridica': 'Cédula Jurídica',
        'dimex': 'DIMEX',
        'nite': 'NITE',
      };

  final ParticipanteService _participanteService = ParticipanteService();
  final ScrollController _scrollController = ScrollController();

  List<Participante> _participantes = <Participante>[];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final String _search = '';
  final bool? _activoFilter = null;
  final String? _tipoIdentificacionFilter = null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadParticipantes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadParticipantes(page: _currentPage + 1, append: true);
    }
  }

  Future<void> _loadParticipantes({int page = 1, bool append = false}) async {
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
      final response = await _participanteService.getParticipantes(
        search: _search,
        activo: _activoFilter,
        tipoIdentificacion: _tipoIdentificacionFilter,
        page: page,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (append) {
          _participantes = List<Participante>.unmodifiable(<Participante>[
            ..._participantes,
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

  void _applyResponse(PaginatedResponse<Participante> response) {
    _participantes = response.data;
    _currentPage = response.currentPage;
    _lastPage = response.lastPage;
    _isLoading = false;
  }

  Future<void> _toggleParticipante(Participante participante) async {
    final confirmed = await showConfirmDialog(
      context,
      title: participante.activo
          ? 'Desactivar participante'
          : 'Activar participante',
      message: participante.activo
          ? '¿Desea desactivar a ${participante.nombre}?'
          : '¿Desea activar a ${participante.nombre}?',
      confirmLabel: participante.activo ? 'Desactivar' : 'Activar',
      isDestructive: participante.activo,
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      final updatedParticipante = await _participanteService.toggleParticipante(
        participante.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _participantes = _participantes
            .map(
              (item) => item.id == updatedParticipante.id
                  ? updatedParticipante
                  : item,
            )
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
      title: 'Participantes',
      currentRoute: AppRoutes.participantes,
      floatingActionButton: AppPrimaryFab(
        onPressed: () => context.go(AppRoutes.participantesCrear),
        icon: Icons.person_add_alt_1,
        tooltip: 'Nuevo participante',
      ),
      body: RefreshIndicator(
        onRefresh: _loadParticipantes,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_participantes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.people_outline,
            subtitle: 'No hay participantes para los filtros seleccionados.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _participantes.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _participantes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final participante = _participantes[index];

        return AdminListCard<String>(
          title: participante.nombre,
          subtitle:
              '${_tipoIdentificacionLabel(participante.tipoIdentificacion)} • ${participante.numeroIdentificacion}',
          extraLines: (participante.telefono ?? '').isNotEmpty
              ? <Widget>[Text(participante.telefono!)]
              : const <Widget>[],
          onTap: () =>
              context.go('${AppRoutes.participantes}/${participante.id}'),
          onLongPress: () => _toggleParticipante(participante),
          menuActions: <ListMenuAction<String>>[
            const ListMenuAction<String>(value: 'edit', label: 'Editar'),
            ListMenuAction<String>(
              value: 'toggle',
              label: participante.activo ? 'Desactivar' : 'Activar',
            ),
          ],
          onMenuSelected: (value) {
            if (value == 'edit') {
              context.go('${AppRoutes.participantes}/${participante.id}');
              return;
            }

            _toggleParticipante(participante);
          },
          chips: <Widget>[
            StatusBadge(status: participante.activo ? 'Activo' : 'Inactivo'),
            if (participante.ferias.isNotEmpty)
              StatusBadge(
                status:
                    '${participante.ferias.length} feria${participante.ferias.length == 1 ? '' : 's'}',
              ),
          ],
        );
      },
    );
  }

  String _tipoIdentificacionLabel(String value) {
    return _tipoIdentificacionOptions[value] ?? value.toUpperCase();
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
