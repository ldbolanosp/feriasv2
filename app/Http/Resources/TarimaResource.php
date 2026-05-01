<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TarimaResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'feria_id' => $this->feria_id,
            'user_id' => $this->user_id,
            'participante_id' => $this->participante_id,
            'numero_tarima' => $this->numero_tarima,
            'cantidad' => $this->cantidad,
            'precio_unitario' => $this->precio_unitario,
            'total' => $this->total,
            'estado' => $this->estado,
            'estado_label' => match ($this->estado) {
                'facturado' => 'Facturado',
                'cancelado' => 'Cancelado',
                default => ucfirst((string) $this->estado),
            },
            'observaciones' => $this->observaciones,
            'pdf_path' => $this->pdf_path,
            'feria' => $this->whenLoaded('feria', fn (): array => [
                'id' => $this->feria->id,
                'codigo' => $this->feria->codigo,
                'descripcion' => $this->feria->descripcion,
            ]),
            'usuario' => $this->whenLoaded('usuario', fn (): ?array => $this->usuario ? [
                'id' => $this->usuario->id,
                'name' => $this->usuario->name,
                'email' => $this->usuario->email,
            ] : null),
            'participante' => $this->whenLoaded('participante', fn (): ?array => $this->participante ? [
                'id' => $this->participante->id,
                'nombre' => $this->participante->nombre,
                'numero_identificacion' => $this->participante->numero_identificacion,
            ] : null),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
