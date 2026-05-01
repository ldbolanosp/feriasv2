<?php

namespace App\Models;

use App\Enums\TipoIdentificacion;
use App\Enums\TipoSangre;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Participante extends Model
{
    use HasFactory, SoftDeletes;

    /** @var list<string> */
    protected $fillable = [
        'nombre',
        'tipo_identificacion',
        'numero_identificacion',
        'correo_electronico',
        'numero_carne',
        'fecha_emision_carne',
        'fecha_vencimiento_carne',
        'procedencia',
        'telefono',
        'tipo_sangre',
        'padecimientos',
        'contacto_emergencia_nombre',
        'contacto_emergencia_telefono',
        'activo',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'tipo_identificacion' => TipoIdentificacion::class,
            'tipo_sangre' => TipoSangre::class,
            'fecha_emision_carne' => 'date',
            'fecha_vencimiento_carne' => 'date',
            'activo' => 'boolean',
        ];
    }

    public function ferias(): BelongsToMany
    {
        return $this->belongsToMany(Feria::class, 'feria_participante');
    }

    public function facturas(): HasMany
    {
        return $this->hasMany(Factura::class);
    }

    public function tarimas(): HasMany
    {
        return $this->hasMany(Tarima::class);
    }

    public function inspecciones(): HasMany
    {
        return $this->hasMany(Inspeccion::class);
    }

    /** @param Builder<Participante> $query */
    public function scopeActivos(Builder $query): void
    {
        $query->where('activo', true);
    }

    /** @param Builder<Participante> $query */
    public function scopePorFeria(Builder $query, int $feriaId): void
    {
        $query->whereHas('ferias', fn (Builder $q) => $q->where('ferias.id', $feriaId));
    }
}
