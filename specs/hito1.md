# Especificación — Hito 1: núcleo incremental + UI plana

> Estado: **borrador, en revisión EGM** (etapas 5-7 aplicadas; informes en `reviews/hito1/`). No se escribe código hasta que el usuario lo apruebe.
>
> Fuentes: `GAME_DESIGN.md` §3, §4 y §11 (hito 1); `specs/incremental.md` (diseño aprobado del incremental); `specs/hito0.md` (proyecto base y procedimientos); `CLAUDE.md` (Arquitectura, Convenciones, Decisiones fijadas).

**Contexto:** *The Living Room* es un juego de terror psicológico en primera persona. El jugador juega a un incremental en una tele antigua, y lo que compra altera su piso. Este hito construye ese incremental. Va antes que la tele 3D (hito 2) y el director de miedo (hito 3) porque los dos se apoyan en él, y su ritmo tiene que estar probado primero.

**Herramientas (del hito 0):**
- `$GODOT` es la variable de entorno con la ruta del ejecutable de consola de Godot 4.7.2.
- El **MCP `godot`** es GoPeak, que ejecuta el juego y hace capturas mediante el addon `godot_mcp_runtime`, que carga el autoload `DevBoot` solo en la build de depuración.
- `tools/verify.sh` hace 5 comprobaciones: importación, tests, exportación, exclusión del addon y arranque.

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
| D7 | Recompensa de la interferencia | Instantánea: `max(60 × producción por segundo, 50 × valor del clic)`, calculada al atraparla | No necesita guardar un estado de bonificación. El mínimo de 50 clics hace que valga la pena al principio, cuando la producción es casi 0 | ×7 a la producción durante 30 s: más estado que guardar y probar |
| D8 | Aleatoriedad | Un `RandomNumberGenerator` dentro de `Economy`, con semilla al azar al empezar o cargar. Los tests inyectan una semilla fija | El test es repetible. La partida guardada ya incluye los segundos que faltan para la próxima interferencia, que es todo lo que hace falta | Guardar la semilla y el estado: el JSON de Godot corrompe los enteros de 64 bits (comprobado con 4.7.2), habría que guardarlos como texto, y no aporta nada |
| D9 | Guardado | `user://run.json`, con `.tmp` y `.bak`; formato y reglas en la §4 | `CLAUDE.md` fija el `.tmp`, el `.bak` y que el meta-estado vaya aparte; esta especificación fija la ruta, el esquema y la validación | Ninguna para el `.tmp` y el `.bak`: los impone `CLAUDE.md`. Binario (`store_var`): no se puede leer ni comparar |
| D10 | Cuándo se guarda | Al empezar cada run (también la primera), cada 5 min de juego y al cerrar la ventana. No se guarda si el juego arranca con el argumento de usuario `--no-save`, que usan los tests y `verify.sh` | El GDD §3 pide inicio de run y cada ~5 min; guardar al cerrar evita perder hasta 5 min. `--no-save` evita que las verificaciones toquen la partida real | Solo lo del GDD: se perderían hasta 5 min al cerrar |
| D11 | Runs 2 y siguientes en este hito | Usan la configuración y el umbral de la run 1 | Sus umbrales se fijan en los hitos 4-5 (GDD §11); así *Reiniciar* se puede probar varias veces | Bloquear tras el primer reinicio: no deja probar el guardado de las runs siguientes |
| D12 | Sonido provisional de compra | Un clic de la colección «UI Audio» de Kenney (CC0), en `assets/audio/ui/` | Es CC0 y de una fuente permitida por `CLAUDE.md`; se sustituye en el hito 3 | Generarlo con IA: `CLAUDE.md` lo permite, pero es más trabajo para un sonido provisional |
| D13 | Números en pantalla | Energía y costes: entero con punto de miles (`12.345`). Producción por segundo: 1 decimal por debajo de 100 (`0,2/s`) y entero a partir de 100. Los formatos de más de 10⁹ se fijan en el hito 4 | Español y sin decimales engañosos; la run 1 no pasa de ~10⁸ | Notación científica: poco legible para el jugador |

## 3. Reglas del núcleo (`Economy`)

### 3.1 Producción y clics

- **Multiplicadores:** cada mejora ×2 multiplica por 2 el valor actual (dos mejoras dan ×4). Sin mejoras, valen 1.
- **Producción por segundo** = suma, para cada generador, de `poseídos × producción base × multiplicador del generador`.
- **Valor del clic** = `1 × multiplicador del clic` + `0,02 × producción por segundo` si se tiene *Resonancia*.
- **Clic manual** (`click()`): suma el valor del clic.
- **`tick(delta: float, holding: bool)`:**
  1. Suma `producción × delta`.
  2. Suma `valor del clic × clics automáticos × delta`. Los clics automáticos son la suma de dos partes: el dial sostenido (4 si `holding` y se ha comprado *Dial firme*; si no, 0) y el dial solo (2 con *Dial solo*, 5 con *Dial solo II*; si no, 0).
  3. Avanza el temporizador de la interferencia (§3.3).
- Lo que se gana va a la **Energía** y a la **Energía producida en la run**, que es lo que mide el umbral.
- **Mantener pulsado:** mientras se sostiene el dial no hay clics manuales; soltarlo no cuenta como clic. `holding` lo fija la UI (`Game.set_holding`) y se pone a `false` si la ventana pierde el foco.

### 3.2 Tienda

- **Coste de un generador** = `ceil(coste base × 1,15 ^ poseídos)`.
- **Aparición:** el primer generador está visible desde el principio, y cada uno aparece cuando se ha comprado al menos una vez el anterior. Una mejora aparece cuando se cumple su requisito. Una vez visible, no desaparece en esa run.
- **Comprar** algo sin Energía suficiente, algo ya comprado, una mejora cuyo requisito no se cumple o un generador no visible no hace nada y devuelve `false`.

### 3.3 Interferencias

- Hay un temporizador `next_in`. Al empezar una run, y cada vez que termina una interferencia, se sortea entre 120 y 240 s.
- Cuando llega a 0, empieza una interferencia de 8 s (`active_left`).
- `catch_interference()` solo funciona si hay una activa. Paga la recompensa de D7 una vez y la termina. No cuenta como clic del dial, y los clics automáticos no la atrapan: solo un clic del jugador sobre la capa de estática.
- Si pasan los 8 s sin atraparla, termina sin recompensa.

### 3.4 Reiniciar

Es posible si `Energía producida en la run ≥ umbral`. Pone a cero la Energía, la Energía producida, `play_time`, los generadores y las mejoras; cancela una interferencia activa y sortea un `next_in` nuevo; suma 1 al número de run y guarda.

### 3.5 Valores iniciales y ritmo

**Generadores** (en `data/economy_run1.tres`). Coste base = `15 × 9^posición`; producción base = `0,2 × 6^posición` (posición 0 a 5):

| Posición | id | Nombre (clave de traducción) | Coste base | Producción base (/s) |
|---|---|---|---|---|
| 0 | `antenna` | `GEN_ANTENNA` | 15 | 0,2 |
| 1 | `valves` | `GEN_VALVES` | 135 | 1,2 |
| 2 | `audio_frequency` | `GEN_AUDIO_FREQUENCY` | 1.215 | 7,2 |
| 3 | `tuner` | `GEN_TUNER` | 10.935 | 43,2 |
| 4 | `remote` | `GEN_REMOTE` | 98.415 | 259,2 |
| 5 | `channel_3` | `GEN_CHANNEL_3` | 885.735 | 1.555,2 |

**Mejoras de generador (12):** `<id>_x2_10` (requisito: 10 poseídos; coste: 12 × coste base) y `<id>_x2_25` (requisito: 25 poseídos; coste: 120 × coste base). Efecto: ×2 a ese generador.

**Mejoras de clic (6):**

| id | Nombre | Requisito | Coste inicial | Efecto |
|---|---|---|---|---|
| `pulse` | *Pulso* | ninguno | 5 | clic ×2 |
| `dial_hold` | *Dial firme* | 150 de Energía producida | 100 | mantener pulsado = 4 clics/s |
| `pulse_strong` | *Pulso fuerte* | 5.000 producida | 2.500 | clic ×2 |
| `resonance` | *Resonancia* | 30.000 producida | 15.000 | el clic suma el 2 % de la producción/s |
| `dial_auto` | *Dial solo* | 150.000 producida | 75.000 | 2 clics/s solos |
| `dial_auto_2` | *Dial solo II* | 2.000.000 producida y tener *Dial solo* | 1.000.000 | 5 clics/s solos (sustituye a *Dial solo*) |

**Umbral inicial:** 10.000.000 de Energía producida (mayor que el coste de lo que se espera comprar). Todos estos valores son iniciales: el paso 3 de la §6 los ajusta.

**Rangos que comprueba el test de ritmo** (copiados de `specs/incremental.md` §8, que sigue siendo la fuente):

| Medida | Rango |
|---|---|
| Primera compra | antes de 15 s |
| Algo nuevo en la tienda (primera vez que se ve un generador o una mejora) | como mucho cada 3 min |
| Generador nuevo | uno cada 5-6 min (aparición de cada uno respecto al anterior: 4-7 min) |
| Compras por minuto (sin contar clics automáticos) | 3-8 en los minutos 0-15; ≥ 1,5 después |
| Minuto en que se habilita *Reiniciar* | 30-40, en las 4 simulaciones |

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
3. Se lee `X`. Si es **ilegible**, se renombra a `X.corrupt` (sustituye al anterior), se registra un aviso y se intenta `X.bak`. Si el `.bak` también es ilegible, se renombra a `X.bak.corrupt` y se empieza una partida nueva. Nada se borra.

**Ilegible** significa cualquiera de estas cosas:
- no es JSON;
- no tiene `version`, o su versión es mayor que 1;
- falta una clave obligatoria (todas las del ejemplo), o tiene otro tipo.

Al cargar, los enteros se convierten desde `float` (el JSON de Godot devuelve todos los números como `float`), y los valores negativos se ponen a 0. Un `id` desconocido se ignora con un aviso, para que renombrar algo no haga perder la partida.

No hay migradores en este hito, porque solo existe la versión 1. El primero llega en el hito 4, con su test (GDD §11).

## 5. Archivos

```
core/generator_def.gd              crear (class_name GeneratorDef, Resource: id, name_key, base_cost, base_production)
core/upgrade_def.gd                crear (class_name UpgradeDef, Resource: id, name_key, kind, target_id, value, cost, req_generator_count, req_energy_produced, req_upgrade_id)
core/economy_config.gd             crear (class_name EconomyConfig, Resource: generators, upgrades, cost_growth, threshold, intervalos de interferencia)
core/run_state.gd                  crear (class_name RunState: datos de la run; to_dict/from_dict con la validación de la §4)
core/economy.gd                    crear (class_name Economy: reglas de la §3, señales purchased y restarted)
core/save_system.gd                crear (class_name SaveSystem: §4; ruta inyectable para los tests)
data/economy_run1.tres             crear (EconomyConfig con los 6 generadores y las 18 mejoras de la §3.5)
autoload/event_bus.gd              crear (señales de D3)
autoload/game.gd                   crear (posee Economy y SaveSystem; adaptador; guardado de D10; --no-save)
autoload/game_clock.gd             crear (único _process con lógica)
presentation/ui/tv_game_ui.tscn    crear (UI plana)
presentation/ui/tv_game_ui.gd      crear
presentation/ui/number_format.gd   crear (class_name NumberFormat: D13)
presentation/main.tscn             modificar (instancia la UI; se quitan Camera3D, luz y Label3D)
presentation/main.gd               modificar (sigue imprimiendo BOOT_OK)
assets/audio/ui/purchase.ogg       crear (Kenney, CC0)
locale/strings.csv                 modificar (textos de la UI y nombres de generadores y mejoras)
project.godot                      modificar (autoloads de D2)
tests/test_economy.gd              crear
tests/test_run_state.gd            crear
tests/test_save_system.gd          crear
tests/test_pacing.gd               crear
tests/test_number_format.gd        crear
tests/test_smoke.gd                sin cambios
tools/verify.sh                    modificar (comprobación 2 y --no-save: ver §6)
ASSETS.md                          modificar (sonido de Kenney)
```

**La UI:**
- **Dial:** es un `Button`. `pressed` llama a `Game.click()`, salvo si estaba sostenido; `button_down` y `button_up` llaman a `Game.set_holding`.
- **Tienda:** lista los generadores visibles (nombre, poseídos, coste y producción) y las mejoras visibles no compradas. Los botones se desactivan si no hay Energía suficiente.
- ***Reiniciar*:** se ve desactivado hasta llegar al umbral, con el progreso (`Energía producida / umbral`).
- **Interferencia:** una capa de estática a pantalla completa con un botón encima, visible mientras dure; ese botón llama a `Game.catch_interference()`.
- **Actualización:** la UI lee el estado de `Game` en su `_process` (solo pinta, sin lógica de juego) y escucha `purchase_made` para el sonido.
- **Textos:** todos con `tr()`.

**Cierre:** `Game` desactiva `auto_accept_quit` y, al recibir `NOTIFICATION_WM_CLOSE_REQUEST`, guarda y llama a `get_tree().quit()`. Si el guardado falla, se cierra igual.

## 6. Pasos

1. Crear las clases de `core/` y sus tests (§7). Los tests pasan.
2. Crear `data/economy_run1.tres` con los valores iniciales de la §3.5.
3. **Ajustar el ritmo**, en este orden, con `test_pacing.gd`:
   1. Medir con los valores iniciales: minuto del umbral en cada simulación y diferencia entre perfiles.
   2. Cerrar la diferencia entre los perfiles tocando solo las mejoras de clic (costes, requisitos y efectos).
   3. Fijar la duración media con el umbral y con los factores de la fórmula de los generadores (coste `15 × a^posición`, producción `0,2 × b^posición`).

   Si en el paso 3.2 la diferencia no baja de 10 minutos, se para y se le enseña al usuario lo más cercano conseguido. Los rangos no se cambian sin su aprobación.
4. Crear los autoloads, la UI y los textos. Descargar el sonido de Kenney, comprobar su licencia y registrarlo en `ASSETS.md`.
5. LSP de todos los scripts nuevos: cero errores (procedimiento del hito 0, paso 6: editor headless con `--lsp-port 6005`, `lsp-diagnostics` por script, cerrar el proceso por su línea de comandos).
6. Captura con GoPeak de la UI en marcha (hito 0, paso 7: activar el grupo `testing`, `editor-run` con ventana, `capture-screenshot`, `editor-stop`). Jugar con el MCP: clic en el dial, comprar una Antena y ver que sube la producción.
7. **`verify.sh`:**
   - La comprobación 2 pasa a ser: el log de GUT contiene `All tests passed` y no contiene ninguna línea con `Passing Tests` seguido de espacios y `none`.
   - GUT y el arranque de la build se lanzan con `-- --no-save`.

   Ejecutarlo: `VERIFY OK`.
8. **Prueba del usuario:** juega la run 1 (o un trozo) en la build exportada y la aprueba. Se le enseñan los valores finales del `.tres` y la línea de tiempo de las 4 simulaciones.
9. Anotar el umbral final en el GDD §4 (el resto de valores están en el `.tres`). Commit y push.

## 7. Tests

| Test | Qué comprueba |
|---|---|
| `test_economy.gd` | Lo siguiente, con semilla fija:<br>• el clic suma el valor del clic;<br>• comprar descuenta el coste y el siguiente es `ceil(base × 1,15^n)`;<br>• sin Energía no compra;<br>• un generador no visible no se compra;<br>• `tick` suma la producción;<br>• los multiplicadores se multiplican entre sí;<br>• cada tipo de mejora aplica su efecto;<br>• *Dial firme* solo cuenta mientras se sostiene;<br>• *Dial solo II* requiere *Dial solo* y lo sustituye;<br>• *Reiniciar* solo funciona con el umbral y deja todo a cero con la run +1;<br>• la interferencia aparece entre 120 y 240 s y dura 8 s;<br>• atraparla paga D7 una sola vez;<br>• si no se atrapa, no paga nada;<br>• *Reiniciar* cancela la interferencia activa;<br>• las señales se emiten una vez por evento |
| `test_run_state.gd` | `to_dict` → `from_dict` devuelve el mismo estado; un `id` desconocido se ignora |
| `test_save_system.gd` | En una carpeta temporal de `user://`:<br>• guardar y cargar, pasando por JSON, recupera los mismos valores;<br>• la escritura deja en `.bak` la versión anterior;<br>• la primera vez no hay aviso;<br>• con el principal dañado y el `.bak` bueno, se carga el `.bak`, el principal pasa a `.corrupt`, y tras un guardado nuevo el `.bak` sigue siendo el bueno;<br>• con los dos dañados, partida nueva y los dos `.corrupt`;<br>• la versión 2 se trata como ilegible;<br>• una clave ausente o de otro tipo, también;<br>• los negativos pasan a 0;<br>• un `.tmp` sobrante se borra |
| `test_pacing.gd` | Carga `data/economy_run1.tres` y simula la run 1 con `tick(0,25)`.<br>• **Cómo compra:** compra lo que más Energía por segundo añade para ese perfil (contando clics, sostener y clics automáticos) dividido entre su coste. Si tardaría más de 30 s en poder pagarlo, al ritmo de ingresos actual, compra lo mejor que ya pueda pagar.<br>• **4 simulaciones:** 2 perfiles × con y sin atrapar interferencias. *Activo:* 6 clics/s, nunca sostiene. *Tranquilo:* 0,5 clics/s, y sostiene el dial en cuanto tiene *Dial firme*.<br>• **Resultado:** el simulador devuelve una línea de tiempo (compras, apariciones y minuto del umbral) y el test comprueba los rangos de la §3.5 |
| `test_number_format.gd` | Los ejemplos de D13: el 0, `12.345`, `0,2/s`, `99,9/s` y `100/s` |

## 8. Criterio de cierre

- Los tests pasan y `verify.sh` termina con `VERIFY OK`.
- La captura de la UI se ha enseñado al usuario.
- El usuario juega la build exportada y aprueba el ritmo y la UI.
- El GDD §4 anota el umbral final; `ASSETS.md` registra el sonido.
- Commit y push.

## 9. Riesgos

- **El ritmo no cuadra para los dos perfiles a la vez:** el ajuste en orden del paso 3 lo intenta. Si no lo consigue, decide el usuario (§6, paso 3).
- **Partida guardada dañada:** la lectura de la §4 nunca borra nada y siempre deja jugar. En el peor caso se empieza de cero, sin estado de derrota.
- **Precisión de los números:** el `float` basta para la run 1 (D5); los umbrales de las runs 2-4 se revisan en los hitos 4-5.
- **Cerrar sin guardar:** si Windows cierra el proceso a la fuerza (por ejemplo, al apagar), se pierde como mucho lo jugado desde el último guardado periódico (≤ 5 min).
