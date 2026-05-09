<?php

namespace App\Http\Requests\MetodoPago;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateMetodoPagoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $metodoPago = $this->route('metodoPago');

        return [
            'nombre' => ['required', 'string', 'max:255', Rule::unique('metodo_pagos', 'nombre')->ignore($metodoPago)],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'nombre.required' => 'El nombre es requerido.',
            'nombre.max' => 'El nombre no puede exceder 255 caracteres.',
            'nombre.unique' => 'Ya existe un método de pago con ese nombre.',
        ];
    }
}
