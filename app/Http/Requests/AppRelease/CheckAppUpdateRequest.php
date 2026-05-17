<?php

namespace App\Http\Requests\AppRelease;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class CheckAppUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'platform' => ['required', 'string', 'in:android,ios'],
            'channel' => ['nullable', 'string', 'max:30'],
            'current_version' => ['nullable', 'string', 'max:40'],
            'current_build_number' => ['required', 'integer', 'min:1'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'platform.required' => 'La plataforma es obligatoria.',
            'platform.in' => 'La plataforma solicitada no es válida.',
            'current_build_number.required' => 'El número de compilación actual es obligatorio.',
            'current_build_number.integer' => 'El número de compilación debe ser numérico.',
        ];
    }
}
