import 'package:dio/dio.dart';

import '../models/model_parsers.dart';
import '../models/paginated_response.dart';
import '../models/sanitario.dart';
import 'api_service.dart';

class SanitarioService {
  SanitarioService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<SanitarioListResponse> listar({
    String? estado,
    String? search,
    int page = 1,
    int perPage = 15,
    String? sort,
    String? direction,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/sanitarios',
      queryParameters: <String, dynamic>{
        'estado': estado?.trim().isEmpty == true ? null : estado?.trim(),
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'page': page,
        'per_page': perPage,
        'sort': sort?.trim().isEmpty == true ? null : sort?.trim(),
        'direction': direction?.trim().isEmpty == true
            ? null
            : direction?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    final payload = response.data ?? <String, dynamic>{};

    return SanitarioListResponse(
      pagination: PaginatedResponse<Sanitario>.fromJson(
        payload,
        Sanitario.fromJson,
      ),
      precioActual: parseDouble(payload['precio_actual']),
    );
  }

  Future<Sanitario> obtener(int sanitarioId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/sanitarios/$sanitarioId',
    );

    return _sanitarioFromResource(response.data);
  }

  Future<Sanitario> crear({
    int? participanteId,
    required int cantidad,
    String? observaciones,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/sanitarios',
      data: <String, dynamic>{
        'participante_id': participanteId,
        'cantidad': cantidad,
        'observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    return _sanitarioFromResource(response.data);
  }

  Future<Sanitario> cancelar(int sanitarioId, {String? observaciones}) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/sanitarios/$sanitarioId/cancelar',
      data: <String, dynamic>{
        'observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    return _sanitarioFromResource(response.data);
  }

  Future<List<int>> obtenerPdf(int sanitarioId) async {
    final response = await _apiService.get<List<int>>(
      '/sanitarios/$sanitarioId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data ?? const <int>[];
  }

  Sanitario _sanitarioFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Sanitario.fromJson(Map<String, dynamic>.from(data));
    }

    return Sanitario.fromJson(payload ?? <String, dynamic>{});
  }
}

class SanitarioListResponse {
  const SanitarioListResponse({
    required this.pagination,
    required this.precioActual,
  });

  final PaginatedResponse<Sanitario> pagination;
  final double precioActual;
}
