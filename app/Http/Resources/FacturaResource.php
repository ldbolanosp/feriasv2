<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FacturaResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'feria_id' => $this->feria_id,
            'participante_id' => $this->participante_id,
            'user_id' => $this->user_id,
            'consecutivo' => $this->consecutivo,
            'es_publico_general' => $this->es_publico_general,
            'nombre_publico' => $this->nombre_publico,
            'tipo_puesto' => $this->tipo_puesto,
            'numero_puesto' => $this->numero_puesto,
            'subtotal' => $this->subtotal,
            'monto_pago' => $this->monto_pago,
            'monto_cambio' => $this->monto_cambio,
            'observaciones' => $this->observaciones,
            'estado' => $this->estado->value,
            'estado_label' => $this->estado->label(),
            'fecha_emision' => $this->fecha_emision?->toIso8601String(),
            'pdf_path' => $this->pdf_path,
            'detalles_count' => $this->detalles_count ?? ($this->relationLoaded('detalles') ? $this->detalles->count() : 0),
            'feria' => $this->whenLoaded('feria', fn (): array => [
                'id' => $this->feria->id,
                'codigo' => $this->feria->codigo,
                'descripcion' => $this->feria->descripcion,
                'facturacion_publico' => $this->feria->facturacion_publico,
            ]),
            'participante' => $this->whenLoaded('participante', fn (): ?array => $this->participante ? [
                'id' => $this->participante->id,
                'nombre' => $this->participante->nombre,
                'numero_identificacion' => $this->participante->numero_identificacion,
            ] : null),
            'usuario' => $this->whenLoaded('usuario', fn (): ?array => $this->usuario ? [
                'id' => $this->usuario->id,
                'name' => $this->usuario->name,
                'email' => $this->usuario->email,
            ] : null),
            'detalles' => $this->whenLoaded('detalles', function (): array {
                return $this->detalles->map(function ($detalle): array {
                    return [
                        'id' => $detalle->id,
                        'producto_id' => $detalle->producto_id,
                        'descripcion_producto' => $detalle->descripcion_producto,
                        'cantidad' => $detalle->cantidad,
                        'precio_unitario' => $detalle->precio_unitario,
                        'subtotal_linea' => $detalle->subtotal_linea,
                        'producto' => $detalle->relationLoaded('producto') && $detalle->producto
                            ? [
                                'id' => $detalle->producto->id,
                                'codigo' => $detalle->producto->codigo,
                                'descripcion' => $detalle->producto->descripcion,
                            ]
                            : null,
                    ];
                })->values()->all();
            }, []),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'deleted_at' => $this->deleted_at?->toIso8601String(),
        ];
    }
}
