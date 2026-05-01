import 'package:flutter/foundation.dart';

import '../models/factura.dart';
import '../models/parqueo.dart';
import '../models/sanitario.dart';
import '../models/tarima.dart';
import '../services/printer_factory.dart';
import '../services/printer_service.dart';

class PrinterProvider extends ChangeNotifier {
  PrinterService? _printerService;
  bool _isInitialized = false;
  bool _isLoading = false;

  PrinterType get printerType => _printerService?.type ?? PrinterType.generic;
  bool get isReady => _isInitialized;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _printerService = await PrinterFactory.detect();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> printFactura(Factura factura, String feriaName) async {
    await _ensureInitialized();
    await _printerService!.printTicketFactura(factura, feriaName);
  }

  Future<void> printParqueo(Parqueo parqueo, String feriaName) async {
    await _ensureInitialized();
    await _printerService!.printTicketParqueo(parqueo, feriaName);
  }

  Future<void> printTarima(Tarima tarima, String feriaName) async {
    await _ensureInitialized();
    await _printerService!.printTicketTarima(tarima, feriaName);
  }

  Future<void> printSanitario(Sanitario sanitario, String feriaName) async {
    await _ensureInitialized();
    await _printerService!.printTicketSanitario(sanitario, feriaName);
  }

  Future<void> _ensureInitialized() async {
    if (_printerService == null) {
      await initialize();
    }
  }
}
