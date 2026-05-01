<?php

namespace App\Http\Requests\Inspeccion;

use App\Models\Inspeccion;
use App\Models\Participante;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreInspeccionRequest extends FormRequest
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
            'reinspeccion_de_id' => ['nullable', 'integer', 'exists:inspecciones,id'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.item_diagnostico_id' => ['required', 'integer', 'distinct', 'exists:item_diagnosticos,id'],
            'items.*.cumple' => ['required', 'boolean'],
            'items.*.observaciones' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator): void {
                $feriaId = (int) $this->header('X-Feria-Id');
                $participanteId = (int) $this->input('participante_id');

                if ($participanteId > 0 && ! Participante::query()->whereKey($participanteId)->porFeria($feriaId)->exists()) {
                    $validator->errors()->add('participante_id', 'El participante seleccionado no pertenece a la feria activa.');
                }

                $reinspeccionDeId = $this->integer('reinspeccion_de_id');
                if ($reinspeccionDeId <= 0) {
                    return;
                }

                $inspeccionBase = Inspeccion::query()->find($reinspeccionDeId);

                if (! $inspeccionBase) {
                    return;
                }

                if ($inspeccionBase->feria_id !== $feriaId) {
                    $validator->errors()->add('reinspeccion_de_id', 'La inspección base no pertenece a la feria activa.');
                }

                if ($participanteId > 0 && $inspeccionBase->participante_id !== $participanteId) {
                    $validator->errors()->add('reinspeccion_de_id', 'La reinspección debe corresponder al mismo participante.');
                }
            },
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
            'reinspeccion_de_id.exists' => 'La inspección base seleccionada no existe.',
            'items.required' => 'Debe agregar al menos un item de inspección.',
            'items.array' => 'Los items deben enviarse en un arreglo.',
            'items.min' => 'Debe agregar al menos un item de inspección.',
            'items.*.item_diagnostico_id.required' => 'Cada item debe tener un diagnóstico seleccionado.',
            'items.*.item_diagnostico_id.exists' => 'Uno de los items seleccionados no existe.',
            'items.*.item_diagnostico_id.distinct' => 'No puede repetir items de diagnóstico en la misma inspección.',
            'items.*.cumple.required' => 'Debe indicar si cada item cumple o no cumple.',
            'items.*.cumple.boolean' => 'El estado de cumplimiento de cada item no es válido.',
            'items.*.observaciones.max' => 'Las observaciones no pueden exceder 1000 caracteres.',
        ];
    }
}
