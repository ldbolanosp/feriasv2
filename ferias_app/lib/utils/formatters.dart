import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static final NumberFormat _moneyFormatter = NumberFormat.currency(
    locale: 'es_CR',
    symbol: 'CRC',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  static String formatMoney(double value) {
    final formatted = _moneyFormatter.format(value);
    return formatted.replaceFirst('CRC', '₡').trim();
  }

  static String formatDate(DateTime value) {
    return _dateFormatter.format(value);
  }

  static String formatDateTime(DateTime value) {
    return _dateTimeFormatter.format(value);
  }
}
