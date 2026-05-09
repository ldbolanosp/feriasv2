<?php

namespace App\Http\Requests\Reporte;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class ExportReporteRequest extends FormRequest
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
            'fecha_inicio' => ['required', 'date_format:Y-m-d'],
            'fecha_fin' => ['required', 'date_format:Y-m-d', 'after_or_equal:fecha_inicio'],
            'feria_id' => ['nullable', 'integer', 'exists:ferias,id'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'fecha_inicio.required' => 'Debe seleccionar la fecha inicial.',
            'fecha_inicio.date_format' => 'La fecha inicial debe tener el formato YYYY-MM-DD.',
            'fecha_fin.required' => 'Debe seleccionar la fecha final.',
            'fecha_fin.date_format' => 'La fecha final debe tener el formato YYYY-MM-DD.',
            'fecha_fin.after_or_equal' => 'La fecha final debe ser igual o posterior a la fecha inicial.',
            'feria_id.integer' => 'La feria seleccionada no es válida.',
            'feria_id.exists' => 'La feria seleccionada no existe.',
        ];
    }
}
