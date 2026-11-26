# Especificación — Hito 4b: corte vertical (runs 1 y 2)

> Estado: **v2 aprobada por el usuario (2026-11-26)**, tras la revisión EGM (`reviews/hito4b/egm_report.md`); §9 aprobada con las recomendaciones.
>
> Fuentes: `GAME_DESIGN.md` §2-§8, §11 (hito 4) y §12; `CLAUDE.md`; `PENDIENTES.md` (hito 4b); `specs/hito2.md` (D7, D14, D16), `specs/hito4a.md` (D5-D7, D11, D14-D16), `specs/hito3.md` (D3, D6, D8, D9), `specs/incremental_v2.md`.

**Ya decidido por el usuario:**
- En la run 1 llama un **vecino**, un señor de mediana edad, que pide algo de electricidad: en la época del juego no hay repartidores (2026-11-26).
- Sin zoom out: tras los golpes y un segundo de silencio, el jugador se levanta **girando hacia la puerta del salón**, en un solo movimiento lo más realista posible (2026-11-26).
- Desde la run 2 se levanta cuando quiere (2026-11-26).
- **El jugador no tiene cuerpo:** todo se cuenta con la cámara, con animaciones al levantarse y al andar (2026-11-26; sustituye a los brazos del paso 3 y al «sin balanceo de cámara» de hito4a D6).
- El vecino, un señor cualquiera de mediana edad, se hace con MPFB2, solo con assets CC0, y se anima a mano en Blender (2026-11-26).
- **La casa está en espejo desde la run 2** y lo sigue después del apagón; tras cambiar el plomo, el jugador vuelve a la tele y sigue jugando hasta el *Reiniciar* (2026-11-26).
- **Subtítulos sí; la voz del vecino se decide más adelante** (2026-11-26).
- **Playtest: las ~5 personas juegan desde cero** (2026-11-26).
- Interactuables (2026-11-25): plomos e inventario pequeño; grifos, puertas de armario, cajones, interruptores y la radio; coger objetos solo si aporta miedo.
- En el piso en espejo la tele se ve normal y los demás textos salen al revés (2026-11-24; manda sobre hito2 y hito4a D14).

**Términos:**
- **Secuencia:** el evento que dispara un *Reiniciar* (el vecino, el apagón). Se divide en **pasos** con nombre.
- **Plomos:** fusibles de porcelana de las casas antiguas españolas, enroscados en la **caja de plomos**.
- **Cabeza:** el nodo que mueve la cámara de pie; las animaciones lo desplazan sin tocar la cápsula del jugador.
- **Ancla:** el sitio y el giro desde donde se reproduce una animación (el sofá, la rendija, la caja de plomos).
- **†:** dato del motor que se confirma al implementar (con context7 o probándolo); si no coincide, se corrige esta especificación antes de seguir.

## 1. Objetivo

El primer entregable jugable: la run 1 entera, la llamada del vecino, la run 2 en el piso en espejo, el apagón hasta cambiar el plomo y la vuelta a la tele, con pistas que suman Evidencia, todo guardado y un playtest con ~5 personas que juegan desde cero. Tres fases, cada una con una parada del usuario, y el playtest.

Fuera de 4b: la llamada de la señora y la escalera (hito 5); el *Reiniciar* de la run 3 enseña una carta de «continuará» hasta entonces. También quedan fuera los finales (hito 6), la voz del vecino (§9, P1), la mezcla de sonido por run (hito 5), la música y el mando (hito 7).

## 2. Decisiones

### Fase 1 — El vecino

**D1 — Secuencias.** `RunState` guarda `sequence` (`&""`, `&"neighbor"`, `&"blackout"`) y `step`, el paso en el que se puede volver a entrar al cargar.

| Secuencia | Paso | Qué pasa | ¿Produce la tele? | Al cargar |
|---|---|---|---|---|
| neighbor | `knock` | Golpes, levantarse, buscar los plomos, dárselos | No | Sentado; empieza la llamada desde el principio |
| neighbor | `free` | Ya se fue; explorar el piso (~15 min, opcional) | No | De pie donde estaba |
| blackout | `dark` | Apagón; buscar el repuesto y cambiar el plomo | No | Sentado a oscuras, ya en espejo |
| blackout | `fixed` | La luz ha vuelto; explorar o volver a la tele | No | De pie donde estaba |

- **Empieza:** `Economy.restart()` pone `sequence = Sequence.after_restart(run que acaba)` (1 → `neighbor`, 2 → `blackout`, 3 → `&""`) con `step` en el primer paso, y **copia `evidence`** a la run nueva, igual que hoy copia `carga` y `perks`. El `run_index` sube al pulsar: durante el vecino ya vale 2, y durante el apagón, 3.
- **Avanza:** solo por `Game.sequence_done(done)`, la única entrada, que llama a la función pura `Sequence.next(sequence, step, done) -> StringName`. Si el paso nuevo se puede reentrar, `Game` guarda.
- **Termina:** al sentarse en `free` o en `fixed`. `Game.finish_sequence()` vacía la secuencia y guarda, y `main.gd` abre la Carga (`tv_game_ui.open_carga()`). Al cerrar la Carga empieza la run.
- **Tiempos** (los 3 s, el segundo de silencio, los ~40 s entre golpes, el temporizador del rellano): los cuenta `Sequence` dentro de `Game.tick`, con el reloj único. Así se paran en la pausa y se prueban con `tick()`. Cada momento sale como `EventBus.sequence_cue(id)`.
- **La tele, la economía y el director:** con secuencia, `Game.tick` no avanza ni la economía ni el director (la casa calla después del evento), pero `Game.running` sigue en true. La pausa es lo único que lo pone a false.
- **Carga:** `tv_game_ui._restart()` deja de abrir la Carga: la carta de fin de emisión se queda y después la tele se queda en nieve. `_start_playing()` no abre la Carga si hay secuencia: arranca en el paso de reentrada.
- Descartado: guardar dentro de un paso (lo que llevas en la mano, puertas abiertas). El GDD §3 dice que un evento se repite desde su inicio.

**D2 — La llamada.** Paso `knock`:
1. La tele pasa a la carta de fin de emisión y luego a nieve.
2. A los 3 s suenan tres golpes en la puerta de entrada, con un `DirectionalSound` propio en el bus `HouseEvents` que pierde volumen por muros y puertas como los demás (`flat.sound_loss`). No se usa `HouseAudio`: tiene un solo reproductor y un silencio previo al azar.
3. Un segundo de silencio y empieza `stand_to_door` (D3).
4. Si en 40 s no abre la puerta de entrada, vuelven a llamar, 2 dB más fuerte cada vez, hasta 6 dB. No hay derrota: solo insiste.

**D3 — Levantarse: animación de la cámara.** Sin cuerpo, el realismo está en cómo se mueve la vista (usuario, 2026-11-26). Las animaciones son recursos `Animation` de Godot con interpolación cúbica, en `data/camera_anims.tres`, que escribe `tools/make_camera_anims.gd` a partir de una tabla de fotogramas clave (instante, posición, giro, FOV). Así se ajustan como texto y el FOV se anima sin trucos.
- **`stand`** (~2,5 s): la única subida que se pule a fondo.
  - La vista se echa adelante y baja, como quien se apoya para impulsarse.
  - Sube con esfuerzo, sin velocidad constante, con un pequeño tirón al despegar del asiento.
  - Se pasa un poco, se recoloca y se balancea hasta quedar quieta.
- **`stand_to_door`** (~3,5 s): primero la cabeza se vuelve hacia la puerta del salón y se para un instante, como quien duda; después sigue con la misma `stand`, girada hacia la puerta.
- **`sit`:** se queda la transición de cámara de 0,5 s de hito4a D7 (§9, P14).
- **Anclas:** `CameraMotion.play(anim, anchor)`. `stand*` usa `SeatAnchor`. Antes de empezar, la cámara va en 0,3 s desde donde esté hasta el primer fotograma.
- **Salida:** la última pose tiene los ojos a 1,6 m, sin inclinación lateral y con el FOV de pie (70°). El control pasa al `Player` con `Player.stand_at`, que ya existe. El FOV de sentado al de pie es parte de la animación: la vista que se abre al levantarse, no un zoom (§9, P15).
- **Sonido:** pistas de método en la propia animación: crujido del sofá, la tela y el paso al apoyar el pie (CC0).
- **Espejo:** la animación se reproduce sobre el ancla reflejada (`MirrorMath.mirror_transform`, determinante +1); los giros a un lado pasan al otro solos.
- Se ajusta con capturas del juego, cuadro a cuadro, y lo aprueba el usuario jugándolo (parada 1).

**D3b — Andar con la cámara viva** (usuario, 2026-11-26; cambia hito4a D6, que no tenía balanceo). En `player.gd`, sobre la cabeza, sin tocar la cápsula:
- **Al andar:** la vista baja ~1,5 cm en cada pisada, al compás de los pasos que ya suenan (`STRIDE`), con un vaivén lateral de ~0,8 cm cada dos pasos y una inclinación de ~0,4°. Va por la distancia andada: parado no se mueve.
- **Al pararse:** se asienta en ~0,4 s, con un último medio paso.
- **Quieto:** respiración muy leve, ~0,4 cm cada 4 s.
- **Ajuste «Movimiento de cámara»** en Controles, 0-100 %, por defecto 100 %: a 0 no hay balanceo ni respiración, por si marea (§9, P16).

**D4 — El vecino (MPFB2, solo CC0).**
- Hombre de unos 58 años, piel `old_caucasian_male`, jersey de lana pardo, pantalón gris y botines (hecho en el paso 3: `tools/blender/build_characters.py` y `export_character.py`, ~41 000 triángulos, a medir en el benchmark).
- El esfuerzo va a la cara y a la mano, que es lo que se ve por la rendija. Sin boca animada: sin voz por ahora (P1), y la cara queda en sombra o se ve de lado. La cabeza sigue al jugador con `LookAtModifier3D` †, con límites de unos 50° de giro y 25° de cabeceo.
- Animaciones en su `.blend` (reposo y la mano que entra a coger los plomos), exportadas en el mismo glTF.
- Cada asset de MakeHuman usado va a `ASSETS.md` con su paquete y su licencia.

**D5 — La puerta de entrada y el vecino.**
- **Puerta:** es la `Door` de `door_front`, que ya existe con llave. Durante `knock` deja de tener llave y su tope pasa a 12°: la cadena de seguridad. `front_door.gd` solo añade la cadena, el rellano y el vecino.
- **Rellano:** una pieza mínima y oscura del 8.º, hecha en Blender en los dos pisos, con su **luz de escalera con temporizador**, que va por `LightMixer`. A mitad de la conversación se apaga sola, con su clic, y la cara del vecino se queda en sombra. Él la vuelve a encender: se oye el clic y vuelve la luz.
- **Lo que dice:** frases cortas con subtítulos (D15), sin voz por ahora. Sí se oyen su respiración y el roce de la ropa. Propuesta de texto (P5):
  - «Perdona que llame tan tarde… Se me han fundido los plomos.»
  - «¿No tendrás unos de sobra? En el taller tendrás, tú de esto sabes.»
  - Al dárselos: «Gracias. Ya te los devuelvo.» No los devuelve.
- **Qué hace el jugador** (P9): ir al taller, abrir la caja de herramientas y coger los plomos (D7). Después vuelve, apunta a la rendija y hace clic:
  - la mano del vecino entra por la rendija (su animación); los plomos aparecen delante de la cámara y van hacia su mano con un tween;
  - el vecino se aparta y se oyen sus pasos bajando la escalera;
  - la luz del rellano se apaga y la puerta se cierra sola despacio (`creep`), con la llave echada. Si el jugador está en el recorrido, espera a que se aparte.
  - Paso `free`.
- **Sentarse:** el sofá no se puede usar en `knock`. En `free` se puede, y al sentarse se abre la Carga.
- **El espejo empieza aquí:** al sentarse en `free`, la tele pasa a nieve y, con la vista fija en ella, la escena se vuelve a cargar en espejo (D8). Cuando la Carga se cierra, la run 2 se juega en espejo, y el jugador lo descubre cuando se levanta.

### Fase 2 — La run 2 y el apagón

**D6 — Levantarse cuando quieras.** Una acción `stand_up` en `project.godot` (tecla Q), con su fila en Controles.
- Levanta con `stand` si `run_index >= 2` y no hay secuencia, o en los pasos `dark` y `fixed`, sin el árbol ni la pausa abiertos.
- No depende de `is_idle()`.
- En la run 1 solo funciona en la build de pruebas, como ahora.
- De pie, la tele sigue produciendo, salvo con secuencia (GDD §12).

**D7 — Lo que llevas.** Un solo hueco y sin intercambio: los plomos (run 1) o el repuesto (run 2), nunca a la vez. Sin manos no se ve: al cogerlo sale una línea abajo («Llevas los plomos», con `tr()`) y la retícula crece donde se puede usar. No se guarda: si se carga, se vuelve a coger.

**D8 — El espejo y el apagón.**
- **Variante del piso:** una función pura, `Sequence.flat_variant(run_index, sequence, step) -> {mirror, dark}`:
  - `mirror` si `run_index >= 2` y no estás en el vecino;
  - `dark` si estás en el paso `dark`.
  - `main.gd` la lee del estado; `TLR_MIRROR` y `TLR_DARK` pasan por encima solo en depuración.
- **Recarga** (solo al sentarse tras el vecino):
  - con la tele en nieve y la vista fija en ella, `reload_current_scene()`, a través de un `Callable` que los tests sustituyen †;
  - tras la recarga, `main.gd` arranca sentado, sin menú, con la Carga abierta;
  - el color de fondo durante la recarga es negro.
  - † confirmar que no quedan conexiones del `EventBus` a la escena vieja.
- **El apagón**, sin recargar: al pulsar *Reiniciar* en la run 2, paso `dark`.
  1. El zumbido se para y la tele se apaga (`tv.power`). Las luces caen a negro en un solo bajón, con el ruido de la corriente al cortarse. Con «Intensidad de efectos» a 0, se apagan en 3 s (GDD §5).
  2. Estás sentado a oscuras: Q levanta y F enciende la linterna, la única luz. No gasta pilas.
  3. **Caja de plomos**, en el trastero (`fuse_box_zone`, ya en el plano): cuadro de madera con plomos de porcelana, uno fundido, modelado en Blender.
  4. **La caja de herramientas está vacía:** el vecino se llevó los plomos. El repuesto está en un cajón de la cocina (P3).
  5. Con el repuesto en la mano, clic en el plomo fundido: la cámara se acerca a la caja, el plomo fundido se desenrosca solo y entra el nuevo, con el sonido de la porcelana. La luz vuelve con un golpe seco y el zumbido. La tele se enciende sola. Paso `fixed`.
  6. Al sentarse se abre la Carga y empieza la run 3, en la misma casa en espejo. Su *Reiniciar* enseña «continuará» hasta el hito 5.

**D9 — Interactuables.** Lista cerrada, en los dos pisos:
- **Puertas de armario** (bisagra, la `Door` de siempre): el armario del recibidor (pista del uniforme) y uno por dormitorio.
- **Cajones** (`drawer.gd`, en línea recta): 3-4 de la cocina (uno con el repuesto) y uno del taller.
- **Caja de herramientas:** la tapa del `metal_toolbox` del taller.
- **Interruptores:** uno por habitación con lámpara. `LightMixer.set_light_on(light, on)` la enciende o la apaga, y el parpadeo del director se salta las apagadas. En el apagón suenan y no hacen nada.
- **Grifo de la cocina:** abre y cierra con el sonido del grifo del baño (hito 3). En el apagón sigue saliendo agua.
- **Radio de la cocina:** enciende y apaga con estática; en el apagón no hace nada.
- **Física:** `DoorMath.step(..., max_open := MAX_ANGLE)` acepta el tope (cadena, armarios) y `DoorMath.step_linear(pos, vel, drag, held, delta, max_pos)` hace los cajones. Los valores se ajustan en la parada 2.
- **Uso:** todo lo que se usa tiene `use(player)` y `can_use(player)`. `player.gd` y la retícula preguntan lo mismo, en vez de comprobar tipos a mano.
- **Geometría:** cajones, puertas, tapa y grifo se separan como nodos propios en `furnish_flat.py`, siguiendo el patrón de `_add_wardrobe`. Los interruptores, el rellano y la caja de plomos son nuevos. Todo va en los dos glTF, con un horneado nuevo de la GI del salón y un caso en `test_flat.gd` en los dos pisos. El suceso `wardrobe` del director no mueve un armario que el jugador esté agarrando.

### Fase 3 — Evidencia, guardado y lo demás

**D10 — Evidencia.**
- **Datos:** `narrative/clue_def.gd` (`ClueDef`: id, `name_key`, `text_key` y `node`, el nombre del objeto del piso) y las pistas en `data/clues.tres`.
- **Estado:** `RunState.evidence`. `Game.find_clue(id) -> bool` lo añade en `core/` y `EventBus.clue_found(id)` lo avisa.
- **Examinar:** clic en la pista. El objeto se acerca a la cámara sin girarlo y su texto sale abajo (en espejo, al revés, como los demás textos). La primera vez suma, con un sonido suave. Clic o Esc lo devuelve a su sitio.
- **Registro:** botón «Pistas» en la pausa, con el nombre de las halladas y sin huecos para las que faltan (P13).
- **Pistas** (GDD §7; textos en P5):
  - el uniforme con el nombre de la empresa, en el armario del recibidor;
  - la caja de herramientas, en el taller (pista aparte de la tapa y de los plomos);
  - las llaves de la furgoneta, en el recibidor;
  - una carta mal entregada, a nombre del 3.º;
  - la nota sin firma que vino con la tele, junto a ella;
  - fotos, en el dormitorio principal.

**D11 — Guardado v5.** `RunState` versión 5:
- **Esquema:** `sequence: String`, `step: String`, `evidence: [String]` y `player: {standing: bool, pos: [x, y, z], yaw, pitch}`.
- **`migrate_v4`:** `sequence` y `step` vacíos, `evidence` vacía y el jugador sentado. Su test usa `_valid_dict()`, que ya es v4.
- **Validación:** como hoy. Id de pista desconocido o secuencia desconocida → aviso y se descarta; `pos` mal formado → sentado.
- **Posición:** la da un proveedor `Game.player_pose: Callable`, puesto por `main.gd`, como `senses`. Solo se guarda en un paso reentrable o sin secuencia. Al pulsar «Continuar», si el sitio no está en ninguna zona o choca, el jugador empieza sentado.

**D12 — Pausa de pie e invertir el eje Y.**
- Esc de pie ya no te sienta: abre la pausa en un `SubViewport` de 320 × 240 mostrado a pantalla completa en 4:3, con filtro nearest; ratón visible al abrir y capturado al cerrar.
- «Menú principal» te sienta primero. Cerrar la pausa respeta la secuencia.
- Fila «Invertir eje Y» en Controles, en `UserSettings` y en `settings.cfg`, sin cambiar de versión.

**D13 — Pasos según el suelo.** `player.gd` ya elige por el suelo de la zona; falta la grabación CC0 de pasos sobre baldosa.

**D14 — Aviso de fotosensibilidad.** Lo monta `main.gd` antes del menú, una vez por proceso (no tras la recarga del espejo). Texto claro sobre negro, con `tr()`, que se cierra con cualquier tecla pasados 2 s. Se salta con `TLR_SKIP_MENU`, `TLR_SHOT` y el benchmark.

**D15 — Subtítulos.** Una etiqueta abajo en pantalla (`presentation/ui/subtitles.gd`) escucha `EventBus`:
- las frases del vecino salen siempre, porque no tienen voz;
- los sucesos con `subtitle_key` salen solo con la opción «Subtítulos» de Ajustes, desactivada por defecto.

**D16 — Enseñar sin estorbar.**
- Una línea `tr()` la primera vez que sirve Q, F o arrastrar un cajón.
- Respuesta corta, con sonido y subtítulo, al abrir la caja de herramientas vacía y al tocar el plomo fundido sin repuesto.

**D17 — Desarrollo.**
- `TLR_SEQUENCE=<secuencia>[:<paso>]` arranca ahí, con la run que toca y por encima de `TLR_MIRROR` y `TLR_DARK`. Solo en depuración.
- Truco F1 «dar todas las pistas».
- «Run 1/Run 2» y «Reiniciar ya» ya existen y, con D1, arrancan el vecino o el apagón.
- `_new_game` vacía `evidence` y la secuencia.

## 3. Archivos

```
core/run_state.gd                cambiar  (v5: sequence, step, evidence, player; migrate_v4)
core/sequence.gd                 crear    (Sequence: after_restart, next, flat_variant, tiempos con tick)
core/economy.gd                  cambiar  (restart copia evidence y pone la secuencia)
core/user_settings.gd            cambiar  (invertir eje Y, subtítulos)
autoload/game.gd                 cambiar  (sequence_done, finish_sequence, find_clue, player_pose)
autoload/event_bus.gd            cambiar  (sequence_cue, clue_found)
presentation/main.gd             cambiar  (variante desde el estado, recarga, stand_up, aviso, pose)
presentation/player/player.gd    cambiar  (use/can_use, Esc de pie, eje Y, cabeza que se mueve al andar)
presentation/player/camera_motion.gd  crear  (animaciones de la cámara, anclas, paso al Player)
tools/make_camera_anims.gd       crear    (escribe data/camera_anims.tres)
presentation/ui/tv_game_ui.gd    cambiar  (sin Carga en _restart; open_carga; reentrada)
presentation/ui/main_menu_ui.gd  cambiar  (botón Pistas, filas nuevas, pausa en SubViewport)
presentation/ui/clue_view.gd     crear
presentation/ui/subtitles.gd     crear
presentation/ui/photo_warning.gd crear
presentation/graphics/light_mixer.gd    cambiar  (set_light_on)
presentation/graphics/light_flicker.gd  cambiar  (saltarse las apagadas)
world/player_flat/front_door.gd  crear    (cadena, rellano, luz con temporizador, vecino)
world/player_flat/fuse_box.gd    crear
world/player_flat/drawer.gd      crear
world/player_flat/light_switch.gd crear   (y grifo y radio, si caben en el mismo patrón)
world/player_flat/door.gd, door_math.gd, flat.gd  cambiar
tools/blender/furnish_flat.py, build_flat.py  cambiar  (piezas separadas, interruptores, caja de plomos, rellano)
tools/blender/export_character.py crear
assets/models/living_room/flat.gltf, flat_mirror.gltf y la GI del salón (normal y espejo)  regenerar
narrative/clue_def.gd            crear    (carpeta nueva)
data/clues.tres                  crear
art_source/characters/*.blend    crear    (carpeta nueva)
assets/models/characters/        crear    (carpeta nueva)
project.godot                    cambiar  (acción stand_up)
locale/strings.csv               cambiar
tools/dev_cheats.gd, tools/verify.sh (22 scripts de test)  cambiar
tests/test_sequence.gd           crear
tests/test_run_state.gd, test_save_system.gd, test_economy.gd, test_user_settings.gd, test_light_mixer.gd,
      test_door_math.gd, test_tv_screen_math.gd, test_flat.gd, test_flow.gd, test_main_menu_ui.gd, test_dev_cheats.gd  cambiar
ASSETS.md, PENDIENTES.md, GAME_DESIGN.md (§3, §11), CLAUDE.md  cambiar
```

## 4. Interfaces

```gdscript
# core/sequence.gd
class_name Sequence extends RefCounted
static func after_restart(finished_run: int) -> StringName
static func first_step(sequence: StringName) -> StringName
static func next(sequence: StringName, step: StringName, done: StringName) -> StringName  # &"" = se acabó
static func resumes_standing(step: StringName) -> bool              # free y fixed: se carga de pie
static func flat_variant(run_index: int, sequence: StringName, step: StringName) -> Dictionary  # {mirror, dark}
func tick(delta: float, sequence: StringName, step: StringName) -> Array[StringName]          # cues de este tick
static func knock_boost_db(n: int) -> float
func door_opened() -> void                     # Game.sequence_done(&"door_opened"): ya no vuelven a llamar

# autoload/game.gd
func in_sequence() -> bool
func sequence_done(done: StringName) -> void
func finish_sequence() -> void
func find_clue(id: StringName) -> bool
var player_pose: Callable

# autoload/event_bus.gd
signal sequence_cue(id: StringName)   # knock, silence_over, stair_light_off…
signal clue_found(id: StringName)

# presentation/player/camera_motion.gd
signal finished(anim: StringName)
func play(anim: StringName, anchor: Transform3D) -> void   # stand, stand_to_door

# interactuables (puerta, cajón, interruptor, grifo, radio, caja de plomos, pista, rendija)
func can_use(player: Player) -> bool
func use(player: Player) -> void
```

## 5. Pasos

1. **Copia de seguridad** (hecha el 2026-11-26).
2. **Secuencias y guardado v5** (D1, D11): `Sequence`, `RunState` v5, `Economy`, `Game` y `tv_game_ui`. Tests primero.
3. **Personajes** (D4): el vecino, con `export_character.py`. Renders en Blender para revisarlos. Hecho el 2026-11-26.
4. **La cámara** (D3, D3b): `stand`, `stand_to_door`, el balanceo al andar y la respiración, con `CameraMotion` y el ajuste. Capturas del juego, cuadro a cuadro.
5. **La llamada y la puerta** (D2, D4, D5, D7, D15): con las animaciones del vecino; cadena, rellano, vecino, plomos, subtítulos y la recarga en espejo al sentarse.
   - **Parada 1:** el usuario juega desde el final de la run 1 hasta empezar la run 2 en espejo.
6. **Run 2 y apagón** (D6, D8, D9, D16): Q, interactuables, la geometría de los dos pisos con su horneado, el apagón, la caja de plomos y la vuelta de la luz.
   - **Parada 2:** el usuario juega el apagón entero.
7. **Fase 3** (D10, D12-D14, D17): Evidencia, pausa de pie, eje Y, pasos, aviso y trucos.
   - **Parada 3:** el usuario juega las runs 1 y 2 seguidas, con las pistas.
8. **Benchmark** en los 4 presets: en el apagón con la linterna y en la rendija del vecino (`TLR_SEQUENCE=neighbor`). **Documentación:** GDD §3, §7, §11 y §12, `CLAUDE.md`, `ASSETS.md`.
9. **Playtest:** las ~5 personas juegan desde cero, en persona, en el PC de desarrollo. Claude propone las preguntas y qué apunta quien observa:
   - el minuto en que dejan de mirar la tele o preguntan cuánto falta;
   - los sustos;
   - si se pierden en el apagón y cuánto tardan en cambiar el plomo;
   - qué pistas encuentran.
   El usuario aprueba las preguntas y decide con el resultado si el hito se cierra.
10. **Copia de seguridad del cierre.**

## 6. Tests

- `test_sequence.gd`:
  - qué secuencia deja cada run;
  - `next` en cada paso;
  - `reentrable`;
  - `flat_variant` en todos los casos;
  - los tiempos con `tick()` (3 s, 1 s, golpes cada 40 s con su tope);
  - con secuencia, ni la economía ni el director avanzan.
- `test_economy.gd`: `restart` copia `evidence` y pone la secuencia.
- `test_run_state.gd` y `test_save_system.gd`: v5 de ida y vuelta; `migrate_v4`; datos raros en `sequence`, `step`, `evidence` y `player`. Se actualizan las aserciones que esperaban la v4.
- `test_flow.gd`: *Reiniciar* deja la nieve sin Carga; la Carga sale con `open_carga`; cargar a mitad de secuencia la repite. Lo visual va por capturas.
- `test_door_math.gd`: `max_open` y `step_linear`.
- `test_light_mixer.gd`: `set_light_on` y el parpadeo sobre una lámpara apagada.
- `test_tv_screen_math.gd`: raycast → UV con la tele en el piso en espejo.
- `test_flat.gd`: cada interactuable existe y queda en su sitio en los dos pisos.
- `test_user_settings.gd`, `test_main_menu_ui.gd` y `test_dev_cheats.gd`: las filas y trucos nuevos.
- Evidencia: suma una sola vez, se conserva tras *Reiniciar* y se vacía en una partida nueva.
- `verify.sh` pasa y la build exportada arranca sin el addon de capturas.

## 7. Criterio de cierre

- Tests en headless y `verify.sh` en verde.
- Las tres paradas aprobadas por el usuario.
- Benchmark dentro de hito2 D16 en los 4 presets, con el vecino en la rendija y en el apagón.
- Playtest hecho y el usuario decide que el hito se cierra.

## 8. Riesgos y límites

- **La animación es lo más incierto:** Claude no puede verla en movimiento, solo cuadro a cuadro, y depende de la opinión del usuario. Habrá varias vueltas. Si algo no queda creíble, se recorta (menos tiempo de brazos en pantalla) antes que dejarlo mal.
- **La recarga en espejo:** si tarda más de lo que tapa la nieve, se alarga la nieve. El mecanismo ya existe en los trucos (`_room` en `dev_cheats.gd`).
- **Geometría en los dos pisos:** separar cajones y puertas obliga a reconstruir y hornear los dos. Es el paso más largo de la fase 2.
- **Alcance:** es el hito más grande hasta ahora. Si una fase se alarga, se para y se pregunta qué recortar.
- **Licencias:** solo assets de MakeHuman cuyos archivos dicen CC0. Los que dicen AGPL o CC-BY ya se descartaron al instalarlos.

## 9. Decisiones para el usuario

| # | Pregunta | Recomendación o estado |
|---|---|---|
| P1 | ¿Voz del vecino? | **Aplazada (usuario).** En 4b, subtítulos, respiración y ropa. Antes del playtest se puede probar una voz generada (VoxCPM2 o MOSS-TTS, Apache-2.0). Es una herramienta nueva y choca con «ni voces ni llantos» (GDD §6, sonidos de la casa); se pregunta entonces. |
| P2 | ¿Desde cuándo está la casa en espejo? | **Decidido (usuario):** desde la run 2 y después del apagón. |
| P3 | ¿Dónde está el plomo de repuesto? | En un cajón de la cocina, lejos del trastero: se cruza media casa a oscuras dos veces. |
| P4 | ¿Grifos y radio? | Una versión barata: el grifo de la cocina, que sigue corriendo en el apagón, y la radio, con estática y muerta en el apagón. |
| P5 | ¿Escribo yo los textos del vecino y de las pistas? | Sí: los propongo y tú los apruebas, antes del paso 5 y del paso 7. |
| P6 | ¿Cómo es el playtest? | **Decidido (usuario):** los 5 desde cero. |
| P7 | ¿Qué era el «aviso previo de *Tus ojos*» (`specs/incremental_v2.md`)? | No está descrito en ningún documento. Si no lo recuerdas, se quita de pendientes. |
| P9 | ¿Qué hace el jugador con lo que pide el vecino? (GDD §3, [PENDIENTE]) | Buscar los plomos en la caja de herramientas del taller y dárselos por la rendija. |
| P10 | ¿Sucesos propios en la run 2? Hoy repite los de la run 1 durante 18-26 min. | Sí, solo datos: `data/fear_events_run2.tres`, que guarda algunos sonidos de la run 1 y da más peso a parpadeos y bajones de luz. |
| P11 | Ideas para la vuelta de la luz (pediste consejo) | Al volver la luz, la tele ya está encendida y **el contador ha subido solo, como si alguien hubiera jugado mientras estabas a oscuras**. No cuesta casi nada y anuncia la run 4. Otra opción, más cara, es que algo del salón esté cambiado (§5, run 3): mejor para el hito 5. |
| P12 | ¿Guardar la posición, o cargar siempre sentado? | Guardarla, como dice `PENDIENTES.md`. Sentado es más simple, pero tras 15 min explorando el piso perderías el sitio. |
| P13 | ¿Huecos en «Pistas» para las que faltan? | No: dirían cuántas hay y convertirían la exploración en una lista. |
| P14 | ¿Sentarse con animación? | No: se queda la transición de 0,5 s, porque te sientas muchas veces. El realismo va a levantarse. |
| P15 | ¿Vale que la vista se abra al levantarse (el FOV de sentado pasa al de pie)? | Sí: no es un zoom out, es lo que ve alguien que se pone de pie, y sin eso habría un salto. |
| P16 | ¿Balanceo de la cámara al andar con ajuste para quien se maree? | Sí: «Movimiento de cámara» 0-100 % en Controles, al 100 % por defecto. |
