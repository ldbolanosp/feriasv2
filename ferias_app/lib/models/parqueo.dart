import 'feria.dart';
import 'model_parsers.dart';
import 'user.dart';

class Parqueo {
  final int id;
  final int feriaId;
  final int userId;
  final String placa;
  final DateTime fechaHoraIngreso;
  final DateTime? fechaHoraSalida;
  final double tarifa;
  final String tarifaTipo;
  final String? tarifaTipoLabel;
  final String estado;
  final String? estadoLabel;
  final String? observaciones;
  final String? pdfPath;
  final Feria? feria;
  final User? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Parqueo({
    required this.id,
    required this.feriaId,
    required this.userId,
    required this.placa,
    required this.fechaHoraIngreso,
    this.fechaHoraSalida,
    required this.tarifa,
    required this.tarifaTipo,
    this.tarifaTipoLabel,
    required this.estado,
    this.estadoLabel,
    this.observaciones,
    this.pdfPath,
    this.feria,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory Parqueo.fromJson(Map<String, dynamic> json) {
    return Parqueo(
      id: parseInt(json['id']),
      feriaId: parseInt(json['feria_id']),
      userId: parseInt(json['user_id']),
      placa: parseString(json['placa']) ?? '',
      fechaHoraIngreso:
          parseDateTime(json['fecha_hora_ingreso']) ?? DateTime.now(),
      fechaHoraSalida: parseDateTime(json['fecha_hora_salida']),
      tarifa: parseDouble(json['tarifa']),
      tarifaTipo: parseString(json['tarifa_tipo']) ?? 'fija',
      tarifaTipoLabel: parseString(json['tarifa_tipo_label']),
      estado: parseString(json['estado']) ?? '',
      estadoLabel: parseString(json['estado_label']),
      observaciones: parseString(json['observaciones']),
      pdfPath: parseString(json['pdf_path']),
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
      'placa': placa,
      'fecha_hora_ingreso': fechaHoraIngreso.toIso8601String(),
      'fecha_hora_salida': fechaHoraSalida?.toIso8601String(),
      'tarifa': tarifa,
      'tarifa_tipo': tarifaTipo,
      'tarifa_tipo_label': tarifaTipoLabel,
      'estado': estado,
      'estado_label': estadoLabel,
      'observaciones': observaciones,
      'pdf_path': pdfPath,
      'feria': feria?.toJson(),
      'user': user?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
