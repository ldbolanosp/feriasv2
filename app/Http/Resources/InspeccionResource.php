<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InspeccionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'feria_id' => $this->feria_id,
            'participante_id' => $this->participante_id,
            'reinspeccion_de_id' => $this->reinspeccion_de_id,
            'total_items' => $this->total_items,
            'total_incumplidos' => $this->total_incumplidos,
            'es_reinspeccion' => $this->reinspeccion_de_id !== null,
            'participante' => $this->relationLoaded('participante') && $this->participante
                ? [
                    'id' => $this->participante->id,
                    'nombre' => $this->participante->nombre,
                    'numero_identificacion' => $this->participante->numero_identificacion,
                    'numero_carne' => $this->participante->numero_carne,
                    'fecha_vencimiento_carne' => $this->participante->fecha_vencimiento_carne?->toDateString(),
                ]
                : null,
            'inspector' => $this->relationLoaded('inspector') && $this->inspector
                ? [
                    'id' => $this->inspector->id,
                    'name' => $this->inspector->name,
                    'email' => $this->inspector->email,
                ]
                : null,
            'reinspeccion_de' => $this->relationLoaded('reinspeccionDe') && $this->reinspeccionDe
                ? [
                    'id' => $this->reinspeccionDe->id,
                    'created_at' => $this->reinspeccionDe->created_at,
                    'total_incumplidos' => $this->reinspeccionDe->total_incumplidos,
                ]
                : null,
            'items' => $this->whenLoaded('items', function (): array {
                return $this->items
                    ->map(fn ($item): array => [
                        'id' => $item->id,
                        'item_diagnostico_id' => $item->item_diagnostico_id,
                        'nombre_item' => $item->nombre_item,
                        'cumple' => $item->cumple,
                        'observaciones' => $item->observaciones,
                        'orden' => $item->orden,
                    ])
                    ->values()
                    ->all();
            }, []),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
