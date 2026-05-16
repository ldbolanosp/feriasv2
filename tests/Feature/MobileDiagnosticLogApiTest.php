<?php

use App\Models\Feria;
use App\Models\MobileDiagnosticLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Permission;

use function Pest\Laravel\getJson;
use function Pest\Laravel\postJson;

uses(RefreshDatabase::class);

function mobileDiagnosticFeria(array $overrides = []): Feria
{
    return Feria::create(array_merge([
        'codigo' => fake()->unique()->bothify('FER-###'),
        'descripcion' => fake()->sentence(3),
        'facturacion_publico' => true,
        'activa' => true,
    ], $overrides));
}

it('stores mobile diagnostic logs for the authenticated user', function (): void {
    $user = User::factory()->create();
    $feria = mobileDiagnosticFeria();

    Sanctum::actingAs($user);

    postJson('/api/v1/auth/mobile-diagnostic-logs', [
        'session_id' => 'session-test-001',
        'trigger' => 'manual',
        'platform' => 'android',
        'app_version' => '1.0.0+1',
        'device_name' => 'ferias-app-android',
        'current_route' => '/configuracion',
        'feria_id' => $feria->id,
        'logs' => [
            [
                'timestamp' => now()->subMinute()->toIso8601String(),
                'level' => 'info',
                'category' => 'ui',
                'message' => 'Usuario abrió configuración',
                'route' => '/configuracion',
                'context' => ['source' => 'settings'],
            ],
            [
                'timestamp' => now()->toIso8601String(),
                'level' => 'error',
                'category' => 'crash',
                'message' => 'La aplicación se cerró inesperadamente.',
                'route' => '/facturacion',
                'error' => 'StateError: Bad state',
                'stack_trace' => '#0 FacturaScreen.submit',
            ],
        ],
    ])
        ->assertCreated()
        ->assertJsonPath('data.event_count', 2);

    $storedLog = MobileDiagnosticLog::query()->firstOrFail();

    expect($storedLog->user_id)->toBe($user->id)
        ->and($storedLog->feria_id)->toBe($feria->id)
        ->and($storedLog->trigger)->toBe('manual')
        ->and($storedLog->event_count)->toBe(2)
        ->and($storedLog->summary)->toBe('La aplicación se cerró inesperadamente.');
});

it('validates that at least one log entry is sent', function (): void {
    Sanctum::actingAs(User::factory()->create());

    postJson('/api/v1/auth/mobile-diagnostic-logs', [
        'session_id' => 'session-test-002',
        'trigger' => 'manual',
        'logs' => [],
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['logs']);
});

it('lists mobile diagnostic logs with fair filtering', function (): void {
    Permission::findOrCreate('configuracion.ver', 'web');

    $user = User::factory()->create();
    $user->givePermissionTo('configuracion.ver');
    $feriaA = mobileDiagnosticFeria(['codigo' => 'FER-A']);
    $feriaB = mobileDiagnosticFeria(['codigo' => 'FER-B']);

    Sanctum::actingAs($user);

    MobileDiagnosticLog::query()->create([
        'user_id' => $user->id,
        'feria_id' => $feriaA->id,
        'session_id' => 'session-a',
        'trigger' => 'manual',
        'platform' => 'android',
        'app_version' => '1.0.0+1',
        'device_name' => 'device-a',
        'current_route' => '/configuracion',
        'summary' => 'Cierre inesperado en configuración',
        'event_count' => 3,
        'last_event_at' => now(),
        'payload' => ['logs' => [['message' => 'Cierre inesperado en configuración']]],
    ]);

    MobileDiagnosticLog::query()->create([
        'user_id' => $user->id,
        'feria_id' => $feriaB->id,
        'session_id' => 'session-b',
        'trigger' => 'automatic',
        'platform' => 'android',
        'app_version' => '1.0.0+1',
        'device_name' => 'device-b',
        'current_route' => '/facturacion',
        'summary' => 'Otro evento',
        'event_count' => 1,
        'last_event_at' => now()->subMinute(),
        'payload' => ['logs' => [['message' => 'Otro evento']]],
    ]);

    getJson('/api/v1/auth/mobile-diagnostic-logs', ['X-Feria-Id' => (string) $feriaA->id])
        ->assertOk()
        ->assertJsonPath('data.0.feria.codigo', 'FER-A')
        ->assertJsonCount(1, 'data');
});
