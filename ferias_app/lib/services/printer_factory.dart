import 'pdf_printer_service.dart';
import 'printer_service.dart';
import 'sunmi_printer_service.dart';

class PrinterFactory {
  const PrinterFactory._();

  static Future<PrinterService> detect() async {
    final sunmiPrinterService = SunmiPrinterService();

    if (await sunmiPrinterService.isAvailable()) {
      return sunmiPrinterService;
    }

    return PdfPrinterService();
  }
}
