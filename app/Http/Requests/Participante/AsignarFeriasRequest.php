<?php

namespace App\Http\Requests\Participante;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class AsignarFeriasRequest extends FormRequest
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
            'ferias' => ['required', 'array', 'min:1'],
            'ferias.*' => ['required', 'integer', 'exists:ferias,id'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'ferias.required' => 'Debe seleccionar al menos una feria.',
            'ferias.array' => 'El campo ferias debe ser un arreglo.',
            'ferias.min' => 'Debe seleccionar al menos una feria.',
            'ferias.*.integer' => 'Cada feria debe ser un identificador numérico.',
            'ferias.*.exists' => 'Una o más ferias seleccionadas no existen.',
        ];
    }
}
