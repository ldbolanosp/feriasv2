<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Sanitario extends Model
{
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'feria_id',
        'user_id',
        'participante_id',
        'cantidad',
        'precio_unitario',
        'total',
        'estado',
        'observaciones',
        'pdf_path',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'cantidad' => 'integer',
            'precio_unitario' => 'decimal:2',
            'total' => 'decimal:2',
        ];
    }

    /** @param Builder<Sanitario> $query */
    public function scopePorFeria(Builder $query, int $feriaId): void
    {
        $query->where('feria_id', $feriaId);
    }

    public function feria(): BelongsTo
    {
        return $this->belongsTo(Feria::class);
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function participante(): BelongsTo
    {
        return $this->belongsTo(Participante::class);
    }
}
