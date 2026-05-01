DateTime? parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  final normalized = value.toString().trim();
  if (normalized.isEmpty) {
    return null;
  }

  return DateTime.tryParse(normalized);
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double parseDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1') {
    return true;
  }

  if (normalized == 'false' || normalized == '0') {
    return false;
  }

  return fallback;
}

String? parseString(dynamic value) {
  if (value == null) {
    return null;
  }

  final parsed = value.toString();

  return parsed.isEmpty ? null : parsed;
}

List<String> parseStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString())
        .whereType<String>()
        .toList(growable: false);
  }

  return const <String>[];
}
