<?php

namespace App\Http\Requests\Usuario;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class AsignarFeriasUsuarioRequest extends FormRequest
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
            'ferias' => ['required', 'array'],
            'ferias.*' => ['integer', 'distinct', 'exists:ferias,id'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'ferias.required' => 'Debe seleccionar al menos una feria.',
            'ferias.array' => 'Las ferias deben enviarse como un arreglo.',
            'ferias.*.distinct' => 'No se pueden repetir ferias.',
            'ferias.*.exists' => 'Una de las ferias seleccionadas no existe.',
        ];
    }
}
