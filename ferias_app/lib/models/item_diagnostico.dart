import 'model_parsers.dart';

class ItemDiagnostico {
  const ItemDiagnostico({
    required this.id,
    required this.nombre,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String nombre;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ItemDiagnostico.fromJson(Map<String, dynamic> json) {
    return ItemDiagnostico(
      id: parseInt(json['id']),
      nombre: parseString(json['nombre']) ?? '',
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
