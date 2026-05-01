<?php

namespace App\Http\Requests\Factura;

use App\Models\Participante;
use App\Models\ProductoPrecio;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreFacturaRequest extends FormRequest
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
            'es_publico_general' => ['sometimes', 'boolean'],
            'nombre_publico' => ['nullable', 'string', 'max:255'],
            'participante_id' => ['nullable', 'integer', 'exists:participantes,id'],
            'tipo_puesto' => ['nullable', 'string', 'max:100'],
            'numero_puesto' => ['nullable', 'string', 'max:50'],
            'monto_pago' => ['nullable', 'numeric', 'min:0', 'decimal:0,2'],
            'observaciones' => ['nullable', 'string'],
            'detalles' => ['required', 'array', 'min:1'],
            'detalles.*.producto_id' => ['required', 'integer', 'distinct', 'exists:productos,id'],
            'detalles.*.cantidad' => ['required', 'numeric', 'min:1', 'multiple_of:0.5', 'decimal:0,1'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'nombre_publico.max' => 'El nombre no puede exceder 255 caracteres.',
            'participante_id.exists' => 'El participante seleccionado no existe.',
            'tipo_puesto.max' => 'El tipo de puesto no puede exceder 100 caracteres.',
            'numero_puesto.max' => 'El número de puesto no puede exceder 50 caracteres.',
            'monto_pago.numeric' => 'El monto de pago debe ser numérico.',
            'monto_pago.min' => 'El monto de pago no puede ser negativo.',
            'monto_pago.decimal' => 'El monto de pago solo puede tener hasta 2 decimales.',
            'detalles.required' => 'Debe agregar al menos un detalle.',
            'detalles.array' => 'Los detalles deben enviarse como arreglo.',
            'detalles.min' => 'Debe agregar al menos un detalle.',
            'detalles.*.producto_id.required' => 'El producto es obligatorio en cada detalle.',
            'detalles.*.producto_id.distinct' => 'No se puede repetir un producto en la misma factura.',
            'detalles.*.producto_id.exists' => 'El producto seleccionado no existe.',
            'detalles.*.cantidad.required' => 'La cantidad es obligatoria en cada detalle.',
            'detalles.*.cantidad.min' => 'La cantidad mínima es 1.',
            'detalles.*.cantidad.multiple_of' => 'La cantidad debe avanzar en incrementos de 0.5.',
            'detalles.*.cantidad.decimal' => 'La cantidad solo puede tener un decimal.',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $feriaId = (int) $this->header('X-Feria-Id');
            $esPublicoGeneral = filter_var($this->input('es_publico_general', false), FILTER_VALIDATE_BOOLEAN);
            $participanteId = $this->integer('participante_id');

            if ($esPublicoGeneral) {
                if (! $this->filled('nombre_publico')) {
                    $validator->errors()->add('nombre_publico', 'El nombre para público general es obligatorio.');
                }
            } elseif ($participanteId <= 0) {
                $validator->errors()->add('participante_id', 'Debe seleccionar un participante.');
            } elseif (! Participante::query()->whereKey($participanteId)->porFeria($feriaId)->exists()) {
                $validator->errors()->add('participante_id', 'El participante no pertenece a la feria seleccionada.');
            }

            $detalles = collect($this->input('detalles', []))
                ->map(fn ($detalle): array => is_array($detalle) ? $detalle : []);

            $productoIds = $detalles
                ->pluck('producto_id')
                ->filter()
                ->map(fn ($productoId): int => (int) $productoId)
                ->unique()
                ->values();

            if ($productoIds->isEmpty()) {
                return;
            }

            $productosConPrecio = ProductoPrecio::query()
                ->where('feria_id', $feriaId)
                ->whereIn('producto_id', $productoIds)
                ->pluck('producto_id')
                ->all();

            $detalles->each(function (array $detalle, int $index) use ($productosConPrecio, $validator): void {
                $productoId = isset($detalle['producto_id']) ? (int) $detalle['producto_id'] : 0;

                if ($productoId > 0 && ! in_array($productoId, $productosConPrecio, true)) {
                    $validator->errors()->add("detalles.{$index}.producto_id", 'El producto no tiene precio configurado en la feria seleccionada.');
                }
            });
        });
    }
}
