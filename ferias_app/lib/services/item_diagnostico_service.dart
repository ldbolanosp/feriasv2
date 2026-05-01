import '../models/item_diagnostico.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

class ItemDiagnosticoService {
  ItemDiagnosticoService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResponse<ItemDiagnostico>> getItemsDiagnostico({
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/items-diagnostico',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'page': page,
        'per_page': perPage,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<ItemDiagnostico>.fromJson(
      response.data ?? <String, dynamic>{},
      ItemDiagnostico.fromJson,
    );
  }

  Future<ItemDiagnostico> createItemDiagnostico({
    required String nombre,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/items-diagnostico',
      data: <String, dynamic>{'nombre': nombre.trim()},
    );

    return _fromResource(response.data);
  }

  Future<ItemDiagnostico> updateItemDiagnostico({
    required int id,
    required String nombre,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/items-diagnostico/$id',
      data: <String, dynamic>{'nombre': nombre.trim()},
    );

    return _fromResource(response.data);
  }

  Future<void> deleteItemDiagnostico(int id) async {
    await _apiService.delete<Map<String, dynamic>>('/items-diagnostico/$id');
  }

  ItemDiagnostico _fromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return ItemDiagnostico.fromJson(Map<String, dynamic>.from(data));
    }

    return ItemDiagnostico.fromJson(payload ?? <String, dynamic>{});
  }
}
