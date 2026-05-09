<?php

namespace App\Http\Requests\Usuario;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUsuarioRequest extends FormRequest
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
        $user = $this->route('user');

        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user)],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
            'activo' => ['sometimes', 'boolean'],
            'role' => ['nullable', 'string', 'exists:roles,name'],
            'ferias' => ['sometimes', 'array'],
            'ferias.*' => ['integer', 'distinct', 'exists:ferias,id'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'El nombre es requerido.',
            'email.required' => 'El correo electrónico es requerido.',
            'email.email' => 'El correo electrónico no tiene un formato válido.',
            'email.unique' => 'El correo electrónico ya está registrado.',
            'password.min' => 'La contraseña debe tener al menos 8 caracteres.',
            'password.confirmed' => 'La confirmación de la contraseña no coincide.',
            'role.exists' => 'El rol seleccionado no existe.',
            'ferias.array' => 'Las ferias deben enviarse como un arreglo.',
            'ferias.*.distinct' => 'No se pueden repetir ferias.',
            'ferias.*.exists' => 'Una de las ferias seleccionadas no existe.',
        ];
    }
}
