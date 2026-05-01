import '../models/factura.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

class FacturaService {
  FacturaService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResponse<Factura>> listar({
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    int? participanteId,
    int? feriaId,
    int page = 1,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/facturas',
      queryParameters: <String, dynamic>{
        'estado': estado?.trim().isEmpty == true ? null : estado?.trim(),
        'fecha_desde': fechaDesde?.trim().isEmpty == true
            ? null
            : fechaDesde?.trim(),
        'fecha_hasta': fechaHasta?.trim().isEmpty == true
            ? null
            : fechaHasta?.trim(),
        'participante_id': participanteId,
        'feria_id': feriaId,
        'page': page,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<Factura>.fromJson(
      response.data ?? <String, dynamic>{},
      Factura.fromJson,
    );
  }

  Future<Factura> obtener(int facturaId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/facturas/$facturaId',
    );

    return _facturaFromResource(response.data);
  }

  Future<Factura> crear(Map<String, dynamic> data) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/facturas',
      data: data,
    );

    return _facturaFromResource(response.data);
  }

  Future<Factura> actualizar(int facturaId, Map<String, dynamic> data) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/facturas/$facturaId',
      data: data,
    );

    return _facturaFromResource(response.data);
  }

  Future<Factura> facturar(int facturaId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/facturas/$facturaId/facturar',
    );

    return _facturaFromResource(response.data);
  }

  Future<void> eliminar(int facturaId) async {
    await _apiService.delete<void>('/facturas/$facturaId');
  }

  Factura _facturaFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Factura.fromJson(Map<String, dynamic>.from(data));
    }

    return Factura.fromJson(payload ?? <String, dynamic>{});
  }
}
