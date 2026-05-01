<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Ticket Factura</title>
    <style>
        @page {
            margin: 6mm 5mm 8mm 5mm;
        }

        body {
            font-family: "Courier", "DejaVu Sans Mono", monospace;
            font-size: 10px;
            line-height: 1.28;
            color: #111;
            margin: 0;
            padding: 0;
        }

        h1, h2, h3, p {
            margin: 0;
        }

        .ticket {
            width: 100%;
        }

        .center,
        .footer {
            text-align: center;
        }

        .brand {
            margin-bottom: 8px;
        }

        .brand h1 {
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
        }

        .brand p {
            font-size: 9px;
            color: #4b5563;
        }

        .receipt-number {
            margin-top: 5px;
            padding: 3px 0;
            font-size: 11px;
            font-weight: 700;
            border-top: 1px dashed #6b7280;
            border-bottom: 1px dashed #6b7280;
        }

        .section {
            margin-top: 8px;
        }

        .divider {
            border-top: 1px dashed #6b7280;
            margin: 7px 0;
        }

        .meta-row {
            width: 100%;
            margin-bottom: 2px;
        }

        .meta-row td {
            vertical-align: top;
            padding: 0;
        }

        .meta-row .label {
            width: 28%;
            color: #4b5563;
        }

        .meta-row .value {
            width: 72%;
            text-align: right;
            font-weight: 600;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            padding: 2px 0;
            text-align: left;
            vertical-align: top;
        }

        thead th {
            font-size: 9px;
            color: #4b5563;
            font-weight: 700;
            border-bottom: 1px dashed #9ca3af;
            padding-bottom: 3px;
        }

        tbody td {
            border-bottom: 1px dotted #d1d5db;
        }

        .producto {
            width: 40%;
            padding-right: 4px;
        }

        .cantidad {
            width: 14%;
        }

        .precio {
            width: 22%;
        }

        .subtotal {
            width: 24%;
        }

        .text-right {
            text-align: right;
        }

        .muted {
            color: #4b5563;
        }

        .totals {
            margin-top: 6px;
        }

        .totals td {
            padding: 1px 0;
        }

        .totals .label {
            color: #4b5563;
        }

        .totals .value {
            text-align: right;
            font-weight: 600;
        }

        .totals .grand-total td {
            padding-top: 5px;
            font-size: 12px;
            font-weight: 700;
            border-top: 1px dashed #6b7280;
        }

        .notes {
            white-space: pre-line;
        }

        .footer {
            margin-top: 10px;
            font-size: 9px;
            color: #4b5563;
        }
    </style>
</head>
<body>
    <div class="ticket">
        <div class="brand center">
            <h1>{{ $factura->feria->descripcion ?? 'Factura' }}</h1>
            <p>Comprobante de facturación</p>
            <p>{{ optional($factura->fecha_emision ?? $factura->created_at)->format('d/m/Y H:i') }}</p>
        </div>

        <div class="receipt-number center">
            {{ $factura->consecutivo ?? 'BORRADOR' }}
        </div>

        <div class="divider"></div>

        <div class="section">
            <table class="meta-row">
                <tr>
                    <td class="label">Cliente</td>
                    <td class="value">
                        {{ $factura->es_publico_general ? $factura->nombre_publico : ($factura->participante->nombre ?? 'N/A') }}
                    </td>
                </tr>
            </table>
            <table class="meta-row">
                <tr>
                    <td class="label">Cajero</td>
                    <td class="value">{{ $factura->usuario->name ?? 'N/A' }}</td>
                </tr>
            </table>
            @if($factura->tipo_puesto || $factura->numero_puesto)
                <table class="meta-row">
                    <tr>
                        <td class="label">Puesto</td>
                        <td class="value">
                            {{ trim(($factura->tipo_puesto ?? '').' '.($factura->numero_puesto ?? '')) }}
                        </td>
                    </tr>
                </table>
            @endif
            <table class="meta-row">
                <tr>
                    <td class="label">Items</td>
                    <td class="value">{{ $factura->detalles->count() }}</td>
                </tr>
            </table>
        </div>

        <div class="divider"></div>

        <div class="section">
            <table>
                <thead>
                    <tr>
                        <th class="producto">Producto</th>
                        <th class="cantidad text-right">Cant.</th>
                        <th class="precio text-right">Precio</th>
                        <th class="subtotal text-right">Subt.</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($factura->detalles as $detalle)
                        <tr>
                            <td class="producto">{{ $detalle->descripcion_producto }}</td>
                            <td class="cantidad text-right">{{ number_format((float) $detalle->cantidad, 1) }}</td>
                            <td class="precio text-right">{{ number_format((float) $detalle->precio_unitario, 2) }}</td>
                            <td class="subtotal text-right">{{ number_format((float) $detalle->subtotal_linea, 2) }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        <div class="section">
            <table class="totals">
                @if($factura->monto_pago !== null)
                    <tr>
                        <td class="label">Pago</td>
                        <td class="value">CRC {{ number_format((float) $factura->monto_pago, 2) }}</td>
                    </tr>
                    <tr>
                        <td class="label">Cambio</td>
                        <td class="value">CRC {{ number_format((float) $factura->monto_cambio, 2) }}</td>
                    </tr>
                @endif
                <tr class="grand-total">
                    <td>Total</td>
                    <td class="text-right">CRC {{ number_format((float) $factura->subtotal, 2) }}</td>
                </tr>
            </table>
        </div>

        @if($factura->observaciones)
            <div class="divider"></div>
            <div class="section">
                <p class="muted">Observaciones</p>
                <p class="notes">{{ $factura->observaciones }}</p>
            </div>
        @endif

        <div class="divider"></div>
        <div class="footer">
            <p>Gracias por su compra</p>
            <p>Ferias v2r</p>
        </div>
    </div>
</body>
</html>
