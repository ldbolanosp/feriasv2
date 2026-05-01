import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    ApiService? apiService,
  }) : _authService = authService ?? AuthService(),
       _apiService = apiService ?? ApiService() {
    _apiService.setUnauthorizedHandler(_handleUnauthorized);
  }

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final AuthService _authService;
  final ApiService _apiService;

  User? _user;
  String? _token;
  bool _isLoading = true;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _user != null;

  Future<void> login({
    required String email,
    required String password,
    String deviceName = 'ferias-app-android',
  }) async {
    _setLoading(true);

    try {
      final result = await _authService.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );

      _token = result.token;
      _user = result.user;
      _apiService.setToken(_token);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, result.token);
      await preferences.setString(_userKey, _encodeUser(result.user));

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final hadToken = _token != null && _token!.isNotEmpty;

    try {
      if (hadToken) {
        await _authService.logout();
      }
    } catch (_) {
    } finally {
      await _clearSession();
    }
  }

  Future<void> checkAuth() async {
    _setLoading(true);

    try {
      final preferences = await SharedPreferences.getInstance();
      final storedToken = preferences.getString(_tokenKey);

      if (storedToken == null || storedToken.isEmpty) {
        await _clearSession(notify: false);
        return;
      }

      _token = storedToken;
      _apiService.setToken(storedToken);

      final user = await _authService.getUser();
      _user = user;
      await preferences.setString(_userKey, _encodeUser(user));
      notifyListeners();
    } catch (_) {
      await _clearSession();
    } finally {
      _setLoading(false);
    }
  }

  bool hasPermission(String permiso) {
    final permisos = _user?.permisos ?? const <String>[];

    return permisos.contains(permiso);
  }

  Future<void> _handleUnauthorized() async {
    await _clearSession();
  }

  Future<void> _clearSession({bool notify = true}) async {
    _user = null;
    _token = null;
    _apiService.clearAuth();

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_userKey);

    if (notify) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _encodeUser(User user) {
    return jsonEncode(user.toJson());
  }
}
