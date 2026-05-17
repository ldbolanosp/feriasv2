<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppReleaseResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'platform' => $this->platform,
            'channel' => $this->channel,
            'version_name' => $this->version_name,
            'version_code' => $this->version_code,
            'min_supported_version_code' => $this->min_supported_version_code,
            'storage_disk' => $this->storage_disk,
            'storage_path' => $this->storage_path,
            'file_name' => $this->file_name,
            'file_size_bytes' => $this->file_size_bytes,
            'checksum_sha256' => $this->checksum_sha256,
            'release_notes' => $this->release_notes,
            'is_mandatory' => $this->is_mandatory,
            'is_active' => $this->is_active,
            'published_at' => $this->published_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
