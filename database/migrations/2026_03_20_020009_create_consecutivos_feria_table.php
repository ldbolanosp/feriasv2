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
        Schema::create('consecutivos_feria', function (Blueprint $table) {
            $table->id();
            $table->foreignId('feria_id')->unique()->constrained('ferias')->cascadeOnDelete();
            $table->integer('ultimo_consecutivo')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('consecutivos_feria');
    }
};
