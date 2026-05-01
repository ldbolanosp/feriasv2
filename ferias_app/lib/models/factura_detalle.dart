import 'model_parsers.dart';
import 'producto.dart';

class FacturaDetalle {
  final int id;
  final int facturaId;
  final int productoId;
  final String descripcionProducto;
  final double cantidad;
  final double precioUnitario;
  final double subtotalLinea;
  final Producto? producto;

  const FacturaDetalle({
    required this.id,
    required this.facturaId,
    required this.productoId,
    required this.descripcionProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotalLinea,
    this.producto,
  });

  factory FacturaDetalle.fromJson(Map<String, dynamic> json) {
    return FacturaDetalle(
      id: parseInt(json['id']),
      facturaId: parseInt(json['factura_id']),
      productoId: parseInt(json['producto_id']),
      descripcionProducto: parseString(json['descripcion_producto']) ?? '',
      cantidad: parseDouble(json['cantidad']),
      precioUnitario: parseDouble(json['precio_unitario']),
      subtotalLinea: parseDouble(json['subtotal_linea']),
      producto: json['producto'] is Map<String, dynamic>
          ? Producto.fromJson(json['producto'] as Map<String, dynamic>)
          : json['producto'] is Map
          ? Producto.fromJson(Map<String, dynamic>.from(json['producto'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'factura_id': facturaId,
      'producto_id': productoId,
      'descripcion_producto': descripcionProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal_linea': subtotalLinea,
      'producto': producto?.toJson(),
    };
  }
}
