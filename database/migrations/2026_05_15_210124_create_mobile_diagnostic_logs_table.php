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
        Schema::create('mobile_diagnostic_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('feria_id')->nullable()->constrained('ferias')->nullOnDelete();
            $table->string('session_id', 120);
            $table->string('trigger', 20)->default('manual');
            $table->string('platform', 40)->nullable();
            $table->string('app_version', 40)->nullable();
            $table->string('device_name', 120)->nullable();
            $table->string('current_route', 255)->nullable();
            $table->string('summary', 500)->nullable();
            $table->unsignedInteger('event_count')->default(0);
            $table->timestamp('last_event_at')->nullable();
            $table->json('payload');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mobile_diagnostic_logs');
    }
};
