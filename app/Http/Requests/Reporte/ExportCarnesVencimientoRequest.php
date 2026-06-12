<?php

namespace App\Http\Requests\Reporte;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class ExportCarnesVencimientoRequest extends FormRequest
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
            'feria_id' => ['nullable', 'integer', 'exists:ferias,id'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'feria_id.integer' => 'La feria seleccionada no es válida.',
            'feria_id.exists' => 'La feria seleccionada no existe.',
        ];
    }
}
