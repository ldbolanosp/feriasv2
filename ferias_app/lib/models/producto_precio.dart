import 'feria.dart';
import 'model_parsers.dart';

class ProductoPrecio {
  final int id;
  final int productoId;
  final int feriaId;
  final double precio;
  final Feria? feria;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductoPrecio({
    required this.id,
    required this.productoId,
    required this.feriaId,
    required this.precio,
    this.feria,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductoPrecio.fromJson(Map<String, dynamic> json) {
    return ProductoPrecio(
      id: parseInt(json['id']),
      productoId: parseInt(json['producto_id']),
      feriaId: parseInt(json['feria_id']),
      precio: parseDouble(json['precio']),
      feria: json['feria'] is Map<String, dynamic>
          ? Feria.fromJson(json['feria'] as Map<String, dynamic>)
          : json['feria'] is Map
          ? Feria.fromJson(Map<String, dynamic>.from(json['feria'] as Map))
          : null,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'producto_id': productoId,
      'feria_id': feriaId,
      'precio': precio,
      'feria': feria?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
