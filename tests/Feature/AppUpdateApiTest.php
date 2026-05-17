<?php

use App\Models\AppRelease;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

use function Pest\Laravel\getJson;
use function Pest\Laravel\patchJson;

uses(RefreshDatabase::class);

it('returns the latest available app update for android', function (): void {
    Storage::disk('local')->put('releases/ferias-app-v1.0.2.apk', 'apk-content');

    AppRelease::query()->create([
        'platform' => 'android',
        'channel' => 'stable',
        'version_name' => '1.0.2',
        'version_code' => 2,
        'min_supported_version_code' => 1,
        'storage_disk' => 'local',
        'storage_path' => 'releases/ferias-app-v1.0.2.apk',
        'file_name' => 'ferias-app-v1.0.2.apk',
        'file_size_bytes' => 12,
        'release_notes' => 'Mejoras de impresion para iMin.',
        'is_mandatory' => false,
        'is_active' => true,
        'published_at' => now()->subMinute(),
    ]);

    Sanctum::actingAs(User::factory()->create());

    getJson('/api/v1/auth/app-update?platform=android&channel=stable&current_version=1.0.0&current_build_number=1')
        ->assertOk()
        ->assertJsonPath('update_available', true)
        ->assertJsonPath('required', false)
        ->assertJsonPath('release.version_name', '1.0.2')
        ->assertJsonPath('release.version_code', 2);
});

it('returns no update when the installed build is already the latest', function (): void {
    Storage::disk('local')->put('releases/ferias-app-v1.0.2.apk', 'apk-content');

    AppRelease::query()->create([
        'platform' => 'android',
        'channel' => 'stable',
        'version_name' => '1.0.2',
        'version_code' => 2,
        'storage_disk' => 'local',
        'storage_path' => 'releases/ferias-app-v1.0.2.apk',
        'file_name' => 'ferias-app-v1.0.2.apk',
        'is_active' => true,
        'published_at' => now()->subMinute(),
    ]);

    Sanctum::actingAs(User::factory()->create());

    getJson('/api/v1/auth/app-update?platform=android&current_build_number=2')
        ->assertOk()
        ->assertJsonPath('update_available', false)
        ->assertJsonPath('current_build_number', 2);
});

it('allows the authorized email to upload and publish an app release', function (): void {
    Storage::fake('local');

    Sanctum::actingAs(User::factory()->create([
        'email' => 'ldbolanosp@gmail.com',
    ]));

    $apkFile = UploadedFile::fake()->create(
        'ferias-app.apk',
        1024,
        'application/vnd.android.package-archive',
    );

    $response = $this->postJson('/api/v1/auth/app-releases', [
        'platform' => 'android',
        'channel' => 'stable',
        'version_name' => '1.1.0',
        'version_code' => 10,
        'min_supported_version_code' => 8,
        'release_notes' => 'Release de prueba',
        'is_mandatory' => true,
        'apk_file' => $apkFile,
    ]);

    $response
        ->assertCreated()
        ->assertJsonPath('data.version_name', '1.1.0')
        ->assertJsonPath('data.version_code', 10);

    $release = AppRelease::query()->firstOrFail();

    expect($release->is_active)->toBeTrue()
        ->and($release->is_mandatory)->toBeTrue()
        ->and($release->storage_disk)->toBe('local');

    Storage::disk('local')->assertExists($release->storage_path);
});

it('forbids uploading an app release for any other email', function (): void {
    Sanctum::actingAs(User::factory()->create([
        'email' => 'otro@example.com',
    ]));

    $apkFile = UploadedFile::fake()->create(
        'ferias-app.apk',
        1024,
        'application/vnd.android.package-archive',
    );

    $this->postJson('/api/v1/auth/app-releases', [
        'platform' => 'android',
        'version_name' => '1.1.0',
        'version_code' => 10,
        'apk_file' => $apkFile,
    ])->assertForbidden();
});

it('lists published app releases for the authorized email', function (): void {
    AppRelease::query()->create([
        'platform' => 'android',
        'channel' => 'stable',
        'version_name' => '1.1.0',
        'version_code' => 10,
        'storage_disk' => 'local',
        'storage_path' => 'app-releases/android/stable/a.apk',
        'file_name' => 'a.apk',
        'is_active' => true,
        'published_at' => now()->subMinute(),
    ]);

    Sanctum::actingAs(User::factory()->create([
        'email' => 'ldbolanosp@gmail.com',
    ]));

    getJson('/api/v1/auth/app-releases')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.version_name', '1.1.0');
});

it('allows the authorized email to deactivate a release', function (): void {
    $release = AppRelease::query()->create([
        'platform' => 'android',
        'channel' => 'stable',
        'version_name' => '1.1.0',
        'version_code' => 10,
        'storage_disk' => 'local',
        'storage_path' => 'app-releases/android/stable/a.apk',
        'file_name' => 'a.apk',
        'is_active' => true,
        'published_at' => now()->subMinute(),
    ]);

    Sanctum::actingAs(User::factory()->create([
        'email' => 'ldbolanosp@gmail.com',
    ]));

    patchJson("/api/v1/auth/app-releases/{$release->id}/deactivate")
        ->assertOk()
        ->assertJsonPath('data.is_active', false);

    expect($release->fresh()->is_active)->toBeFalse();
});
