<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InspeccionItem extends Model
{
    /** @use HasFactory<\Database\Factories\InspeccionItemFactory> */
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'inspeccion_id',
        'item_diagnostico_id',
        'nombre_item',
        'cumple',
        'observaciones',
        'orden',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'cumple' => 'boolean',
            'orden' => 'integer',
        ];
    }

    public function inspeccion(): BelongsTo
    {
        return $this->belongsTo(Inspeccion::class);
    }

    public function itemDiagnostico(): BelongsTo
    {
        return $this->belongsTo(ItemDiagnostico::class);
    }
}
