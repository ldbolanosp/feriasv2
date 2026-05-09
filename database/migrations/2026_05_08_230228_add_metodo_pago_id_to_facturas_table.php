<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $metodoPagoId = (int) DB::table('metodo_pagos')
            ->where('nombre', 'Efectivo')
            ->value('id');

        Schema::table('facturas', function (Blueprint $table) use ($metodoPagoId): void {
            $table->foreignId('metodo_pago_id')
                ->after('user_id')
                ->default($metodoPagoId)
                ->constrained('metodo_pagos')
                ->restrictOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('facturas', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('metodo_pago_id');
        });
    }
};
