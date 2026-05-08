<?php

namespace App\Console\Commands;

use App\Services\Legacy\LegacyCatalogImporter;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Throwable;

#[Signature('app:import-legacy-catalog-data {path? : Ruta al SQL dump legado}')]
#[Description('Importa ferias, participantes, productos, precios y usuarios desde el dump legado')]
class ImportLegacyCatalogData extends Command
{
    public function __construct(private LegacyCatalogImporter $importer)
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $path = (string) ($this->argument('path') ?: base_path('feriasdump.sql'));

        $this->components->info("Importando catalogos legacy desde: {$path}");

        try {
            $summary = $this->importer->import($path);
        } catch (Throwable $exception) {
            $this->components->error($exception->getMessage());

            return self::FAILURE;
        }

        $this->newLine();
        $this->components->info('Importacion completada.');
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
