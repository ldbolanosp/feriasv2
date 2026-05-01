import 'package:dio/dio.dart';

import '../models/paginated_response.dart';
import '../models/parqueo.dart';
import '../models/model_parsers.dart';
import 'api_service.dart';

class ParqueoService {
  ParqueoService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<ParqueoListResponse> listar({
    String? estado,
    String? placa,
    String? fecha,
    int page = 1,
    int perPage = 15,
    String? sort,
    String? direction,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/parqueos',
      queryParameters: <String, dynamic>{
        'estado': estado?.trim().isEmpty == true ? null : estado?.trim(),
        'placa': placa?.trim().isEmpty == true
            ? null
            : placa?.trim().toUpperCase(),
        'fecha': fecha?.trim().isEmpty == true ? null : fecha?.trim(),
        'page': page,
        'per_page': perPage,
        'sort': sort?.trim().isEmpty == true ? null : sort?.trim(),
        'direction': direction?.trim().isEmpty == true
            ? null
            : direction?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    final payload = response.data ?? <String, dynamic>{};

    return ParqueoListResponse(
      pagination: PaginatedResponse<Parqueo>.fromJson(
        payload,
        Parqueo.fromJson,
      ),
      tarifaActual: parseDouble(payload['tarifa_actual']),
    );
  }

  Future<Parqueo> obtener(int parqueoId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/parqueos/$parqueoId',
    );

    return _parqueoFromResource(response.data);
  }

  Future<Parqueo> crear({required String placa, String? observaciones}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/parqueos',
      data: <String, dynamic>{
        'placa': placa.trim().toUpperCase(),
        'observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    return _parqueoFromResource(response.data);
  }

  Future<Parqueo> registrarSalida(
    int parqueoId, {
    String? observaciones,
  }) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/parqueos/$parqueoId/salida',
      data: <String, dynamic>{
        'observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    return _parqueoFromResource(response.data);
  }

  Future<Parqueo> cancelar(int parqueoId, {String? observaciones}) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/parqueos/$parqueoId/cancelar',
      data: <String, dynamic>{
        'observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    return _parqueoFromResource(response.data);
  }

  Future<List<int>> obtenerPdf(int parqueoId) async {
    final response = await _apiService.get<List<int>>(
      '/parqueos/$parqueoId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data ?? const <int>[];
  }

  Parqueo _parqueoFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Parqueo.fromJson(Map<String, dynamic>.from(data));
    }

    return Parqueo.fromJson(payload ?? <String, dynamic>{});
  }
}

class ParqueoListResponse {
  const ParqueoListResponse({
    required this.pagination,
    required this.tarifaActual,
  });

  final PaginatedResponse<Parqueo> pagination;
  final double tarifaActual;
}
