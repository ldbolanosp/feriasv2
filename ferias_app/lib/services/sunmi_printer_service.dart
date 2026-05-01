import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import '../models/factura.dart';
import '../models/parqueo.dart';
import '../models/sanitario.dart';
import '../models/tarima.dart';
import '../utils/factura_ticket_layout.dart';
import 'printer_service.dart';

class SunmiPrinterService extends PrinterService {
  SunmiPrinterService({SunmiPrinterPlus? printer})
    : _printer = printer ?? SunmiPrinterPlus();

  final SunmiPrinterPlus _printer;

  @override
  PrinterType get type => PrinterType.sunmi;

  @override
  Future<bool> isAvailable() async {
    try {
      final isBound = await _printer.rebindPrinter();
      if (isBound) {
        return true;
      }

      final printerType = await _printer.getType();
      return printerType != null && printerType.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> printTicketFactura(Factura factura, String feriaName) async {
    final lineas = FacturaTicketLayout.generarLineasFactura(factura, feriaName);
    await _imprimirLineas(lineas);
  }

  @override
  Future<void> printTicketParqueo(Parqueo parqueo, String feriaName) async {
    final lineas = FacturaTicketLayout.generarLineasParqueo(parqueo, feriaName);
    await _imprimirLineas(lineas);
    await _printer.printQrcode(
      text: parqueo.placa,
      style: SunmiQrcodeStyle(align: SunmiPrintAlign.CENTER, qrcodeSize: 5),
    );
    await _printer.lineWrap(times: 3);
    await _printer.cutPaper();
  }

  @override
  Future<void> printTicketTarima(Tarima tarima, String feriaName) async {
    final lineas = FacturaTicketLayout.generarLineasTarima(tarima, feriaName);
    await _imprimirLineas(lineas);
  }

  @override
  Future<void> printTicketSanitario(
    Sanitario sanitario,
    String feriaName,
  ) async {
    final lineas = FacturaTicketLayout.generarLineasSanitario(
      sanitario,
      feriaName,
    );
    await _imprimirLineas(lineas);
  }

  Future<void> _imprimirLineas(List<TicketLine> lineas) async {
    await _printer.rebindPrinter();

    for (final linea in lineas) {
      await _printer.printText(
        text: '${linea.text}\n',
        style: SunmiTextStyle(
          align: linea.isCenter ? SunmiPrintAlign.CENTER : SunmiPrintAlign.LEFT,
          bold: linea.isBold,
          fontSize: linea.isLarge ? 30 : 24,
        ),
      );
    }

    await _printer.lineWrap(times: 3);
    await _printer.cutPaper();
  }
}
