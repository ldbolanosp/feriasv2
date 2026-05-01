import 'factura_detalle.dart';
import 'feria.dart';
import 'model_parsers.dart';
import 'participante.dart';
import 'user.dart';

class Factura {
  final int id;
  final int feriaId;
  final int? participanteId;
  final int userId;
  final String? consecutivo;
  final bool esPublicoGeneral;
  final String? nombrePublico;
  final String? tipoPuesto;
  final String? numeroPuesto;
  final double subtotal;
  final double? montoPago;
  final double? montoCambio;
  final String? observaciones;
  final String estado;
  final String? estadoLabel;
  final DateTime? fechaEmision;
  final String? pdfPath;
  final List<FacturaDetalle> detalles;
  final int detallesCount;
  final Participante? participante;
  final User? user;
  final Feria? feria;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Factura({
    required this.id,
    required this.feriaId,
    required this.participanteId,
    required this.userId,
    this.consecutivo,
    required this.esPublicoGeneral,
    this.nombrePublico,
    this.tipoPuesto,
    this.numeroPuesto,
    required this.subtotal,
    this.montoPago,
    this.montoCambio,
    this.observaciones,
    required this.estado,
    this.estadoLabel,
    this.fechaEmision,
    this.pdfPath,
    this.detalles = const <FacturaDetalle>[],
    this.detallesCount = 0,
    this.participante,
    this.user,
    this.feria,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    final facturaId = parseInt(json['id']);
    final detallesJson = json['detalles'];

    return Factura(
      id: facturaId,
      feriaId: parseInt(json['feria_id']),
      participanteId: json['participante_id'] == null
          ? null
          : parseInt(json['participante_id']),
      userId: parseInt(json['user_id']),
      consecutivo: parseString(json['consecutivo']),
      esPublicoGeneral: parseBool(json['es_publico_general']),
      nombrePublico: parseString(json['nombre_publico']),
      tipoPuesto: parseString(json['tipo_puesto']),
      numeroPuesto: parseString(json['numero_puesto']),
      subtotal: parseDouble(json['subtotal']),
      montoPago: json['monto_pago'] == null
          ? null
          : parseDouble(json['monto_pago']),
      montoCambio: json['monto_cambio'] == null
          ? null
          : parseDouble(json['monto_cambio']),
      observaciones: parseString(json['observaciones']),
      estado: parseString(json['estado']) ?? '',
      estadoLabel: parseString(json['estado_label']),
      fechaEmision: parseDateTime(json['fecha_emision']),
      pdfPath: parseString(json['pdf_path']),
      detalles: detallesJson is List
          ? detallesJson.whereType<Map>().map((item) {
              final normalized = Map<String, dynamic>.from(item);
              normalized.putIfAbsent('factura_id', () => facturaId);
              return FacturaDetalle.fromJson(normalized);
            }).toList(growable: false)
          : const <FacturaDetalle>[],
      detallesCount: parseInt(json['detalles_count']),
      participante: json['participante'] is Map<String, dynamic>
          ? Participante.fromJson(json['participante'] as Map<String, dynamic>)
          : json['participante'] is Map
          ? Participante.fromJson(
              Map<String, dynamic>.from(json['participante'] as Map),
            )
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
      feria: json['feria'] is Map<String, dynamic>
          ? Feria.fromJson(json['feria'] as Map<String, dynamic>)
          : json['feria'] is Map
          ? Feria.fromJson(Map<String, dynamic>.from(json['feria'] as Map))
          : null,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      deletedAt: parseDateTime(json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'feria_id': feriaId,
      'participante_id': participanteId,
      'user_id': userId,
      'consecutivo': consecutivo,
      'es_publico_general': esPublicoGeneral,
      'nombre_publico': nombrePublico,
      'tipo_puesto': tipoPuesto,
      'numero_puesto': numeroPuesto,
      'subtotal': subtotal,
      'monto_pago': montoPago,
      'monto_cambio': montoCambio,
      'observaciones': observaciones,
      'estado': estado,
      'estado_label': estadoLabel,
      'fecha_emision': fechaEmision?.toIso8601String(),
      'pdf_path': pdfPath,
      'detalles_count': detallesCount,
      'detalles': detalles.map((item) => item.toJson()).toList(growable: false),
      'participante': participante?.toJson(),
      'user': user?.toJson(),
      'feria': feria?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
