# UI MIGRATION MASTER SPEC — FERIAS APP (FLUTTER)

## PROPÓSITO

Mejorar la UI actual de la app Flutter con un nuevo enfoque visual inspirado en el mock de referencia proporcionado por el usuario, sin romper nada y sin tocar lógica de negocio.

Este documento define exactamente qué deben hacer los agentes de AI, qué no deben tocar, cómo deben organizar el trabajo, qué entregables deben producir y cómo validar que la migración sea segura.

---

## CONTEXTO

Antes de trabajar, el agente debe leer `FLUTTER_CONTEXT.md` y `PROJECT_CONTEXT.md`.

La app ya existe y ya funciona. Tiene backend, arquitectura, providers, services, modelos, rutas y lógica de negocio implementada. El problema actual no es funcional: es visual y de experiencia de usuario.

La nueva dirección visual debe parecerse al estilo del mock adjunto:
- estética moderna tipo fintech / SaaS mobile
- tarjetas limpias
- sombras suaves
- jerarquía tipográfica clara
- espaciado amplio
- navegación inferior
- componentes visuales personalizados
- pantallas enfocadas y menos densas
- apariencia premium y consistente

El objetivo no es rehacer la app. El objetivo es mejorar únicamente la capa visual existente.

---

## REGLA PRINCIPAL

TODO ESTE PROCESO ES SOLO DE UI.

Si alguna tarea requiere modificar lógica, flujo de negocio, estructura de datos, requests HTTP, validaciones del dominio, navegación funcional o comportamiento del backend, el agente debe detenerse y no hacerlo.

---

## RESTRICCIONES ABSOLUTAS

Los agentes NO pueden modificar:
- providers
- services
- models
- lógica de negocio
- endpoints API
- contratos de datos
- nombres de campos JSON
- interceptores Dio
- autenticación
- impresión
- flujos de negocio
- validaciones funcionales existentes
- reglas de permisos
- routing lógico ya existente
- estructura funcional de navegación
- rutas registradas en GoRouter
- guards, redirects o permisos de rutas

Los agentes SOLO pueden modificar o crear:
- widgets visuales
- componentes reutilizables de UI
- layouts
- temas visuales
- tokens de diseño
- wrappers visuales de pantalla
- composición visual
- animaciones sutiles
- estilos
- iconografía
- estructura visual del contenido

---

## ENFOQUE DE MIGRACIÓN

La mejora visual debe hacerse de forma incremental y segura.

No se deben destruir ni rehacer los flujos actuales. La implementación debe apoyarse sobre las pantallas y lógica ya existentes, cambiando únicamente su presentación visual.

La estrategia correcta es:
1. Crear un design system propio.
2. Crear componentes visuales base reutilizables.
3. Crear layouts visuales reutilizables.
4. Refactorizar visualmente las pantallas críticas existentes.
5. Reutilizar providers, services y modelos existentes sin modificarlos.
6. Integrar los componentes visuales nuevos dentro de las pantallas existentes sin alterar rutas ni comportamiento.
7. No tocar la lógica existente.

---

## RESULTADO ESPERADO

Al finalizar, la app debe:
- verse moderna y consistente
- parecer diseñada a medida, no genérica de Material por defecto
- conservar exactamente la misma lógica funcional
- seguir funcionando con los mismos providers y services
- seguir consumiendo la misma API
- mantener los mismos permisos y flujos
- sentirse más simple, limpia y rápida en móvil
- verse bien en pantallas compactas tipo SUNMI V3

---

## ESTILO VISUAL OBJETIVO

El nuevo diseño debe tomar como referencia el mock proporcionado por el usuario. Las características visuales son:

### Apariencia general
- fondo claro y suave, no blanco puro duro
- tarjetas blancas con bordes redondeados
- sombras sutiles y limpias
- headers sencillos
- información bien agrupada
- jerarquía tipográfica marcada
- badges de estado claros
- navegación inferior
- acciones importantes destacadas
- menos ruido visual
- más aire y espacio en blanco

### Rasgos de UI
- nada debe verse como widget default sin personalizar
- evitar apariencia de sistema administrativo web adaptado a móvil
- evitar pantallas densas con demasiados elementos visibles
- evitar tablas pesadas en móvil
- convertir listados en tarjetas modernas
- destacar montos, acciones y estados
- agrandar objetivos táctiles
- mantener consistencia extrema entre pantallas

### Principios de interacción
- una pantalla debe priorizar una tarea principal
- la acción principal debe ser obvia
- los estados deben ser visualmente escaneables
- el usuario debe poder operar rápido
- la UI debe sentirse liviana

---

## ORGANIZACIÓN DE UI

Se puede crear una capa visual reutilizable si hace falta, por ejemplo:

lib/ui/
- theme/
- components/
- layouts/
- utils/

Esto es opcional y solo debe hacerse si ayuda a centralizar estilos sin duplicar código.

No crear una arquitectura paralela innecesaria ni duplicar pantallas completas si el mismo resultado se puede lograr sobre las screens actuales.

---

## DESIGN SYSTEM OBLIGATORIO

Los agentes deben crear y usar un design system centralizado. No deben hardcodear estilos repetidos por toda la app sin centralizarlos.

### Tokens mínimos obligatorios
- colores
- espaciados
- radios
- sombras
- tipografías
- tamaños de icono
- alturas de botones
- paddings de tarjetas
- estilos de inputs
- estilos de badges
- estilos de navegación

### Reglas del design system
- todos los colores deben venir de una clase central
- todos los textos importantes deben usar estilos tipográficos definidos
- todos los espaciados repetidos deben salir de constantes
- todas las tarjetas deben compartir lenguaje visual
- todos los botones primarios deben compartir estilo
- todos los badges deben compartir patrón
- todos los inputs deben compartir patrón

### Paleta sugerida
El azul principal debe ser moderno y vivo, coherente con el mock.
La UI debe usar neutrales suaves para fondo y texto secundario.
Éxito, advertencia y error deben tener colores claros y distinguibles.

### Ejemplo de intención visual
- primary: azul vivo
- background: gris muy claro azulado
- surface/card: blanco
- text primary: oscuro casi negro
- text secondary: gris medio
- success: verde moderno
- warning: ámbar
- danger: rojo moderno

No es obligatorio usar exactamente estos valores, pero la estética final debe acercarse al mock.

---

## USO DE MATERIAL

Se puede seguir usando Flutter con Material como base técnica, pero no se deben usar widgets Material con su apariencia por defecto como resultado final.

Eso significa:
- sí se puede usar Scaffold, Theme, Navigator, BottomNavigationBar si está correctamente personalizado
- no se debe dejar Card(), ElevatedButton(), ListTile(), TextField(), AppBar() o Chips con estilo default si rompen la estética objetivo

Flutter debe usarse como motor y framework, no como look visual por defecto.

---

## COMPONENTES VISUALES QUE DEBEN CREARSE

Los agentes deben crear una librería mínima de componentes custom reutilizables.

### Componentes base obligatorios
- AppScreen
- AppSurfaceCard o BaseCard
- AppPrimaryButton
- AppSecondaryButton
- AppIconButton
- AppTextField
- AppSearchField
- AppStatusBadge
- AppSectionTitle
- AppStatCard
- AppListCard
- AppBottomNav
- AppTopHeader
- AppEmptyState
- AppLoadingView
- AppFilterChip o tab pill custom
- AppScaffoldShell

### Reglas para los componentes
- deben ser reutilizables
- deben aceptar personalización razonable
- deben ocultar styling repetitivo
- deben ser coherentes entre sí
- no deben contener lógica de negocio
- deben recibir data ya preparada por las capas existentes

---

## COMPONENTES A EVITAR EN SU FORMA DEFAULT

No dejar en producción estos widgets con look default:
- ListTile
- Card
- ElevatedButton
- OutlinedButton
- TextButton
- FloatingActionButton
- AppBar
- BottomNavigationBar
- TextField
- InputDecorator
- AlertDialog
- Chip
- TabBar

Se pueden usar internamente si quedan completamente personalizados y alineados al nuevo sistema visual.

---

## NAVEGACIÓN OBJETIVO

La nueva UI debe moverse hacia una navegación inferior en lugar del drawer como patrón principal de uso móvil, siempre que eso pueda hacerse sin romper rutas, permisos o flujo.

### Objetivo
- priorizar navegación móvil moderna
- reducir dependencia de drawer
- mejorar acceso rápido a módulos frecuentes

### Importante
No romper GoRouter ni guards ni permisos.
No introducir una navegación nueva si cambia el comportamiento actual de la app.
Solo se permite ajustar la apariencia visual de la navegación existente.

---

## PANTALLAS PRIORITARIAS A MIGRAR

Estas son las primeras pantallas a migrar al nuevo enfoque visual:

1. Dashboard
2. Listado de facturas
3. Formulario de factura
4. Parqueos
5. Configuración o ajustes
6. Navegación existente, solo a nivel visual

Estas pantallas deben convertirse en referencia visual para después continuar con el resto de módulos.

---

## DIRECTRICES POR PANTALLA

### 1. DASHBOARD
La pantalla debe verse como un home moderno, no como un panel administrativo pesado.

#### Debe incluir
- saludo o contexto superior
- acceso a ajustes o perfil
- una tarjeta principal destacada con KPI
- accesos rápidos a acciones frecuentes
- sección de registros recientes en formato de tarjetas
- navegación coherente con el patrón actual de la app

#### Debe evitar
- tablas
- bloques densos
- demasiadas métricas simultáneas
- exceso de texto

#### Prioridad visual
- KPI principal destacado
- acciones rápidas claras
- recientes fáciles de escanear

---

### 2. LISTADO DE FACTURAS
Debe verse como el mock: limpio, escaneable y moderno.

#### Debe incluir
- título claro
- acción principal para crear
- campo de búsqueda moderno
- filtros o tabs tipo pills
- tarjetas por factura
- monto destacado
- badge de estado visible
- subtítulo con número o fecha
- scroll cómodo

#### Debe evitar
- filas tipo tabla
- list tiles genéricos
- información amontonada
- demasiados detalles visibles a la vez

---

### 3. FORMULARIO DE FACTURA
Debe sentirse más ordenado, por bloques, y con un resumen fuerte.

#### Debe incluir
- secciones claras
- contenedores o tarjetas por bloque
- inputs modernos
- selector de participante bien presentado
- área de productos clara
- resumen con total muy destacado
- acciones fijas o bien visibles al final
- espaciado amplio

#### Debe evitar
- muro de inputs
- densidad visual excesiva
- total perdido entre otros datos
- look de formulario default

#### Regla
La lógica de facturación actual no se toca. Solo se reorganiza visualmente su presentación.

---

### 4. PARQUEOS
Debe ser extremadamente simple y rápida.

#### Debe incluir
- input principal muy claro
- foco en la placa
- tarifa visible
- botón principal grande
- pocas distracciones
- operación rápida

#### Debe evitar
- saturación visual
- elementos secundarios irrelevantes en la vista principal

---

### 5. CONFIGURACIÓN / AJUSTES
Debe parecer una pantalla de settings moderna.

#### Debe incluir
- secciones agrupadas
- íconos suaves
- filas limpias
- navegación clara
- acciones peligrosas separadas visualmente

#### Debe evitar
- formularios densos
- apariencia técnica o administrativa innecesaria

---

## COMPATIBILIDAD CON LA LÓGICA EXISTENTE

Los agentes deben preservar por completo la integración con:
- Provider
- ChangeNotifier
- GoRouter
- Services existentes
- Modelos existentes
- SharedPreferences existentes
- permisos existentes
- flujos actuales de impresión
- llamadas al backend

La UI nueva solo consume la misma información ya existente.
No debe exigir nuevos estados, nuevos endpoints ni nuevas rutas.

---

## REGLA DE REUTILIZACIÓN

Antes de crear lógica nueva, revisar si la pantalla actual ya tiene:
- provider funcional
- métodos cargando data
- acciones de guardar
- acciones de eliminar
- acciones de imprimir
- estados de loading
- controladores
- validaciones

Si ya existe, reutilizarlo. No duplicar negocio.

---

## PATRÓN DE IMPLEMENTACIÓN RECOMENDADO

Cada mejora de pantalla debe seguir este patrón:

1. reutilizar provider o lógica existente
2. mejorar la screen actual o envolverla visualmente
3. componer con componentes del design system
4. mover estilos inline repetidos a componentes o theme
5. validar que el comportamiento sea idéntico
6. no cambiar rutas ni flujo

---

## CONVENCIONES DE NOMBRADO

Usar nombres claros y consistentes.

### Ejemplos
- app_colors.dart
- app_spacing.dart
- app_radii.dart
- app_shadows.dart
- app_text_styles.dart
- app_surface_card.dart
- app_status_badge.dart
- app_search_field.dart

No renombrar providers ni services existentes.

---

## REGLAS DE IMPLEMENTACIÓN DE CÓDIGO

### Deben hacer
- mantener widgets pequeños y componibles
- extraer UI repetida
- usar const cuando aplique
- respetar null safety
- mantener separación entre UI y negocio
- evitar anidar widgets sin sentido
- escribir código legible
- preservar exactamente las acciones, handlers y flujos existentes

### No deben hacer
- meter lógica de negocio en widgets visuales
- recrear providers
- duplicar services
- cambiar contratos
- hardcodear strings de estado sin mapear visualmente de forma segura
- hacer hacks visuales que rompan mantenibilidad
- crear pantallas nuevas si no son estrictamente necesarias para el restyling
- cambiar patrón de navegación solo por preferencia estética

---

## UX PARA DISPOSITIVOS COMPACTOS

La app se usa en dispositivos compactos. El nuevo diseño debe considerar:
- targets táctiles amplios
- botones cómodos
- inputs fáciles de usar
- scroll natural
- jerarquía visual fuerte
- poca densidad por pantalla
- evitar dependencias del ancho grande

### Debe funcionar bien en
- teléfonos Android
- pantallas compactas tipo SUNMI V3
- orientación vertical

---

## ACCESIBILIDAD Y LEGIBILIDAD

La UI debe ser clara y legible.

### Reglas
- contraste suficiente
- tamaño de letra razonable
- badges legibles
- botones claros
- iconos entendibles
- no depender solo del color para comunicar estado
- evitar textos diminutos
- espaciados consistentes

---

## ESTADOS VISUALES OBLIGATORIOS

Todas las pantallas intervenidas deben contemplar:
- loading
- empty state
- error state visual amigable, solo si ese estado ya existe en la pantalla actual
- success feedback cuando ya exista en la lógica
- disabled state
- pressed/selected states cuando aplique

No inventar nuevos flujos. Solo representar mejor los existentes.

---

## ANIMACIONES

Se pueden agregar animaciones sutiles y seguras:
- transición suave entre tabs o secciones
- fade/slide leves
- microanimaciones discretas
- feedback táctil visual

No agregar animaciones exageradas ni que afecten rendimiento.

---

## SOMBRAS, RADIOS Y SUPERFICIES

Definir constantes centralizadas para:
- radios de tarjeta
- radios de botón
- radios de input
- sombras de tarjetas
- sombras de elementos flotantes

Todas las superficies deben hablar el mismo lenguaje visual.

---

## LISTADOS

Los listados deben migrarse de una estética administrativa a una estética basada en cards.

### Reglas
- usar tarjetas con padding generoso
- separar visualmente cada ítem
- mostrar dato principal, dato secundario y estado
- destacar montos o valores clave
- mantener acciones contextualizadas
- evitar filas densas

---

## FORMULARIOS

Los formularios deben:
- dividirse en secciones
- usar contenedores limpios
- tener jerarquía visual clara
- usar inputs custom
- destacar la acción primaria
- reducir densidad
- mantener validación funcional existente sin cambios

---

## BADGES Y ESTADOS

Todos los badges de estado deben pasar por un solo componente visual reusable.

### Debe mapear al menos
- facturado / pagada / activo / aprobado → éxito
- borrador / pendiente → advertencia
- eliminado / vencido / cancelado / error → peligro
- inactivo / neutro → neutral

Si hay más estados, mapearlos con consistencia.
No cambiar la lógica de estados; solo su representación visual.

---

## RUTAS

No cambiar rutas ni guards.

La mejora debe aplicarse sobre las rutas actuales y mantener exactamente el mismo comportamiento de navegación.

---

## ENTREGABLES OBLIGATORIOS

Los agentes deben entregar como mínimo:

1. Design system completo base
2. Componentes visuales reutilizables
3. Dashboard mejorado visualmente
4. Listado de facturas mejorado visualmente
5. Formulario de factura mejorado visualmente
6. Parqueos mejorado visualmente
7. Navegación existente mejorada visualmente si aplica
8. Resumen breve en la respuesta final de qué archivos nuevos o modificados se usaron
10. Confirmación explícita de que no se tocó lógica

---

## CHECKLIST TÉCNICO DE VALIDACIÓN

Antes de dar por completada la migración, los agentes deben revisar y confirmar:

- no se modificó ningún provider funcional
- no se modificó ningún service
- no se modificó ningún model
- no se cambiaron endpoints
- no se alteró autenticación
- no se alteró impresión
- no se alteraron permisos
- no se rompieron rutas
- la UI nueva compila
- las pantallas nuevas consumen la misma data existente
- los flujos principales siguen funcionando
- la estética final es consistente con el mock
- los widgets default no quedaron expuestos visualmente sin personalizar
- no se agregó funcionalidad nueva

---

## CHECKLIST VISUAL DE VALIDACIÓN

- la app ya no se ve como CRUD web en móvil
- cards limpias y consistentes
- navegación visual consistente con la app actual
- título y jerarquía visual claros
- badges modernos
- inputs modernos
- montos destacados
- espacio en blanco suficiente
- apariencia moderna y profesional
- coherencia entre dashboard, listas, formularios y configuración

---

## ORDEN DE EJECUCIÓN RECOMENDADO PARA LOS AGENTES

### Fase 1
Crear design system y componentes base.

### Fase 2
Mejorar navegación existente solo a nivel visual.

### Fase 3
Migrar dashboard.

### Fase 4
Migrar listado de facturas.

### Fase 5
Migrar formulario de factura.

### Fase 6
Migrar parqueos.

### Fase 7
Refinar configuración y otras pantallas secundarias.

### Fase 8
Pulido visual final, estados, responsividad, consistencia.

---

## CRITERIO DE DECISIÓN SI HAY DUDA

Si el agente duda entre:
- tocar lógica para facilitar UI
- o mantener lógica intacta y adaptar visualmente

Debe elegir siempre la segunda opción.

Si una mejora visual parece requerir tocar negocio, debe documentarlo pero no implementarlo.

---

## MENSAJE DE CONTROL PARA LOS AGENTES

Seguir este documento estrictamente.

La prioridad es:
1. no romper nada
2. no tocar lógica
3. no agregar funcionalidad nueva
4. mejorar drásticamente la UI
5. acercarse visualmente al mock de referencia
6. crear una base reusable y mantenible

---

## DEFINICIÓN DE ÉXITO

La migración se considera exitosa si:
- el usuario percibe que la app fue rediseñada por un diseñador profesional
- el comportamiento funcional se mantiene intacto
- la estética se alinea con el mock
- la base UI queda lista para escalar al resto de módulos
- no hubo regresiones funcionales

---

## REGLA FINAL

Si una tarea implica cambiar lógica, detenerse.

Este trabajo es exclusivamente de migración visual.
