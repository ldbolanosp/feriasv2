import 'package:flutter/foundation.dart';

import '../models/parqueo.dart';
import '../services/parqueo_service.dart';

class ParqueoProvider extends ChangeNotifier {
  ParqueoProvider({ParqueoService? parqueoService})
    : _parqueoService = parqueoService ?? ParqueoService();

  final ParqueoService _parqueoService;

  List<Parqueo> _parqueos = const <Parqueo>[];
  Parqueo? _parqueoSeleccionado;
  double _tarifaActual = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  Map<String, dynamic> _filtros = const <String, dynamic>{};

  List<Parqueo> get parqueos => _parqueos;
  Parqueo? get parqueoSeleccionado => _parqueoSeleccionado;
  double get tarifaActual => _tarifaActual;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _currentPage < _totalPages;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  Map<String, dynamic> get filtros =>
      Map<String, dynamic>.unmodifiable(_filtros);

  Future<void> cargarParqueos({bool reset = false, int? page}) async {
    _setLoading(true);

    try {
      final effectivePage = reset ? 1 : (page ?? _currentPage);
      final response = await _parqueoService.listar(
        estado: _filtros['estado'] as String?,
        placa: _filtros['placa'] as String?,
        fecha: _filtros['fecha'] as String?,
        page: effectivePage,
      );

      _parqueos = response.pagination.data;
      _tarifaActual = response.tarifaActual;
      _currentPage = response.pagination.currentPage;
      _totalPages = response.pagination.lastPage;
      _totalItems = response.pagination.total;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> buscarPorPlaca(String value) async {
    final normalized = value.trim();
    _filtros = <String, dynamic>{
      ..._filtros,
      'placa': normalized.isEmpty ? null : normalized.toUpperCase(),
    }..removeWhere((key, dynamic value) => value == null);
    notifyListeners();
    await cargarParqueos(reset: true);
  }

  Future<void> setEstadoFiltro(String? estado) async {
    final normalized = estado?.trim();
    _filtros = <String, dynamic>{
      ..._filtros,
      'estado': normalized == null || normalized.isEmpty ? null : normalized,
    }..removeWhere((key, dynamic value) => value == null);
    notifyListeners();
    await cargarParqueos(reset: true);
  }

  Future<void> setFechaFiltro(DateTime? fecha) async {
    _filtros = <String, dynamic>{
      ..._filtros,
      'fecha': fecha == null ? null : _formatApiDate(fecha),
    }..removeWhere((key, dynamic value) => value == null);
    notifyListeners();
    await cargarParqueos(reset: true);
  }

  Future<void> limpiarFiltros() async {
    _filtros = const <String, dynamic>{};
    notifyListeners();
    await cargarParqueos(reset: true);
  }

  Future<Parqueo> registrarParqueo({
    required String placa,
    String? observaciones,
  }) async {
    return _runSubmitting(() async {
      final parqueo = await _parqueoService.crear(
        placa: placa,
        observaciones: observaciones,
      );
      _parqueoSeleccionado = parqueo;
      await cargarParqueos(page: _currentPage);
      return parqueo;
    });
  }

  Future<Parqueo> registrarSalida(
    int parqueoId, {
    String? observaciones,
  }) async {
    return _runSubmitting(() async {
      final parqueo = await _parqueoService.registrarSalida(
        parqueoId,
        observaciones: observaciones,
      );
      _parqueoSeleccionado = parqueo;
      _upsertParqueo(parqueo);
      return parqueo;
    });
  }

  Future<Parqueo> cancelarParqueo(
    int parqueoId, {
    String? observaciones,
  }) async {
    return _runSubmitting(() async {
      final parqueo = await _parqueoService.cancelar(
        parqueoId,
        observaciones: observaciones,
      );
      _parqueoSeleccionado = parqueo;
      _upsertParqueo(parqueo);
      return parqueo;
    });
  }

  Future<Parqueo> obtenerParqueo(int parqueoId) async {
    _setLoading(true);

    try {
      final parqueo = await _parqueoService.obtener(parqueoId);
      _parqueoSeleccionado = parqueo;
      _upsertParqueo(parqueo);
      return parqueo;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<int>> obtenerPdf(int parqueoId) {
    return _parqueoService.obtenerPdf(parqueoId);
  }

  Future<void> cargarMas() async {
    if (_isLoadingMore || !hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _parqueoService.listar(
        estado: _filtros['estado'] as String?,
        placa: _filtros['placa'] as String?,
        fecha: _filtros['fecha'] as String?,
        page: _currentPage + 1,
      );

      _parqueos = List<Parqueo>.unmodifiable(<Parqueo>[
        ..._parqueos,
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
    _parqueos = const <Parqueo>[];
    _parqueoSeleccionado = null;
    _tarifaActual = 0;
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

  void _upsertParqueo(Parqueo parqueo) {
    final index = _parqueos.indexWhere((item) => item.id == parqueo.id);

    if (index >= 0) {
      final updated = List<Parqueo>.from(_parqueos);
      updated[index] = parqueo;
      _parqueos = List<Parqueo>.unmodifiable(updated);
      notifyListeners();
      return;
    }

    cargarParqueos(page: _currentPage);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  String _formatApiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
