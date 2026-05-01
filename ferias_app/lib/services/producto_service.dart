import '../models/paginated_response.dart';
import '../models/producto.dart';
import 'api_service.dart';

class ProductoService {
  ProductoService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResponse<Producto>> getProductos({
    String? search,
    bool? activo,
    int page = 1,
    int perPage = 15,
    String sort = 'codigo',
    String direction = 'asc',
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/productos',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'activo': activo,
        'page': page,
        'per_page': perPage,
        'sort': sort,
        'direction': direction,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<Producto>.fromJson(
      response.data ?? <String, dynamic>{},
      Producto.fromJson,
    );
  }

  Future<Producto> getProducto(int productoId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/productos/$productoId',
    );

    return _productoFromResource(response.data);
  }

  Future<Producto> createProducto({
    required String codigo,
    required String descripcion,
    bool activo = true,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/productos',
      data: <String, dynamic>{
        'codigo': codigo.trim(),
        'descripcion': descripcion.trim(),
        'activo': activo,
      },
    );

    return _productoFromResource(response.data);
  }

  Future<Producto> updateProducto({
    required int productoId,
    required String codigo,
    required String descripcion,
    required bool activo,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/productos/$productoId',
      data: <String, dynamic>{
        'codigo': codigo.trim(),
        'descripcion': descripcion.trim(),
        'activo': activo,
      },
    );

    return _productoFromResource(response.data);
  }

  Future<Producto> toggleProducto(int productoId) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/productos/$productoId/toggle',
    );
    final payload = response.data ?? <String, dynamic>{};

    return Producto.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }

  Future<Producto> assignPrecios({
    required int productoId,
    required List<Map<String, dynamic>> precios,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/productos/$productoId/precios',
      data: <String, dynamic>{'precios': precios},
    );
    final payload = response.data ?? <String, dynamic>{};

    return Producto.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }

  Future<Producto> removePrecio({
    required int productoId,
    required int feriaId,
  }) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '/productos/$productoId/precios/$feriaId',
    );
    final payload = response.data ?? <String, dynamic>{};

    return Producto.fromJson(Map<String, dynamic>.from(payload['data'] as Map));
  }

  Future<List<Producto>> getProductosPorFeria({String? search}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/productos/por-feria',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    final payload = response.data ?? <String, dynamic>{};
    final data = payload['data'];

    if (data is! List) {
      return <Producto>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Producto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Producto _productoFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Producto.fromJson(Map<String, dynamic>.from(data));
    }

    return Producto.fromJson(payload ?? <String, dynamic>{});
  }
}
