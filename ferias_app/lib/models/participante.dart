import 'feria.dart';
import 'model_parsers.dart';

class Participante {
  final int id;
  final String nombre;
  final String tipoIdentificacion;
  final String numeroIdentificacion;
  final String? correoElectronico;
  final String? numeroCarne;
  final DateTime? fechaEmisionCarne;
  final DateTime? fechaVencimientoCarne;
  final String? procedencia;
  final String? telefono;
  final String? tipoSangre;
  final String? padecimientos;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  final bool activo;
  final List<Feria> ferias;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Participante({
    required this.id,
    required this.nombre,
    required this.tipoIdentificacion,
    required this.numeroIdentificacion,
    this.correoElectronico,
    this.numeroCarne,
    this.fechaEmisionCarne,
    this.fechaVencimientoCarne,
    this.procedencia,
    this.telefono,
    this.tipoSangre,
    this.padecimientos,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    required this.activo,
    this.ferias = const <Feria>[],
    this.createdAt,
    this.updatedAt,
  });

  factory Participante.fromJson(Map<String, dynamic> json) {
    final feriasJson = json['ferias'];

    return Participante(
      id: parseInt(json['id']),
      nombre: parseString(json['nombre']) ?? '',
      tipoIdentificacion: parseString(json['tipo_identificacion']) ?? '',
      numeroIdentificacion: parseString(json['numero_identificacion']) ?? '',
      correoElectronico: parseString(json['correo_electronico']),
      numeroCarne: parseString(json['numero_carne']),
      fechaEmisionCarne: parseDateTime(json['fecha_emision_carne']),
      fechaVencimientoCarne: parseDateTime(json['fecha_vencimiento_carne']),
      procedencia: parseString(json['procedencia']),
      telefono: parseString(json['telefono']),
      tipoSangre: parseString(json['tipo_sangre']),
      padecimientos: parseString(json['padecimientos']),
      contactoEmergenciaNombre: parseString(
        json['contacto_emergencia_nombre'],
      ),
      contactoEmergenciaTelefono: parseString(
        json['contacto_emergencia_telefono'],
      ),
      activo: parseBool(json['activo'], fallback: true),
      ferias: feriasJson is List
          ? feriasJson
              .whereType<Map>()
              .map((item) => Feria.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const <Feria>[],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'tipo_identificacion': tipoIdentificacion,
      'numero_identificacion': numeroIdentificacion,
      'correo_electronico': correoElectronico,
      'numero_carne': numeroCarne,
      'fecha_emision_carne': fechaEmisionCarne?.toIso8601String(),
      'fecha_vencimiento_carne': fechaVencimientoCarne?.toIso8601String(),
      'procedencia': procedencia,
      'telefono': telefono,
      'tipo_sangre': tipoSangre,
      'padecimientos': padecimientos,
      'contacto_emergencia_nombre': contactoEmergenciaNombre,
      'contacto_emergencia_telefono': contactoEmergenciaTelefono,
      'activo': activo,
      'ferias': ferias.map((item) => item.toJson()).toList(growable: false),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
