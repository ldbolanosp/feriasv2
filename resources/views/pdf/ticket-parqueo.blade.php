<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Ticket Parqueo</title>
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
        <strong>{{ $parqueo->feria->descripcion ?? 'Parqueo' }}</strong>
        <div>Ticket de parqueo</div>
    </div>

    <div class="row"><strong>Placa:</strong> {{ $parqueo->placa }}</div>
    <div class="row"><strong>Ingreso:</strong> {{ optional($parqueo->fecha_hora_ingreso)->format('d/m/Y H:i') }}</div>
    <div class="row"><strong>Salida:</strong> {{ optional($parqueo->fecha_hora_salida)->format('d/m/Y H:i') ?? 'Pendiente' }}</div>
    <div class="row"><strong>Tarifa:</strong> CRC {{ number_format((float) $parqueo->tarifa, 2) }}</div>
    <div class="row"><strong>Estado:</strong> {{ $parqueo->estado->label() }}</div>
    <div class="row"><strong>Usuario:</strong> {{ $parqueo->usuario->name ?? 'N/A' }}</div>
</body>
</html>
