<?php

namespace App\Http\Requests\Sanitario;

use App\Models\Participante;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreSanitarioRequest extends FormRequest
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
            'participante_id' => ['nullable', 'integer', 'exists:participantes,id'],
            'cantidad' => ['required', 'integer', 'min:1'],
            'observaciones' => ['nullable', 'string'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'participante_id.exists' => 'El participante seleccionado no existe.',
            'cantidad.required' => 'La cantidad es obligatoria.',
            'cantidad.integer' => 'La cantidad debe ser un número entero.',
            'cantidad.min' => 'La cantidad mínima es 1.',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $feriaId = (int) $this->header('X-Feria-Id');
            $participanteId = $this->input('participante_id');

            if ($participanteId === null || $participanteId === '') {
                return;
            }

            $participanteId = (int) $participanteId;

            if (! Participante::query()->whereKey($participanteId)->porFeria($feriaId)->exists()) {
                $validator->errors()->add('participante_id', 'El participante no pertenece a la feria seleccionada.');
            }
        });
    }
}
