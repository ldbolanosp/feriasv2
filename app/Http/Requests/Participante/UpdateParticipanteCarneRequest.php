<?php

namespace App\Http\Requests\Participante;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateParticipanteCarneRequest extends FormRequest
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
            'numero_carne' => ['nullable', 'string', 'max:50'],
            'fecha_emision_carne' => ['nullable', 'date'],
            'fecha_vencimiento_carne' => ['nullable', 'date', 'after:fecha_emision_carne'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'numero_carne.max' => 'El número de carné no puede exceder 50 caracteres.',
            'fecha_vencimiento_carne.after' => 'La fecha de vencimiento del carné debe ser posterior a la fecha de emisión.',
        ];
    }
}
