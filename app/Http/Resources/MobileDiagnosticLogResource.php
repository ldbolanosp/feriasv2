<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MobileDiagnosticLogResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'feria_id' => $this->feria_id,
            'session_id' => $this->session_id,
            'trigger' => $this->trigger,
            'platform' => $this->platform,
            'app_version' => $this->app_version,
            'device_name' => $this->device_name,
            'current_route' => $this->current_route,
            'summary' => $this->summary,
            'event_count' => $this->event_count,
            'last_event_at' => $this->last_event_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'user' => $this->whenLoaded('user', fn (): array => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'email' => $this->user->email,
            ]),
            'feria' => $this->whenLoaded('feria', fn (): array => [
                'id' => $this->feria->id,
                'codigo' => $this->feria->codigo,
                'descripcion' => $this->feria->descripcion,
            ]),
            'payload' => $this->payload,
        ];
    }
}
