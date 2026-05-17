<?php

namespace App\Http\Requests\AppRelease;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\File;

class StoreAppReleaseRequest extends FormRequest
{
    private const AUTHORIZED_EMAIL = 'ldbolanosp@gmail.com';

    public function authorize(): bool
    {
        return $this->user()?->email === self::AUTHORIZED_EMAIL;
    }

    /**
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'platform' => ['required', 'string', 'in:android'],
            'channel' => ['nullable', 'string', 'max:30'],
            'version_name' => ['required', 'string', 'max:40'],
            'version_code' => ['required', 'integer', 'min:1'],
            'min_supported_version_code' => ['nullable', 'integer', 'min:1'],
            'release_notes' => ['nullable', 'string', 'max:10000'],
            'is_mandatory' => ['nullable', 'boolean'],
            'apk_file' => [
                'required',
                File::types(['apk'])->max(200 * 1024),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'platform.required' => 'La plataforma es obligatoria.',
            'platform.in' => 'Solo se permite publicar APKs de Android.',
            'version_name.required' => 'La versión es obligatoria.',
            'version_code.required' => 'El código de versión es obligatorio.',
            'version_code.integer' => 'El código de versión debe ser numérico.',
            'min_supported_version_code.integer' => 'La versión mínima soportada debe ser numérica.',
            'apk_file.required' => 'Debe adjuntar el archivo APK.',
            'apk_file.max' => 'El APK no puede superar los 200 MB.',
        ];
    }
}
