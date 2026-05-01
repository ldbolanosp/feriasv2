import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feria.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class FeriaProvider extends ChangeNotifier {
  FeriaProvider({
    AuthService? authService,
    ApiService? apiService,
  }) : _authService = authService ?? AuthService(),
       _apiService = apiService ?? ApiService();

  static const String _feriaIdKey = 'feria_activa_id';

  final AuthService _authService;
  final ApiService _apiService;

  Feria? _feriaActiva;
  List<Feria> _ferias = const <Feria>[];
  bool _isLoading = false;

  Feria? get feriaActiva => _feriaActiva;
  List<Feria> get ferias => _ferias;
  bool get isLoading => _isLoading;

  Future<void> loadFerias() async {
    _setLoading(true);

    try {
      _ferias = await _authService.getFerias();
      await restoreFeriaActiva();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restoreFeriaActiva() async {
    final preferences = await SharedPreferences.getInstance();
    final storedFeriaId = preferences.getInt(_feriaIdKey);

    if (storedFeriaId == null) {
      _feriaActiva = null;
      _apiService.setFeriaId(null);
      notifyListeners();
      return;
    }

    final feria = _ferias.where((item) => item.id == storedFeriaId).cast<Feria?>().firstWhere(
      (item) => item != null,
      orElse: () => null,
    );

    if (feria == null) {
      _feriaActiva = null;
      _apiService.setFeriaId(null);
      await preferences.remove(_feriaIdKey);
      notifyListeners();
      return;
    }

    _feriaActiva = feria;
    _apiService.setFeriaId(feria.id);
    notifyListeners();
  }

  Future<void> setFeriaActiva(Feria feria) async {
    _feriaActiva = await _authService.seleccionarFeria(feria.id);
    _apiService.setFeriaId(_feriaActiva!.id);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_feriaIdKey, _feriaActiva!.id);

    notifyListeners();
  }

  Future<void> clear() async {
    _feriaActiva = null;
    _ferias = const <Feria>[];
    _apiService.setFeriaId(null);

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_feriaIdKey);

    notifyListeners();
  }

  void setFerias(List<Feria> ferias) {
    _ferias = List<Feria>.unmodifiable(ferias);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
