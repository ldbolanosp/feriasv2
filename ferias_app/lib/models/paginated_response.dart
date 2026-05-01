import 'model_parsers.dart';

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    JsonFactory<T> fromJsonT,
  ) {
    final dataJson = json['data'];

    return PaginatedResponse<T>(
      data: dataJson is List
          ? dataJson
              .whereType<Map>()
              .map((item) => fromJsonT(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : <T>[],
      currentPage: parseInt(json['current_page'], fallback: 1),
      lastPage: parseInt(json['last_page'], fallback: 1),
      perPage: parseInt(json['per_page'], fallback: 15),
      total: parseInt(json['total']),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T item) toJsonT) {
    return <String, dynamic>{
      'data': data.map(toJsonT).toList(growable: false),
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }
}
