# Especificación — Hito 1: núcleo incremental + UI plana

> Estado: **implementada y aprobada por el usuario (2026-11-17)**. Revisión EGM en `reviews/hito1/`.
>
> Fuentes: `GAME_DESIGN.md` §3, §4 y §11 (hito 1); `specs/incremental.md` (diseño aprobado del incremental); `specs/hito0.md` (proyecto base y procedimientos); `CLAUDE.md` (Arquitectura, Convenciones, Decisiones fijadas).

**Contexto:** *The Living Room* es un juego de terror psicológico en primera persona. El jugador juega a un incremental en una tele antigua, y lo que compra altera su piso. Este hito construye ese incremental. Va antes que la tele 3D (hito 2) y el director de miedo (hito 3) porque los dos se apoyan en él, y su ritmo tiene que estar probado primero.

**Herramientas (del hito 0):**
- `$GODOT` es la variable de entorno con la ruta del ejecutable de consola de Godot 4.7.2.
- El **MCP `godot`** es GoPeak, que ejecuta el juego y hace capturas mediante el addon `godot_mcp_runtime`, que carga el autoload `DevBoot` solo en la build de depuración.
- `tools/verify.sh` hace 5 comprobaciones: importación, tests, exportación, exclusión del addon y arranque.

**†:** marca lo que se confirma al implementar (con context7 o probándolo); si no coincide, se corrige esta especificación antes de seguir.

**Builds:** la **build de depuración** es el proyecto ejecutado con `$GODOT` sin exportar; la **build exportada** es la que se genera en `build/`.

## 1. Objetivo

La run 1 del incremental se puede jugar entera en una UI plana (2D, sin la tele 3D):
- el dial da Energía al hacer clic; la tienda vende los 6 generadores y las 18 mejoras de la run;
- las interferencias aparecen y se pueden atrapar;
- *Reiniciar* se habilita al llegar al umbral, pone a cero la run y pasa a la siguiente;
- la partida se guarda y se carga (JSON versión 1, escritura atómica y copia `.bak`, que se carga si el archivo principal está dañado);
- cada compra suena (sonido provisional);
- un test determinista demuestra que el ritmo cumple los rangos aprobados (§3.5);
- `tools/verify.sh` termina con `VERIFY OK`.

**Fuera de alcance:**
- la Carga y las mejoras permanentes (hito 4), y los umbrales de las runs 2-4 (hitos 4-5);
- la tele 3D (hito 2);
- el director, el fotograma en la estática, las luces que bajan y el audio del piso (hito 3);
- los menús de pausa y de ajustes (hitos 3 y 7), y el archivo `meta.json` (solo se documenta su formato, §4);
- **la producción con el juego cerrado**: las duraciones del GDD §3 cuentan el tiempo delante de la tele;
- comprar de 10 en 10 y vender.

## 2. Decisiones que cierra este hito

| # | Decisión | Propuesta | Por qué | Alternativas descartadas |
|---|---|---|---|---|
| D1 | Reparto en clases de `core/` | `GeneratorDef`, `UpgradeDef` y `EconomyConfig` (datos, `Resource`); `RunState` (estado de la run, `RefCounted`, serializable); `Economy` (reglas de la §3; `RefCounted`, con señales); `SaveSystem` (archivos, `RefCounted`) | Cada clase tiene una sola tarea y todas se prueban sin escena (`CLAUDE.md`, Arquitectura) | Una clase única con todo: más difícil de probar. Lógica en nodos: `CLAUDE.md` lo prohíbe |
| D2 | Autoloads | `EventBus` (solo señales), `Game` (posee `Economy` y `SaveSystem`, reenvía las señales de `core/` al `EventBus`, guarda solo) y `GameClock` (el único `_process()` con lógica: llama a `Game.tick(delta)`). Orden en `project.godot`: `DevBoot`, `EventBus`, `Game`, `GameClock` | Es lo que pide `CLAUDE.md`. El reloj va aparte porque en el hito 3 también hará avanzar al director | Reloj dentro de `Game`: habría que separarlo en el hito 3 |
| D3 | Eventos del `EventBus` | `purchase_made(item_id: StringName)` (lo escucha el sonido de compra) y `run_restarted(run_index: int)` (`CLAUDE.md` lo nombra) | Solo eventos discretos y con alguien que los use. Las señales de la interferencia llegan con el director (hito 3) | Emitir la Energía en cada tick: `CLAUDE.md` lo prohíbe |
| D4 | Datos | Un solo recurso, `data/economy_run1.tres` (`EconomyConfig`), con los generadores y las mejoras como sub-recursos | Un archivo que el test de ritmo carga directamente | Un `.tres` por generador y mejora: 24 archivos |
| D5 | Números | `float` (64 bits) para Energía y producción | Su error relativo (~10⁻¹⁶) es despreciable hasta ~10¹⁵; la run 1 se queda muy por debajo. Las runs 2-4 se revisan cuando se fijen sus umbrales (hitos 4-5) | Una librería de números grandes: innecesaria, y sería una dependencia más |
| D6 | Clics automáticos | Mantener pulsado (*Dial firme*) y *Dial solo* suman `valor del clic × clics por segundo × delta` en cada tick | Es determinista y no depende de los fotogramas; el test puede simularlo | Simular clics sueltos con temporizadores: depende del ritmo de fotogramas |
| D7 | Recompensa de la interferencia | Instantánea: `max(15 × producción por segundo, 50 × valor del clic)`, calculada al atraparla (era 60; cambiado con aprobación del usuario el 2026-11-17 en el ajuste del ritmo) | No necesita guardar un estado de bonificación. Con 15 s, atrapar interferencias acelera la run en torno a un 8-11 %: premia mirar la tele sin hacerlo obligatorio (con 60 s eran ~10 min de diferencia y no cabía en el rango de 30-40 min). El mínimo de 50 clics hace que valga la pena al principio, cuando la producción es casi 0 | ×7 a la producción durante 30 s: más estado que guardar y probar |
| D8 | Aleatoriedad | Un `RandomNumberGenerator` dentro de `Economy`, con semilla al azar al empezar o cargar. Los tests inyectan una semilla fija | El test es repetible. La partida guardada ya incluye los segundos que faltan para la próxima interferencia, que es todo lo que hace falta | Guardar la semilla y el estado: el JSON de Godot corrompe los enteros de 64 bits (comprobado con 4.7.2), habría que guardarlos como texto, y no aporta nada |
| D9 | Guardado | `user://run.json`, con `.tmp` y `.bak`; formato y reglas en la §4 | `CLAUDE.md` fija el `.tmp`, el `.bak` y que el meta-estado vaya aparte; esta especificación fija la ruta, el esquema y la validación | Ninguna para el `.tmp` y el `.bak`: los impone `CLAUDE.md`. Binario (`store_var`): no se puede leer ni comparar |
| D10 | Cuándo se guarda | Al empezar cada run (también la primera), cada 5 min de juego y al cerrar la ventana. Con la variable de entorno `TLR_NO_SAVE=1` (la usan los tests y `verify.sh`), `Game` no lee ni escribe `run.json` y empieza una partida nueva; `SaveSystem` no consulta la variable | El GDD §3 pide inicio de run y cada ~5 min; guardar al cerrar evita perder hasta 5 min. `TLR_NO_SAVE` evita que las verificaciones toquen la partida real. Va en una variable de entorno porque GUT rechaza cualquier argumento que no conoce, también los que van tras `--` (comprobado en su código) | Solo lo del GDD: se perderían hasta 5 min al cerrar |
| D11 | Runs 2 y siguientes en este hito | Usan la configuración y el umbral de la run 1 | Sus umbrales se fijan en los hitos 4-5 (GDD §11); así *Reiniciar* se puede probar varias veces | Bloquear tras el primer reinicio: no deja probar el guardado de las runs siguientes |
| D12 | Sonido provisional de compra | Un clic de la colección «UI Audio» de Kenney (CC0), en `assets/audio/ui/` | Es CC0 y de una fuente permitida por `CLAUDE.md`; se sustituye en el hito 3 | Generarlo con IA: `CLAUDE.md` lo permite, pero es más trabajo para un sonido provisional |
| D13 | Números en pantalla | Energía y costes: entero con punto de miles (`12.345`). Producción por segundo: 1 decimal por debajo de 100 (`0,2/s`) y entero a partir de 100. Los formatos de más de 10⁹ se fijan en el hito 4 | Español y sin decimales engañosos; la run 1 no pasa de ~10⁸ | Notación científica: poco legible para el jugador |
| D14 | Rangos de ritmo medibles | «Algo nuevo cada 2-3 min» se mide como «como mucho 3 min sin nada nuevo en la tienda» hasta la aparición de *Canal 3*; «un generador nuevo cada 5-6 min» admite 4-7 min entre la aparición de uno y la del siguiente; las compras por minuto, como medias por tramo (§3.5) | `specs/incremental.md` §8 da los rangos en lenguaje natural; el test necesita un límite exacto y un poco de margen | Exigir 5-6 min exactos: un ajuste a mano casi nunca cae dentro |

## 3. Reglas del núcleo (`Economy`)

### 3.1 Producción y clics

- **Multiplicadores:** cada mejora ×2 multiplica por 2 el valor actual (dos mejoras dan ×4). Sin mejoras, valen 1.
- **Producción por segundo** = suma, para cada generador, de `poseídos × producción base × multiplicador del generador`.
- **Valor del clic** = `1 × multiplicador del clic` + `0,02 × producción por segundo` si se tiene *Resonancia*.
- **Clic manual** (`click()`): suma el valor del clic. Cuenta siempre, también si se ha mantenido pulsado.
- **`tick(delta: float, holding: bool)`:**
  1. Suma `producción × delta`.
  2. Suma `valor del clic × clics automáticos × delta`. Los clics automáticos son la suma de dos partes: el dial sostenido (si `holding`, el valor de la mejora `HOLD_RATE` comprada, 4 en *Dial firme*; si no, 0) y el dial solo (el mayor valor de las mejoras `AUTO_CLICK_RATE` compradas: 2 en *Dial solo*, 5 en *Dial solo II*; si no, 0).
  3. Avanza el temporizador de la interferencia (§3.3).
  4. Suma `delta` a `play_time`.
- Lo que se gana va a la **Energía** y a la **Energía producida en la run**, que es lo que mide el umbral.
- **Mantener pulsado:** mientras el botón del dial está pulsado se suman los clics del dial sostenido; un clic rápido añade una fracción insignificante. `holding` lo fija la UI (`Game.set_holding`) y se pone a `false` si la ventana pierde el foco.
- **Los efectos salen de los datos:** `Economy` aplica cada mejora según su `kind` (`GENERATOR_MULT`, `CLICK_MULT`, `HOLD_RATE`, `CLICK_PRODUCTION_SHARE`, `AUTO_CLICK_RATE`) y su `value`, leídos del `.tres`. No hay números de efectos escritos en el código.

### 3.2 Tienda

- **Coste de un generador** = `ceil(coste base × 1,15 ^ poseídos)`.
- **Aparición:** generadores y mejoras siguen la misma regla: aparecen cuando se cumple su requisito (Energía producida en la run y, en las mejoras de generador, generadores poseídos). Una vez visible, nada desaparece en esa run.
- **Comprar** algo sin Energía suficiente, algo ya comprado, una mejora cuyo requisito no se cumple o un generador no visible no hace nada y devuelve `false`.

### 3.3 Interferencias

- Hay un temporizador `next_in`. Al empezar una run, y cada vez que termina una interferencia, se sortea entre 120 y 240 s.
- Cuando llega a 0, empieza una interferencia de 8 s (`active_left`).
- `catch_interference()` solo funciona si hay una activa. Paga la recompensa de D7 una vez y la termina. No cuenta como clic del dial, y los clics automáticos no la atrapan: solo un clic del jugador sobre la capa de estática.
- Si pasan los 8 s sin atraparla, termina sin recompensa.

### 3.4 Reiniciar

Es posible si `Energía producida en la run ≥ umbral`. Pone a cero la Energía, la Energía producida, `play_time`, los generadores y las mejoras; cancela una interferencia activa y sortea un `next_in` nuevo; suma 1 al número de run y emite `restarted`. `Game` guarda al recibirla (D10).

### 3.5 Valores iniciales y ritmo

**Generadores** (en `data/economy_run1.tres`). Coste base = `15 × 9^posición`; producción base = `0,2 × 6^posición` (posición 0 a 5):

| Posición | id | Nombre (clave de traducción) | Coste base | Producción base (/s) | Aparece con (Energía producida) |
|---|---|---|---|---|---|
| 0 | `antenna` | `GEN_ANTENNA` | 15 | 0,2 | 0 |
| 1 | `valves` | `GEN_VALVES` | 135 | 1,2 | 400 |
| 2 | `audio_frequency` | `GEN_AUDIO_FREQUENCY` | 1.215 | 7,2 | 5.000 |
| 3 | `tuner` | `GEN_TUNER` | 10.935 | 43,2 | 50.000 |
| 4 | `remote` | `GEN_REMOTE` | 98.415 | 259,2 | 500.000 |
| 5 | `channel_3` | `GEN_CHANNEL_3` | 885.735 | 1.555,2 | 4.000.000 |

Los requisitos de aparición se ajustan en el paso 3 para que los generadores aparezcan hacia los minutos 0/5/10/15/20,5/26, en el centro de los rangos de abajo. `specs/incremental.md` §3 daba 22 y 28: mandan los rangos, y la diferencia se enseña al usuario en el paso 8.

**Mejoras de generador (12):** `<id>_x2_10` (requisito: 10 poseídos; coste: 12 × coste base) y `<id>_x2_25` (requisito: 25 poseídos; coste: 120 × coste base). Efecto: ×2 a ese generador.

**Mejoras de clic (6):**

| id | Nombre | Requisito | Coste inicial | Efecto |
|---|---|---|---|---|
| `pulse` | *Pulso* | ninguno | 5 | `CLICK_MULT` 2 |
| `dial_hold` | *Dial firme* | 150 de Energía producida | 100 | `HOLD_RATE` 4 (mantener pulsado = 4 clics/s más) |
| `pulse_strong` | *Pulso fuerte* | 5.000 producida | 2.500 | `CLICK_MULT` 2 |
| `resonance` | *Resonancia* | 30.000 producida | 15.000 | `CLICK_PRODUCTION_SHARE` 0,02 |
| `dial_auto` | *Dial solo* | 150.000 producida | 75.000 | `AUTO_CLICK_RATE` 2 |
| `dial_auto_2` | *Dial solo II* | 2.000.000 producida | 1.000.000 | `AUTO_CLICK_RATE` 5 (cuenta la mayor tasa comprada) |

**Umbral inicial:** 10.000.000 de Energía producida (mayor que el coste de lo que se espera comprar). Todos estos valores son iniciales: el paso 3 de la §6 los ajusta. **Resultado del ajuste (2026-11-17):** los valores finales están en `data/economy_run1.tres` (generado por `tools/gen_economy_tres.py`): coste `15 × 6^posición`, producción `0,2 × 5,5^posición`, umbral 6.986.879 y recompensa de la interferencia de 15 s (D7). Para cumplir el rango «algo nuevo cada ≤ 3 min», cada novedad tiene un minuto objetivo en un calendario, y las mejoras ×2 piden además Energía producida (siguen pidiendo 10 o 25 del generador). Los efectos aprobados no cambian. **Reajuste del 2026-11-18 (economía centrada en el clic, pedido por el usuario):** cada generador tiene un bono por clic (`click_bonus` = 0,03 × 0,2 × 5,5^posición, multiplicado por los ×2 del generador y por *Pulso*) y produce 0,4 × 0,2 × 5,5^posición por segundo; *Dial firme* pasa a 6 clics/s; umbral 16.846.002. Requisitos y costes de las mejoras de clic (= requisito / 2) recalculados para conservar los minutos de aparición; todos los rangos se siguen cumpliendo.

**Rangos que comprueba el test de ritmo** (de `specs/incremental.md` §8, traducidos a medidas comprobables; la traducción es la decisión D14):

| Medida | Rango | Cómo se mide |
|---|---|---|
| Primera compra | ≤ 15 s | segundo de la primera compra |
| Algo nuevo en la tienda | ≤ 180 s sin nada nuevo | hueco más largo entre dos apariciones (de generador o de mejora), desde t = 0 hasta la aparición de *Canal 3* |
| Generador nuevo | 240-420 s | tiempo entre la aparición de un generador y la del siguiente, para los 5 pares |
| Compras por minuto (sin contar clics automáticos) | 3-8 y ≥ 1,5 | media de los minutos 0-15 entre 3 y 8; media desde el minuto 15 hasta el umbral ≥ 1,5 |
| Minuto en que se habilita *Reiniciar* | 30-40 | minuto en que la Energía producida alcanza el umbral |

Todos los rangos se cumplen en las 4 simulaciones del test (§7).

Minutos aproximados de aparición de las mejoras de clic (`specs/incremental.md` §2): *Pulso* 0, *Dial firme* 2, *Pulso fuerte* 8, *Resonancia* 12, *Dial solo* 18, *Dial solo II* 26.

## 4. Formato de guardado (versión 1)

**`user://run.json`** (`X` en esta sección es `run.json`):

```json
{
  "version": 1,
  "run_index": 1,
  "energy": 0.0,
  "energy_produced_run": 0.0,
  "generators": { "antenna": 3, "valves": 1 },
  "upgrades": ["pulse"],
  "interference": { "next_in": 150.0, "active_left": 0.0 },
  "play_time": 0.0
}
```

- `play_time`: segundos jugados en la run actual; vuelve a 0 al reiniciar. El guardado periódico usa su propio contador de 5 min, que no se guarda.
- `generators` es un diccionario `id → poseídos`; `upgrades` es una lista de `id`. Los `id` son el campo `id` de cada `GeneratorDef` y `UpgradeDef` del `.tres` (§3.5).

**`user://meta.json`** (reservado; no se crea en este hito): `{ "version": 1, "last_ending": "" }`. `last_ending` es `""` o el id de un final; los ids se fijan en el hito 6.

**Escritura atómica:** se escribe `X.tmp`; si existe `X`, se renombra a `X.bak` (sustituye al `.bak` anterior); se renombra `X.tmp` a `X`. En Windows, renombrar sobre un archivo existente lo sustituye (comprobado con Godot 4.7.2).

**Lectura:**
1. Si existe un `X.tmp` sobrante (de un cierre a medias), se borra.
2. Si no existen ni `X` ni `X.bak`, es la primera vez: partida nueva, sin aviso.
3. Si falta `X` pero existe `X.bak` (el juego se cortó entre los dos renombrados), se lee el `.bak` sin crear ningún `.corrupt`.
4. Se lee `X`. Si es **ilegible**, se renombra a `X.corrupt` (sustituye al anterior), se registra un aviso y se intenta `X.bak`. Si no hay `.bak`, o también es ilegible (se renombra a `X.bak.corrupt`), se empieza una partida nueva. Lo mismo en el caso 3 si el `.bak` es ilegible. Nunca se borran `X` ni `X.bak`.

**Cómo se lee y se escribe:**
- Antes de abrir un archivo se comprueba `FileAccess.file_exists`.
- El texto se analiza con `JSON.new().parse(text)` y se comprueba el `Error` que devuelve. No se usa `JSON.parse_string`, que escribe un error del motor, y GUT cuenta esos errores como fallo de test.
- Los avisos van con `push_warning`, nunca con `push_error`.
- Se escribe con `JSON.stringify(datos, "", true, true)`, con precisión completa.
- `save_run` crea la carpeta si falta.

**Ilegible** significa cualquiera de estas cosas:
- no es JSON;
- no tiene `version`, o su versión es mayor que 1;
- falta una clave obligatoria (todas las del ejemplo), o tiene otro tipo;
- un elemento de `generators` o de `upgrades` tiene otro tipo.

Al cargar, un número puede venir como `int` o `float` y un id como `String` o `StringName`; los enteros se convierten desde `float` (el JSON de Godot devuelve todos los números como `float`), y los valores negativos se ponen a 0. Un `id` desconocido se ignora con un aviso, para que renombrar algo no haga perder la partida.

No hay migradores en este hito, porque solo existe la versión 1. El primero llega en el hito 4, con su test (GDD §11).


## 5. Archivos e interfaces

### 5.1 Lista de archivos

```
core/generator_def.gd              crear (class_name GeneratorDef)
core/upgrade_def.gd                crear (class_name UpgradeDef)
core/economy_config.gd             crear (class_name EconomyConfig)
core/run_state.gd                  crear (class_name RunState)
core/economy.gd                    crear (class_name Economy)
core/save_system.gd                crear (class_name SaveSystem)
data/economy_run1.tres             crear (EconomyConfig con los 6 generadores y las 18 mejoras de la §3.5)
autoload/event_bus.gd              crear
autoload/game.gd                   crear
autoload/game_clock.gd             crear
presentation/ui/tv_game_ui.tscn    crear
presentation/ui/tv_game_ui.gd      crear
presentation/ui/number_format.gd   crear (class_name NumberFormat)
presentation/main.tscn             modificar (§5.4)
presentation/main.gd               modificar (§5.4)
assets/audio/ui/purchase.ogg       crear (Kenney, CC0; §6 paso 4)
locale/strings.csv                 modificar (§5.6)
project.godot                      modificar (autoloads de D2)
tests/test_economy.gd              crear
tests/test_run_state.gd            crear
tests/test_save_system.gd          crear
tests/test_pacing.gd               crear
tests/test_number_format.gd        crear
tests/test_smoke.gd                sin cambios (usa la clave TITLE, que se mantiene)
tools/verify.sh                    modificar (§6 paso 1)
ASSETS.md                          modificar (sonido de Kenney; §6 paso 4)
specs/incremental.md               modificar solo si el paso 8 aprueba cambios
GAME_DESIGN.md                     modificar (§6 paso 9)
specs/hito1.md                     modificar (línea de estado; §6 paso 9)
```

Archivos que genera Godot y que se versionan, como en el hito 0: el `.uid` de cada script nuevo, `assets/audio/ui/purchase.ogg.import` y `locale/strings.es.translation`, regenerado.

### 5.2 Datos (`Resource`)

Campos exportados (`@export`), con su tipo y valor inicial:

| Clase | Campo | Tipo | Valor inicial / nota |
|---|---|---|---|
| `GeneratorDef` | `id` | `StringName` | §3.5 |
| | `name_key` | `String` | clave de traducción |
| | `base_cost`, `base_production`, `req_energy_produced` | `float` | §3.5 |
| `UpgradeDef` | `id` | `StringName` | §3.5 |
| | `name_key`, `desc_key` | `String` | §5.6 |
| | `kind` | `Kind` (enum de la clase: `GENERATOR_MULT`, `CLICK_MULT`, `HOLD_RATE`, `CLICK_PRODUCTION_SHARE`, `AUTO_CLICK_RATE`) | §3.5 |
| | `target_id` | `StringName` | generador afectado; vacío en las de clic |
| | `value`, `cost`, `req_energy_produced` | `float` | §3.5; en las de generador, Energía producida que piden además de los 10 o 25 poseídos (calendario del ajuste; 0 si no hace falta) |
| | `req_generator_count` | `int` | 10 o 25 en las de generador; 0 en las de clic |
| `EconomyConfig` | `generators` | `Array[GeneratorDef]` | 6 |
| | `upgrades` | `Array[UpgradeDef]` | 18 |
| | `cost_growth` | `float` | 1,15 |
| | `threshold` | `float` | 10.000.000 |
| | `base_click_value` | `float` | 1 |
| | `interference_min`, `interference_max`, `interference_duration` | `float` | 120, 240, 8 |
| | `reward_production_seconds`, `reward_min_clicks` | `float` | 15, 50 |

Formato del `.tres` † (se confirma al escribirlo, importándolo sin errores):
- una cabecera `[gd_resource type="Resource" script_class="EconomyConfig" ...]`;
- un `[ext_resource]` por script;
- un `[sub_resource type="Resource" id="..."]` por generador y mejora, con `script = ExtResource(...)` y sus campos;
- un `[resource]` final con `script = ExtResource("...")` (el de `economy_config.gd`), `generators = Array[ExtResource("...")]([SubResource("..."), ...])`, y lo mismo para `upgrades`.

### 5.3 Interfaces del núcleo y de los autoloads

**`RunState`** (`RefCounted`)
- Campos: `run_index: int`, `energy: float`, `energy_produced_run: float`, `generators: Dictionary` (`StringName` → `int`), `upgrades: Array[StringName]`, `interference_next_in: float`, `interference_active_left: float`, `play_time: float`.
- `to_dict() -> Dictionary`: el formato de la §4.
- `static from_dict(d: Dictionary, config: EconomyConfig, warnings: PackedStringArray) -> RunState`: devuelve `null` si es ilegible (§4) y añade a `warnings` los `id` desconocidos.
- `static new_run(config: EconomyConfig, run_index: int, rng: RandomNumberGenerator) -> RunState`: una run nueva, con `next_in` sorteado.

**`Economy`** (`RefCounted`)
- `_init(config: EconomyConfig, state: RunState = null, rng_seed: int = -1)`: con -1 se usa una semilla al azar. Si `state` es `null`, crea la run 1 con `RunState.new_run` y su propio generador, así que solo hay uno y los tests lo siembran.
- Señales: `purchased(item_id: StringName)` y `restarted(run_index: int)`.
- Acciones: `click()`, `tick(delta: float, holding: bool)`, `buy(id: StringName) -> bool`, `catch_interference() -> bool`, `restart() -> bool`.
- Consultas: `production_per_second() -> float`, `generator_production(id: StringName) -> float` (producción total de un generador, para la tienda), `click_value() -> float`, `cost_of(id: StringName) -> float`, `is_visible(id: StringName) -> bool`, `is_bought(id: StringName) -> bool`, `owned(id: StringName) -> int`, `can_restart() -> bool`, `interference_active() -> bool`, `visible_generators() -> Array[GeneratorDef]`, `visible_upgrades() -> Array[UpgradeDef]` (visibles y no compradas).
- Para el test de ritmo:
  - `income_per_second(manual_cps: float, holding: bool) -> float`: producción + clics manuales + clics automáticos.
  - `gain_if_bought(id: StringName, manual_cps: float, holding: bool) -> float`: cuánto subiría `income_per_second` con esa compra, sin comprar y sin exigir Energía.

**`SaveSystem`** (`RefCounted`)
- `_init(dir: String = "user://")`.
- `load_run(config: EconomyConfig) -> RunState`: `null` significa partida nueva.
- `save_run(state: RunState) -> bool`.
- `warnings: PackedStringArray`: los avisos de la última carga.

**`EventBus`** (autoload): `signal purchase_made(item_id: StringName)` y `signal run_restarted(run_index: int)`.

**`Game`** (autoload)
- Interfaz: `economy: Economy`, `click()`, `set_holding(value: bool)`, `buy(id: StringName) -> bool`, `catch_interference() -> bool`, `restart() -> bool`, `tick(delta: float)`.
- Reenvía `purchased` → `EventBus.purchase_made` y `restarted` → `EventBus.run_restarted`.
- **Guardado:**
  - Al arrancar, carga `res://data/economy_run1.tres` y la partida (`SaveSystem.load_run`). Si no hay partida, crea `Economy` con `state = null` y la guarda.
  - Guarda también al recibir `restarted`, cada 300 s de juego (constante `AUTOSAVE_INTERVAL` en `game.gd`) y al cerrar.
  - Con `TLR_NO_SAVE=1` (`OS.get_environment("TLR_NO_SAVE") == "1"`) no lee ni escribe. Solo `Game` lo comprueba.
- **Cierre y foco:**
  - En `_ready` pone `get_tree().auto_accept_quit = false`.
  - En `_notification`, con `NOTIFICATION_APPLICATION_FOCUS_OUT` llama a `set_holding(false)`.
  - Con `NOTIFICATION_WM_CLOSE_REQUEST` guarda y llama a `get_tree().quit()`, también si el guardado falla.

**`GameClock`** (autoload): `_process(delta)` llama a `Game.tick(delta)`. Es el único `_process` con lógica de juego.

**`NumberFormat`**
- `static func energy(x: float) -> String`: truncado a entero, con punto de miles.
- `static func rate(x: float) -> String`, seguido siempre de `/s`:
  - por debajo de 100, 1 decimal con coma, redondeado (si al redondear da 100, pasa al formato entero);
  - a partir de 100, entero redondeado con punto de miles.

### 5.4 Escena principal

- **`main.tscn`:** la raíz pasa a ser `Main` (`Node`, script `main.gd`), con un único hijo, `TvGameUI` (instancia de `tv_game_ui.tscn`). Se quitan `Camera3D`, `DirectionalLight3D` y `Label3D`.
- **`main.gd`:** `extends Node`; su `_ready()` solo hace `print("BOOT_OK")`. Se quita la línea `$Label3D.text = tr("TITLE")`, que daría error.

### 5.5 UI plana (`tv_game_ui.tscn`)

```
TvGameUI (Control, pantalla completa, script tv_game_ui.gd)
├── Background (ColorRect, color oscuro, mouse_filter = IGNORE)
├── Layout (HBoxContainer, pantalla completa, con márgenes)
│   ├── Left (VBoxContainer)
│   │   ├── EnergyLabel (Label)
│   │   ├── ProductionLabel (Label)
│   │   ├── Dial (Button, grande)
│   │   ├── RestartButton (Button)
│   │   └── RestartProgress (Label)
│   └── ShopScroll (ScrollContainer) > ShopList (VBoxContainer)
├── Interference (Button, pantalla completa, plano, oculto)
│   ├── Static (ColorRect gris semitransparente, mouse_filter = IGNORE)
│   └── Hint (Label, UI_INTERFERENCE, mouse_filter = IGNORE)
└── PurchaseSound (AudioStreamPlayer, stream = purchase.ogg)
```

- **Dial:** `pressed` → `Game.click()`; `button_down` y `button_up` → `Game.set_holding(true)` y `Game.set_holding(false)`.
- **Tienda:**
  - Cuando un generador o una mejora se vuelve visible, se crea un `Button` en `ShopList` y se guarda en un diccionario `id → Button`.
  - Cada fotograma se actualizan su texto y su `disabled` (Energía insuficiente). Una mejora comprada se quita.
  - Un generador muestra su nombre, poseídos, producción total y coste (el orden de `UI_GENERATOR_ROW`); una mejora, su nombre, su descripción y su coste. Las mejoras de generador rellenan su `%s` con el nombre traducido del generador de su `target_id`.
  - Con `EventBus.run_restarted` se liberan todas las filas de `ShopList` y se vacía el diccionario.
  - `pressed` → `Game.buy(id)`.
- **Reiniciar:** `RestartButton.disabled = not can_restart()`; `pressed` → `Game.restart()`. `RestartProgress` muestra `Energía producida / umbral`.
- **Interferencia:** `Interference.visible = interference_active()`; `pressed` → `Game.catch_interference()`. La estática real llega con la tele (hitos 2-3).
- **Sonido:** `EventBus.purchase_made` → `PurchaseSound.play()`.
- **Actualización:** la UI lee `Game.economy` en su `_process` (solo pinta, sin lógica de juego). Todos los textos van con `tr()`.
- **Fuera de este hito:** el medidor de señal de `specs/incremental.md` §1.

### 5.6 Textos (`locale/strings.csv`)

Se mantiene `TITLE`. Se añaden:

| Clave | es |
|---|---|
| `UI_ENERGY` | `Energía: %s` |
| `UI_PRODUCTION` | `Producción: %s` |
| `UI_DIAL` | `Sintonizar` |
| `UI_RESTART` | `Reiniciar` |
| `UI_RESTART_PROGRESS` | `%s / %s` |
| `UI_INTERFERENCE` | `Interferencia: pulsa para atraparla` |
| `UI_GENERATOR_ROW` | `%s — tienes %s — %s — coste %s` |
| `UI_UPGRADE_ROW` | `%s: %s — coste %s` |
| `GEN_ANTENNA`, `GEN_VALVES`, `GEN_AUDIO_FREQUENCY`, `GEN_TUNER`, `GEN_REMOTE`, `GEN_CHANNEL_3` | `Antena`, `Válvulas`, `Frecuencia de audio`, `Sintonizador`, `Mando a distancia`, `Canal 3` |
| `UPG_PULSE`, `UPG_DIAL_HOLD`, `UPG_PULSE_STRONG`, `UPG_RESONANCE`, `UPG_DIAL_AUTO`, `UPG_DIAL_AUTO_2` | `Pulso`, `Dial firme`, `Pulso fuerte`, `Resonancia`, `Dial solo`, `Dial solo II` |
| `UPG_PULSE_DESC`, `UPG_PULSE_STRONG_DESC` | `Cada clic vale el doble` |
| `UPG_DIAL_HOLD_DESC` | `Mantén pulsado el dial para sintonizar sin parar` |
| `UPG_RESONANCE_DESC` | `Cada clic suma parte de la producción` |
| `UPG_DIAL_AUTO_DESC`, `UPG_DIAL_AUTO_2_DESC` | `El dial gira solo` |
| `UPG_GEN_X2_10` | `%s ×2` |
| `UPG_GEN_X2_25` | `%s ×2 (25)` |
| `UPG_GEN_X2_DESC` | `Duplica la producción de %s` |

Los `%s` se rellenan con `tr(clave) % [valores]`.

## 6. Pasos

1. **Núcleo y `verify.sh`:**
   - Cambiar `verify.sh`:
     - comprobación 2: `TLR_NO_SAVE=1 "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd`. Pasa si el log contiene `---- All tests passed! ----` y la línea `Scripts` con un 6 (`grep -q -E 'Scripts +6$'`), y no contiene `SCRIPT ERROR` ni `Parse Error`;
     - comprobación 5: `TLR_NO_SAVE=1 ./build/TheLivingRoom.exe` con los argumentos actuales;
     - se actualizan los comentarios.
   - Crear las clases de `core/` y `test_economy.gd`, `test_run_state.gd` y `test_save_system.gd`, y comprobar que pasan. Hasta el paso 4 no existen los 6 scripts de test, así que los tests se ejecutan con GUT directamente, siempre con `TLR_NO_SAVE=1`.
2. Crear `data/economy_run1.tres` con los valores iniciales de la §3.5 y comprobar que se carga con `load()` y pasa `test_config_valid` (§7).
3. **Crear `test_pacing.gd` y ajustar el ritmo**, en este orden:
   1. Medir con los valores iniciales. La **diferencia** es el minuto del umbral más tardío menos el más temprano de las 4 simulaciones; la **media** es la media de esos 4 minutos.
   2. Bajar la diferencia por debajo de 10 minutos tocando solo las mejoras de clic (costes, requisitos y efectos).
   3. Llevar la media a 35 ± 1 minutos con el umbral y con los factores de la fórmula de los generadores (coste `15 × a^posición`, producción `0,2 × b^posición`).
   4. Ajustar los requisitos de aparición y los costes de las mejoras de generador hasta cumplir el resto de rangos de la §3.5. Mandan los rangos sobre los minutos objetivo.

   Si al terminar algún rango no se cumple, se para y se le enseña al usuario lo más cercano conseguido. Los rangos no se cambian sin su aprobación. Si el ajuste cambia un efecto o un minuto de aparición aprobados en `specs/incremental.md` (×2, 4 clics/s…), se le dice al usuario en el paso 8.
4. **Presentación:**
   - Crear los autoloads, `NumberFormat` y `test_number_format.gd`, la UI (§5.5) y los textos (§5.6).
   - Modificar `main.tscn`, `main.gd` (§5.4) y `project.godot`.
   - Descargar el paquete «UI Audio» de Kenney (`https://kenney.nl/assets/ui-audio`), comprobar su licencia (CC0) y copiar `click1.ogg` † (o el clic más neutro del paquete) como `assets/audio/ui/purchase.ogg`. Registrarlo en `ASSETS.md`.
5. Pasar el LSP a todos los scripts nuevos y modificados: cero errores. Procedimiento del hito 0, paso 6: editor headless con `--lsp-port 6005`, `lsp_get_diagnostics` por script y cerrar el proceso por su línea de comandos.
6. **Captura y prueba con GoPeak** (hito 0, paso 7: grupo de herramientas `testing`, `run_project` con ventana, `capture_screenshot` con hasta 10 reintentos, `stop_project`):
   - borrar antes `run.json*`, como en el paso 8;
   - capturar la UI recién arrancada;
   - con `inject_mouse_click` de GoPeak (grupo `testing`) †, hacer clic en el dial hasta tener 15 de Energía, comprar una Antena y comprobar en una segunda captura que la producción pasa a `0,2/s`;
   - enseñarle las dos capturas al usuario.

   Si `inject_mouse_click` no sirve, la compra se deja para la prueba del usuario.
7. Ejecutar `verify.sh` y comprobar que termina con `VERIFY OK`.
8. **Prueba del usuario:**
   - Borrar las partidas de las pruebas (`run.json`, `run.json.bak`, `run.json.tmp` y `run.json*.corrupt` en `%APPDATA%/Godot/app_userdata/The Living Room/`).
   - El usuario juega la build exportada el tiempo que quiera y aprueba la UI.
   - Aprueba el ritmo con la línea de tiempo de las 4 simulaciones y los valores finales del `.tres`, que se le enseñan, junto con los efectos o minutos de aparición que haya cambiado el ajuste (paso 3).
9. Actualizar el GDD:
   - §4: el umbral final y la nota del balance de la run 1, que remite al `.tres`;
   - §4: quitar el [PENDIENTE] del balance de la run 1;
   - §12: cerrar «Rangos de ritmo del hito 1» y limitar el balance pendiente a las runs 2-4;
   - `specs/incremental.md`, si el usuario aprobó cambios en el paso 8.

   Actualizar la línea de estado de esta especificación. Commit y push.

## 7. Tests

| Test | Qué comprueba |
|---|---|
| `test_economy.gd` | Con un `EconomyConfig` pequeño creado en el propio test (no lee el `.tres`, para que el ajuste no lo rompa) y semilla fija:<br>• el clic suma el valor del clic;<br>• comprar descuenta el coste y el siguiente es `ceil(base × 1,15^n)`;<br>• no se compra sin Energía, lo ya comprado, una mejora sin su requisito ni un generador no visible;<br>• `tick` suma la producción y `play_time`;<br>• los multiplicadores se multiplican entre sí;<br>• cada `kind` aplica su efecto;<br>• `HOLD_RATE` solo cuenta con `holding`;<br>• con dos `AUTO_CLICK_RATE` cuenta la mayor;<br>• `restart` solo funciona con el umbral y deja todo a cero con la run +1;<br>• la interferencia aparece entre 120 y 240 s y dura 8 s;<br>• `catch_interference` paga D7 una sola vez, y si no se atrapa no paga;<br>• `restart` cancela la interferencia activa;<br>• `gain_if_bought` no cambia el estado;<br>• cada señal se emite una vez por evento (`watch_signals` y `assert_signal_emit_count`) |
| `test_run_state.gd` | `to_dict` → `from_dict` devuelve el mismo estado.<br>Un `id` desconocido se ignora y queda en `warnings`.<br>Devuelve `null` si al diccionario le falta una clave, si una clave es de otro tipo o si un elemento es de otro tipo.<br>Los negativos pasan a 0.<br>Acepta números `int` o `float` e ids `String` o `StringName`. |
| `test_save_system.gd` | En `user://test_save/`, que se borra en `after_each`:<br>• guardar y cargar, pasando por JSON, recupera los mismos valores;<br>• la escritura deja en `.bak` la versión anterior;<br>• la primera vez devuelve `null` sin avisos;<br>• con el principal dañado y el `.bak` bueno, se carga el `.bak`, el principal pasa a `.corrupt`, y tras un guardado nuevo el `.bak` sigue siendo el bueno;<br>• con los dos dañados, `null` y los dos `.corrupt`;<br>• sin `X` pero con `.bak`, se carga el `.bak` sin crear `.corrupt`;<br>• la versión 2 se trata como ilegible;<br>• un `.tmp` sobrante se borra;<br>• `X` ilegible y sin `.bak`: `null`;<br>• solo `.bak` e ilegible: `null` y `X.bak.corrupt`;<br>• un archivo sin `version` es ilegible;<br>• leer un archivo dañado no produce errores del motor (el test pasa con el rastreador de errores de GUT activo) |
| `test_pacing.gd` | • **`test_config_valid`** (primer test): carga el `.tres` con `load()` y comprueba que es un `EconomyConfig` con 6 generadores y 18 mejoras, `id` únicos e iguales a los de la §3.5, `target_id` que existen, `req_generator_count` de 10 o 25 en las de generador, y que todas las `name_key` y `desc_key` tienen traducción (`tr(k) != k`).<br>• **Simulación:** carga `data/economy_run1.tres` y simula la run 1 con pasos de 0,25 s (`tick(0.25, holding)`), semilla 1 y un máximo de 60 min simulados (si se llega a él, el test falla).<br>• **Cada paso, en este orden:** atrapar la interferencia (si toca), clics manuales, compras y `tick`. La simulación termina al llegar al umbral.<br>• **Compras:** se repite hasta que no compra nada. Elige lo de mayor `gain_if_bought(id, manual_cps, holding) / coste` y salta lo que no añade nada; en un empate gana el primero en el orden del `.tres`. Si eso tardaría más de 30 s en poder pagarse al ritmo de `income_per_second(manual_cps, holding)`, compra en su lugar lo mejor que ya pueda pagar.<br>• **Clics manuales:** un acumulador suma `manual_cps × 0,25` en cada paso y llama a `click()` cada vez que llega a 1.<br>• **4 simulaciones:** 2 perfiles × con y sin atrapar interferencias. *Activo:* 6 clics/s, nunca sostiene. *Tranquilo:* pasa siempre `holding = true` (no tiene efecto hasta comprar *Dial firme*); `manual_cps` vale 0,5 hasta tenerla y 0 después.<br>• **Interferencias:** la simulación que las atrapa lo hace en el primer paso en que están activas.<br>• **Resultado:** el simulador devuelve una línea de tiempo (compras, apariciones y minuto del umbral), que se imprime en el log, y el test comprueba los rangos de la §3.5 |
| `test_number_format.gd` | `energy`: 0 → `0`; 12345 → `12.345`; 1000000 → `1.000.000`; 99,6 → `99`.<br>`rate`: 0 → `0,0/s`; 0,2 → `0,2/s`; 99,9 → `99,9/s`; 99,96 → `100/s`; 1555,2 → `1.555/s`; 1555,6 → `1.556/s` |

## 8. Criterio de cierre

- Los tests pasan y `verify.sh` termina con `VERIFY OK`.
- Las capturas de la UI se han enseñado al usuario.
- El usuario juega la build exportada y aprueba la UI. Aprueba el ritmo con la línea de tiempo de las simulaciones.
- El GDD (§6, paso 9) y `ASSETS.md` (§6, paso 4) están actualizados.
- Commit y push.

## 9. Riesgos

- **El ritmo no cuadra en las 4 simulaciones a la vez:** el ajuste en orden del paso 3 lo intenta. Si no lo consigue, decide el usuario (§6, paso 3).
- **Partida guardada dañada:** la lectura de la §4 nunca borra `X` ni `X.bak` y siempre deja jugar. En el peor caso se empieza una partida nueva.
- **Precisión de los números:** el `float` basta para la run 1 (D5). Los umbrales de las runs 2-4 se revisan en los hitos 4-5.
- **Cerrar sin guardar:** si Windows cierra el proceso a la fuerza (por ejemplo, al apagar), se pierde como mucho lo jugado desde el último guardado periódico (≤ 5 min).
- **Formato del `.tres` escrito a mano:** si está mal escrito, `test_config_valid` lo detecta en el paso 2, antes de seguir.
