<?php

namespace App\Services\Legacy;

use App\Models\User;
use Database\Seeders\RolesAndPermissionsSeeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LegacyCatalogImporter
{
    public function __construct(private LegacySqlDumpParser $parser) {}

    /**
     * @return array<string, int>
     */
    public function import(string $path): array
    {
        $legacyFerias = $this->parser->parseTable($path, 'ferias');
        $legacyParticipantes = $this->parser->parseTable($path, 'participants');
        $legacyFeriaParticipante = $this->parser->parseTable($path, 'feria_participant');
        $legacyProductos = $this->parser->parseTable($path, 'facturacion_productos');
        $legacyProductoPrecios = $this->parser->parseTable($path, 'feria_facturacion_producto');
        $legacyUsers = $this->parser->parseTable($path, 'users');
        $legacyRoles = $this->parser->parseTable($path, 'roles');

        DB::transaction(function () use (
            $legacyFerias,
            $legacyParticipantes,
            $legacyFeriaParticipante,
            $legacyProductos,
            $legacyProductoPrecios,
            $legacyUsers,
            $legacyRoles
        ): void {
            $this->importFerias($legacyFerias);
            $this->importParticipantes($legacyParticipantes);
            $this->importFeriaParticipante($legacyFeriaParticipante);
            $this->importProductos($legacyProductos);
            $this->importProductoPrecios($legacyProductoPrecios);
            $this->importUsers($legacyUsers, $legacyRoles);
        });

        return [
            'ferias' => count($legacyFerias),
            'consecutivos_feria' => count($legacyFerias),
            'participantes' => count($legacyParticipantes),
            'feria_participante' => count($legacyFeriaParticipante),
            'productos' => count($legacyProductos),
            'producto_precios' => count($legacyProductoPrecios),
            'usuarios' => count($legacyUsers),
        ];
    }

    /**
     * @param  list<array<string, int|string|null>>  $legacyFerias
     */
    private function importFerias(array $legacyFerias): void
    {
        $usedCodes = DB::table('ferias')
            ->select(['id', 'codigo'])
            ->get()
            ->filter(fn (object $feria): bool => $feria->codigo !== null)
            ->mapWithKeys(fn (object $feria): array => [$feria->codigo => (int) $feria->id])
            ->all();

        $ferias = [];

        foreach ($legacyFerias as $feria) {
            $legacyId = (int) $feria['id'];

            $ferias[] = [
                'id' => $legacyId,
                'codigo' => $this->resolveUniqueIdentifier((string) $feria['codigo'], $legacyId, 20, $usedCodes),
                'descripcion' => $feria['descripcion'],
                'facturacion_publico' => (bool) $feria['facturacion_publico'],
                'activa' => $feria['deleted_at'] === null,
                'created_at' => $feria['created_at'],
                'updated_at' => $feria['updated_at'],
                'deleted_at' => $feria['deleted_at'],
            ];
        }

        $consecutivos = array_map(function (array $feria): array {
            return [
                'feria_id' => $feria['id'],
                'ultimo_consecutivo' => (int) $feria['consecutivo_actual'],
                'created_at' => $feria['created_at'],
                'updated_at' => $feria['updated_at'],
            ];
        }, $legacyFerias);

        $this->upsert('ferias', $ferias, ['id']);
        $this->upsert('consecutivos_feria', $consecutivos, ['feria_id']);

        $this->syncSequence('ferias');
        $this->syncSequence('consecutivos_feria');
    }

    /**
     * @param  list<array<string, int|string|null>>  $legacyParticipantes
     */
    private function importParticipantes(array $legacyParticipantes): void
    {
        $usedIdentifiers = DB::table('participantes')
            ->select(['id', 'numero_identificacion'])
            ->get()
            ->filter(fn (object $participante): bool => $participante->numero_identificacion !== null)
            ->mapWithKeys(fn (object $participante): array => [$participante->numero_identificacion => (int) $participante->id])
            ->all();

        $participantes = [];

        foreach ($legacyParticipantes as $participante) {
            $legacyId = (int) $participante['id'];
            $numeroIdentificacion = $this->resolveUniqueIdentifier(
                $this->nullableString($participante['identification_number']) ?? "legacy-participante-{$legacyId}",
                $legacyId,
                50,
                $usedIdentifiers
            );

            $participantes[] = [
                'id' => $legacyId,
                'nombre' => $participante['name'],
                'tipo_identificacion' => $this->mapTipoIdentificacion($participante['identification_type']),
                'numero_identificacion' => $numeroIdentificacion,
                'correo_electronico' => $this->nullableString($participante['email']),
                'numero_carne' => $this->nullableString($participante['card_number']),
                'fecha_emision_carne' => null,
                'fecha_vencimiento_carne' => null,
                'procedencia' => $this->nullableString($participante['origin']),
                'telefono' => $this->nullableString($participante['phone']),
                'tipo_sangre' => $this->nullableString($participante['blood_type']),
                'padecimientos' => $this->nullableString($participante['medical_conditions']),
                'contacto_emergencia_nombre' => $this->nullableString($participante['emergency_contact_name']),
                'contacto_emergencia_telefono' => $this->nullableString($participante['emergency_contact_phone']),
                'activo' => $participante['deleted_at'] === null,
                'created_at' => $participante['created_at'],
                'updated_at' => $participante['updated_at'],
                'deleted_at' => $participante['deleted_at'],
            ];
        }

        $this->upsert('participantes', $participantes, ['id']);
        $this->syncSequence('participantes');
    }

    /**
     * @param  list<array<string, int|string|null>>  $legacyFeriaParticipante
     */
    private function importFeriaParticipante(array $legacyFeriaParticipante): void
    {
        $rows = array_map(function (array $row): array {
            return [
                'feria_id' => $row['feria_id'],
                'participante_id' => $row['participant_id'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
            ];
        }, $legacyFeriaParticipante);

        $feriaIds = array_values(array_unique(array_map(
            static fn (array $row): int => (int) $row['feria_id'],
            $rows
        )));

        if ($feriaIds !== []) {
            DB::table('feria_participante')
                ->whereIn('feria_id', $feriaIds)
                ->delete();
        }

        if ($rows !== []) {
            DB::table('feria_participante')->insert($rows);
        }
    }

    /**
     * @param  list<array<string, int|string|null>>  $legacyProductos
     */
    private function importProductos(array $legacyProductos): void
    {
        $usedCodes = DB::table('productos')
            ->select(['id', 'codigo'])
            ->get()
            ->filter(fn (object $producto): bool => $producto->codigo !== null)
            ->mapWithKeys(fn (object $producto): array => [$producto->codigo => (int) $producto->id])
            ->all();

        $productos = [];

        foreach ($legacyProductos as $producto) {
            $legacyId = (int) $producto['id'];

            $productos[] = [
                'id' => $legacyId,
                'codigo' => $this->resolveUniqueIdentifier((string) $producto['codigo'], $legacyId, 20, $usedCodes),
                'descripcion' => $producto['descripcion'],
                'activo' => $producto['deleted_at'] === null,
                'created_at' => $producto['created_at'],
                'updated_at' => $producto['updated_at'],
                'deleted_at' => $producto['deleted_at'],
            ];
        }

        $this->upsert('productos', $productos, ['id']);
        $this->syncSequence('productos');
    }

    /**
     * @param  list<array<string, int|string|null>>  $legacyProductoPrecios
     */
    private function importProductoPrecios(array $legacyProductoPrecios): void
    {
        $precios = array_map(function (array $precio): array {
            return [
                'producto_id' => $precio['facturacion_producto_id'],
                'feria_id' => $precio['feria_id'],
                'precio' => $precio['precio'],
                'created_at' => $precio['created_at'],
                'updated_at' => $precio['updated_at'],
            ];
        }, $legacyProductoPrecios);

        $productoIds = array_values(array_unique(array_map(
            static fn (array $precio): int => (int) $precio['producto_id'],
            $precios
        )));

        if ($productoIds !== []) {
            DB::table('producto_precios')
                ->whereIn('producto_id', $productoIds)
                ->delete();
        }

        if ($precios !== []) {
            DB::table('producto_precios')->insert($precios);
        }
    }

    /**
     * @param  list<array<string, int|string|null>>  $legacyUsers
     * @param  list<array<string, int|string|null>>  $legacyRoles
     */
    private function importUsers(array $legacyUsers, array $legacyRoles): void
    {
        app(RolesAndPermissionsSeeder::class)->run();

        $users = array_map(function (array $user): array {
            return [
                'id' => $user['id'],
                'name' => $user['name'],
                'email' => $this->normalizeEmail($user['email']),
                'email_verified_at' => $user['email_verified_at'],
                'password' => $user['password'],
                'remember_token' => $user['remember_token'],
                'activo' => (bool) $user['active'],
                'created_at' => $user['created_at'],
                'updated_at' => $user['updated_at'],
                'deleted_at' => null,
            ];
        }, $legacyUsers);

        $this->upsert('users', $users, ['id']);
        $this->syncSequence('users');

        $rolesById = [];

        foreach ($legacyRoles as $role) {
            $mappedRole = $this->mapLegacyRole($role);

            if ($mappedRole !== null) {
                $rolesById[(int) $role['id']] = $mappedRole;
            }
        }

        /** @var array<int, array<string, int|string|null>> $legacyUsersById */
        $legacyUsersById = [];

        foreach ($legacyUsers as $legacyUser) {
            $legacyUsersById[(int) $legacyUser['id']] = $legacyUser;
        }

        User::query()
            ->whereIn('id', array_keys($legacyUsersById))
            ->get()
            ->each(function (User $user) use ($legacyUsersById, $rolesById): void {
                $legacyUser = $legacyUsersById[$user->id];
                $roleId = $legacyUser['role_id'];

                if (! is_int($roleId) || ! array_key_exists($roleId, $rolesById)) {
                    return;
                }

                $user->syncRoles([$rolesById[$roleId]]);
            });
    }

    /**
     * @param  list<array<string, mixed>>  $rows
     * @param  list<string>  $uniqueBy
     */
    private function upsert(string $table, array $rows, array $uniqueBy): void
    {
        if ($rows === []) {
            return;
        }

        $updateColumns = array_values(array_filter(
            array_keys($rows[0]),
            static fn (string $column): bool => ! in_array($column, $uniqueBy, true)
        ));

        DB::table($table)->upsert($rows, $uniqueBy, $updateColumns);
    }

    private function syncSequence(string $table): void
    {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, 'id')) {
            return;
        }

        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            DB::statement(
                "SELECT setval(pg_get_serial_sequence('{$table}', 'id'), COALESCE((SELECT MAX(id) FROM {$table}), 1), (SELECT COUNT(*) > 0 FROM {$table}))"
            );
        }
    }

    private function mapTipoIdentificacion(int|string|null $value): string
    {
        return match ($value) {
            'Física' => 'fisica',
            'Jurídica' => 'juridica',
            'DIMEX' => 'dimex',
            'NITE' => 'nite',
            default => 'fisica',
        };
    }

    /**
     * @param  array<string, int|string|null>  $role
     */
    private function mapLegacyRole(array $role): ?string
    {
        return match ($role['slug']) {
            'administradores' => 'administrador',
            'supervisores' => 'supervisor',
            'inspectores' => 'inspector',
            'facturadores' => 'facturador',
            default => null,
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

    private function normalizeEmail(int|string|null $value): ?string
    {
        $email = $this->nullableString($value);

        return $email === null ? null : mb_strtolower($email);
    }

    /**
     * @param  array<string, int>  $usedIdentifiers
     */
    private function resolveUniqueIdentifier(string $value, int $legacyId, int $maxLength, array &$usedIdentifiers): string
    {
        $candidate = mb_substr($value, 0, $maxLength);

        if (! array_key_exists($candidate, $usedIdentifiers) || $usedIdentifiers[$candidate] === $legacyId) {
            $usedIdentifiers[$candidate] = $legacyId;

            return $candidate;
        }

        $suffix = "-legacy-{$legacyId}";
        $baseLength = max($maxLength - mb_strlen($suffix), 1);
        $base = mb_substr($candidate, 0, $baseLength);
        $counter = 0;

        do {
            $counterSuffix = $counter === 0 ? $suffix : "{$suffix}-{$counter}";
            $adjustedBaseLength = max($maxLength - mb_strlen($counterSuffix), 1);
            $resolved = mb_substr($base, 0, $adjustedBaseLength).$counterSuffix;
            $counter++;
        } while (array_key_exists($resolved, $usedIdentifiers) && $usedIdentifiers[$resolved] !== $legacyId);

        $usedIdentifiers[$resolved] = $legacyId;

        return $resolved;
    }
}
