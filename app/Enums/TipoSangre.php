<?php

namespace App\Enums;

enum TipoSangre: string
{
    case APositivo = 'A+';
    case ANegativo = 'A-';
    case BPositivo = 'B+';
    case BNegativo = 'B-';
    case AbPositivo = 'AB+';
    case AbNegativo = 'AB-';
    case OPositivo = 'O+';
    case ONegativo = 'O-';

    public function label(): string
    {
        return $this->value;
    }

    /** @return string[] */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }

    /** @return array<int, array{value: string, label: string}> */
    public static function options(): array
    {
        return array_map(
            fn(self $case) => ['value' => $case->value, 'label' => $case->label()],
            self::cases()
        );
    }
}
