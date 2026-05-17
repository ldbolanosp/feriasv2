<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppRelease extends Model
{
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'platform',
        'channel',
        'version_name',
        'version_code',
        'min_supported_version_code',
        'storage_disk',
        'storage_path',
        'file_name',
        'file_size_bytes',
        'checksum_sha256',
        'release_notes',
        'is_mandatory',
        'is_active',
        'published_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'version_code' => 'integer',
            'min_supported_version_code' => 'integer',
            'file_size_bytes' => 'integer',
            'is_mandatory' => 'boolean',
            'is_active' => 'boolean',
            'published_at' => 'datetime',
        ];
    }
}
