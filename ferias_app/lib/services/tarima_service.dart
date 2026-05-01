import 'package:dio/dio.dart';

import '../models/model_parsers.dart';
import '../models/paginated_response.dart';
import '../models/tarima.dart';
import 'api_service.dart';

class TarimaService {
  TarimaService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<TarimaListResponse> listar({
    String? estado,
    String? search,
    int page = 1,
    int perPage = 15,
    String? sort,
    String? direction,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/tarimas',
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

    return TarimaListResponse(
      pagination: PaginatedResponse<Tarima>.fromJson(payload, Tarima.fromJson),
      precioActual: parseDouble(payload['precio_actual']),
    );
  }

  Future<Tarima> obtener(int tarimaId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/tarimas/$tarimaId',
    );

    return _tarimaFromResource(response.data);
  }

  Future<Tarima> crear({
    required int participanteId,
    String? numeroTarima,
    required int cantidad,
    String? observaciones,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/tarimas',
      data: <String, dynamic>{
        'participante_id': participanteId,
        'numero_tarima': numeroTarima?.trim().isEmpty == true
            ? null
            : numeroTarima?.trim(),
        'cantidad': cantidad,
        'observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    return _tarimaFromResource(response.data);
  }

  Future<Tarima> cancelar(int tarimaId, {String? observaciones}) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/tarimas/$tarimaId/cancelar',
      data: <String, dynamic>{
        'observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    return _tarimaFromResource(response.data);
  }

  Future<List<int>> obtenerPdf(int tarimaId) async {
    final response = await _apiService.get<List<int>>(
      '/tarimas/$tarimaId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data ?? const <int>[];
  }

  Tarima _tarimaFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Tarima.fromJson(Map<String, dynamic>.from(data));
    }

    return Tarima.fromJson(payload ?? <String, dynamic>{});
  }
}

class TarimaListResponse {
  const TarimaListResponse({
    required this.pagination,
    required this.precioActual,
  });

  final PaginatedResponse<Tarima> pagination;
  final double precioActual;
}
