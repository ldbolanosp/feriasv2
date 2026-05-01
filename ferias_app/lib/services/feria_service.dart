import '../models/feria.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

class FeriaService {
  FeriaService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResponse<Feria>> getFerias({
    String? search,
    bool? activa,
    int page = 1,
    int perPage = 15,
    String sort = 'id',
    String direction = 'asc',
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/ferias',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'activa': activa,
        'page': page,
        'per_page': perPage,
        'sort': sort,
        'direction': direction,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<Feria>.fromJson(
      response.data ?? <String, dynamic>{},
      Feria.fromJson,
    );
  }

  Future<Feria> getFeria(int feriaId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/ferias/$feriaId',
    );

    return _feriaFromResource(response.data);
  }

  Future<Feria> createFeria({
    required String codigo,
    required String descripcion,
    required bool facturacionPublico,
    bool activa = true,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/ferias',
      data: <String, dynamic>{
        'codigo': codigo.trim(),
        'descripcion': descripcion.trim(),
        'facturacion_publico': facturacionPublico,
        'activa': activa,
      },
    );

    return _feriaFromResource(response.data);
  }

  Future<Feria> updateFeria({
    required int feriaId,
    required String codigo,
    required String descripcion,
    required bool facturacionPublico,
    required bool activa,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/ferias/$feriaId',
      data: <String, dynamic>{
        'codigo': codigo.trim(),
        'descripcion': descripcion.trim(),
        'facturacion_publico': facturacionPublico,
        'activa': activa,
      },
    );

    return _feriaFromResource(response.data);
  }

  Future<Feria> toggleFeria(int feriaId) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/ferias/$feriaId/toggle',
    );
    final payload = response.data ?? <String, dynamic>{};

    return Feria.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }

  Feria _feriaFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Feria.fromJson(Map<String, dynamic>.from(data));
    }

    return Feria.fromJson(payload ?? <String, dynamic>{});
  }
}
