<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AppRelease\CheckAppUpdateRequest;
use App\Http\Requests\AppRelease\ManageAppReleaseRequest;
use App\Http\Requests\AppRelease\StoreAppReleaseRequest;
use App\Http\Resources\AppReleaseResource;
use App\Models\AppRelease;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AppUpdateController extends Controller
{
    private const DEFAULT_RELEASES_DISK = 'main';

    public function index(ManageAppReleaseRequest $request): AnonymousResourceCollection
    {
        $query = AppRelease::query()
            ->when($request->filled('platform'), function ($builder) use ($request): void {
                $builder->where('platform', $request->string('platform')->value());
            })
            ->orderByDesc('is_active')
            ->orderByDesc('published_at')
            ->orderByDesc('version_code');

        $perPage = min((int) ($request->per_page ?? 10), 50);

        return AppReleaseResource::collection($query->paginate($perPage));
    }

    public function store(StoreAppReleaseRequest $request): JsonResponse
    {
        /** @var UploadedFile $apkFile */
        $apkFile = $request->file('apk_file');
        $validated = $request->validated();
        $channel = $validated['channel'] ?? 'stable';
        $disk = $this->releasesDisk();
        $versionName = $validated['version_name'];
        $versionCode = (int) $validated['version_code'];
        $sanitizedVersion = Str::of($versionName)->replace([' ', '/', '\\'], '-')->value();
        $fileName = "ferias-app-v{$sanitizedVersion}-b{$versionCode}.apk";
        $storagePath = "app-releases/android/{$channel}/{$fileName}";

        $stream = fopen($apkFile->getRealPath(), 'r');
        Storage::disk($disk)->put($storagePath, $stream);
        if (is_resource($stream)) {
            fclose($stream);
        }

        $release = DB::transaction(function () use (
            $validated,
            $channel,
            $disk,
            $storagePath,
            $fileName,
            $apkFile,
            $versionCode
        ): AppRelease {
            AppRelease::query()
                ->where('platform', 'android')
                ->where('channel', $channel)
                ->update(['is_active' => false]);

            return AppRelease::query()->create([
                'platform' => 'android',
                'channel' => $channel,
                'version_name' => $validated['version_name'],
                'version_code' => $versionCode,
                'min_supported_version_code' => $validated['min_supported_version_code'] ?? null,
                'storage_disk' => $disk,
                'storage_path' => $storagePath,
                'file_name' => $fileName,
                'file_size_bytes' => $apkFile->getSize(),
                'checksum_sha256' => hash_file('sha256', $apkFile->getRealPath()),
                'release_notes' => $validated['release_notes'] ?? null,
                'is_mandatory' => (bool) ($validated['is_mandatory'] ?? false),
                'is_active' => true,
                'published_at' => now(),
            ]);
        });

        return response()->json([
            'message' => 'Release publicada correctamente.',
            'data' => [
                'id' => $release->id,
                'version_name' => $release->version_name,
                'version_code' => $release->version_code,
                'channel' => $release->channel,
                'file_name' => $release->file_name,
            ],
        ], 201);
    }

    public function deactivate(ManageAppReleaseRequest $request, AppRelease $appRelease): JsonResponse
    {
        $appRelease->update(['is_active' => false]);

        return response()->json([
            'message' => 'Release desactivada correctamente.',
            'data' => new AppReleaseResource($appRelease->fresh()),
        ]);
    }

    public function show(CheckAppUpdateRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $platform = $validated['platform'];
        $channel = $validated['channel'] ?? 'stable';
        $currentBuildNumber = (int) $validated['current_build_number'];

        $release = AppRelease::query()
            ->where('platform', $platform)
            ->where('channel', $channel)
            ->where('is_active', true)
            ->where(function ($query): void {
                $query->whereNull('published_at')
                    ->orWhere('published_at', '<=', now());
            })
            ->orderByDesc('version_code')
            ->orderByDesc('published_at')
            ->first();

        if (! $release) {
            return response()->json([
                'update_available' => false,
                'required' => false,
                'current_version' => $validated['current_version'] ?? null,
                'current_build_number' => $currentBuildNumber,
            ]);
        }

        $updateAvailable = $release->version_code > $currentBuildNumber;
        $required = $release->is_mandatory
            || ($release->min_supported_version_code !== null
                && $currentBuildNumber < $release->min_supported_version_code);

        return response()->json([
            'update_available' => $updateAvailable,
            'required' => $required && $updateAvailable,
            'current_version' => $validated['current_version'] ?? null,
            'current_build_number' => $currentBuildNumber,
            'release' => [
                'id' => $release->id,
                'platform' => $release->platform,
                'channel' => $release->channel,
                'version_name' => $release->version_name,
                'version_code' => $release->version_code,
                'min_supported_version_code' => $release->min_supported_version_code,
                'file_name' => $release->file_name,
                'file_size_bytes' => $release->file_size_bytes,
                'checksum_sha256' => $release->checksum_sha256,
                'release_notes' => $release->release_notes,
                'published_at' => $release->published_at?->toIso8601String(),
                'download_url' => $this->resolveDownloadUrl($release),
                'download_url_expires_at' => now()->addMinutes(30)->toIso8601String(),
            ],
        ]);
    }

    private function resolveDownloadUrl(AppRelease $release): string
    {
        return Storage::disk($release->storage_disk)->temporaryUrl(
            $release->storage_path,
            now()->addMinutes(30),
            [
                'ResponseContentType' => 'application/vnd.android.package-archive',
                'ResponseContentDisposition' => 'attachment; filename="'.$release->file_name.'"',
            ],
        );
    }

    private function releasesDisk(): string
    {
        $configuredDisk = (string) config('app.app_releases_disk', self::DEFAULT_RELEASES_DISK);
        $availableDisks = array_keys(config('filesystems.disks', []));

        if (in_array($configuredDisk, $availableDisks, true)) {
            return $configuredDisk;
        }

        return (string) (config('filesystems.default') ?: 'local');
    }
}
