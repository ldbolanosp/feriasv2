import 'model_parsers.dart';
import 'producto_precio.dart';

class Producto {
  final int id;
  final String codigo;
  final String descripcion;
  final bool activo;
  final double? precio;
  final int preciosCount;
  final List<ProductoPrecio> precios;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Producto({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.activo,
    this.precio,
    this.preciosCount = 0,
    this.precios = const <ProductoPrecio>[],
    this.createdAt,
    this.updatedAt,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final id = parseInt(json['id']);
    final preciosJson = json['precios'];

    return Producto(
      id: id,
      codigo: parseString(json['codigo']) ?? '',
      descripcion: parseString(json['descripcion']) ?? '',
      activo: parseBool(json['activo'], fallback: true),
      precio: json['precio'] != null
          ? parseDouble(json['precio'])
          : json['precio_feria_actual'] != null
          ? parseDouble(json['precio_feria_actual'])
          : null,
      preciosCount: parseInt(json['precios_count']),
      precios: preciosJson is List
          ? preciosJson.whereType<Map>().map((item) {
              final normalized = Map<String, dynamic>.from(item);
              normalized.putIfAbsent('producto_id', () => id);
              return ProductoPrecio.fromJson(normalized);
            }).toList(growable: false)
          : const <ProductoPrecio>[],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'codigo': codigo,
      'descripcion': descripcion,
      'activo': activo,
      'precio': precio,
      'precios_count': preciosCount,
      'precios': precios.map((item) => item.toJson()).toList(growable: false),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
