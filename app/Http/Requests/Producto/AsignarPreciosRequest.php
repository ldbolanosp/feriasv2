<?php

namespace App\Http\Requests\Producto;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class AsignarPreciosRequest extends FormRequest
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
            'precios' => ['required', 'array', 'min:1'],
            'precios.*.feria_id' => ['required', 'integer', 'distinct', 'exists:ferias,id'],
            'precios.*.precio' => ['required', 'numeric', 'gt:0', 'decimal:0,2'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'precios.required' => 'Debe enviar al menos un precio.',
            'precios.array' => 'Los precios deben enviarse como un arreglo.',
            'precios.min' => 'Debe indicar al menos un precio.',
            'precios.*.feria_id.required' => 'La feria es requerida para cada precio.',
            'precios.*.feria_id.distinct' => 'No se pueden repetir ferias en la misma solicitud.',
            'precios.*.feria_id.exists' => 'La feria seleccionada no existe.',
            'precios.*.precio.required' => 'El monto es requerido para cada precio.',
            'precios.*.precio.numeric' => 'El precio debe ser numérico.',
            'precios.*.precio.gt' => 'El precio debe ser mayor a cero.',
            'precios.*.precio.decimal' => 'El precio solo puede tener hasta 2 decimales.',
        ];
    }
}
