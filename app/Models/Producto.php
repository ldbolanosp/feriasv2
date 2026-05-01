<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Producto extends Model
{
    use HasFactory, SoftDeletes;

    /** @var list<string> */
    protected $fillable = [
        'codigo',
        'descripcion',
        'activo',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'activo' => 'boolean',
        ];
    }

    public function precios(): HasMany
    {
        return $this->hasMany(ProductoPrecio::class);
    }

    public function ferias(): BelongsToMany
    {
        return $this->belongsToMany(Feria::class, 'producto_precios')
            ->withPivot('precio')
            ->withTimestamps();
    }

    public function facturaDetalles(): HasMany
    {
        return $this->hasMany(FacturaDetalle::class);
    }

    /** @param Builder<Producto> $query */
    public function scopeActivos(Builder $query): void
    {
        $query->where('activo', true);
    }

    /** @param Builder<Producto> $query */
    public function scopeConPrecioEnFeria(Builder $query, int $feriaId): void
    {
        $query->whereHas('precios', fn (Builder $q) => $q->where('feria_id', $feriaId));
    }
}
