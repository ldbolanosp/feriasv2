<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Inspeccion extends Model
{
    /** @use HasFactory<\Database\Factories\InspeccionFactory> */
    use HasFactory;

    protected $table = 'inspecciones';

    /** @var list<string> */
    protected $fillable = [
        'feria_id',
        'participante_id',
        'user_id',
        'reinspeccion_de_id',
        'total_items',
        'total_incumplidos',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'total_items' => 'integer',
            'total_incumplidos' => 'integer',
        ];
    }

    public function feria(): BelongsTo
    {
        return $this->belongsTo(Feria::class);
    }

    public function participante(): BelongsTo
    {
        return $this->belongsTo(Participante::class);
    }

    public function inspector(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function reinspeccionDe(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reinspeccion_de_id');
    }

    public function reinspecciones(): HasMany
    {
        return $this->hasMany(self::class, 'reinspeccion_de_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(InspeccionItem::class);
    }
}
