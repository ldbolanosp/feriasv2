<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Configuracion extends Model
{
    use HasFactory;

    protected $table = 'configuraciones';

    /** @var list<string> */
    protected $fillable = [
        'feria_id',
        'clave',
        'valor',
        'descripcion',
    ];

    public function feria(): BelongsTo
    {
        return $this->belongsTo(Feria::class);
    }
}
