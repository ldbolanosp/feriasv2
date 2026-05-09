<?php

namespace App\Models;

use Database\Factories\MetodoPagoFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MetodoPago extends Model
{
    /** @use HasFactory<MetodoPagoFactory> */
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'nombre',
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

    public function facturas(): HasMany
    {
        return $this->hasMany(Factura::class);
    }
}
