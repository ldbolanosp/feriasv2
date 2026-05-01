import '../models/paginated_response.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserSessionInfo {
  const UserSessionInfo({
    required this.id,
    required this.ipAddress,
    required this.userAgent,
    required this.browser,
    required this.platform,
    required this.device,
    required this.lastActivity,
    required this.isCurrent,
  });

  final String id;
  final String? ipAddress;
  final String? userAgent;
  final String browser;
  final String platform;
  final String device;
  final DateTime? lastActivity;
  final bool isCurrent;

  factory UserSessionInfo.fromJson(Map<String, dynamic> json) {
    return UserSessionInfo(
      id: (json['id'] ?? '').toString(),
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      browser: (json['browser'] ?? 'Desconocido').toString(),
      platform: (json['platform'] ?? 'Desconocido').toString(),
      device: (json['device'] ?? 'Desconocido').toString(),
      lastActivity: json['last_activity'] == null
          ? null
          : DateTime.tryParse(json['last_activity'].toString()),
      isCurrent: json['is_current'] == true,
    );
  }
}

class UsuarioService {
  UsuarioService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResponse<User>> getUsuarios({
    String? search,
    bool? activo,
    String? role,
    int page = 1,
    int perPage = 15,
    String sort = 'name',
    String direction = 'asc',
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/usuarios',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'activo': activo,
        'role': role?.trim().isEmpty == true ? null : role?.trim(),
        'page': page,
        'per_page': perPage,
        'sort': sort,
        'direction': direction,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<User>.fromJson(
      response.data ?? <String, dynamic>{},
      User.fromJson,
    );
  }

  Future<User> getUsuario(int userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/usuarios/$userId',
    );

    return _userFromResource(response.data);
  }

  Future<User> createUsuario({required Map<String, dynamic> data}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/usuarios',
      data: data,
    );

    return _userFromResource(response.data);
  }

  Future<User> updateUsuario({
    required int userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/usuarios/$userId',
      data: data,
    );

    return _userFromResource(response.data);
  }

  Future<User> toggleUsuario(int userId) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/usuarios/$userId/toggle',
    );
    final payload = response.data ?? <String, dynamic>{};

    return User.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }

  Future<void> deleteUsuario(int userId) async {
    await _apiService.delete<void>('/usuarios/$userId');
  }

  Future<void> resetPassword({
    required int userId,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiService.patch<void>(
      '/usuarios/$userId/reset-password',
      data: <String, dynamic>{
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<User> assignRole({required int userId, required String role}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/usuarios/$userId/roles',
      data: <String, dynamic>{'role': role},
    );
    final payload = response.data ?? <String, dynamic>{};

    return User.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }

  Future<User> assignFerias({
    required int userId,
    required List<int> feriaIds,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/usuarios/$userId/ferias',
      data: <String, dynamic>{'ferias': feriaIds},
    );
    final payload = response.data ?? <String, dynamic>{};

    return User.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }

  Future<List<UserSessionInfo>> getSesiones(int userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/usuarios/$userId/sesiones',
    );
    final payload = response.data ?? <String, dynamic>{};
    final data = payload['data'];

    if (data is! List) {
      return <UserSessionInfo>[];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => UserSessionInfo.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> cerrarSesion({
    required int userId,
    required String sessionId,
  }) async {
    await _apiService.delete<void>('/usuarios/$userId/sesiones/$sessionId');
  }

  User _userFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return User.fromJson(Map<String, dynamic>.from(data));
    }

    return User.fromJson(payload ?? <String, dynamic>{});
  }
}
