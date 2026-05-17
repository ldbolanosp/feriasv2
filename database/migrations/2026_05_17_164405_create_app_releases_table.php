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
        Schema::create('app_releases', function (Blueprint $table) {
            $table->id();
            $table->string('platform', 20);
            $table->string('channel', 30)->default('stable');
            $table->string('version_name', 40);
            $table->unsignedInteger('version_code');
            $table->unsignedInteger('min_supported_version_code')->nullable();
            $table->string('storage_disk', 50)->default('s3');
            $table->string('storage_path', 500);
            $table->string('file_name', 255);
            $table->unsignedBigInteger('file_size_bytes')->nullable();
            $table->string('checksum_sha256', 64)->nullable();
            $table->text('release_notes')->nullable();
            $table->boolean('is_mandatory')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index(['platform', 'channel', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('app_releases');
    }
};
