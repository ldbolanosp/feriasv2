import 'feria.dart';
import 'model_parsers.dart';
import 'participante.dart';
import 'user.dart';

class Sanitario {
  final int id;
  final int feriaId;
  final int userId;
  final int? participanteId;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final String estado;
  final String? estadoLabel;
  final String? observaciones;
  final String? pdfPath;
  final bool esPublico;
  final Participante? participante;
  final Feria? feria;
  final User? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Sanitario({
    required this.id,
    required this.feriaId,
    required this.userId,
    this.participanteId,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.estado,
    this.estadoLabel,
    this.observaciones,
    this.pdfPath,
    required this.esPublico,
    this.participante,
    this.feria,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory Sanitario.fromJson(Map<String, dynamic> json) {
    return Sanitario(
      id: parseInt(json['id']),
      feriaId: parseInt(json['feria_id']),
      userId: parseInt(json['user_id']),
      participanteId: json['participante_id'] == null
          ? null
          : parseInt(json['participante_id']),
      cantidad: parseInt(json['cantidad'], fallback: 1),
      precioUnitario: parseDouble(json['precio_unitario']),
      total: parseDouble(json['total']),
      estado: parseString(json['estado']) ?? '',
      estadoLabel: parseString(json['estado_label']),
      observaciones: parseString(json['observaciones']),
      pdfPath: parseString(json['pdf_path']),
      esPublico: parseBool(
        json['es_publico'],
        fallback: json['participante_id'] == null,
      ),
      participante: json['participante'] is Map<String, dynamic>
          ? Participante.fromJson(json['participante'] as Map<String, dynamic>)
          : json['participante'] is Map
          ? Participante.fromJson(
              Map<String, dynamic>.from(json['participante'] as Map),
            )
          : null,
      feria: json['feria'] is Map<String, dynamic>
          ? Feria.fromJson(json['feria'] as Map<String, dynamic>)
          : json['feria'] is Map
          ? Feria.fromJson(Map<String, dynamic>.from(json['feria'] as Map))
          : null,
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : json['usuario'] is Map<String, dynamic>
          ? User.fromJson(json['usuario'] as Map<String, dynamic>)
          : json['user'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : json['usuario'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['usuario'] as Map))
          : null,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'feria_id': feriaId,
      'user_id': userId,
      'participante_id': participanteId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'estado': estado,
      'estado_label': estadoLabel,
      'observaciones': observaciones,
      'pdf_path': pdfPath,
      'es_publico': esPublico,
      'participante': participante?.toJson(),
      'feria': feria?.toJson(),
      'user': user?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
