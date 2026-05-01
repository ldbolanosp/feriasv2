<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ParticipanteResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nombre' => $this->nombre,
            'tipo_identificacion' => $this->tipo_identificacion,
            'numero_identificacion' => $this->numero_identificacion,
            'correo_electronico' => $this->correo_electronico,
            'numero_carne' => $this->numero_carne,
            'fecha_emision_carne' => $this->fecha_emision_carne?->toDateString(),
            'fecha_vencimiento_carne' => $this->fecha_vencimiento_carne?->toDateString(),
            'procedencia' => $this->procedencia,
            'telefono' => $this->telefono,
            'tipo_sangre' => $this->tipo_sangre,
            'padecimientos' => $this->padecimientos,
            'contacto_emergencia_nombre' => $this->contacto_emergencia_nombre,
            'contacto_emergencia_telefono' => $this->contacto_emergencia_telefono,
            'activo' => $this->activo,
            'ferias' => FeriaResource::collection($this->whenLoaded('ferias')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
