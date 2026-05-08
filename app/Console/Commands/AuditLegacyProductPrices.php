<?php

namespace App\Console\Commands;

use App\Services\Legacy\LegacySqlDumpParser;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

#[Signature('app:audit-legacy-product-prices {path? : Ruta al SQL dump legado} {--limit=20 : Cantidad maxima de productos con diferencias a mostrar}')]
#[Description('Compara los precios de productos importados contra el pivot legacy del dump SQL')]
class AuditLegacyProductPrices extends Command
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
        $limit = max((int) $this->option('limit'), 1);

        $legacyRows = $this->parser->parseTable($path, 'feria_facturacion_producto');
        $legacyPrices = [];

        foreach ($legacyRows as $row) {
            $legacyPrices[(int) $row['facturacion_producto_id']][(int) $row['feria_id']] = number_format((float) $row['precio'], 2, '.', '');
        }

        $currentRows = DB::table('producto_precios')
            ->select(['producto_id', 'feria_id', 'precio'])
            ->get();

        $currentPrices = [];

        foreach ($currentRows as $row) {
            $currentPrices[(int) $row->producto_id][(int) $row->feria_id] = number_format((float) $row->precio, 2, '.', '');
        }

        $productos = DB::table('productos')
            ->select(['id', 'codigo', 'descripcion'])
            ->orderBy('id')
            ->get()
            ->keyBy('id');

        $issues = [];
        $productIds = array_unique(array_merge(array_keys($legacyPrices), array_keys($currentPrices)));
        sort($productIds);

        foreach ($productIds as $productId) {
            $legacy = $legacyPrices[$productId] ?? [];
            $current = $currentPrices[$productId] ?? [];

            ksort($legacy);
            ksort($current);

            $extras = array_diff_key($current, $legacy);
            $missing = array_diff_key($legacy, $current);
            $mismatched = [];

            foreach ($legacy as $feriaId => $legacyPrice) {
                if (array_key_exists($feriaId, $current) && $current[$feriaId] !== $legacyPrice) {
                    $mismatched[$feriaId] = "legacy={$legacyPrice}, actual={$current[$feriaId]}";
                }
            }

            if ($extras === [] && $missing === [] && $mismatched === []) {
                continue;
            }

            $producto = $productos->get($productId);

            $issues[] = [
                'producto_id' => (string) $productId,
                'codigo' => (string) ($producto->codigo ?? 'N/D'),
                'legacy' => (string) count($legacy),
                'actual' => (string) count($current),
                'extras' => $this->formatFeriaPriceMap($extras),
                'faltantes' => $this->formatFeriaPriceMap($missing),
                'distintos' => implode('; ', array_map(
                    static fn (int $feriaId, string $values): string => "{$feriaId}:{$values}",
                    array_keys($mismatched),
                    array_values($mismatched)
                )),
            ];
        }

        $this->components->info('Auditoria completada.');
        $this->line('Productos con diferencias: '.count($issues));

        if ($issues !== []) {
            $this->table(
                ['Producto ID', 'Codigo', 'Legacy', 'Actual', 'Extras', 'Faltantes', 'Distintos'],
                array_slice($issues, 0, $limit)
            );
        }

        return self::SUCCESS;
    }

    /**
     * @param  array<int, string>  $map
     */
    private function formatFeriaPriceMap(array $map): string
    {
        if ($map === []) {
            return '';
        }

        ksort($map);

        return implode(', ', array_map(
            static fn (int $feriaId, string $precio): string => "{$feriaId}:{$precio}",
            array_keys($map),
            array_values($map)
        ));
    }
}
