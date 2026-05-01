import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/factura.dart';
import '../models/parqueo.dart';
import '../models/sanitario.dart';
import '../models/tarima.dart';
import '../utils/factura_ticket_layout.dart';
import 'printer_service.dart';

class PdfPrinterService extends PrinterService {
  PdfPrinterService();

  @override
  PrinterType get type => PrinterType.generic;

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<void> printTicketFactura(Factura factura, String feriaName) async {
    final lineas = FacturaTicketLayout.generarLineasFactura(factura, feriaName);
    await _imprimirPdf('Factura ${factura.consecutivo ?? factura.id}', lineas);
  }

  @override
  Future<void> printTicketParqueo(Parqueo parqueo, String feriaName) async {
    final lineas = FacturaTicketLayout.generarLineasParqueo(parqueo, feriaName);
    await _imprimirPdf('Parqueo ${parqueo.placa}', lineas);
  }

  @override
  Future<void> printTicketTarima(Tarima tarima, String feriaName) async {
    final lineas = FacturaTicketLayout.generarLineasTarima(tarima, feriaName);
    await _imprimirPdf('Tarima ${tarima.id}', lineas);
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
    await _imprimirPdf('Sanitario ${sanitario.id}', lineas);
  }

  Future<void> _imprimirPdf(String titulo, List<TicketLine> lineas) async {
    await Printing.layoutPdf(
      name: titulo,
      onLayout: (_) async => _generarDocumento(lineas),
      format: PdfPageFormat.roll80,
    );
  }

  Future<Uint8List> _generarDocumento(List<TicketLine> lineas) async {
    final documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        build: (_) {
          return <pw.Widget>[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: lineas
                  .map(
                    (linea) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        linea.text,
                        textAlign: linea.isCenter
                            ? pw.TextAlign.center
                            : pw.TextAlign.left,
                        style: pw.TextStyle(
                          font: linea.isBold
                              ? pw.Font.courierBold()
                              : pw.Font.courier(),
                          fontSize: linea.isLarge ? 12 : 9,
                          lineSpacing: 1.1,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ];
        },
      ),
    );

    return documento.save();
  }
}
