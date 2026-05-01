<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductoPrecio extends Model
{
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'producto_id',
        'feria_id',
        'precio',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'precio' => 'decimal:2',
        ];
    }

    public function producto(): BelongsTo
    {
        return $this->belongsTo(Producto::class);
    }

    public function feria(): BelongsTo
    {
        return $this->belongsTo(Feria::class);
    }
}
