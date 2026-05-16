<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\MobileDiagnosticLog\StoreMobileDiagnosticLogRequest;
use App\Http\Resources\MobileDiagnosticLogResource;
use App\Models\MobileDiagnosticLog;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Arr;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class MobileDiagnosticLogController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = MobileDiagnosticLog::query()
            ->with(['user', 'feria']);

        if ($request->filled('search')) {
            $search = $request->string('search')->value();

            $query->where(function (Builder $innerQuery) use ($search): void {
                $innerQuery
                    ->where('summary', 'ilike', "%{$search}%")
                    ->orWhere('current_route', 'ilike', "%{$search}%")
                    ->orWhere('platform', 'ilike', "%{$search}%")
                    ->orWhere('device_name', 'ilike', "%{$search}%")
                    ->orWhereHas('user', function (Builder $userQuery) use ($search): void {
                        $userQuery
                            ->where('name', 'ilike', "%{$search}%")
                            ->orWhere('email', 'ilike', "%{$search}%");
                    });
            });
        }

        if ($request->filled('trigger')) {
            $query->where('trigger', $request->string('trigger')->value());
        }

        if ($request->filled('platform')) {
            $query->where('platform', $request->string('platform')->value());
        }

        $feriaId = $request->integer('feria_id') ?: (int) $request->header('X-Feria-Id');

        if ($feriaId > 0) {
            $query->where('feria_id', $feriaId);
        }

        $allowedSortFields = ['id', 'created_at', 'last_event_at', 'event_count', 'platform', 'trigger'];
        $sortField = in_array($request->sort, $allowedSortFields, true) ? $request->sort : 'last_event_at';
        $direction = $request->direction === 'asc' ? 'asc' : 'desc';

        $query->orderBy($sortField, $direction)->orderByDesc('id');

        $perPage = min((int) ($request->per_page ?? 15), 100);

        return MobileDiagnosticLogResource::collection($query->paginate($perPage));
    }

    public function store(StoreMobileDiagnosticLogRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $logs = collect($validated['logs']);
        $lastLog = $logs
            ->sortBy(fn (array $log): string => (string) Arr::get($log, 'timestamp', ''))
            ->last();

        $mobileDiagnosticLog = MobileDiagnosticLog::query()->create([
            'user_id' => $request->user()?->id,
            'feria_id' => $validated['feria_id'] ?? null,
            'session_id' => $validated['session_id'],
            'trigger' => $validated['trigger'],
            'platform' => $validated['platform'] ?? null,
            'app_version' => $validated['app_version'] ?? null,
            'device_name' => $validated['device_name'] ?? null,
            'current_route' => $validated['current_route'] ?? Arr::get($lastLog, 'route'),
            'summary' => Str::limit((string) Arr::get($lastLog, 'message', 'Diagnóstico móvil enviado'), 500),
            'event_count' => $logs->count(),
            'last_event_at' => $lastLog ? Carbon::parse($lastLog['timestamp']) : null,
            'payload' => $validated,
        ]);

        return response()->json([
            'message' => 'Diagnóstico recibido correctamente.',
            'data' => [
                'id' => $mobileDiagnosticLog->id,
                'event_count' => $mobileDiagnosticLog->event_count,
            ],
        ], 201);
    }
}
