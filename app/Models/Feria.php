<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Feria extends Model
{
    use HasFactory, SoftDeletes;

    /** @var list<string> */
    protected $fillable = [
        'codigo',
        'descripcion',
        'facturacion_publico',
        'activa',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'facturacion_publico' => 'boolean',
            'activa' => 'boolean',
        ];
    }

    public function usuarios(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'feria_user');
    }

    public function participantes(): BelongsToMany
    {
        return $this->belongsToMany(Participante::class, 'feria_participante');
    }

    public function facturas(): HasMany
    {
        return $this->hasMany(Factura::class);
    }

    public function productosPrecios(): HasMany
    {
        return $this->hasMany(ProductoPrecio::class);
    }

    /** @param Builder<Feria> $query */
    public function scopeActivas(Builder $query): void
    {
        $query->where('activa', true);
    }
}
