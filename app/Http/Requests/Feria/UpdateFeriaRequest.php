<?php

namespace App\Http\Requests\Feria;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateFeriaRequest extends FormRequest
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
            'codigo' => ['required', 'string', 'max:20', Rule::unique('ferias', 'codigo')->ignore($this->route('feria'))],
            'descripcion' => ['required', 'string', 'max:255'],
            'facturacion_publico' => ['boolean'],
            'activa' => ['boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'codigo.required' => 'El código es requerido.',
            'codigo.max' => 'El código no puede exceder 20 caracteres.',
            'codigo.unique' => 'El código ya existe.',
            'descripcion.required' => 'La descripción es requerida.',
            'descripcion.max' => 'La descripción no puede exceder 255 caracteres.',
        ];
    }
}
