<?php

namespace App\Http\Requests\Producto;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductoRequest extends FormRequest
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
        $producto = $this->route('producto');

        return [
            'codigo' => ['required', 'string', 'max:20', Rule::unique('productos', 'codigo')->ignore($producto)],
            'descripcion' => ['required', 'string', 'max:255'],
            'activo' => ['boolean'],
            'precios' => ['sometimes', 'array', 'min:1'],
            'precios.*.feria_id' => ['required_with:precios', 'integer', 'distinct', 'exists:ferias,id'],
            'precios.*.precio' => ['required_with:precios', 'numeric', 'gt:0', 'decimal:0,2'],
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
            'codigo.unique' => 'El código ya está registrado.',
            'descripcion.required' => 'La descripción es requerida.',
            'descripcion.max' => 'La descripción no puede exceder 255 caracteres.',
            'precios.array' => 'Los precios deben enviarse como un arreglo.',
            'precios.min' => 'Debe indicar al menos un precio.',
            'precios.*.feria_id.required_with' => 'La feria es requerida para cada precio.',
            'precios.*.feria_id.distinct' => 'No se pueden repetir ferias en la misma solicitud.',
            'precios.*.feria_id.exists' => 'La feria seleccionada no existe.',
            'precios.*.precio.required_with' => 'El monto es requerido para cada precio.',
            'precios.*.precio.numeric' => 'El precio debe ser numérico.',
            'precios.*.precio.gt' => 'El precio debe ser mayor a cero.',
            'precios.*.precio.decimal' => 'El precio solo puede tener hasta 2 decimales.',
        ];
    }
}
