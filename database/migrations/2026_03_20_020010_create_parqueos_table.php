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
        Schema::create('parqueos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('feria_id')->constrained('ferias')->restrictOnDelete();
            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $table->string('placa', 20);
            $table->timestamp('fecha_hora_ingreso')->useCurrent();
            $table->timestamp('fecha_hora_salida')->nullable();
            $table->decimal('tarifa', 12, 2);
            $table->string('tarifa_tipo', 20)->default('fija');
            $table->string('estado', 20)->default('activo');
            $table->text('observaciones')->nullable();
            $table->string('pdf_path', 500)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('parqueos');
    }
};
