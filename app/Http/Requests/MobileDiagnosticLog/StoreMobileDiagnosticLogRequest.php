<?php

namespace App\Http\Requests\MobileDiagnosticLog;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreMobileDiagnosticLogRequest extends FormRequest
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
            'session_id' => ['required', 'string', 'max:120'],
            'trigger' => ['required', 'string', 'in:manual,automatic,crash'],
            'platform' => ['nullable', 'string', 'max:40'],
            'app_version' => ['nullable', 'string', 'max:40'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'current_route' => ['nullable', 'string', 'max:255'],
            'feria_id' => ['nullable', 'integer', 'exists:ferias,id'],
            'logs' => ['required', 'array', 'min:1', 'max:500'],
            'logs.*.timestamp' => ['required', 'date'],
            'logs.*.level' => ['required', 'string', 'max:20'],
            'logs.*.category' => ['required', 'string', 'max:50'],
            'logs.*.message' => ['required', 'string', 'max:5000'],
            'logs.*.route' => ['nullable', 'string', 'max:255'],
            'logs.*.error' => ['nullable', 'string', 'max:10000'],
            'logs.*.stack_trace' => ['nullable', 'string', 'max:50000'],
            'logs.*.context' => ['nullable', 'array'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'session_id.required' => 'La sesión del diagnóstico es obligatoria.',
            'trigger.in' => 'El origen del diagnóstico no es válido.',
            'logs.required' => 'Debe enviar al menos un log.',
            'logs.min' => 'Debe enviar al menos un log.',
            'logs.max' => 'No puede enviar más de 500 logs por reporte.',
            'logs.*.timestamp.required' => 'Cada log debe incluir fecha y hora.',
            'logs.*.level.required' => 'Cada log debe incluir el nivel.',
            'logs.*.category.required' => 'Cada log debe incluir la categoría.',
            'logs.*.message.required' => 'Cada log debe incluir el mensaje.',
        ];
    }
}
