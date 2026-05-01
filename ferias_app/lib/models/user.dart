import 'feria.dart';
import 'model_parsers.dart';

class User {
  final int id;
  final String name;
  final String email;
  final bool activo;
  final String? role;
  final List<String> roles;
  final List<String> permisos;
  final List<Feria> ferias;
  final int feriasCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.activo,
    this.role,
    this.roles = const <String>[],
    this.permisos = const <String>[],
    this.ferias = const <Feria>[],
    this.feriasCount = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final feriasJson = json['ferias'];

    return User(
      id: parseInt(json['id']),
      name: parseString(json['name']) ?? '',
      email: parseString(json['email']) ?? '',
      activo: parseBool(json['activo'], fallback: true),
      role: parseString(json['role']),
      roles: parseStringList(json['roles']),
      permisos: parseStringList(json['permisos']),
      ferias: feriasJson is List
          ? feriasJson
              .whereType<Map>()
              .map((item) => Feria.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const <Feria>[],
      feriasCount: parseInt(json['ferias_count']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      deletedAt: parseDateTime(json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'activo': activo,
      'role': role,
      'roles': roles,
      'permisos': permisos,
      'ferias_count': feriasCount,
      'ferias': ferias.map((item) => item.toJson()).toList(growable: false),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
