import 'package:flutter/foundation.dart';

import '../models/tarima.dart';
import '../services/tarima_service.dart';

class TarimaProvider extends ChangeNotifier {
  TarimaProvider({TarimaService? tarimaService})
    : _tarimaService = tarimaService ?? TarimaService();

  final TarimaService _tarimaService;

  List<Tarima> _tarimas = const <Tarima>[];
  Tarima? _tarimaSeleccionada;
  double _precioActual = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  Map<String, dynamic> _filtros = const <String, dynamic>{};

  List<Tarima> get tarimas => _tarimas;
  Tarima? get tarimaSeleccionada => _tarimaSeleccionada;
  double get precioActual => _precioActual;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _currentPage < _totalPages;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  Map<String, dynamic> get filtros =>
      Map<String, dynamic>.unmodifiable(_filtros);

  Future<void> cargarTarimas({bool reset = false, int? page}) async {
    _setLoading(true);

    try {
      final effectivePage = reset ? 1 : (page ?? _currentPage);
      final response = await _tarimaService.listar(
        estado: _filtros['estado'] as String?,
        search: _filtros['search'] as String?,
        page: effectivePage,
      );

      _tarimas = response.pagination.data;
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
    await cargarTarimas(reset: true);
  }

  Future<void> setEstadoFiltro(String? estado) async {
    final normalized = estado?.trim();
    _filtros = <String, dynamic>{
      ..._filtros,
      'estado': normalized == null || normalized.isEmpty ? null : normalized,
    }..removeWhere((key, dynamic value) => value == null);
    notifyListeners();
    await cargarTarimas(reset: true);
  }

  Future<void> limpiarFiltros() async {
    _filtros = const <String, dynamic>{};
    notifyListeners();
    await cargarTarimas(reset: true);
  }

  Future<Tarima> crearTarima({
    required int participanteId,
    String? numeroTarima,
    required int cantidad,
    String? observaciones,
  }) async {
    return _runSubmitting(() async {
      final tarima = await _tarimaService.crear(
        participanteId: participanteId,
        numeroTarima: numeroTarima,
        cantidad: cantidad,
        observaciones: observaciones,
      );
      _tarimaSeleccionada = tarima;
      await cargarTarimas(page: _currentPage);
      return tarima;
    });
  }

  Future<Tarima> cancelarTarima(int tarimaId, {String? observaciones}) async {
    return _runSubmitting(() async {
      final tarima = await _tarimaService.cancelar(
        tarimaId,
        observaciones: observaciones,
      );
      _tarimaSeleccionada = tarima;
      _upsertTarima(tarima);
      return tarima;
    });
  }

  Future<Tarima> obtenerTarima(int tarimaId) async {
    _setLoading(true);

    try {
      final tarima = await _tarimaService.obtener(tarimaId);
      _tarimaSeleccionada = tarima;
      _upsertTarima(tarima);
      return tarima;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<int>> obtenerPdf(int tarimaId) {
    return _tarimaService.obtenerPdf(tarimaId);
  }

  Future<void> cargarMas() async {
    if (_isLoadingMore || !hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _tarimaService.listar(
        estado: _filtros['estado'] as String?,
        search: _filtros['search'] as String?,
        page: _currentPage + 1,
      );

      _tarimas = List<Tarima>.unmodifiable(<Tarima>[
        ..._tarimas,
        ...response.pagination.data,
      ]);
      _currentPage = response.pagination.currentPage;
      _totalPages = response.pagination.lastPage;
      _totalItems = response.pagination.total;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void clear() {
    _tarimas = const <Tarima>[];
    _tarimaSeleccionada = null;
    _precioActual = 0;
    _isLoading = false;
    _isLoadingMore = false;
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

  void _upsertTarima(Tarima tarima) {
    final index = _tarimas.indexWhere((item) => item.id == tarima.id);

    if (index >= 0) {
      final updated = List<Tarima>.from(_tarimas);
      updated[index] = tarima;
      _tarimas = List<Tarima>.unmodifiable(updated);
      notifyListeners();
      return;
    }

    cargarTarimas(page: _currentPage);
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
