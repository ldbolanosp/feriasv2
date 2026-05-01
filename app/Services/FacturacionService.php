<?php

namespace App\Services;

use App\Enums\EstadoFactura;
use App\Models\Factura;
use App\Models\FacturaDetalle;
use App\Models\Participante;
use App\Models\ProductoPrecio;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class FacturacionService
{
    public function __construct(
        public ConsecutivoService $consecutivoService,
        public PdfTicketService $pdfTicketService,
    ) {
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function crearFactura(array $data, int $feriaId, int $userId): Factura
    {
        $payload = $this->normalizeFacturaPayload($data, $feriaId);

        return DB::transaction(function () use ($payload, $feriaId, $userId): Factura {
            $factura = Factura::query()->create([
                'feria_id' => $feriaId,
                'participante_id' => $payload['participante_id'],
                'user_id' => $userId,
                'es_publico_general' => $payload['es_publico_general'],
                'nombre_publico' => $payload['nombre_publico'],
                'tipo_puesto' => $payload['tipo_puesto'],
                'numero_puesto' => $payload['numero_puesto'],
                'subtotal' => $payload['subtotal'],
                'monto_pago' => $payload['monto_pago'],
                'monto_cambio' => $payload['monto_cambio'],
                'observaciones' => $payload['observaciones'],
                'estado' => EstadoFactura::Borrador,
            ]);

            $this->crearDetalles($factura, $payload['detalles']);

            return $factura->load(['detalles.producto', 'participante', 'feria', 'usuario']);
        });
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function actualizarFactura(Factura $factura, array $data): Factura
    {
        $this->ensureFacturaEditable($factura);

        $payload = $this->normalizeFacturaPayload($data, $factura->feria_id);

        return DB::transaction(function () use ($factura, $payload): Factura {
            $factura->update([
                'participante_id' => $payload['participante_id'],
                'es_publico_general' => $payload['es_publico_general'],
                'nombre_publico' => $payload['nombre_publico'],
                'tipo_puesto' => $payload['tipo_puesto'],
                'numero_puesto' => $payload['numero_puesto'],
                'subtotal' => $payload['subtotal'],
                'monto_pago' => $payload['monto_pago'],
                'monto_cambio' => $payload['monto_cambio'],
                'observaciones' => $payload['observaciones'],
            ]);

            $factura->detalles()->delete();
            $this->crearDetalles($factura, $payload['detalles']);

            return $factura->load(['detalles.producto', 'participante', 'feria', 'usuario']);
        });
    }

    public function facturar(Factura $factura): Factura
    {
        $this->ensureFacturaEditable($factura);

        $factura = DB::transaction(function () use ($factura): Factura {
            $factura->refresh();
            $this->ensureFacturaEditable($factura);

            $factura->update([
                'consecutivo' => $this->consecutivoService->generarConsecutivo($factura->feria_id),
                'estado' => EstadoFactura::Facturado,
                'fecha_emision' => now(),
            ]);

            return $factura->load(['detalles.producto', 'participante', 'feria', 'usuario']);
        });

        $pdfPath = $this->pdfTicketService->generarTicketFactura($factura);
        $factura->forceFill(['pdf_path' => $pdfPath])->save();

        return $factura->fresh(['detalles.producto', 'participante', 'feria', 'usuario']);
    }

    public function eliminar(Factura $factura): void
    {
        DB::transaction(function () use ($factura): void {
            $factura->refresh();
            $factura->update(['estado' => EstadoFactura::Eliminado]);
            $factura->delete();
        });
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array{
     *     participante_id:int|null,
     *     es_publico_general:bool,
     *     nombre_publico:string|null,
     *     tipo_puesto:string|null,
     *     numero_puesto:string|null,
     *     subtotal:string,
     *     monto_pago:string|null,
     *     monto_cambio:string|null,
     *     observaciones:string|null,
     *     detalles:array<int, array{
     *         producto_id:int,
     *         descripcion_producto:string,
     *         cantidad:string,
     *         precio_unitario:string,
     *         subtotal_linea:string
     *     }>
     * }
     */
    private function normalizeFacturaPayload(array $data, int $feriaId): array
    {
        $esPublicoGeneral = (bool) ($data['es_publico_general'] ?? false);
        $participanteId = isset($data['participante_id']) ? (int) $data['participante_id'] : null;
        $nombrePublico = isset($data['nombre_publico']) ? trim((string) $data['nombre_publico']) : null;
        $detalles = $this->normalizeDetalles($data['detalles'] ?? [], $feriaId);
        $subtotal = collect($detalles)
            ->sum(fn (array $detalle): float => (float) $detalle['subtotal_linea']);

        if ($esPublicoGeneral) {
            if ($nombrePublico === null || $nombrePublico === '') {
                throw ValidationException::withMessages([
                    'nombre_publico' => 'El nombre para público general es obligatorio.',
                ]);
            }

            $participanteId = null;
        } else {
            if ($participanteId === null) {
                throw ValidationException::withMessages([
                    'participante_id' => 'Debe seleccionar un participante.',
                ]);
            }

            $participantePerteneceAFeria = Participante::query()
                ->whereKey($participanteId)
                ->porFeria($feriaId)
                ->exists();

            if (! $participantePerteneceAFeria) {
                throw ValidationException::withMessages([
                    'participante_id' => 'El participante no pertenece a la feria seleccionada.',
                ]);
            }
        }

        $montoPago = $data['monto_pago'] ?? null;
        $montoPagoNormalizado = $montoPago !== null && $montoPago !== ''
            ? $this->asMoney($montoPago)
            : null;

        return [
            'participante_id' => $participanteId,
            'es_publico_general' => $esPublicoGeneral,
            'nombre_publico' => $esPublicoGeneral ? $nombrePublico : null,
            'tipo_puesto' => $this->nullableString($data['tipo_puesto'] ?? null),
            'numero_puesto' => $this->nullableString($data['numero_puesto'] ?? null),
            'subtotal' => $this->asMoney($subtotal),
            'monto_pago' => $montoPagoNormalizado,
            'monto_cambio' => $montoPagoNormalizado !== null ? $this->asMoney((float) $montoPagoNormalizado - $subtotal) : null,
            'observaciones' => $this->nullableString($data['observaciones'] ?? null),
            'detalles' => $detalles,
        ];
    }

    /**
     * @param  mixed  $detalles
     * @return array<int, array{
     *     producto_id:int,
     *     descripcion_producto:string,
     *     cantidad:string,
     *     precio_unitario:string,
     *     subtotal_linea:string
     * }>
     */
    private function normalizeDetalles(mixed $detalles, int $feriaId): array
    {
        if (! is_array($detalles) || $detalles === []) {
            throw ValidationException::withMessages([
                'detalles' => 'La factura debe incluir al menos un producto.',
            ]);
        }

        /** @var Collection<int, array<string, mixed>> $detallesCollection */
        $detallesCollection = collect($detalles)->map(function (mixed $detalle): array {
            if (! is_array($detalle)) {
                throw ValidationException::withMessages([
                    'detalles' => 'Cada detalle debe ser un arreglo válido.',
                ]);
            }

            return $detalle;
        });

        $productoIds = $detallesCollection
            ->pluck('producto_id')
            ->map(fn (mixed $productoId): int => (int) $productoId)
            ->unique()
            ->values();

        $preciosPorProducto = ProductoPrecio::query()
            ->with('producto')
            ->where('feria_id', $feriaId)
            ->whereIn('producto_id', $productoIds)
            ->get()
            ->keyBy('producto_id');

        return $detallesCollection->map(function (array $detalle, int $index) use ($preciosPorProducto): array {
            $productoId = isset($detalle['producto_id']) ? (int) $detalle['producto_id'] : 0;
            $cantidad = isset($detalle['cantidad']) ? (float) $detalle['cantidad'] : 0.0;

            if ($productoId <= 0) {
                throw ValidationException::withMessages([
                    "detalles.{$index}.producto_id" => 'Debe seleccionar un producto válido.',
                ]);
            }

            if ($cantidad < 1 || fmod($cantidad * 10, 5.0) !== 0.0) {
                throw ValidationException::withMessages([
                    "detalles.{$index}.cantidad" => 'La cantidad debe ser mínimo 1 y en incrementos de 0.5.',
                ]);
            }

            /** @var ProductoPrecio|null $precio */
            $precio = $preciosPorProducto->get($productoId);

            if ($precio === null || $precio->producto === null) {
                throw ValidationException::withMessages([
                    "detalles.{$index}.producto_id" => 'El producto seleccionado no tiene precio configurado en la feria.',
                ]);
            }

            $subtotalLinea = $cantidad * (float) $precio->precio;

            return [
                'producto_id' => $productoId,
                'descripcion_producto' => $precio->producto->descripcion,
                'cantidad' => number_format($cantidad, 1, '.', ''),
                'precio_unitario' => $this->asMoney($precio->precio),
                'subtotal_linea' => $this->asMoney($subtotalLinea),
            ];
        })->values()->all();
    }

    /**
     * @param  array<int, array{
     *     producto_id:int,
     *     descripcion_producto:string,
     *     cantidad:string,
     *     precio_unitario:string,
     *     subtotal_linea:string
     * }>  $detalles
     */
    private function crearDetalles(Factura $factura, array $detalles): void
    {
        $factura->detalles()->createMany(
            array_map(
                fn (array $detalle): array => array_merge($detalle, ['factura_id' => $factura->id]),
                $detalles
            )
        );
    }

    private function ensureFacturaEditable(Factura $factura): void
    {
        if ($factura->estado !== EstadoFactura::Borrador) {
            throw ValidationException::withMessages([
                'factura' => 'Solo las facturas en borrador pueden modificarse.',
            ]);
        }
    }

    private function asMoney(string|int|float $value): string
    {
        return number_format((float) $value, 2, '.', '');
    }

    private function nullableString(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $text = trim((string) $value);

        return $text === '' ? null : $text;
    }
}
