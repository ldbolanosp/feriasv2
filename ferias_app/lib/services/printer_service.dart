import '../models/factura.dart';
import '../models/parqueo.dart';
import '../models/sanitario.dart';
import '../models/tarima.dart';

enum PrinterType { sunmi, generic }

abstract class PrinterService {
  PrinterType get type;

  Future<bool> isAvailable();

  Future<void> printTicketFactura(Factura factura, String feriaName);

  Future<void> printTicketParqueo(Parqueo parqueo, String feriaName);

  Future<void> printTicketTarima(Tarima tarima, String feriaName);

  Future<void> printTicketSanitario(Sanitario sanitario, String feriaName);
}
