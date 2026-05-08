<?php

namespace App\Console\Commands;

use App\Services\Legacy\LegacyParkingImporter;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Throwable;

#[Signature('app:import-legacy-parkings {path? : Ruta al SQL dump legado} {--feria=LA VILLA : Codigo de feria destino} {--tarifa=700 : Tarifa fija a aplicar} {--replace-current : Borra parqueos actuales antes de importar}')]
#[Description('Importa parqueos desde el dump legacy')]
class ImportLegacyParkings extends Command
{
    public function __construct(private LegacyParkingImporter $importer)
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $path = (string) ($this->argument('path') ?: base_path('feriasdump.sql'));
        $feriaCode = (string) $this->option('feria');
        $tarifa = (string) $this->option('tarifa');
        $replaceCurrent = (bool) $this->option('replace-current');
        $currentCount = $this->importer->currentParkingCount();

        if ($currentCount > 0 && ! $replaceCurrent) {
            $this->components->error("La base actual ya tiene {$currentCount} parqueos. Usa --replace-current para reemplazarlos.");

            return self::FAILURE;
        }

        $this->components->info("Importando parqueos legacy desde: {$path}");

        try {
            $summary = $this->importer->import($path, $feriaCode, $tarifa, $replaceCurrent);
        } catch (Throwable $exception) {
            $this->components->error($exception->getMessage());

            return self::FAILURE;
        }

        $this->newLine();
        $this->components->info('Importacion de parqueos completada.');
        $this->table(
            ['Entidad', 'Registros'],
            collect($summary)
                ->map(fn (int $count, string $entity): array => [$entity, $count])
                ->values()
                ->all()
        );

        return self::SUCCESS;
    }
}
