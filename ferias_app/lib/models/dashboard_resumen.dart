import 'model_parsers.dart';

class DashboardResumen {
  final String? rol;
  final int facturasHoy;
  final int facturasBorrador;
  final double totalFacturadoHoy;
  final int parqueosActivos;
  final int parqueosHoy;
  final double totalParqueosHoy;
  final int tarimasHoy;
  final double totalTarimasHoy;
  final int sanitariosHoy;
  final double totalSanitariosHoy;
  final double recaudacionTotalHoy;

  const DashboardResumen({
    this.rol,
    required this.facturasHoy,
    required this.facturasBorrador,
    required this.totalFacturadoHoy,
    required this.parqueosActivos,
    required this.parqueosHoy,
    required this.totalParqueosHoy,
    required this.tarimasHoy,
    required this.totalTarimasHoy,
    required this.sanitariosHoy,
    required this.totalSanitariosHoy,
    required this.recaudacionTotalHoy,
  });

  factory DashboardResumen.fromJson(Map<String, dynamic> json) {
    return DashboardResumen(
      rol: parseString(json['rol']),
      facturasHoy:
          parseInt(json['facturas_hoy'], fallback: parseInt(json['facturas_count'])),
      facturasBorrador: parseInt(
        json['facturas_borrador'],
        fallback: parseInt(json['mis_borradores']),
      ),
      totalFacturadoHoy: parseDouble(
        json['total_facturado_hoy'],
        fallback: parseDouble(json['recaudacion_facturas']),
      ),
      parqueosActivos: parseInt(json['parqueos_activos']),
      parqueosHoy:
          parseInt(json['parqueos_hoy'], fallback: parseInt(json['parqueos_count'])),
      totalParqueosHoy: parseDouble(
        json['total_parqueos_hoy'],
        fallback: parseDouble(json['recaudacion_parqueos']),
      ),
      tarimasHoy:
          parseInt(json['tarimas_hoy'], fallback: parseInt(json['tarimas_count'])),
      totalTarimasHoy: parseDouble(
        json['total_tarimas_hoy'],
        fallback: parseDouble(json['recaudacion_tarimas']),
      ),
      sanitariosHoy: parseInt(
        json['sanitarios_hoy'],
        fallback: parseInt(json['sanitarios_count']),
      ),
      totalSanitariosHoy: parseDouble(
        json['total_sanitarios_hoy'],
        fallback: parseDouble(json['recaudacion_sanitarios']),
      ),
      recaudacionTotalHoy: parseDouble(
        json['recaudacion_total_hoy'],
        fallback: parseDouble(json['recaudacion_total']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rol': rol,
      'facturas_hoy': facturasHoy,
      'facturas_borrador': facturasBorrador,
      'total_facturado_hoy': totalFacturadoHoy,
      'parqueos_activos': parqueosActivos,
      'parqueos_hoy': parqueosHoy,
      'total_parqueos_hoy': totalParqueosHoy,
      'tarimas_hoy': tarimasHoy,
      'total_tarimas_hoy': totalTarimasHoy,
      'sanitarios_hoy': sanitariosHoy,
      'total_sanitarios_hoy': totalSanitariosHoy,
      'recaudacion_total_hoy': recaudacionTotalHoy,
    };
  }
}
