<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'codigo' => $this->codigo,
            'descripcion' => $this->descripcion,
            'activo' => $this->activo,
            'precios_count' => $this->precios_count ?? ($this->relationLoaded('precios') ? $this->precios->count() : 0),
            'precio_feria_actual' => $this->when(isset($this->precio_feria_actual), (float) $this->precio_feria_actual),
            'precios' => $this->whenLoaded('precios', function (): array {
                return $this->precios
                    ->map(fn ($precio): array => [
                        'id' => $precio->id,
                        'feria_id' => $precio->feria_id,
                        'precio' => $precio->precio,
                        'feria' => $precio->relationLoaded('feria') && $precio->feria
                            ? [
                                'id' => $precio->feria->id,
                                'codigo' => $precio->feria->codigo,
                                'descripcion' => $precio->feria->descripcion,
                            ]
                            : null,
                        'created_at' => $precio->created_at,
                        'updated_at' => $precio->updated_at,
                    ])
                    ->values()
                    ->all();
            }, []),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
