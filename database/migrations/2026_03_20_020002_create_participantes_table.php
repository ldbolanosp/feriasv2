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
        Schema::create('participantes', function (Blueprint $table) {
            $table->id();
            $table->string('nombre');
            $table->string('tipo_identificacion', 20);
            $table->string('numero_identificacion', 50)->unique();
            $table->string('correo_electronico')->nullable();
            $table->string('numero_carne', 50)->nullable();
            $table->date('fecha_emision_carne')->nullable();
            $table->date('fecha_vencimiento_carne')->nullable();
            $table->string('procedencia')->nullable();
            $table->string('telefono', 30)->nullable();
            $table->string('tipo_sangre', 5)->nullable();
            $table->text('padecimientos')->nullable();
            $table->string('contacto_emergencia_nombre')->nullable();
            $table->string('contacto_emergencia_telefono', 30)->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('participantes');
    }
};
