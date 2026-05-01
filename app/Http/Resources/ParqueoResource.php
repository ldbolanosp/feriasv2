<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ParqueoResource extends JsonResource
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
            'placa' => $this->placa,
            'fecha_hora_ingreso' => $this->fecha_hora_ingreso?->toIso8601String(),
            'fecha_hora_salida' => $this->fecha_hora_salida?->toIso8601String(),
            'tarifa' => $this->tarifa,
            'tarifa_tipo' => $this->tarifa_tipo->value,
            'tarifa_tipo_label' => $this->tarifa_tipo->label(),
            'estado' => $this->estado->value,
            'estado_label' => $this->estado->label(),
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
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
