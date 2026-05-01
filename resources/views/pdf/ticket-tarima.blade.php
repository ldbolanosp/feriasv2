<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Ticket Tarima</title>
    <style>
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 11px;
            color: #111827;
            margin: 0;
            padding: 10px;
            width: 80mm;
        }
        .center { text-align: center; }
        .row { margin-top: 6px; }
    </style>
</head>
<body>
    <div class="center">
        <strong>{{ $tarima->feria->descripcion ?? 'Tarima' }}</strong>
        <div>Ticket de tarima</div>
    </div>

    <div class="row"><strong>Participante:</strong> {{ $tarima->participante->nombre ?? 'N/A' }}</div>
    <div class="row"><strong>Número:</strong> {{ $tarima->numero_tarima ?? 'N/A' }}</div>
    <div class="row"><strong>Cantidad:</strong> {{ $tarima->cantidad }}</div>
    <div class="row"><strong>Precio unitario:</strong> CRC {{ number_format((float) $tarima->precio_unitario, 2) }}</div>
    <div class="row"><strong>Total:</strong> CRC {{ number_format((float) $tarima->total, 2) }}</div>
    <div class="row"><strong>Usuario:</strong> {{ $tarima->usuario->name ?? 'N/A' }}</div>
</body>
</html>
