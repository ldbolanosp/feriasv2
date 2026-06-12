<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('participantes', function (Blueprint $table) {
            $table->foreignId('carne_actualizado_por_user_id')
                ->nullable()
                ->after('fecha_vencimiento_carne')
                ->constrained('users')
                ->nullOnDelete();
            $table->timestamp('carne_actualizado_en')->nullable()->after('carne_actualizado_por_user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('participantes', function (Blueprint $table) {
            $table->dropConstrainedForeignId('carne_actualizado_por_user_id');
            $table->dropColumn('carne_actualizado_en');
        });
    }
};
