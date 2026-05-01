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
        Schema::create('sanitarios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('feria_id')->constrained('ferias')->restrictOnDelete();
            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('participante_id')->nullable()->constrained('participantes')->restrictOnDelete();
            $table->integer('cantidad')->default(1);
            $table->decimal('precio_unitario', 12, 2);
            $table->decimal('total', 12, 2);
            $table->string('estado', 20)->default('facturado');
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
        Schema::dropIfExists('sanitarios');
    }
};
