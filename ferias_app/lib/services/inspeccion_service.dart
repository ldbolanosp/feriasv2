import '../models/inspeccion.dart';
import '../models/paginated_response.dart';
import '../models/participante.dart';
import 'api_service.dart';

class InspeccionService {
  InspeccionService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResponse<Inspeccion>> getInspecciones({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/inspecciones',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'page': page,
        'per_page': perPage,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<Inspeccion>.fromJson(
      response.data ?? <String, dynamic>{},
      Inspeccion.fromJson,
    );
  }

  Future<PaginatedResponse<Inspeccion>> getReinspecciones({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/inspecciones/reinspecciones',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'page': page,
        'per_page': perPage,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<Inspeccion>.fromJson(
      response.data ?? <String, dynamic>{},
      Inspeccion.fromJson,
    );
  }

  Future<PaginatedResponse<Participante>> getVencimientosCarne({
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/inspecciones/vencimientos-carne',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'page': page,
        'per_page': perPage,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<Participante>.fromJson(
      response.data ?? <String, dynamic>{},
      Participante.fromJson,
    );
  }

  Future<Inspeccion> createInspeccion({
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/inspecciones',
      data: data,
    );

    return _fromResource(response.data);
  }

  Inspeccion _fromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Inspeccion.fromJson(Map<String, dynamic>.from(data));
    }

    return Inspeccion.fromJson(payload ?? <String, dynamic>{});
  }
}
