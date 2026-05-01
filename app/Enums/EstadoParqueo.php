<?php

namespace App\Enums;

enum EstadoParqueo: string
{
    case Activo = 'activo';
    case Finalizado = 'finalizado';
    case Cancelado = 'cancelado';

    public function label(): string
    {
        return match($this) {
            self::Activo => 'Activo',
            self::Finalizado => 'Finalizado',
            self::Cancelado => 'Cancelado',
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
