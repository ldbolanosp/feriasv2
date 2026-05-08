<?php

namespace App\Services\Legacy;

use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use RuntimeException;

class LegacyParkingImporter
{
    private const STORAGE_TIMEZONE = 'UTC';

    private const LEGACY_TIMEZONE = 'America/Costa_Rica';

    public function __construct(private LegacySqlDumpParser $parser) {}

    /**
     * @return array<string, int>
     */
    public function import(string $path, string $feriaCode, string $tarifa, bool $replaceCurrent = false): array
    {
        $legacyParkings = $this->parser->parseTable($path, 'parqueo_registros');
        $feriaId = $this->resolveFeriaId($feriaCode);
        $existingUserIds = DB::table('users')
            ->pluck('id')
            ->map(fn (mixed $id): int => (int) $id)
            ->flip()
            ->all();

        $rows = [];
        $adjustedExitCount = 0;

        foreach ($legacyParkings as $parking) {
            $userId = (int) $parking['user_id'];

            if (! array_key_exists($userId, $existingUserIds)) {
                throw new RuntimeException("No existe el usuario {$userId} requerido para importar parqueos legacy.");
            }

            $ingresoLocal = $this->parseLegacyTimestamp((string) $parking['ingreso_at']);
            $salidaLocal = $this->resolveExitTimestamp($ingresoLocal);
            $ingresoUtc = $ingresoLocal->setTimezone(new DateTimeZone(self::STORAGE_TIMEZONE));
            $salidaUtc = $salidaLocal->setTimezone(new DateTimeZone(self::STORAGE_TIMEZONE));

            if ($salidaUtc->format('Y-m-d H:i:s') === $ingresoUtc->format('Y-m-d H:i:s')) {
                $adjustedExitCount++;
            }

            $rows[] = [
                'id' => (int) $parking['id'],
                'feria_id' => $feriaId,
                'user_id' => $userId,
                'placa' => mb_strtoupper(trim((string) $parking['placa'])),
                'fecha_hora_ingreso' => $ingresoUtc->format('Y-m-d H:i:s'),
                'fecha_hora_salida' => $salidaUtc->format('Y-m-d H:i:s'),
                'tarifa' => number_format((float) $tarifa, 2, '.', ''),
                'tarifa_tipo' => 'fija',
                'estado' => 'finalizado',
                'observaciones' => null,
                'pdf_path' => null,
                'created_at' => $parking['created_at'],
                'updated_at' => $parking['updated_at'],
            ];
        }

        DB::transaction(function () use ($replaceCurrent, $rows): void {
            if ($replaceCurrent) {
                DB::table('parqueos')->delete();
            }

            $this->insertInChunks('parqueos', $rows);
            $this->assertRowsWereInserted('parqueos', array_column($rows, 'id'));
            $this->syncSequence('parqueos');
        });

        return [
            'parqueos' => count($rows),
            'feria_id' => $feriaId,
            'tarifa_aplicada' => (int) round(((float) $tarifa) * 100),
            'salidas_ajustadas' => $adjustedExitCount,
        ];
    }

    public function currentParkingCount(): int
    {
        return DB::table('parqueos')->count();
    }

    private function resolveFeriaId(string $feriaCode): int
    {
        $feriaId = DB::table('ferias')
            ->where('codigo', $feriaCode)
            ->value('id');

        if (! is_int($feriaId)) {
            throw new RuntimeException("No existe la feria con codigo {$feriaCode}.");
        }

        return $feriaId;
    }

    private function parseLegacyTimestamp(string $timestamp): DateTimeImmutable
    {
        return new DateTimeImmutable($timestamp, new DateTimeZone(self::LEGACY_TIMEZONE));
    }

    private function resolveExitTimestamp(DateTimeImmutable $ingresoLocal): DateTimeImmutable
    {
        $localTime = $ingresoLocal->format('H:i:s');

        if ($localTime > '17:00:00') {
            return $ingresoLocal;
        }

        return $ingresoLocal->setTime(17, 0, 0);
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
