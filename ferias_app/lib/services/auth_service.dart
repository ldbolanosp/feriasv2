import '../models/feria.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthLoginResult {
  const AuthLoginResult({
    required this.user,
    required this.token,
    required this.roles,
    required this.permisos,
    required this.ferias,
    this.tokenType,
  });

  final User user;
  final String token;
  final String? tokenType;
  final List<String> roles;
  final List<String> permisos;
  final List<Feria> ferias;
}

class AuthService {
  AuthService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AuthLoginResult> login({
    required String email,
    required String password,
    String deviceName = 'ferias-app-android',
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );

    final payload = response.data ?? <String, dynamic>{};
    final roles = _parseStringList(payload['roles']);
    final permisos = _parseStringList(payload['permisos']);
    final ferias = _parseFerias(payload['ferias']);
    final userPayload = Map<String, dynamic>.from(payload['user'] as Map);

    final user = User.fromJson(<String, dynamic>{
      ...userPayload,
      'roles': roles,
      'permisos': permisos,
      'ferias': ferias.map((item) => item.toJson()).toList(growable: false),
      'role': roles.isEmpty ? null : roles.first,
      'ferias_count': ferias.length,
    });

    return AuthLoginResult(
      user: user,
      token: (payload['token'] ?? '').toString(),
      tokenType: payload['token_type']?.toString(),
      roles: roles,
      permisos: permisos,
      ferias: ferias,
    );
  }

  Future<void> logout() async {
    await _apiService.post<void>('/auth/logout');
  }

  Future<User> getUser() async {
    final response = await _apiService.get<Map<String, dynamic>>('/auth/user');
    final payload = response.data ?? <String, dynamic>{};
    final roles = _parseStringList(payload['roles']);
    final permisos = _parseStringList(payload['permisos']);
    final ferias = _parseFerias(payload['ferias']);
    final userPayload = Map<String, dynamic>.from(payload['user'] as Map);

    return User.fromJson(<String, dynamic>{
      ...userPayload,
      'roles': roles,
      'permisos': permisos,
      'ferias': ferias.map((item) => item.toJson()).toList(growable: false),
      'role': roles.isEmpty ? null : roles.first,
      'ferias_count': ferias.length,
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _apiService.put<void>(
      '/auth/password',
      data: <String, dynamic>{
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      },
    );
  }

  Future<List<Feria>> getFerias() async {
    final response = await _apiService.get<Map<String, dynamic>>('/auth/mis-ferias');
    final payload = response.data ?? <String, dynamic>{};

    return _parseFerias(payload['data']);
  }

  Future<Feria> seleccionarFeria(int feriaId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/seleccionar-feria',
      data: <String, dynamic>{'feria_id': feriaId},
    );
    final payload = response.data ?? <String, dynamic>{};

    return Feria.fromJson(Map<String, dynamic>.from(payload['feria'] as Map));
  }

  List<Feria> _parseFerias(dynamic value) {
    if (value is! List) {
      return const <Feria>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Feria.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value.map((item) => item.toString()).toList(growable: false);
  }
}
