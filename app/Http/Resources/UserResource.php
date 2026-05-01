<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $roles = $this->relationLoaded('roles')
            ? $this->roles->pluck('name')->values()->all()
            : $this->getRoleNames()->values()->all();

        $permissions = $this->relationLoaded('permissions')
            ? $this->permissions->pluck('name')->values()->all()
            : $this->getAllPermissions()->pluck('name')->values()->all();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'activo' => $this->activo,
            'role' => $roles[0] ?? null,
            'roles' => $roles,
            'permisos' => $permissions,
            'ferias_count' => $this->ferias_count ?? ($this->relationLoaded('ferias') ? $this->ferias->count() : 0),
            'ferias' => FeriaResource::collection($this->whenLoaded('ferias')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'deleted_at' => $this->deleted_at,
        ];
    }
}
