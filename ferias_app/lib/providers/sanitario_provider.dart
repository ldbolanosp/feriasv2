import 'package:flutter/foundation.dart';

import '../models/sanitario.dart';
import '../services/sanitario_service.dart';

class SanitarioProvider extends ChangeNotifier {
  SanitarioProvider({SanitarioService? sanitarioService})
    : _sanitarioService = sanitarioService ?? SanitarioService();

  final SanitarioService _sanitarioService;

  List<Sanitario> _sanitarios = const <Sanitario>[];
  Sanitario? _sanitarioSeleccionado;
  double _precioActual = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  Map<String, dynamic> _filtros = const <String, dynamic>{};

  List<Sanitario> get sanitarios => _sanitarios;
  Sanitario? get sanitarioSeleccionado => _sanitarioSeleccionado;
  double get precioActual => _precioActual;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  Map<String, dynamic> get filtros =>
      Map<String, dynamic>.unmodifiable(_filtros);

  Future<void> cargarSanitarios({bool reset = false, int? page}) async {
    _setLoading(true);

    try {
      final effectivePage = reset ? 1 : (page ?? _currentPage);
      final response = await _sanitarioService.listar(
        estado: _filtros['estado'] as String?,
        search: _filtros['search'] as String?,
        page: effectivePage,
      );

      _sanitarios = response.pagination.data;
      _precioActual = response.precioActual;
      _currentPage = response.pagination.currentPage;
      _totalPages = response.pagination.lastPage;
      _totalItems = response.pagination.total;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> buscar(String value) async {
    final normalized = value.trim();
    _filtros = <String, dynamic>{
      ..._filtros,
      'search': normalized.isEmpty ? null : normalized,
    }..removeWhere((key, dynamic value) => value == null);
    notifyListeners();
    await cargarSanitarios(reset: true);
  }

  Future<void> setEstadoFiltro(String? estado) async {
    final normalized = estado?.trim();
    _filtros = <String, dynamic>{
      ..._filtros,
      'estado': normalized == null || normalized.isEmpty ? null : normalized,
    }..removeWhere((key, dynamic value) => value == null);
    notifyListeners();
    await cargarSanitarios(reset: true);
  }

  Future<void> limpiarFiltros() async {
    _filtros = const <String, dynamic>{};
    notifyListeners();
    await cargarSanitarios(reset: true);
  }

  Future<Sanitario> crearSanitario({
    int? participanteId,
    required int cantidad,
    String? observaciones,
  }) async {
    return _runSubmitting(() async {
      final sanitario = await _sanitarioService.crear(
        participanteId: participanteId,
        cantidad: cantidad,
        observaciones: observaciones,
      );
      _sanitarioSeleccionado = sanitario;
      await cargarSanitarios(page: _currentPage);
      return sanitario;
    });
  }

  Future<Sanitario> cancelarSanitario(
    int sanitarioId, {
    String? observaciones,
  }) async {
    return _runSubmitting(() async {
      final sanitario = await _sanitarioService.cancelar(
        sanitarioId,
        observaciones: observaciones,
      );
      _sanitarioSeleccionado = sanitario;
      _upsertSanitario(sanitario);
      return sanitario;
    });
  }

  Future<Sanitario> obtenerSanitario(int sanitarioId) async {
    _setLoading(true);

    try {
      final sanitario = await _sanitarioService.obtener(sanitarioId);
      _sanitarioSeleccionado = sanitario;
      _upsertSanitario(sanitario);
      return sanitario;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<int>> obtenerPdf(int sanitarioId) {
    return _sanitarioService.obtenerPdf(sanitarioId);
  }

  void clear() {
    _sanitarios = const <Sanitario>[];
    _sanitarioSeleccionado = null;
    _precioActual = 0;
    _isLoading = false;
    _isSubmitting = false;
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _filtros = const <String, dynamic>{};
    notifyListeners();
  }

  Future<T> _runSubmitting<T>(Future<T> Function() callback) async {
    _setSubmitting(true);

    try {
      return await callback();
    } finally {
      _setSubmitting(false);
    }
  }

  void _upsertSanitario(Sanitario sanitario) {
    final index = _sanitarios.indexWhere((item) => item.id == sanitario.id);

    if (index >= 0) {
      final updated = List<Sanitario>.from(_sanitarios);
      updated[index] = sanitario;
      _sanitarios = List<Sanitario>.unmodifiable(updated);
      notifyListeners();
      return;
    }

    cargarSanitarios(page: _currentPage);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }
}
