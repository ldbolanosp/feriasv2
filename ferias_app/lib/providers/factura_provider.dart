import 'package:flutter/foundation.dart';

import '../models/factura.dart';
import '../services/factura_service.dart';

class FacturaProvider extends ChangeNotifier {
  FacturaProvider({FacturaService? facturaService})
    : _facturaService = facturaService ?? FacturaService();

  final FacturaService _facturaService;

  List<Factura> _facturas = const <Factura>[];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  Map<String, dynamic> _filtros = const <String, dynamic>{};
  Factura? _facturaActual;

  List<Factura> get facturas => _facturas;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentPage < _totalPages;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  Map<String, dynamic> get filtros =>
      Map<String, dynamic>.unmodifiable(_filtros);
  Factura? get facturaActual => _facturaActual;

  Future<void> listar({
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    int? participanteId,
    int? feriaId,
    int page = 1,
  }) async {
    _setLoading(true);

    try {
      _filtros = <String, dynamic>{
        'estado': estado,
        'fecha_desde': fechaDesde,
        'fecha_hasta': fechaHasta,
        'participante_id': participanteId,
        'feria_id': feriaId,
      }..removeWhere((key, value) => value == null);

      final response = await _facturaService.listar(
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        participanteId: participanteId,
        feriaId: feriaId,
        page: page,
      );

      _facturas = response.data;
      _currentPage = response.currentPage;
      _totalPages = response.lastPage;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> recargar() async {
    await listar(
      estado: _filtros['estado'] as String?,
      fechaDesde: _filtros['fecha_desde'] as String?,
      fechaHasta: _filtros['fecha_hasta'] as String?,
      participanteId: _filtros['participante_id'] as int?,
      feriaId: _filtros['feria_id'] as int?,
      page: 1,
    );
  }

  Future<void> cargarMas() async {
    if (_isLoadingMore || !hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _facturaService.listar(
        estado: _filtros['estado'] as String?,
        fechaDesde: _filtros['fecha_desde'] as String?,
        fechaHasta: _filtros['fecha_hasta'] as String?,
        participanteId: _filtros['participante_id'] as int?,
        feriaId: _filtros['feria_id'] as int?,
        page: _currentPage + 1,
      );

      _facturas = List<Factura>.unmodifiable(<Factura>[
        ..._facturas,
        ...response.data,
      ]);
      _currentPage = response.currentPage;
      _totalPages = response.lastPage;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<Factura> obtener(int facturaId) async {
    _setLoading(true);

    try {
      final factura = await _facturaService.obtener(facturaId);
      _facturaActual = factura;
      _upsertFactura(factura);
      return factura;
    } finally {
      _setLoading(false);
    }
  }

  Future<Factura> crear(Map<String, dynamic> data) async {
    _setLoading(true);

    try {
      final factura = await _facturaService.crear(data);
      _facturaActual = factura;
      _upsertFactura(factura);
      return factura;
    } finally {
      _setLoading(false);
    }
  }

  Future<Factura> actualizar(int facturaId, Map<String, dynamic> data) async {
    _setLoading(true);

    try {
      final factura = await _facturaService.actualizar(facturaId, data);
      _facturaActual = factura;
      _upsertFactura(factura);
      return factura;
    } finally {
      _setLoading(false);
    }
  }

  Future<Factura> facturar(int facturaId) async {
    _setLoading(true);

    try {
      final factura = await _facturaService.facturar(facturaId);
      _facturaActual = factura;
      _upsertFactura(factura);
      return factura;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eliminar(int facturaId) async {
    _setLoading(true);

    try {
      await _facturaService.eliminar(facturaId);

      if (_facturaActual?.id == facturaId) {
        _facturaActual = null;
      }

      await recargar();
    } finally {
      _setLoading(false);
    }
  }

  void clear() {
    _facturas = const <Factura>[];
    _isLoading = false;
    _isLoadingMore = false;
    _currentPage = 1;
    _totalPages = 1;
    _filtros = const <String, dynamic>{};
    _facturaActual = null;
    notifyListeners();
  }

  void _upsertFactura(Factura factura) {
    final index = _facturas.indexWhere((item) => item.id == factura.id);

    if (index >= 0) {
      final updatedFacturas = List<Factura>.from(_facturas);
      updatedFacturas[index] = factura;
      _facturas = List<Factura>.unmodifiable(updatedFacturas);
    } else {
      _facturas = List<Factura>.unmodifiable(<Factura>[factura, ..._facturas]);
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
