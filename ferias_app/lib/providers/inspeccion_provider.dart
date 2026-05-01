import 'package:flutter/foundation.dart';

import '../models/inspeccion.dart';
import '../models/participante.dart';
import '../services/inspeccion_service.dart';

class InspeccionProvider extends ChangeNotifier {
  InspeccionProvider({InspeccionService? inspeccionService})
    : _inspeccionService = inspeccionService ?? InspeccionService();

  final InspeccionService _inspeccionService;

  List<Inspeccion> _inspecciones = const <Inspeccion>[];
  List<Inspeccion> _reinspecciones = const <Inspeccion>[];
  List<Participante> _vencimientosCarne = const <Participante>[];
  bool _isLoadingInspecciones = false;
  bool _isLoadingReinspecciones = false;
  bool _isLoadingVencimientos = false;
  bool _isLoadingMoreInspecciones = false;
  bool _isLoadingMoreReinspecciones = false;
  bool _isLoadingMoreVencimientos = false;
  bool _isSubmitting = false;
  int _inspeccionesPage = 1;
  int _inspeccionesTotalPages = 1;
  int _reinspeccionesPage = 1;
  int _reinspeccionesTotalPages = 1;
  int _vencimientosPage = 1;
  int _vencimientosTotalPages = 1;
  String _inspeccionesSearch = '';
  String _reinspeccionesSearch = '';
  String _vencimientosSearch = '';

  List<Inspeccion> get inspecciones => _inspecciones;
  List<Inspeccion> get reinspecciones => _reinspecciones;
  List<Participante> get vencimientosCarne => _vencimientosCarne;
  bool get isLoadingInspecciones => _isLoadingInspecciones;
  bool get isLoadingReinspecciones => _isLoadingReinspecciones;
  bool get isLoadingVencimientos => _isLoadingVencimientos;
  bool get isLoadingMoreInspecciones => _isLoadingMoreInspecciones;
  bool get isLoadingMoreReinspecciones => _isLoadingMoreReinspecciones;
  bool get isLoadingMoreVencimientos => _isLoadingMoreVencimientos;
  bool get isSubmitting => _isSubmitting;
  int get inspeccionesPage => _inspeccionesPage;
  int get reinspeccionesPage => _reinspeccionesPage;
  int get vencimientosPage => _vencimientosPage;
  bool get canLoadMoreInspecciones =>
      _inspeccionesPage < _inspeccionesTotalPages;
  bool get canLoadMoreReinspecciones =>
      _reinspeccionesPage < _reinspeccionesTotalPages;
  bool get canLoadMoreVencimientos =>
      _vencimientosPage < _vencimientosTotalPages;
  String get inspeccionesSearch => _inspeccionesSearch;
  String get reinspeccionesSearch => _reinspeccionesSearch;
  String get vencimientosSearch => _vencimientosSearch;

  Future<void> loadInspecciones({
    String? search,
    bool reset = false,
    bool append = false,
  }) async {
    if (append) {
      if (_isLoadingMoreInspecciones || !canLoadMoreInspecciones) {
        return;
      }

      _isLoadingMoreInspecciones = true;
    } else {
      _isLoadingInspecciones = true;
    }

    if (search != null) {
      _inspeccionesSearch = search.trim();
    }

    notifyListeners();

    try {
      final response = await _inspeccionService.getInspecciones(
        search: _inspeccionesSearch.isEmpty ? null : _inspeccionesSearch,
        page: append ? _inspeccionesPage + 1 : 1,
      );

      _inspecciones = append
          ? List<Inspeccion>.unmodifiable(<Inspeccion>[
              ..._inspecciones,
              ...response.data,
            ])
          : response.data;
      _inspeccionesPage = response.currentPage;
      _inspeccionesTotalPages = response.lastPage;
    } finally {
      _isLoadingInspecciones = false;
      _isLoadingMoreInspecciones = false;
      notifyListeners();
    }
  }

  Future<void> loadReinspecciones({
    String? search,
    bool reset = false,
    bool append = false,
  }) async {
    if (append) {
      if (_isLoadingMoreReinspecciones || !canLoadMoreReinspecciones) {
        return;
      }

      _isLoadingMoreReinspecciones = true;
    } else {
      _isLoadingReinspecciones = true;
    }

    if (search != null) {
      _reinspeccionesSearch = search.trim();
    }

    notifyListeners();

    try {
      final response = await _inspeccionService.getReinspecciones(
        search: _reinspeccionesSearch.isEmpty ? null : _reinspeccionesSearch,
        page: append ? _reinspeccionesPage + 1 : 1,
      );

      _reinspecciones = append
          ? List<Inspeccion>.unmodifiable(<Inspeccion>[
              ..._reinspecciones,
              ...response.data,
            ])
          : response.data;
      _reinspeccionesPage = response.currentPage;
      _reinspeccionesTotalPages = response.lastPage;
    } finally {
      _isLoadingReinspecciones = false;
      _isLoadingMoreReinspecciones = false;
      notifyListeners();
    }
  }

  Future<void> loadVencimientosCarne({
    String? search,
    bool reset = false,
    bool append = false,
  }) async {
    if (append) {
      if (_isLoadingMoreVencimientos || !canLoadMoreVencimientos) {
        return;
      }

      _isLoadingMoreVencimientos = true;
    } else {
      _isLoadingVencimientos = true;
    }

    if (search != null) {
      _vencimientosSearch = search.trim();
    }

    notifyListeners();

    try {
      final response = await _inspeccionService.getVencimientosCarne(
        search: _vencimientosSearch.isEmpty ? null : _vencimientosSearch,
        page: append ? _vencimientosPage + 1 : 1,
      );

      _vencimientosCarne = append
          ? List<Participante>.unmodifiable(<Participante>[
              ..._vencimientosCarne,
              ...response.data,
            ])
          : response.data;
      _vencimientosPage = response.currentPage;
      _vencimientosTotalPages = response.lastPage;
    } finally {
      _isLoadingVencimientos = false;
      _isLoadingMoreVencimientos = false;
      notifyListeners();
    }
  }

  Future<Inspeccion> createInspeccion({
    required Map<String, dynamic> data,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final inspeccion = await _inspeccionService.createInspeccion(data: data);
      _inspecciones = List<Inspeccion>.unmodifiable(<Inspeccion>[
        inspeccion,
        ..._inspecciones,
      ]);
      return inspeccion;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clear() {
    _inspecciones = const <Inspeccion>[];
    _reinspecciones = const <Inspeccion>[];
    _vencimientosCarne = const <Participante>[];
    _isLoadingInspecciones = false;
    _isLoadingReinspecciones = false;
    _isLoadingVencimientos = false;
    _isLoadingMoreInspecciones = false;
    _isLoadingMoreReinspecciones = false;
    _isLoadingMoreVencimientos = false;
    _isSubmitting = false;
    _inspeccionesPage = 1;
    _inspeccionesTotalPages = 1;
    _reinspeccionesPage = 1;
    _reinspeccionesTotalPages = 1;
    _vencimientosPage = 1;
    _vencimientosTotalPages = 1;
    _inspeccionesSearch = '';
    _reinspeccionesSearch = '';
    _vencimientosSearch = '';
    notifyListeners();
  }

  void replaceParticipante(Participante participante) {
    _vencimientosCarne = _vencimientosCarne
        .map((item) => item.id == participante.id ? participante : item)
        .toList(growable: false);
    notifyListeners();
  }
}
