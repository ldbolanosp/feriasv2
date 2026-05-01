<?php

namespace App\Http\Requests\Participante;

use App\Enums\TipoIdentificacion;
use App\Enums\TipoSangre;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreParticipanteRequest extends FormRequest
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
            'nombre' => ['required', 'string', 'max:255'],
            'tipo_identificacion' => ['required', 'string', Rule::enum(TipoIdentificacion::class)],
            'numero_identificacion' => ['required', 'string', 'max:50', 'unique:participantes,numero_identificacion'],
            'correo_electronico' => ['nullable', 'email', 'max:255'],
            'numero_carne' => ['nullable', 'string', 'max:50'],
            'fecha_emision_carne' => ['nullable', 'date'],
            'fecha_vencimiento_carne' => ['nullable', 'date', 'after:fecha_emision_carne'],
            'procedencia' => ['nullable', 'string', 'max:255'],
            'telefono' => ['nullable', 'string', 'max:30'],
            'tipo_sangre' => ['nullable', 'string', Rule::enum(TipoSangre::class)],
            'padecimientos' => ['nullable', 'string'],
            'contacto_emergencia_nombre' => ['nullable', 'string', 'max:255'],
            'contacto_emergencia_telefono' => ['nullable', 'string', 'max:30'],
            'activo' => ['boolean'],
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
            'tipo_identificacion.required' => 'El tipo de identificación es requerido.',
            'tipo_identificacion.enum' => 'El tipo de identificación no es válido. Opciones: fisica, juridica, dimex, nite.',
            'numero_identificacion.required' => 'El número de identificación es requerido.',
            'numero_identificacion.max' => 'El número de identificación no puede exceder 50 caracteres.',
            'numero_identificacion.unique' => 'El número de identificación ya está registrado.',
            'correo_electronico.email' => 'El correo electrónico no tiene un formato válido.',
            'correo_electronico.max' => 'El correo electrónico no puede exceder 255 caracteres.',
            'fecha_vencimiento_carne.after' => 'La fecha de vencimiento del carné debe ser posterior a la fecha de emisión.',
            'tipo_sangre.enum' => 'El tipo de sangre no es válido.',
        ];
    }
}
