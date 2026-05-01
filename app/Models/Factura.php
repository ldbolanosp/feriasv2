<?php

namespace App\Models;

use App\Enums\EstadoFactura;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Factura extends Model
{
    use HasFactory, SoftDeletes;

    /** @var list<string> */
    protected $fillable = [
        'feria_id',
        'participante_id',
        'user_id',
        'consecutivo',
        'es_publico_general',
        'nombre_publico',
        'tipo_puesto',
        'numero_puesto',
        'subtotal',
        'monto_pago',
        'monto_cambio',
        'observaciones',
        'estado',
        'fecha_emision',
        'pdf_path',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'estado' => EstadoFactura::class,
            'es_publico_general' => 'boolean',
            'subtotal' => 'decimal:2',
            'monto_pago' => 'decimal:2',
            'monto_cambio' => 'decimal:2',
            'fecha_emision' => 'datetime',
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

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function detalles(): HasMany
    {
        return $this->hasMany(FacturaDetalle::class);
    }

    /** @param Builder<Factura> $query */
    public function scopePorFeria(Builder $query, int $feriaId): void
    {
        $query->where('feria_id', $feriaId);
    }

    /** @param Builder<Factura> $query */
    public function scopePorUsuario(Builder $query, int $userId): void
    {
        $query->where('user_id', $userId);
    }

    /** @param Builder<Factura> $query */
    public function scopePorEstado(Builder $query, EstadoFactura $estado): void
    {
        $query->where('estado', $estado);
    }
}
