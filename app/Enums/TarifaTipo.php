<?php

namespace App\Enums;

enum TarifaTipo: string
{
    case Fija = 'fija';
    case PorHora = 'por_hora';

    public function label(): string
    {
        return match($this) {
            self::Fija => 'Tarifa Fija',
            self::PorHora => 'Por Hora',
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
