import 'model_parsers.dart';

class Inspeccion {
  const Inspeccion({
    required this.id,
    required this.feriaId,
    required this.participanteId,
    required this.totalItems,
    required this.totalIncumplidos,
    required this.esReinspeccion,
    this.reinspeccionDeId,
    this.participante,
    this.inspector,
    this.reinspeccionDe,
    this.items = const <InspeccionItem>[],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int feriaId;
  final int participanteId;
  final int totalItems;
  final int totalIncumplidos;
  final bool esReinspeccion;
  final int? reinspeccionDeId;
  final InspeccionParticipanteResumen? participante;
  final InspeccionInspectorResumen? inspector;
  final InspeccionBaseResumen? reinspeccionDe;
  final List<InspeccionItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Inspeccion.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];

    return Inspeccion(
      id: parseInt(json['id']),
      feriaId: parseInt(json['feria_id']),
      participanteId: parseInt(json['participante_id']),
      totalItems: parseInt(json['total_items']),
      totalIncumplidos: parseInt(json['total_incumplidos']),
      esReinspeccion: parseBool(json['es_reinspeccion']),
      reinspeccionDeId: parseInt(json['reinspeccion_de_id'], fallback: 0) == 0
          ? null
          : parseInt(json['reinspeccion_de_id']),
      participante: json['participante'] is Map<String, dynamic>
          ? InspeccionParticipanteResumen.fromJson(
              Map<String, dynamic>.from(json['participante'] as Map),
            )
          : null,
      inspector: json['inspector'] is Map<String, dynamic>
          ? InspeccionInspectorResumen.fromJson(
              Map<String, dynamic>.from(json['inspector'] as Map),
            )
          : null,
      reinspeccionDe: json['reinspeccion_de'] is Map<String, dynamic>
          ? InspeccionBaseResumen.fromJson(
              Map<String, dynamic>.from(json['reinspeccion_de'] as Map),
            )
          : null,
      items: itemsJson is List
          ? itemsJson
              .whereType<Map>()
              .map(
                (item) => InspeccionItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <InspeccionItem>[],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'feria_id': feriaId,
      'participante_id': participanteId,
      'reinspeccion_de_id': reinspeccionDeId,
      'total_items': totalItems,
      'total_incumplidos': totalIncumplidos,
      'es_reinspeccion': esReinspeccion,
      'participante': participante?.toJson(),
      'inspector': inspector?.toJson(),
      'reinspeccion_de': reinspeccionDe?.toJson(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class InspeccionParticipanteResumen {
  const InspeccionParticipanteResumen({
    required this.id,
    required this.nombre,
    required this.numeroIdentificacion,
    this.numeroCarne,
    this.fechaVencimientoCarne,
  });

  final int id;
  final String nombre;
  final String numeroIdentificacion;
  final String? numeroCarne;
  final DateTime? fechaVencimientoCarne;

  factory InspeccionParticipanteResumen.fromJson(Map<String, dynamic> json) {
    return InspeccionParticipanteResumen(
      id: parseInt(json['id']),
      nombre: parseString(json['nombre']) ?? '',
      numeroIdentificacion: parseString(json['numero_identificacion']) ?? '',
      numeroCarne: parseString(json['numero_carne']),
      fechaVencimientoCarne: parseDateTime(json['fecha_vencimiento_carne']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'numero_identificacion': numeroIdentificacion,
      'numero_carne': numeroCarne,
      'fecha_vencimiento_carne': fechaVencimientoCarne?.toIso8601String(),
    };
  }
}

class InspeccionInspectorResumen {
  const InspeccionInspectorResumen({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory InspeccionInspectorResumen.fromJson(Map<String, dynamic> json) {
    return InspeccionInspectorResumen(
      id: parseInt(json['id']),
      name: parseString(json['name']) ?? '',
      email: parseString(json['email']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'email': email};
  }
}

class InspeccionBaseResumen {
  const InspeccionBaseResumen({
    required this.id,
    required this.totalIncumplidos,
    this.createdAt,
  });

  final int id;
  final int totalIncumplidos;
  final DateTime? createdAt;

  factory InspeccionBaseResumen.fromJson(Map<String, dynamic> json) {
    return InspeccionBaseResumen(
      id: parseInt(json['id']),
      totalIncumplidos: parseInt(json['total_incumplidos']),
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'total_incumplidos': totalIncumplidos,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class InspeccionItem {
  const InspeccionItem({
    required this.id,
    required this.nombreItem,
    required this.cumple,
    required this.orden,
    this.itemDiagnosticoId,
    this.observaciones,
  });

  final int id;
  final int? itemDiagnosticoId;
  final String nombreItem;
  final bool cumple;
  final int orden;
  final String? observaciones;

  factory InspeccionItem.fromJson(Map<String, dynamic> json) {
    final rawItemDiagnosticoId = parseInt(
      json['item_diagnostico_id'],
      fallback: 0,
    );

    return InspeccionItem(
      id: parseInt(json['id']),
      itemDiagnosticoId: rawItemDiagnosticoId == 0 ? null : rawItemDiagnosticoId,
      nombreItem: parseString(json['nombre_item']) ?? '',
      cumple: parseBool(json['cumple']),
      orden: parseInt(json['orden'], fallback: 1),
      observaciones: parseString(json['observaciones']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'item_diagnostico_id': itemDiagnosticoId,
      'nombre_item': nombreItem,
      'cumple': cumple,
      'orden': orden,
      'observaciones': observaciones,
    };
  }
}
