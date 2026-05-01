import '../models/feria.dart';
import '../models/paginated_response.dart';
import '../models/participante.dart';
import 'api_service.dart';

class ParticipanteService {
  ParticipanteService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PaginatedResponse<Participante>> getParticipantes({
    String? search,
    bool? activo,
    String? tipoIdentificacion,
    int? feriaId,
    int page = 1,
    int perPage = 15,
    String sort = 'nombre',
    String direction = 'asc',
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/participantes',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'activo': activo,
        'tipo_identificacion': tipoIdentificacion,
        'feria_id': feriaId,
        'page': page,
        'per_page': perPage,
        'sort': sort,
        'direction': direction,
      }..removeWhere((key, value) => value == null),
    );

    return PaginatedResponse<Participante>.fromJson(
      response.data ?? <String, dynamic>{},
      Participante.fromJson,
    );
  }

  Future<Participante> getParticipante(int participanteId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/participantes/$participanteId',
    );

    return _participantFromResource(response.data);
  }

  Future<Participante> createParticipante({
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/participantes',
      data: data,
    );

    return _participantFromResource(response.data);
  }

  Future<Participante> updateParticipante({
    required int participanteId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/participantes/$participanteId',
      data: data,
    );

    return _participantFromResource(response.data);
  }

  Future<Participante> updateParticipanteCarne({
    required int participanteId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/participantes/$participanteId/carne',
      data: data,
    );

    return _participantFromResource(response.data);
  }

  Future<Participante> toggleParticipante(int participanteId) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/participantes/$participanteId/toggle',
    );
    final payload = response.data ?? <String, dynamic>{};

    return Participante.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<List<Feria>> getParticipanteFerias(int participanteId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/participantes/$participanteId/ferias',
    );

    final payload = response.data ?? <String, dynamic>{};
    final data = payload['data'];

    if (data is! List) {
      return <Feria>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Feria.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<Participante> assignFerias({
    required int participanteId,
    required List<int> feriaIds,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/participantes/$participanteId/ferias',
      data: <String, dynamic>{'ferias': feriaIds},
    );
    final payload = response.data ?? <String, dynamic>{};

    return Participante.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<Participante> removeFeria({
    required int participanteId,
    required int feriaId,
  }) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '/participantes/$participanteId/ferias/$feriaId',
    );
    final payload = response.data ?? <String, dynamic>{};

    return Participante.fromJson(
      Map<String, dynamic>.from(payload['data'] as Map),
    );
  }

  Future<List<Participante>> getParticipantesPorFeria({String? search}) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/participantes/por-feria',
      queryParameters: <String, dynamic>{
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
      }..removeWhere((key, value) => value == null),
    );

    final payload = response.data ?? <String, dynamic>{};
    final data = payload['data'];

    if (data is! List) {
      return <Participante>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Participante.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Participante _participantFromResource(Map<String, dynamic>? payload) {
    final data = payload?['data'];

    if (data is Map) {
      return Participante.fromJson(Map<String, dynamic>.from(data));
    }

    return Participante.fromJson(payload ?? <String, dynamic>{});
  }
}
