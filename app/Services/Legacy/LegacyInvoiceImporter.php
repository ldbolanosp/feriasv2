<?php

namespace App\Services\Legacy;

use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use RuntimeException;

class LegacyInvoiceImporter
{
    private const STORAGE_TIMEZONE = 'UTC';

    private const LEGACY_TIMEZONE = 'America/Costa_Rica';

    public function __construct(private LegacySqlDumpParser $parser) {}

    /**
     * @return array<string, int>
     */
    public function import(string $path, bool $replaceCurrent = false): array
    {
        $legacyFacturas = $this->parser->parseTable($path, 'facturas');
        $legacyFacturaItems = $this->parser->parseTable($path, 'factura_items');

        $fallbackUserId = $this->resolveFallbackUserId();
        $this->ensureRequiredReferencesExist($legacyFacturas, $legacyFacturaItems);
        $existingUserIds = DB::table('users')
            ->pluck('id')
            ->map(fn (mixed $id): int => (int) $id)
            ->flip()
            ->all();

        $productDescriptions = DB::table('productos')
            ->select(['id', 'descripcion'])
            ->get()
            ->mapWithKeys(fn (object $producto): array => [(int) $producto->id => $producto->descripcion]);

        $facturas = [];
        $fallbackAssignments = 0;

        foreach ($legacyFacturas as $factura) {
            $legacyUserId = $factura['user_id'];
            $resolvedUserId = is_int($legacyUserId) && array_key_exists($legacyUserId, $existingUserIds)
                ? $legacyUserId
                : $fallbackUserId;

            if ($resolvedUserId === $fallbackUserId && $legacyUserId === null) {
                $fallbackAssignments++;
            }

            $nombrePublico = $this->nullableString($factura['nombre_cliente_general']);
            $esPublicoGeneral = $nombrePublico !== null;
            $fechaEmision = $this->resolveInvoiceTimestamp(
                $factura['created_at'] ?? ($factura['fecha'].' 00:00:00')
            );
            $createdAt = $this->resolveInvoiceTimestamp($factura['created_at']);
            $updatedAt = $this->resolveInvoiceTimestamp($factura['updated_at']);

            $facturas[] = [
                'id' => (int) $factura['id'],
                'feria_id' => (int) $factura['feria_id'],
                'participante_id' => $esPublicoGeneral ? null : (int) $factura['participant_id'],
                'user_id' => $resolvedUserId,
                'consecutivo' => $this->mapLegacyConsecutivo((int) $factura['feria_id'], (int) $factura['consecutivo']),
                'es_publico_general' => $esPublicoGeneral,
                'nombre_publico' => $nombrePublico,
                'tipo_puesto' => null,
                'numero_puesto' => null,
                'subtotal' => number_format((float) $factura['total'], 2, '.', ''),
                'monto_pago' => $factura['monto_pago'] === null ? null : number_format((float) $factura['monto_pago'], 2, '.', ''),
                'monto_cambio' => $factura['cambio'] === null ? null : number_format((float) $factura['cambio'], 2, '.', ''),
                'observaciones' => $this->nullableString($factura['observaciones']),
                'estado' => $this->mapLegacyEstado($factura['estatus']),
                'fecha_emision' => $fechaEmision,
                'pdf_path' => null,
                'created_at' => $createdAt,
                'updated_at' => $updatedAt,
                'deleted_at' => null,
            ];
        }

        $detalles = [];

        foreach ($legacyFacturaItems as $detalle) {
            $productoId = (int) $detalle['facturacion_producto_id'];

            $detalles[] = [
                'id' => (int) $detalle['id'],
                'factura_id' => (int) $detalle['factura_id'],
                'producto_id' => $productoId,
                'descripcion_producto' => $productDescriptions[$productoId] ?? "Producto legacy {$productoId}",
                'cantidad' => number_format((float) $detalle['cantidad'], 1, '.', ''),
                'precio_unitario' => number_format((float) $detalle['precio'], 2, '.', ''),
                'subtotal_linea' => number_format((float) $detalle['subtotal'], 2, '.', ''),
                'created_at' => $this->resolveInvoiceTimestamp($detalle['created_at']),
                'updated_at' => $this->resolveInvoiceTimestamp($detalle['updated_at']),
            ];
        }

        DB::transaction(function () use ($replaceCurrent, $facturas, $detalles): void {
            if ($replaceCurrent) {
                DB::table('factura_detalles')->delete();
                DB::table('facturas')->delete();
            }

            $this->insertInChunks('facturas', $facturas);
            $this->assertRowsWereInserted('facturas', array_column($facturas, 'id'));
            $this->insertInChunks('factura_detalles', $detalles);

            $this->syncSequence('facturas');
            $this->syncSequence('factura_detalles');
        });

        return [
            'facturas' => count($facturas),
            'factura_detalles' => count($detalles),
            'usuarios_fallback' => $fallbackAssignments,
        ];
    }

    public function currentInvoiceCount(): int
    {
        return DB::table('facturas')->count();
    }

    private function resolveFallbackUserId(): int
    {
        $fallbackUserId = DB::table('users')->orderBy('id')->value('id');

        if (! is_int($fallbackUserId)) {
            throw new RuntimeException('No hay usuarios disponibles para asignar como fallback en facturas legacy.');
        }

        return $fallbackUserId;
    }

    /**
     * @param  list<array<string, int|string|null>>  $legacyFacturas
     * @param  list<array<string, int|string|null>>  $legacyFacturaItems
     */
    private function ensureRequiredReferencesExist(array $legacyFacturas, array $legacyFacturaItems): void
    {
        $feriaIds = array_values(array_unique(array_map(
            static fn (array $factura): int => (int) $factura['feria_id'],
            $legacyFacturas
        )));

        $participanteIds = array_values(array_unique(array_map(
            static fn (array $factura): int => (int) $factura['participant_id'],
            array_filter($legacyFacturas, static fn (array $factura): bool => $factura['participant_id'] !== null)
        )));

        $productoIds = array_values(array_unique(array_map(
            static fn (array $detalle): int => (int) $detalle['facturacion_producto_id'],
            $legacyFacturaItems
        )));

        $this->ensureIdsExist('ferias', $feriaIds, 'ferias');
        $this->ensureIdsExist('participantes', $participanteIds, 'participantes');
        $this->ensureIdsExist('productos', $productoIds, 'productos');
    }

    /**
     * @param  list<int>  $ids
     */
    private function ensureIdsExist(string $table, array $ids, string $label): void
    {
        if ($ids === []) {
            return;
        }

        $existingIds = DB::table($table)
            ->whereIn('id', $ids)
            ->pluck('id')
            ->map(fn (mixed $id): int => (int) $id)
            ->all();

        $missingIds = array_values(array_diff($ids, $existingIds));

        if ($missingIds !== []) {
            $sample = implode(', ', array_slice($missingIds, 0, 10));

            throw new RuntimeException("Faltan {$label} requeridos para importar facturas legacy. IDs: {$sample}");
        }
    }

    private function mapLegacyConsecutivo(int $feriaId, int $legacyConsecutivo): string
    {
        return 'F'.$feriaId.str_pad((string) $legacyConsecutivo, 8, '0', STR_PAD_LEFT);
    }

    private function mapLegacyEstado(int|string|null $value): string
    {
        $normalizedValue = strtolower(trim((string) $value));

        return match ($normalizedValue) {
            'borrador' => 'borrador',
            'eliminado' => 'eliminado',
            default => 'facturado',
        };
    }

    private function nullableString(int|string|null $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $trimmedValue = trim((string) $value);

        return $trimmedValue === '' ? null : $trimmedValue;
    }

    private function resolveInvoiceTimestamp(int|string|null $value): ?string
    {
        if ($value === null) {
            return null;
        }

        return (new DateTimeImmutable((string) $value, new DateTimeZone(self::LEGACY_TIMEZONE)))
            ->setTimezone(new DateTimeZone(self::STORAGE_TIMEZONE))
            ->format('Y-m-d H:i:s');
    }

    private function syncSequence(string $table): void
    {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, 'id')) {
            return;
        }

        if (DB::getDriverName() === 'pgsql') {
            DB::statement(
                "SELECT setval(pg_get_serial_sequence('{$table}', 'id'), COALESCE((SELECT MAX(id) FROM {$table}), 1), (SELECT COUNT(*) > 0 FROM {$table}))"
            );
        }
    }

    /**
     * @param  list<array<string, mixed>>  $rows
     */
    private function insertInChunks(string $table, array $rows, int $chunkSize = 500): void
    {
        foreach (array_chunk($rows, $chunkSize) as $chunk) {
            DB::table($table)->insert($chunk);
        }
    }

    /**
     * @param  list<int>  $ids
     */
    private function assertRowsWereInserted(string $table, array $ids): void
    {
        if ($ids === []) {
            return;
        }

        $insertedCount = 0;

        foreach (array_chunk($ids, 500) as $chunk) {
            $insertedCount += DB::table($table)->whereIn('id', $chunk)->count();
        }

        if ($insertedCount !== count($ids)) {
            throw new RuntimeException("No se pudieron insertar todos los registros esperados en {$table}. Esperados: ".count($ids).", insertados: {$insertedCount}");
        }
    }
}
