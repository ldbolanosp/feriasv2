<?php

namespace App\Services;

use App\Models\Factura;
use App\Models\Parqueo;
use App\Models\Sanitario;
use App\Models\Tarima;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Storage;

class PdfTicketService
{
    public function generarTicketFactura(Factura $factura): string
    {
        $factura->loadMissing(['feria', 'usuario', 'participante', 'metodoPago', 'detalles.producto']);

        return $this->renderAndStore(
            'pdf.ticket-factura',
            ['factura' => $factura],
            "tickets/{$factura->feria_id}/".now()->format('Y-m-d')."/{$factura->consecutivo}.pdf"
        );
    }

    public function generarTicketParqueo(Parqueo $parqueo): string
    {
        $parqueo->loadMissing(['feria', 'usuario']);

        return $this->renderAndStore(
            'pdf.ticket-parqueo',
            ['parqueo' => $parqueo],
            "tickets/{$parqueo->feria_id}/".now()->format('Y-m-d')."/parqueo-{$parqueo->id}.pdf"
        );
    }

    public function generarTicketTarima(Tarima $tarima): string
    {
        $tarima->loadMissing(['feria', 'usuario', 'participante']);

        return $this->renderAndStore(
            'pdf.ticket-tarima',
            ['tarima' => $tarima],
            "tickets/{$tarima->feria_id}/".now()->format('Y-m-d')."/tarima-{$tarima->id}.pdf"
        );
    }

    public function generarTicketSanitario(Sanitario $sanitario): string
    {
        $sanitario->loadMissing(['feria', 'usuario', 'participante']);

        return $this->renderAndStore(
            'pdf.ticket-sanitario',
            ['sanitario' => $sanitario],
            "tickets/{$sanitario->feria_id}/".now()->format('Y-m-d')."/sanitario-{$sanitario->id}.pdf"
        );
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function renderAndStore(string $view, array $data, string $path): string
    {
        $pdf = Pdf::loadView($view, $data)
            ->setPaper([0, 0, 226.77, 1133.86], 'portrait');

        Storage::disk('local')->put($path, $pdf->output());

        return $path;
    }
}
