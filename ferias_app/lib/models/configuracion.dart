import 'model_parsers.dart';

class Configuracion {
  final int? id;
  final int? feriaId;
  final String clave;
  final String valor;
  final String? descripcion;
  final String? scope;
  final String? globalValor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Configuracion({
    this.id,
    this.feriaId,
    required this.clave,
    required this.valor,
    this.descripcion,
    this.scope,
    this.globalValor,
    this.createdAt,
    this.updatedAt,
  });

  factory Configuracion.fromJson(Map<String, dynamic> json) {
    return Configuracion(
      id: json['id'] == null ? null : parseInt(json['id']),
      feriaId: json['feria_id'] == null ? null : parseInt(json['feria_id']),
      clave: parseString(json['clave']) ?? '',
      valor: parseString(json['valor']) ?? '',
      descripcion: parseString(json['descripcion']),
      scope: parseString(json['scope']),
      globalValor: parseString(json['global_valor']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'feria_id': feriaId,
      'clave': clave,
      'valor': valor,
      'descripcion': descripcion,
      'scope': scope,
      'global_valor': globalValor,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
