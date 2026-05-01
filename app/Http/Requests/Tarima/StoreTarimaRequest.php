<?php

namespace App\Http\Requests\Tarima;

use App\Models\Participante;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreTarimaRequest extends FormRequest
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
            'participante_id' => ['required', 'integer', 'exists:participantes,id'],
            'numero_tarima' => ['nullable', 'string', 'max:50'],
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
            'participante_id.required' => 'Debe seleccionar un participante.',
            'participante_id.exists' => 'El participante seleccionado no existe.',
            'numero_tarima.max' => 'El número de tarima no puede exceder 50 caracteres.',
            'cantidad.required' => 'La cantidad es obligatoria.',
            'cantidad.integer' => 'La cantidad debe ser un número entero.',
            'cantidad.min' => 'La cantidad mínima es 1.',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $feriaId = (int) $this->header('X-Feria-Id');
            $participanteId = $this->integer('participante_id');

            if ($participanteId <= 0) {
                return;
            }

            if (! Participante::query()->whereKey($participanteId)->porFeria($feriaId)->exists()) {
                $validator->errors()->add('participante_id', 'El participante no pertenece a la feria seleccionada.');
            }
        });
    }
}
