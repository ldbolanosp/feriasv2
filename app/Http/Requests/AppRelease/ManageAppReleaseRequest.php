<?php

namespace App\Http\Requests\AppRelease;

use Illuminate\Foundation\Http\FormRequest;

class ManageAppReleaseRequest extends FormRequest
{
    private const AUTHORIZED_EMAIL = 'ldbolanosp@gmail.com';

    public function authorize(): bool
    {
        return $this->user()?->email === self::AUTHORIZED_EMAIL;
    }

    public function rules(): array
    {
        return [];
    }
}
