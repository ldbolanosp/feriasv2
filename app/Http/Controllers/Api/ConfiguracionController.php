<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Configuracion\UpdateConfiguracionRequest;
use App\Models\Configuracion;
use App\Models\Feria;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConfiguracionController extends Controller
{
    /** @var array<int, array{clave:string, descripcion:string}> */
    private const CONFIGURACIONES_EDITABLES = [
        ['clave' => 'tarifa_parqueo', 'descripcion' => 'Tarifa de parqueo en colones'],
        ['clave' => 'precio_tarima', 'descripcion' => 'Precio por tarima en colones'],
        ['clave' => 'precio_sanitario', 'descripcion' => 'Precio por uso de sanitario en colones'],
    ];

    public function index(Request $request): JsonResponse
    {
        $feriaId = (int) $request->header('X-Feria-Id');
        $feria = Feria::query()->findOrFail($feriaId);

        $claves = collect(self::CONFIGURACIONES_EDITABLES)->pluck('clave');

        $globales = Configuracion::query()
            ->whereNull('feria_id')
            ->whereIn('clave', $claves)
            ->get()
            ->keyBy('clave');

        $especificasFeria = Configuracion::query()
            ->where('feria_id', $feriaId)
            ->whereIn('clave', $claves)
            ->get()
            ->keyBy('clave');

        $configuraciones = collect(self::CONFIGURACIONES_EDITABLES)
            ->mapWithKeys(function (array $configuracion) use ($globales, $especificasFeria): array {
                $global = $globales->get($configuracion['clave']);
                $feria = $especificasFeria->get($configuracion['clave']);
                $activa = $feria ?? $global;

                return [
                    $configuracion['clave'] => [
                        'clave' => $configuracion['clave'],
                        'valor' => $activa?->valor,
                        'descripcion' => $configuracion['descripcion'],
                        'scope' => $feria ? 'feria' : 'global',
                        'global_valor' => $global?->valor,
                    ],
                ];
            })
            ->all();

        return response()->json([
            'data' => [
                'feria' => [
                    'id' => $feria->id,
                    'codigo' => $feria->codigo,
                    'descripcion' => $feria->descripcion,
                ],
                'configuraciones' => $configuraciones,
            ],
        ]);
    }

    public function update(UpdateConfiguracionRequest $request): JsonResponse
    {
        $feriaId = (int) $request->header('X-Feria-Id');
        $validated = $request->validated();

        foreach (self::CONFIGURACIONES_EDITABLES as $configuracion) {
            Configuracion::query()->updateOrCreate(
                [
                    'feria_id' => $feriaId,
                    'clave' => $configuracion['clave'],
                ],
                [
                    'valor' => number_format((float) $validated[$configuracion['clave']], 2, '.', ''),
                    'descripcion' => $configuracion['descripcion'],
                ]
            );
        }

        return $this->index($request);
    }
}
