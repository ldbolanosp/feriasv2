<?php

namespace App\Enums;

enum TipoIdentificacion: string
{
    case Fisica = 'fisica';
    case Juridica = 'juridica';
    case Dimex = 'dimex';
    case Nite = 'nite';

    public function label(): string
    {
        return match($this) {
            self::Fisica => 'Cédula Física',
            self::Juridica => 'Cédula Jurídica',
            self::Dimex => 'DIMEX',
            self::Nite => 'NITE',
        };
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
