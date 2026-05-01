<?php

namespace App\Http\Requests\Configuracion;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateConfiguracionRequest extends FormRequest
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
            'tarifa_parqueo' => ['required', 'numeric', 'gt:0', 'decimal:0,2'],
            'precio_tarima' => ['required', 'numeric', 'gt:0', 'decimal:0,2'],
            'precio_sanitario' => ['required', 'numeric', 'gt:0', 'decimal:0,2'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'tarifa_parqueo.required' => 'La tarifa de parqueo es obligatoria.',
            'tarifa_parqueo.numeric' => 'La tarifa de parqueo debe ser numérica.',
            'tarifa_parqueo.gt' => 'La tarifa de parqueo debe ser mayor a cero.',
            'tarifa_parqueo.decimal' => 'La tarifa de parqueo solo puede tener hasta 2 decimales.',
            'precio_tarima.required' => 'El precio de tarima es obligatorio.',
            'precio_tarima.numeric' => 'El precio de tarima debe ser numérico.',
            'precio_tarima.gt' => 'El precio de tarima debe ser mayor a cero.',
            'precio_tarima.decimal' => 'El precio de tarima solo puede tener hasta 2 decimales.',
            'precio_sanitario.required' => 'El precio de sanitario es obligatorio.',
            'precio_sanitario.numeric' => 'El precio de sanitario debe ser numérico.',
            'precio_sanitario.gt' => 'El precio de sanitario debe ser mayor a cero.',
            'precio_sanitario.decimal' => 'El precio de sanitario solo puede tener hasta 2 decimales.',
        ];
    }
}
