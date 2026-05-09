<?php

namespace App\Http\Requests\Rol;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateRolePermissionsRequest extends FormRequest
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
            'permissions' => ['required', 'array'],
            'permissions.*' => ['string', 'distinct', 'exists:permissions,name'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'permissions.required' => 'Debe enviar la lista de permisos del rol.',
            'permissions.array' => 'Los permisos deben enviarse como un arreglo.',
            'permissions.*.distinct' => 'No se pueden repetir permisos en la misma solicitud.',
            'permissions.*.exists' => 'Uno de los permisos seleccionados no existe.',
        ];
    }
}
