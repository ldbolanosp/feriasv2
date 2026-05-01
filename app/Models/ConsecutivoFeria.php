<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConsecutivoFeria extends Model
{
    use HasFactory;

    protected $table = 'consecutivos_feria';

    /** @var list<string> */
    protected $fillable = [
        'feria_id',
        'ultimo_consecutivo',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'ultimo_consecutivo' => 'integer',
        ];
    }

    public function feria(): BelongsTo
    {
        return $this->belongsTo(Feria::class);
    }
}
