<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Ticket Sanitario</title>
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
        <strong>{{ $sanitario->feria->descripcion ?? 'Sanitario' }}</strong>
        <div>Ticket de sanitario</div>
    </div>

    <div class="row"><strong>Participante:</strong> {{ $sanitario->participante->nombre ?? 'Uso público' }}</div>
    <div class="row"><strong>Cantidad:</strong> {{ $sanitario->cantidad }}</div>
    <div class="row"><strong>Precio unitario:</strong> CRC {{ number_format((float) $sanitario->precio_unitario, 2) }}</div>
    <div class="row"><strong>Total:</strong> CRC {{ number_format((float) $sanitario->total, 2) }}</div>
    <div class="row"><strong>Estado:</strong> {{ ucfirst($sanitario->estado) }}</div>
    <div class="row"><strong>Usuario:</strong> {{ $sanitario->usuario->name ?? 'N/A' }}</div>
</body>
</html>
