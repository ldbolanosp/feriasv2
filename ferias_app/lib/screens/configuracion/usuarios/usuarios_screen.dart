import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../models/feria.dart';
import '../../../models/user.dart';
import '../../../services/feria_service.dart';
import '../../../services/usuario_service.dart';
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

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  static const Map<String, String> _roles = <String, String>{
    'administrador': 'Administrador',
    'supervisor': 'Supervisor',
    'facturador': 'Facturador',
    'inspector': 'Inspector',
  };

  final UsuarioService _usuarioService = UsuarioService();
  final ScrollController _scrollController = ScrollController();

  List<User> _usuarios = <User>[];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final String _search = '';
  final bool? _activoFilter = null;
  final String? _roleFilter = null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsuarios();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadUsuarios(page: _currentPage + 1, append: true);
    }
  }

  Future<void> _loadUsuarios({int page = 1, bool append = false}) async {
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
      final response = await _usuarioService.getUsuarios(
        search: _search,
        activo: _activoFilter,
        role: _roleFilter,
        page: page,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (append) {
          _usuarios = List<User>.unmodifiable(<User>[
            ..._usuarios,
            ...response.data,
          ]);
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _isLoadingMore = false;
        } else {
          _usuarios = response.data;
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _isLoading = false;
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

  Future<void> _openUsuarioDialog({User? user}) async {
    final changed = await showAppBottomSheet<bool>(
      context,
      builder: (context) => _UsuarioFormDialog(
        usuarioService: _usuarioService,
        user: user,
        roles: _roles,
      ),
    );

    if (changed == true && mounted) {
      await _loadUsuarios(page: _currentPage);
    }
  }

  Future<void> _toggleUsuario(User user) async {
    final confirmed = await showConfirmDialog(
      context,
      title: user.activo ? 'Desactivar usuario' : 'Activar usuario',
      message: user.activo
          ? '¿Desea desactivar a ${user.name}?'
          : '¿Desea activar a ${user.name}?',
      confirmLabel: user.activo ? 'Desactivar' : 'Activar',
      isDestructive: user.activo,
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      final updated = await _usuarioService.toggleUsuario(user.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _usuarios = _usuarios
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

  Future<void> _deleteUsuario(User user) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar usuario',
      message: '¿Desea eliminar a ${user.name}? Esta acción es irreversible.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _usuarioService.deleteUsuario(user.id);

      if (!mounted) {
        return;
      }

      await _loadUsuarios(page: _currentPage);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _openResetPasswordDialog(User user) async {
    final changed = await showAppBottomSheet<bool>(
      context,
      builder: (context) =>
          _ResetPasswordDialog(user: user, usuarioService: _usuarioService),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contraseña restablecida para ${user.name}.')),
      );
    }
  }

  Future<void> _openSessionsDialog(User user) async {
    await showAppBottomSheet<void>(
      context,
      builder: (context) =>
          _UserSessionsDialog(user: user, usuarioService: _usuarioService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Usuarios',
      currentRoute: AppRoutes.usuarios,
      floatingActionButton: AppPrimaryFab(
        onPressed: () => _openUsuarioDialog(),
        icon: Icons.person_add_alt_1,
        tooltip: 'Nuevo usuario',
      ),
      body: RefreshIndicator(onRefresh: _loadUsuarios, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_usuarios.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.manage_accounts_outlined,
            subtitle: 'No hay usuarios para los filtros seleccionados.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _usuarios.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _usuarios.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = _usuarios[index];

        return AdminListCard<String>(
          title: user.name,
          subtitle: user.email,
          onTap: () => _openUsuarioDialog(user: user),
          menuActions: <ListMenuAction<String>>[
            const ListMenuAction<String>(value: 'edit', label: 'Editar'),
            ListMenuAction<String>(
              value: 'toggle',
              label: user.activo ? 'Desactivar' : 'Activar',
            ),
            const ListMenuAction<String>(
              value: 'reset',
              label: 'Reset password',
            ),
            const ListMenuAction<String>(
              value: 'sessions',
              label: 'Ver sesiones',
            ),
            const ListMenuAction<String>(value: 'delete', label: 'Eliminar'),
          ],
          onMenuSelected: (value) {
            switch (value) {
              case 'edit':
                _openUsuarioDialog(user: user);
                return;
              case 'toggle':
                _toggleUsuario(user);
                return;
              case 'reset':
                _openResetPasswordDialog(user);
                return;
              case 'sessions':
                _openSessionsDialog(user);
                return;
              case 'delete':
                _deleteUsuario(user);
                return;
            }
          },
          chips: <Widget>[
            StatusBadge(status: user.activo ? 'Activo' : 'Inactivo'),
            if ((user.role ?? '').isNotEmpty)
              StatusBadge(status: _roles[user.role] ?? user.role!),
            StatusBadge(
              status:
                  '${user.feriasCount} feria${user.feriasCount == 1 ? '' : 's'}',
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

class _UsuarioFormDialog extends StatefulWidget {
  const _UsuarioFormDialog({
    required this.usuarioService,
    required this.roles,
    this.user,
  });

  final UsuarioService usuarioService;
  final User? user;
  final Map<String, String> roles;

  @override
  State<_UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<_UsuarioFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FeriaService _feriaService = FeriaService();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passwordConfirmationController;
  List<Feria> _ferias = <Feria>[];
  Set<int> _selectedFerias = <int>{};
  String? _selectedRole;
  bool _activo = true;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, String> _fieldErrors = <String, String>{};

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _passwordConfirmationController = TextEditingController();
    _selectedRole = widget.user?.role;
    _selectedFerias =
        widget.user?.ferias.map((item) => item.id).toSet() ?? <int>{};
    _activo = widget.user?.activo ?? true;
    _loadFerias();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
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

  Future<void> _submit() async {
    setState(() {
      _fieldErrors = <String, String>{};
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'activo': _activo,
        'role': _selectedRole,
        'ferias': _selectedFerias.toList(growable: false),
      };

      if (!_isEditing) {
        payload['password'] = _passwordController.text;
        payload['password_confirmation'] = _passwordConfirmationController.text;
      }

      if (_isEditing) {
        await widget.usuarioService.updateUsuario(
          userId: widget.user!.id,
          data: payload,
        );
      } else {
        await widget.usuarioService.createUsuario(data: payload);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      scrollable: true,
      child: _isLoading
          ? const SizedBox(height: 140, child: LoadingWidget())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppSheetHeader(
                      title: _isEditing ? 'Editar usuario' : 'Nuevo usuario',
                    ),
                    const SizedBox(height: 16),
                    FormFieldCustom(
                      label: 'Nombre',
                      isRequired: true,
                      errorText: _fieldErrors['name'],
                      child: TextFormField(
                        controller: _nameController,
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
                      label: 'Correo electrónico',
                      isRequired: true,
                      errorText: _fieldErrors['email'],
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) {
                            return 'El correo electrónico es requerido.';
                          }

                          final emailRegex = RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          );

                          if (!emailRegex.hasMatch(text)) {
                            return 'Ingrese un correo electrónico válido.';
                          }

                          return null;
                        },
                      ),
                    ),
                    if (!_isEditing) ...<Widget>[
                      const SizedBox(height: 16),
                      FormFieldCustom(
                        label: 'Contraseña',
                        isRequired: true,
                        errorText: _fieldErrors['password'],
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').length < 8) {
                              return 'La contraseña debe tener al menos 8 caracteres.';
                            }

                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormFieldCustom(
                        label: 'Confirmar contraseña',
                        isRequired: true,
                        errorText: _fieldErrors['password_confirmation'],
                        child: TextFormField(
                          controller: _passwordConfirmationController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'La confirmación no coincide.';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FormFieldCustom(
                      label: 'Rol',
                      errorText: _fieldErrors['role'],
                      child: DropdownButtonFormField<String>(
                        initialValue: widget.roles.containsKey(_selectedRole)
                            ? _selectedRole
                            : null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: widget.roles.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ferias asignadas',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    ..._ferias.map(
                      (feria) => CheckboxListTile(
                        value: _selectedFerias.contains(feria.id),
                        contentPadding: EdgeInsets.zero,
                        title: Text(feria.descripcion),
                        subtitle: Text(feria.codigo),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedFerias.add(feria.id);
                            } else {
                              _selectedFerias.remove(feria.id);
                            }
                          });
                        },
                      ),
                    ),
                    if (_isEditing)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _activo,
                        title: const Text('Usuario activo'),
                        onChanged: (value) {
                          setState(() {
                            _activo = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    AppSheetActions(
                      isSubmitting: _isSaving || _isLoading,
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

    return 'No fue posible guardar el usuario.';
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({
    required this.user,
    required this.usuarioService,
  });

  final User user;
  final UsuarioService usuarioService;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
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
      await widget.usuarioService.resetPassword(
        userId: widget.user.id,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
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
    return AppSheetContainer(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppSheetHeader(title: 'Reset password: ${widget.user.name}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').length < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordConfirmationController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'La confirmación no coincide.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            AppSheetActions(
              isSubmitting: _isSaving,
              onSubmit: _submit,
              submitLabel: 'Restablecer',
              onCancel: () => Navigator.of(context).pop(false),
            ),
          ],
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
    }

    return 'No fue posible restablecer la contraseña.';
  }
}

class _UserSessionsDialog extends StatefulWidget {
  const _UserSessionsDialog({required this.user, required this.usuarioService});

  final User user;
  final UsuarioService usuarioService;

  @override
  State<_UserSessionsDialog> createState() => _UserSessionsDialogState();
}

class _UserSessionsDialogState extends State<_UserSessionsDialog> {
  List<UserSessionInfo> _sessions = <UserSessionInfo>[];
  bool _isLoading = true;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await widget.usuarioService.getSesiones(widget.user.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _closeSession(String sessionId) async {
    final isAll = sessionId == 'all';
    final confirmed = await showConfirmDialog(
      context,
      title: isAll ? 'Cerrar todas las sesiones' : 'Cerrar sesión',
      message: isAll
          ? '¿Desea cerrar todas las sesiones activas de este usuario?'
          : '¿Desea cerrar esta sesión?',
      confirmLabel: 'Cerrar',
      isDestructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isClosing = true;
    });

    try {
      await widget.usuarioService.cerrarSesion(
        userId: widget.user.id,
        sessionId: sessionId,
      );

      if (!mounted) {
        return;
      }

      if (sessionId == 'all') {
        setState(() {
          _sessions = <UserSessionInfo>[];
          _isClosing = false;
        });
        return;
      }

      await _loadSessions();
      setState(() {
        _isClosing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isClosing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSheetHeader(title: 'Sesiones de ${widget.user.name}'),
          const SizedBox(height: 16),
          if (_isLoading)
            const SizedBox(height: 160, child: LoadingWidget())
          else if (_sessions.isEmpty)
            const EmptyState(
              icon: Icons.devices_outlined,
              subtitle: 'No hay sesiones activas registradas.',
            )
          else
            ..._sessions.map(
              (session) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('${session.browser} • ${session.platform}'),
                  subtitle: Text(
                    '${session.device} • ${session.ipAddress ?? 'Sin IP'}\n${session.lastActivity == null ? 'Sin actividad' : AppFormatters.formatDateTime(session.lastActivity!.toLocal())}',
                  ),
                  isThreeLine: true,
                  trailing: session.isCurrent
                      ? const StatusBadge(status: 'Actual')
                      : IconButton(
                          tooltip: 'Cerrar sesión',
                          onPressed: _isClosing
                              ? null
                              : () => _closeSession(session.id),
                          icon: const Icon(Icons.logout),
                        ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              if (_sessions.isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isClosing ? null : () => _closeSession('all'),
                    child: const Text('Cerrar todas'),
                  ),
                ),
              if (_sessions.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isClosing
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return 'No fue posible consultar las sesiones.';
  }
}
