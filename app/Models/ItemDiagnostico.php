<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ItemDiagnostico extends Model
{
    /** @use HasFactory<\Database\Factories\ItemDiagnosticoFactory> */
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'nombre',
    ];

    public function inspeccionItems(): HasMany
    {
        return $this->hasMany(InspeccionItem::class);
    }
}
