<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

use function Pest\Laravel\postJson;

uses(RefreshDatabase::class);

it('logs in with normalized email casing and whitespace', function (): void {
    $user = User::factory()->create([
        'name' => 'Usuario Legacy',
        'email' => 'legacy-user@example.com',
        'password' => 'Password123!',
        'activo' => true,
    ]);

    postJson('/api/v1/auth/login', [
        'email' => '  LEGACY-USER@EXAMPLE.COM  ',
        'password' => 'Password123!',
    ])
        ->assertOk()
        ->assertJsonPath('user.id', $user->id)
        ->assertJsonPath('user.email', 'legacy-user@example.com');
});
