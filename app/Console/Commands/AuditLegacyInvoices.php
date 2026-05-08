<?php

namespace App\Console\Commands;

use App\Services\Legacy\LegacySqlDumpParser;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

#[Signature('app:audit-legacy-invoices {path? : Ruta al SQL dump legado}')]
#[Description('Compara conteos y montos de facturas legacy contra la base actual')]
class AuditLegacyInvoices extends Command
{
    public function __construct(private LegacySqlDumpParser $parser)
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $path = (string) ($this->argument('path') ?: base_path('feriasdump.sql'));
        $legacyFacturas = $this->parser->parseTable($path, 'facturas');
        $legacyFacturaItems = $this->parser->parseTable($path, 'factura_items');

        $legacyTotal = array_sum(array_map(
            static fn (array $factura): float => (float) $factura['total'],
            $legacyFacturas
        ));

        $legacyDetallesTotal = array_sum(array_map(
            static fn (array $detalle): float => (float) $detalle['subtotal'],
            $legacyFacturaItems
        ));

        $currentInvoiceIds = array_map(
            static fn (array $factura): int => (int) $factura['id'],
            $legacyFacturas
        );

        $currentFacturasCount = DB::table('facturas')->whereIn('id', $currentInvoiceIds)->count();
        $currentDetallesCount = DB::table('factura_detalles')->whereIn('factura_id', $currentInvoiceIds)->count();
        $currentTotal = (float) DB::table('facturas')->whereIn('id', $currentInvoiceIds)->sum('subtotal');
        $currentDetallesTotal = (float) DB::table('factura_detalles')->whereIn('factura_id', $currentInvoiceIds)->sum('subtotal_linea');

        $this->components->info('Auditoria de facturas completada.');
        $this->table(
            ['Metrica', 'Legacy', 'Actual'],
            [
                ['Facturas', count($legacyFacturas), $currentFacturasCount],
                ['Factura Detalles', count($legacyFacturaItems), $currentDetallesCount],
                ['Total Facturas', number_format($legacyTotal, 2, '.', ''), number_format($currentTotal, 2, '.', '')],
                ['Total Detalles', number_format($legacyDetallesTotal, 2, '.', ''), number_format($currentDetallesTotal, 2, '.', '')],
            ]
        );

        return self::SUCCESS;
    }
}
