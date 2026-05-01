import '../models/factura.dart';
import '../models/factura_detalle.dart';
import '../models/parqueo.dart';
import '../models/sanitario.dart';
import '../models/tarima.dart';
import 'formatters.dart';

class TicketLine {
  const TicketLine({
    required this.text,
    this.isBold = false,
    this.isCenter = false,
    this.isLarge = false,
  });

  final String text;
  final bool isBold;
  final bool isCenter;
  final bool isLarge;
}

class FacturaTicketLayout {
  const FacturaTicketLayout._();

  static const int anchoLinea = 32;
  static const String _empresa = 'Ferias del Agricultor';

  static String separador() {
    return ''.padLeft(anchoLinea, '-');
  }

  static String centrar(String texto) {
    final limpio = texto.trim();

    if (limpio.length >= anchoLinea) {
      return limpio;
    }

    final espacioTotal = anchoLinea - limpio.length;
    final espacioIzquierdo = espacioTotal ~/ 2;
    final espacioDerecho = espacioTotal - espacioIzquierdo;

    return '${' ' * espacioIzquierdo}$limpio${' ' * espacioDerecho}';
  }

  static String lineaDoble(String izquierda, String derecha) {
    final izq = izquierda.trim();
    final der = derecha.trim();
    final espacioDisponible = anchoLinea - der.length;

    if (espacioDisponible <= 0) {
      return der.substring(0, anchoLinea);
    }

    final izquierdaCortada = izq.length > espacioDisponible
        ? izq.substring(0, espacioDisponible)
        : izq;
    final espacios = (anchoLinea - izquierdaCortada.length - der.length).clamp(
      1,
      anchoLinea,
    );

    return '$izquierdaCortada${' ' * espacios}$der';
  }

  static List<String> wrapText(String texto, int ancho) {
    final limpio = texto.trim();

    if (limpio.isEmpty) {
      return const <String>[];
    }

    final palabras = limpio.split(RegExp(r'\s+'));
    final lineas = <String>[];
    var lineaActual = '';

    for (final palabra in palabras) {
      if (palabra.length > ancho) {
        if (lineaActual.isNotEmpty) {
          lineas.add(lineaActual);
          lineaActual = '';
        }

        var inicio = 0;
        while (inicio < palabra.length) {
          final fin = (inicio + ancho).clamp(0, palabra.length);
          lineas.add(palabra.substring(inicio, fin));
          inicio = fin;
        }
        continue;
      }

      final candidata = lineaActual.isEmpty ? palabra : '$lineaActual $palabra';
      if (candidata.length <= ancho) {
        lineaActual = candidata;
      } else {
        lineas.add(lineaActual);
        lineaActual = palabra;
      }
    }

    if (lineaActual.isNotEmpty) {
      lineas.add(lineaActual);
    }

    return lineas;
  }

  static List<TicketLine> generarLineasFactura(
    Factura factura,
    String feriaName,
  ) {
    final fecha = factura.fechaEmision ?? factura.createdAt ?? DateTime.now();
    final cliente = factura.esPublicoGeneral
        ? (factura.nombrePublico?.trim().isNotEmpty ?? false)
              ? factura.nombrePublico!.trim()
              : 'Publico general'
        : factura.participante?.nombre ?? 'Participante no disponible';
    final lineas = <TicketLine>[
      TicketLine(text: _empresa, isBold: true, isCenter: true),
      TicketLine(text: feriaName, isBold: true, isCenter: true, isLarge: true),
      TicketLine(text: 'FACTURA', isBold: true, isCenter: true),
      TicketLine(text: separador()),
      TicketLine(
        text: lineaDoble('Fecha', AppFormatters.formatDateTime(fecha)),
      ),
      TicketLine(
        text: lineaDoble('Consec.', factura.consecutivo ?? 'BORRADOR'),
        isBold: true,
      ),
      TicketLine(text: separador()),
      ..._lineasCampo('Cliente', cliente),
      if ((factura.numeroPuesto?.trim().isNotEmpty ?? false) ||
          (factura.tipoPuesto?.trim().isNotEmpty ?? false))
        TicketLine(
          text:
              'Puesto: ${[factura.tipoPuesto?.trim(), factura.numeroPuesto?.trim()].whereType<String>().where((item) => item.isNotEmpty).join(' #')}',
        ),
      if (factura.detalles.isNotEmpty) TicketLine(text: separador()),
      ..._lineasDetallesFactura(factura.detalles),
      TicketLine(text: separador()),
      TicketLine(
        text: lineaDoble(
          'Subtotal',
          AppFormatters.formatMoney(factura.subtotal),
        ),
      ),
      if (factura.montoPago != null)
        TicketLine(
          text: lineaDoble(
            'Pago',
            AppFormatters.formatMoney(factura.montoPago!),
          ),
        ),
      if (factura.montoCambio != null)
        TicketLine(
          text: lineaDoble(
            'Cambio',
            AppFormatters.formatMoney(factura.montoCambio!),
          ),
        ),
      TicketLine(text: separador()),
      TicketLine(
        text: 'Estado: ${factura.estadoLabel ?? factura.estado}',
        isBold: true,
      ),
      if (factura.user != null)
        TicketLine(text: 'Cajero: ${factura.user!.name}', isCenter: true),
      if (factura.observaciones?.trim().isNotEmpty ?? false)
        ..._lineasCampo('Obs.', factura.observaciones!.trim()),
      TicketLine(text: 'Gracias por su compra', isCenter: true),
    ];

    return _normalizarLineas(lineas);
  }

  static List<TicketLine> generarLineasParqueo(
    Parqueo parqueo,
    String feriaName,
  ) {
    final lineas = <TicketLine>[
      TicketLine(text: _empresa, isBold: true, isCenter: true),
      TicketLine(text: feriaName, isBold: true, isCenter: true, isLarge: true),
      TicketLine(text: 'PARQUEO', isBold: true, isCenter: true),
      TicketLine(text: separador()),
      TicketLine(text: 'Placa: ${parqueo.placa}', isBold: true, isCenter: true),
      TicketLine(text: separador()),
      TicketLine(
        text: lineaDoble(
          'Ingreso',
          AppFormatters.formatDateTime(parqueo.fechaHoraIngreso),
        ),
      ),
      if (parqueo.fechaHoraSalida != null)
        TicketLine(
          text: lineaDoble(
            'Salida',
            AppFormatters.formatDateTime(parqueo.fechaHoraSalida!),
          ),
        ),
      TicketLine(
        text: lineaDoble('Tarifa', AppFormatters.formatMoney(parqueo.tarifa)),
      ),
      TicketLine(
        text: 'Tipo: ${parqueo.tarifaTipoLabel ?? parqueo.tarifaTipo}',
      ),
      TicketLine(text: 'Estado: ${parqueo.estadoLabel ?? parqueo.estado}'),
      if (parqueo.user != null)
        TicketLine(text: 'Usuario: ${parqueo.user!.name}', isCenter: true),
      if (parqueo.observaciones?.trim().isNotEmpty ?? false)
        ..._lineasCampo('Obs.', parqueo.observaciones!.trim()),
      TicketLine(text: separador()),
      TicketLine(text: 'Conserve este comprobante', isCenter: true),
    ];

    return _normalizarLineas(lineas);
  }

  static List<TicketLine> generarLineasTarima(Tarima tarima, String feriaName) {
    final fecha = tarima.createdAt ?? DateTime.now();
    final lineas = <TicketLine>[
      TicketLine(text: _empresa, isBold: true, isCenter: true),
      TicketLine(text: feriaName, isBold: true, isCenter: true, isLarge: true),
      TicketLine(text: 'TARIMAS', isBold: true, isCenter: true),
      TicketLine(text: separador()),
      TicketLine(
        text: lineaDoble('Fecha', AppFormatters.formatDateTime(fecha)),
      ),
      if (tarima.participante != null)
        ..._lineasCampo('Participante', tarima.participante!.nombre),
      if (tarima.numeroTarima?.trim().isNotEmpty ?? false)
        TicketLine(text: 'Tarima: ${tarima.numeroTarima}'),
      TicketLine(text: 'Cantidad: ${tarima.cantidad}'),
      TicketLine(
        text: lineaDoble(
          'P. Unit.',
          AppFormatters.formatMoney(tarima.precioUnitario),
        ),
      ),
      TicketLine(
        text: lineaDoble('Total', AppFormatters.formatMoney(tarima.total)),
        isBold: true,
      ),
      TicketLine(text: 'Estado: ${tarima.estadoLabel ?? tarima.estado}'),
      if (tarima.user != null)
        TicketLine(text: 'Usuario: ${tarima.user!.name}', isCenter: true),
      if (tarima.observaciones?.trim().isNotEmpty ?? false)
        ..._lineasCampo('Obs.', tarima.observaciones!.trim()),
      TicketLine(text: separador()),
      TicketLine(text: 'Gracias por su visita', isCenter: true),
    ];

    return _normalizarLineas(lineas);
  }

  static List<TicketLine> generarLineasSanitario(
    Sanitario sanitario,
    String feriaName,
  ) {
    final fecha = sanitario.createdAt ?? DateTime.now();
    final cliente = sanitario.esPublico
        ? 'Publico general'
        : sanitario.participante?.nombre ?? 'Participante no disponible';
    final lineas = <TicketLine>[
      TicketLine(text: _empresa, isBold: true, isCenter: true),
      TicketLine(text: feriaName, isBold: true, isCenter: true, isLarge: true),
      TicketLine(text: 'SANITARIOS', isBold: true, isCenter: true),
      TicketLine(text: separador()),
      TicketLine(
        text: lineaDoble('Fecha', AppFormatters.formatDateTime(fecha)),
      ),
      ..._lineasCampo('Cliente', cliente),
      TicketLine(text: 'Cantidad: ${sanitario.cantidad}'),
      TicketLine(
        text: lineaDoble(
          'P. Unit.',
          AppFormatters.formatMoney(sanitario.precioUnitario),
        ),
      ),
      TicketLine(
        text: lineaDoble('Total', AppFormatters.formatMoney(sanitario.total)),
        isBold: true,
      ),
      TicketLine(text: 'Estado: ${sanitario.estadoLabel ?? sanitario.estado}'),
      if (sanitario.user != null)
        TicketLine(text: 'Usuario: ${sanitario.user!.name}', isCenter: true),
      if (sanitario.observaciones?.trim().isNotEmpty ?? false)
        ..._lineasCampo('Obs.', sanitario.observaciones!.trim()),
      TicketLine(text: separador()),
      TicketLine(text: 'Gracias por su visita', isCenter: true),
    ];

    return _normalizarLineas(lineas);
  }

  static List<TicketLine> _lineasCampo(String etiqueta, String valor) {
    final lineasValor = wrapText(valor, anchoLinea);

    if (lineasValor.isEmpty) {
      return <TicketLine>[TicketLine(text: '$etiqueta:')];
    }

    return <TicketLine>[
      TicketLine(text: '$etiqueta: ${lineasValor.first}'),
      ...lineasValor.skip(1).map((linea) => TicketLine(text: '  $linea')),
    ];
  }

  static List<TicketLine> _lineasDetallesFactura(
    List<FacturaDetalle> detalles,
  ) {
    final lineas = <TicketLine>[];

    for (final detalle in detalles) {
      final descripcion = detalle.descripcionProducto.trim().isEmpty
          ? 'Producto'
          : detalle.descripcionProducto.trim();
      final descripcionLineas = wrapText(descripcion, anchoLinea);

      for (final linea in descripcionLineas) {
        lineas.add(TicketLine(text: linea, isBold: true));
      }

      lineas.add(
        TicketLine(
          text: lineaDoble(
            '${detalle.cantidad} x ${AppFormatters.formatMoney(detalle.precioUnitario)}',
            AppFormatters.formatMoney(detalle.subtotalLinea),
          ),
        ),
      );
    }

    return lineas;
  }

  static List<TicketLine> _normalizarLineas(List<TicketLine> lineas) {
    final resultado = <TicketLine>[];

    for (final linea in lineas) {
      final texto = linea.text.trimRight();

      if (texto.isEmpty) {
        resultado.add(linea);
        continue;
      }

      final lineasEnvueltas = linea.isCenter
          ? wrapText(
              texto,
              anchoLinea,
            ).map((item) => centrar(item)).toList(growable: false)
          : wrapText(texto, anchoLinea);

      if (lineasEnvueltas.isEmpty) {
        resultado.add(linea);
        continue;
      }

      for (final item in lineasEnvueltas) {
        resultado.add(
          TicketLine(
            text: item,
            isBold: linea.isBold,
            isCenter: linea.isCenter,
            isLarge: linea.isLarge,
          ),
        );
      }
    }

    return resultado;
  }
}
