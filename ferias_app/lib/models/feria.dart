import 'model_parsers.dart';

class Feria {
  final int id;
  final String codigo;
  final String descripcion;
  final bool facturacionPublico;
  final bool activa;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Feria({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.facturacionPublico,
    required this.activa,
    this.createdAt,
    this.updatedAt,
  });

  factory Feria.fromJson(Map<String, dynamic> json) {
    return Feria(
      id: parseInt(json['id']),
      codigo: parseString(json['codigo']) ?? '',
      descripcion: parseString(json['descripcion']) ?? '',
      facturacionPublico: parseBool(json['facturacion_publico']),
      activa: parseBool(json['activa'], fallback: true),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'descripcion': descripcion,
      'facturacion_publico': facturacionPublico,
      'activa': activa,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
