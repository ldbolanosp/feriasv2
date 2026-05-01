import 'feria.dart';
import 'model_parsers.dart';
import 'participante.dart';
import 'user.dart';

class Tarima {
  final int id;
  final int feriaId;
  final int userId;
  final int participanteId;
  final String? numeroTarima;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final String estado;
  final String? estadoLabel;
  final String? observaciones;
  final String? pdfPath;
  final Participante? participante;
  final Feria? feria;
  final User? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Tarima({
    required this.id,
    required this.feriaId,
    required this.userId,
    required this.participanteId,
    this.numeroTarima,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.estado,
    this.estadoLabel,
    this.observaciones,
    this.pdfPath,
    this.participante,
    this.feria,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory Tarima.fromJson(Map<String, dynamic> json) {
    return Tarima(
      id: parseInt(json['id']),
      feriaId: parseInt(json['feria_id']),
      userId: parseInt(json['user_id']),
      participanteId: parseInt(json['participante_id']),
      numeroTarima: parseString(json['numero_tarima']),
      cantidad: parseInt(json['cantidad'], fallback: 1),
      precioUnitario: parseDouble(json['precio_unitario']),
      total: parseDouble(json['total']),
      estado: parseString(json['estado']) ?? '',
      estadoLabel: parseString(json['estado_label']),
      observaciones: parseString(json['observaciones']),
      pdfPath: parseString(json['pdf_path']),
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
      'numero_tarima': numeroTarima,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total': total,
      'estado': estado,
      'estado_label': estadoLabel,
      'observaciones': observaciones,
      'pdf_path': pdfPath,
      'participante': participante?.toJson(),
      'feria': feria?.toJson(),
      'user': user?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
