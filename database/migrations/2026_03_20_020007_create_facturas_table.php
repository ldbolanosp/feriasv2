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
        Schema::create('facturas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('feria_id')->constrained('ferias')->restrictOnDelete();
            $table->foreignId('participante_id')->nullable()->constrained('participantes')->restrictOnDelete();
            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $table->string('consecutivo', 20)->nullable();
            $table->boolean('es_publico_general')->default(false);
            $table->string('nombre_publico')->nullable();
            $table->string('tipo_puesto', 100)->nullable();
            $table->string('numero_puesto', 50)->nullable();
            $table->decimal('subtotal', 12, 2)->default(0);
            $table->decimal('monto_pago', 12, 2)->nullable();
            $table->decimal('monto_cambio', 12, 2)->nullable();
            $table->text('observaciones')->nullable();
            $table->string('estado', 20)->default('borrador');
            $table->timestamp('fecha_emision')->nullable();
            $table->string('pdf_path', 500)->nullable();
            $table->timestamps();
            $table->softDeletes();

        });

        // Partial unique index: consecutivo must be unique only when not null (PostgreSQL)
        DB::statement('CREATE UNIQUE INDEX facturas_consecutivo_unique ON facturas (consecutivo) WHERE consecutivo IS NOT NULL');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('facturas');
    }
};
