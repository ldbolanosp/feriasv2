<?php

namespace App\Console\Commands;

use App\Services\Legacy\LegacyInvoiceImporter;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Throwable;

#[Signature('app:import-legacy-invoices {path? : Ruta al SQL dump legado} {--replace-current : Borra facturas actuales antes de importar}')]
#[Description('Importa facturas y detalles desde el dump legacy')]
class ImportLegacyInvoices extends Command
{
    public function __construct(private LegacyInvoiceImporter $importer)
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $path = (string) ($this->argument('path') ?: base_path('feriasdump.sql'));
        $replaceCurrent = (bool) $this->option('replace-current');
        $currentCount = $this->importer->currentInvoiceCount();

        if ($currentCount > 0 && ! $replaceCurrent) {
            $this->components->error("La base actual ya tiene {$currentCount} facturas. Usa --replace-current para reemplazarlas.");

            return self::FAILURE;
        }

        $this->components->info("Importando facturas legacy desde: {$path}");

        try {
            $summary = $this->importer->import($path, $replaceCurrent);
        } catch (Throwable $exception) {
            $this->components->error($exception->getMessage());

            return self::FAILURE;
        }

        $this->newLine();
        $this->components->info('Importacion de facturas completada.');
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
