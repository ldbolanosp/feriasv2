<?php

namespace App\Models;

use App\Enums\EstadoParqueo;
use App\Enums\TarifaTipo;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Parqueo extends Model
{
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'feria_id',
        'user_id',
        'placa',
        'fecha_hora_ingreso',
        'fecha_hora_salida',
        'tarifa',
        'tarifa_tipo',
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
            'tarifa' => 'decimal:2',
            'tarifa_tipo' => TarifaTipo::class,
            'estado' => EstadoParqueo::class,
            'fecha_hora_ingreso' => 'datetime',
            'fecha_hora_salida' => 'datetime',
        ];
    }

    public function feria(): BelongsTo
    {
        return $this->belongsTo(Feria::class);
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /** @param Builder<Parqueo> $query */
    public function scopePorFeria(Builder $query, int $feriaId): void
    {
        $query->where('feria_id', $feriaId);
    }

    /** @param Builder<Parqueo> $query */
    public function scopeActivos(Builder $query): void
    {
        $query->where('estado', EstadoParqueo::Activo);
    }
}
