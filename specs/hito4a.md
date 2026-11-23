# Especificación — Hito 4a: el piso, andar y las puertas

> Estado: **v2 aprobada por el usuario (2026-11-20)**, tras la revisión EGM (`reviews/hito4a/egm_report.md`). §10: P1-P4 y P6 aprobadas tal como se proponen; P5 resuelta el 2026-11-23: sin GI por zona (D9).
>
> Fuentes: `GAME_DESIGN.md` §2-§4, §7, §8, §11 (hito 4) y §12; `CLAUDE.md`; `specs/hito2.md` (salón, D2, D9, D10, D12, espejo D14, presets D15, benchmark D16).

**Por qué ahora:** el usuario pidió (2026-11-20, chat) hacer el piso, andar y las puertas **antes del hito 3**. Esto es una parte del hito 4 («4a»). El resto del hito 4 (repartidor, levantarse animado, apagón, linterna como mecánica, fusible, Evidencia, Carga ampliada, guardado v2, aviso de fotosensibilidad y playtest) queda para «4b», después del hito 3.

**Ya decidido por el usuario (2026-11-20):** especificación antes de construir; GI solo en el salón (D9, cambiado el 2026-11-23); **solo andar lento**; 3-6 muebles básicos por habitación.

**Términos:**
- **Zona:** una habitación o un tramo de pasillo.
- **Hoja:** la parte de la puerta que gira.
- **Vano:** un paso sin puerta.
- **Activa:** zona con su VoxelGI encendido.
- **Build de pruebas:** la que se abre con `Jugar (pruebas).bat`.
- **Build normal:** `build/TheLivingRoom.exe`.

**†:** dato del motor que se confirma al implementar; si no coincide, se corrige esta especificación antes de seguir. Ya confirmados con context7 (Godot 4.7): como mucho 8 VoxelGI dibujados a la vez y 2 mezclados en cada píxel; el sufijo `-colonly` crea colisión sin malla.

## 1. Objetivo

En la build de pruebas, el jugador se levanta del sofá y recorre un piso de 14 habitaciones con muebles básicos. Abre y cierra las puertas arrastrándolas con el ratón como en *Visage* y vuelve a sentarse. Todo funciona igual en espejo y a oscuras, dentro de los objetivos de rendimiento de hito2 D16.

Fuera de 4a: todo lo de 4b, el look-dev fino de cada habitación, la pausa de pie, invertir el eje Y, los pasos según el suelo y guardar la posición.

## 2. El plano

Piso de los años 40, de unos 17,5 × 13 m y 2,6 m de alto. Fachada a la calle (arriba en el croquis). Medidas aproximadas, a eje de muro; las exactas las fija `flat_layout.py` (D1).

```
x→ 0        4.5         9.5        14     17.5
y0 +---------+-----------+----------+------+   fachada (calle)
   | bedroom | LIVING    | dining   |      |
   | _main   | (salón)   | _room    | work |
y4 +--D------+-------D---+----D-----+ shop |
   | c_main_w=  c_main_m  = c_main_e D     |   = vano entre tramos
y5 +-+-D------+--D---+-----+---D----+      |
   |s| bed    | bath |bed  | pantry |      |
   |i| room_2 | room |room |  _hall |      |
   |d|        |      | _3  |        |      |
y8.5 =-+------+------+--D--+---D----+---D--+
   | c_serv_w   =   c_serv_m    =   c_serv_e |
y9.7 +---D--+--D-+----D---+-D--+--+----D-----+
   |gallery|stor|entrance |kitchen |service  |
   | (patio)|age|_hall    |  +larder|_toilet  |
y13+-------+----+----D----+--------+---------+
                    rellano (puerta con llave)
```

**Zonas (21):** 14 habitaciones y 7 tramos de pasillo. Cada pasillo largo se parte en tramos unidos por vanos: así ninguna zona tiene más de 7 vecinas ni mide más de ~6 m (M1 de EGM).

| id | Nombre | Suelo |
|---|---|---|
| `living_room` | Salón (el actual) | parquet |
| `bedroom_main` | Dormitorio principal | parquet |
| `dining_room` | Comedor | parquet |
| `workshop` | Taller del electricista (de la fachada al pasillo de servicio) | baldosa |
| `bedroom_2`, `bedroom_3` | Dormitorios 2 y 3 (casi gemelos) | parquet |
| `bathroom` | Baño | baldosa |
| `pantry_hall` | Oficio (de paso) | baldosa |
| `gallery` | Galería, abierta al patio de luces | baldosa |
| `storage` | Trastero con la **caja de plomos** | baldosa |
| `entrance_hall` | Recibidor | parquet |
| `kitchen` | Cocina | baldosa |
| `larder` | Despensa (dentro de la cocina, x 8,6-10,2) | baldosa |
| `service_toilet` | Aseo de servicio | baldosa |
| `corridor_main_w/_m/_e`, `corridor_side`, `corridor_service_w/_m/_e` | Pasillos | parquet |

**Conexiones** (`H` = hoja, `V` = vano):

| Une | Tipo | Al empezar |
|---|---|---|
| `living_room` – `corridor_main_m` | H (la puerta actual del salón) | cerrada |
| `bedroom_main` – `corridor_main_w` | H | cerrada |
| `dining_room` – `corridor_main_e` | H | entornada |
| `workshop` – `corridor_main_e` | H | cerrada |
| `workshop` – `corridor_service_e` | H | cerrada |
| `bedroom_2` – `corridor_main_w` | H | cerrada |
| `bathroom` – `corridor_main_m` | H | entornada |
| `bedroom_3` – `corridor_service_m` | H | entornada |
| `pantry_hall` – `corridor_main_e` | H | cerrada |
| `pantry_hall` – `corridor_service_e` | H | cerrada |
| `gallery` – `corridor_service_w` | H | cerrada |
| `storage` – `corridor_service_w` | H | cerrada |
| `entrance_hall` – `corridor_service_m` | V | — |
| `kitchen` – `corridor_service_m` | H | cerrada |
| `larder` – `kitchen` | H | cerrada |
| `service_toilet` – `corridor_service_e` | H | cerrada |
| `corridor_main_w` – `corridor_main_m`, `corridor_main_m` – `corridor_main_e` | V | — |
| `corridor_service_w` – `corridor_service_m`, `corridor_service_m` – `corridor_service_e` | V | — |
| `corridor_side` – `corridor_main_w`, `corridor_side` – `corridor_service_w` | V | — |
| `entrance_hall` – rellano | H, con llave | cerrada |

Lo que lo hace difícil de memorizar (GDD §8, run 2):
- **Tres recorridos en círculo** entre los dos pasillos: el lateral, el oficio y el taller.
- **Dormitorios gemelos** que dan a pasillos distintos.
- **Fondos de saco:** la despensa y el trastero.
- **Todas las puertas iguales** y el mismo papel en los pasillos.
- **La caja de plomos lejos del salón:** a 5 pasos por puertas o más.

**Cambios respecto al plano del chat:**
- No hay puerta entre el salón y el comedor: esa es la pared del sofá (§10, P3).
- La despensa se abre solo desde la cocina.
- Los pasillos van en tramos.

## 3. Decisiones

**D1 — Una sola fuente del plano.** `tools/blender/flat_layout.py` es Python puro (sin `bpy`) y contiene zonas, conexiones, luces y la habitación de la caja de plomos.
- Usa coordenadas de Blender con el origen en el centro del salón; la conversión a Godot (x igual, z = −y de Blender) se hace una sola vez, al escribir el `.tres`.
- `build_flat.py` lo importa y escribe `data/flat_layout.tres` en la **misma ejecución** que el glTF, así que no pueden desincronizarse.
- Descartado: dibujar el plano en Godot. Blender necesita los mismos datos para construir.

**D2 — Geometría.** `tools/blender/build_flat.py` construye todo menos el salón:
- Paredes, suelos, techos, marcos y rodapiés, **partidos por zona**: ninguna malla cruza dos zonas, para que cada pixel mezcle como mucho 2 VoxelGI.
- Muros de 15 cm, con colisión `-colonly`.
- Las funciones de ayuda (`box`, `tex_mat`, `import_model`, `mirror_all`…) pasan de `build_living_room.py` a `tools/blender/blender_common.py`, que usan los dos scripts.
- Rotaciones aplicadas antes de `mirror_all`.
- Salida: `assets/models/player_flat/flat.gltf` y `flat_mirror.gltf`, en la misma carpeta que el salón (que se muda de `living_room/`), para compartir texturas.
- Las hojas de las puertas no van en el glTF (D5).

**D3 — El salón cambia solo en colisión.** `build_living_room.py` (modo final) deja de borrar las cajas de los muebles y las exporta como `-colonly`. El sofá va en su propia capa de colisión, para el clic de D7. La hoja `DoorLeaf` y `DoorHandle` siguen en su glTF, pero `flat.gd` las oculta y pone en su bisagra una `Door` de D5. El resto del salón no cambia. Su GI se hornea de nuevo dentro del piso (D9).

**D4 — Montaje.** `world/player_flat/flat.tscn` (`flat.gd`):
- Monta el salón (`living_room.tscn`, como ahora), la geometría del resto y una `Door` por hoja.
- Por cada zona crea un contenedor `Zones/<id>` con su VoxelGI, una `ReflectionProbe` y sus luces.
- `main.gd` monta `flat.tscn` en vez del salón.
- Un solo `WorldEnvironment`, el del salón: la misma luz en toda la casa (usuario, ronda 3).
- `flat.gd` tiene `bake_mode`, que deja todas las zonas visibles para el horneado (D9).

**D5 — Puertas como en Visage.** `world/player_flat/door.tscn`: la hoja es un `AnimatableBody3D` que gira en torno a la bisagra.
- **Agarrar:** con la hoja en el centro de la pantalla a ≤ 2 m, se mantiene el clic.
- **Arrastrar:** mover el ratón **hacia arriba aleja la hoja de ti; hacia abajo, la acerca**, desde cualquier lado. La velocidad del ratón decide si se abre despacio o deprisa. Mientras se arrastra, la vista no gira.
- **Soltar:** la hoja sigue con su inercia y frena con rozamiento.
- **Al llegar a 0° despacio**, queda cerrada con un clic del pestillo. Deprisa, da un portazo y rebota un poco.
- **Tope a 100°:** se para.
- **Si va a chocar con el jugador o con un mueble**, se para. Antes de cada paso se comprueba con `intersect_shape` de la caja de la hoja en el ángulo siguiente. No empuja al jugador.
- **Física de la hoja:** `DoorMath.step(angle, velocity, drag, delta) -> Vector3(angle, velocity, event)`, con `event` 0 nada, 1 pestillo, 2 portazo. Es una función pura con constantes con nombre (`MAX_ANGLE` 100°, `FRICTION`, `LATCH_SPEED`, `AJAR_ANGLE` 6°), que se ajustan en la parada del paso 4.
- **Espejo:** `DoorMath` no lleva signo; `door.gd` lo invierte en el piso en espejo. Reflejar R_y(θ) da R_y(−θ), y así la hoja reflejada coincide con el reflejo de la normal.
- **Con llave:** `try_grab` devuelve `false` y suena un traqueteo.
- **Señal:** `door.closed_changed(id, closed)`, solo para el piso (mismo sistema).
- **Hoja con `gi_mode` dinámico**, para que no deje una sombra fantasma en la GI horneada.
- **Sonido (CC0):** crujido según la velocidad, pestillo, portazo y traqueteo.
- Descartado: `RigidBody3D` con bisagra (inestable, difícil de controlar con el ratón) y abrir con un clic (no es lo que se pidió).

**D6 — Andar.** `presentation/player/player.tscn` (`player.gd`) es un `CharacterBody3D`:
- Cápsula de 0,25 × 1,75 m y ojos a 1,6 m.
- **Solo andar lento**, 1,3 m/s, con aceleración suave. Sin correr, sin saltar y sin balanceo de cámara.
- WASD y ratón capturado; la sensibilidad sale de Ajustes (D10).
- Un solo juego de pasos CC0 para todo el piso; los pasos según el suelo van con el audio del hito 3.
- Se mueve en `_physics_process`, que es física de presentación, no lógica de juego, así que cumple la regla del reloj único de `CLAUDE.md`. Con `physics/common/physics_interpolation` activado, no da tirones a 144 fps o más.
- Con los trucos acelerando el tiempo, o con el modo libre, el jugador no se mueve.
- La linterna (F) es el mismo nodo que la de la cámara sentada y pasa de una cámara a otra. `LightMixer` la muestra siempre que el jugador la tenga encendida (`set_flashlight_on`), con luz o a oscuras (usuario, 2026-11-20). Empieza apagada.

**D7 — Levantarse y sentarse (provisional, §10 P2).**
- **Levantarse:** con la tecla Q, sin tienda, árbol ni pausa abiertos. El jugador aparece 0,6 m delante del asiento, mirando a la tele, tras una transición de cámara de 0,5 s.
- **Sentarse:** clic en el sofá (≤ 2 m), o Esc de pie, que además abre la pausa de la tele que ya existe.
- **De pie:** `GameCamera` deja de pasar el ratón a la tele y `Game.set_holding(false)`.
- El disparo de verdad (el repartidor y la animación) llega en 4b y sustituye a la Q.
- Descartado: una pausa propia de pie. Sería un tercer menú que esperar a 4b; ahora basta con reutilizar la de la tele.

**D8 — Anulada (usuario, 2026-11-23).** Activaba los VoxelGI por zona; sin GI por zona (D9) sobra `RoomActivation`. Se mantiene lo demás: las luces pasan por el único `LightMixer`, las sondas están siempre visibles y las sombras de las lámparas se apagan a 10 m. Los oclusores de pared, descartados aquí, sí se hicieron en el paso 6 por rendimiento.

**D9 — GI solo en el salón (usuario, 2026-11-23, sustituye a un VoxelGI por zona).** Medido: quitar la del salón ahorra poco y lo oscurece bastante, así que se queda. En las demás zonas no se añade: el usuario da por buena la iluminación tal como está. No se ha probado GI en ellas.
- **Alcance:** donde el resto de este documento hable de un VoxelGI por zona, de activarlos o de hornear 42 volúmenes, manda esta decisión.

**D10 — Ajustes.** Página **Controles** con una sola fila: sensibilidad del ratón, 10 pasos de 0,0006 a 0,0024 rad/px, por defecto 0,0012 (el de los trucos). Va en `settings.cfg`, sin cambiar de versión.

**D11 — Retícula.** Un punto en el centro de la pantalla, solo de pie; crece sobre una hoja o sobre el sofá. `presentation/ui/crosshair.gd`.

**D12 — Luces de las zonas nuevas.** Como en *Visage* (usuario, 2026-11-20, sustituye a P4): solo algunas zonas tienen una lámpara tenue (`LIT_ZONES` de `flat_layout.py`) y el resto queda casi a oscuras, iluminado solo por lo que entra por las puertas. Cada lámpara lleva sus metadatos `base_normal` y `base_dark` para `LightMixer`. Siguen a la Energía y al apagón como las del salón. Sin interruptores en 4a.
- Reparto para el miedo (usuario, 2026-11-22): islas de luz baja y cálida con tramos a oscuras entre ellas; lejos del salón, más oscuro. Luz de una lámpara de la habitación (vacío `LampAt_<zona>` del glTF) en el dormitorio principal (quinqué), el recibidor (lámpara de pie con flecos) y el cuarto del niño (flexo encendido sin nadie); del techo en el pasillo principal, la cocina, el baño y el fondo del pasillo de servicio. La farola entra fría y tenue (0,6) por las demás ventanas de la fachada. Sin luz: taller, trastero, despensa, galería, cuarto 2, paso de la despensa, aseo y los extremos de los pasillos.

**D13 — La tele mientras andas.** En 4a la partida sigue produciendo de pie (`Game.running` no cambia). La regla definitiva va a GDD §12 (§10, P6).

**D14 — Muebles básicos.** 3-6 por habitación, de los años 40:
- Camas, armarios, mesas y sillas; en la cocina, fogón y fregadero; en el baño, bañera e inodoro; en el taller, banco de trabajo y estanterías.
- Primero Poly Haven (CC0); lo que falte, modelado en Blender con formas simples y texturas CC0. Todo en `ASSETS.md`.
- Colisión de caja `-colonly` por mueble.
- Los objetos con texto y el fondo de ciudad de las ventanas los coloca Godot (hito2 D14), para que el espejo no invierta las letras.
- La lluvia de partículas solo en el salón.

**D15 — Guardado sin cambios.** La posición no se guarda: al cargar, el jugador siempre está sentado.

**D16 — Herramientas de desarrollo.**
- `TLR_SPAWN=<id de zona>` pone al jugador de pie en el centro de esa zona. Con un id desconocido, avisa y sigue sentado. Solo en depuración.
- El benchmark activa las zonas de la posición de cada cámara.

## 4. Archivos

```
tools/blender/blender_common.py            crear (funciones sacadas de build_living_room.py)
tools/blender/build_living_room.py         cambiar (usa blender_common; colisión de muebles -colonly; nueva carpeta de salida)
tools/blender/flat_layout.py               crear
tools/blender/build_flat.py                crear (glTF normal y espejo + data/flat_layout.tres)
assets/models/player_flat/                 crear (salón movido aquí + piso; texturas compartidas)
data/flat_layout.tres                      generado
world/player_flat/flat_layout.gd           crear (class_name FlatLayout)
world/player_flat/zone_def.gd              crear (class_name ZoneDef)
world/player_flat/connection_def.gd        crear (class_name ConnectionDef)
world/player_flat/door_math.gd             crear (class_name DoorMath)
world/player_flat/door.gd, door.tscn       crear
world/player_flat/flat.gd, flat.tscn       crear
world/player_flat/living_room.gd           cambiar (rutas del glTF)
world/player_flat/gi/                      generado, fuera de git
presentation/player/player.gd, player.tscn crear
presentation/ui/crosshair.gd               crear
presentation/main.gd                       cambiar (monta flat; levantarse y sentarse; TLR_SPAWN)
presentation/camera/game_camera.gd         cambiar (no reenvía a la tele de pie; cede la linterna)
presentation/graphics/light_mixer.gd       cambiar (set_flashlight_on)
presentation/graphics/graphics_settings.gd cambiar (Array de VoxelGI y de sondas)
presentation/graphics/benchmark.gd         cambiar (activa zonas por cámara)
presentation/ui/main_menu_ui.gd            cambiar (página Controles)
presentation/ui/tv_game_ui.gd              cambiar (abrir la pausa al sentarse con Esc)
autoload/event_bus.gd                      cambiar (player_zone_changed)
core/user_settings.gd                      cambiar (mouse_sensitivity)
tools/bake_voxel_gi.gd                     cambiar (todas las zonas, normal y espejo)
project.godot                              cambiar (move_*, stand_up, flashlight; physics_interpolation)
.gitignore                                 cambiar (gi/, texturas y .bin del piso, art_source/flat.blend)
assets/audio/flat/                         crear (pasos, puertas)
locale/strings.csv, ASSETS.md              cambiar
tests/test_flat_layout.gd                  crear
tests/test_door_math.gd                    crear
tests/test_flat.gd                         crear
tests/test_user_settings.gd, test_main_menu_ui.gd, test_light_mixer.gd, test_graphics_settings.gd   cambiar
tools/verify.sh                            cambiar (20 scripts de test)
GAME_DESIGN.md                             cambiar (§8 plano, §11 4a/4b, §12 según P6)
CLAUDE.md                                  cambiar (presentation/player/, si se aprueba P1)
```

## 5. Interfaces

- `FlatLayout`:
  - `zones: Array[ZoneDef]`, `connections: Array[ConnectionDef]`, `fuse_box_zone: StringName`;
  - `zone_at(p: Vector2, mirrored: bool) -> StringName`: en espejo refleja el punto (`p.x = -p.x`); devuelve `&""` en un muro;
  - `neighbors(id) -> Array[StringName]`.
- `ZoneDef`:
  - `id`, `name_key`, `rect: Rect2` (planta X-Z de Godot, interior);
  - `lights: Array[Dictionary]` (`pos`, `color`, `energy`, `range`, `base_normal`, `base_dark`).
- `ConnectionDef`:
  - `id`, `zone_a`, `zone_b` (`&""` = rellano);
  - `kind` (`leaf` | `passage`), `hinge: Vector3`, `facing`, `width`;
  - `start` (`closed` | `ajar` | `locked`).
- `DoorMath.step(angle, velocity, drag, delta) -> Vector3` (D5).
- `Door`: `try_grab(eye: Vector3) -> bool`, `drag(mouse_dy: float)`, `release()`; señal `closed_changed`.
- `Player`:
  - `setup(layout, mirrored)` y `stand_at(transform)`;
  - señal local `sit_requested`;
  - emite `EventBus.player_zone_changed`.

## 6. Pasos

0. Confirmar con context7 los † que faltan (interpolación física, `intersect_shape` con hojas, sondas en el atlas).
1. `flat_layout.py`, el `.tres` y `test_flat_layout.gd`. Rectángulos planos en Blender: **parada, captura cenital del plano.**
2. `blender_common.py`, la geometría del piso, el salón con colisión, `flat.tscn` en normal y en espejo, sin GI nueva.
3. Jugador, levantarse y sentarse, retícula y página Controles.
4. Puertas y sus sonidos. **Parada: el usuario anda y abre puertas en el piso vacío** (tacto de las puertas, velocidad al andar, sensibilidad).
5. Muebles básicos y luces.
6. Benchmark en los 4 presets, en normal y a oscuras con linterna, más la VRAM. Sin GI por zona (D9). **Hecho (2026-11-23).**
7. Documentación: GDD, `CLAUDE.md` y `ASSETS.md`.
8. **Parada final:** capturas de cada zona; el usuario recorre el piso en la build de pruebas.

Cada paso deja los tests en verde y hace commit y push.

## 7. Tests

| Test | Qué comprueba |
|---|---|
| `test_flat_layout.gd` | 21 zonas sin solaparse. Cada conexión une dos zonas separadas 0,15 ± 0,01 m y que se solapan al menos el ancho de la puerta (salvo la del rellano). Todo se alcanza desde el salón. Quitar el lateral, el oficio o el taller (uno cada vez) deja unidos los dos pasillos. La caja de plomos está en `storage`, a ≥ 5 pasos del salón. El salón mide 4 × 5 y su conexión coincide con la puerta actual (pared x = −2,075, z = −1,6, ancho 0,9). `zone_at` dentro, en bordes, en muros y reflejado |
| `test_door_math.gd` | Arrastre rápido abre más deprisa que lento. Sin arrastre frena hasta parar. No pasa de 0 ni de `MAX_ANGLE`. A 0° despacio: pestillo (evento 1); deprisa: portazo y rebote (evento 2). Con dt de 1/30 y de 1/144, menos de 1° de diferencia tras 1 s |
| `test_flat.gd` | Se monta en normal y en espejo, con 21 VoxelGI y una `Door` por hoja. En espejo, cada hoja a θ coincide con `MirrorMath.mirror_transform` de la normal a θ. Cambiar de preset o de estado de la tele no enciende zonas inactivas. Un `TLR_SPAWN` desconocido deja al jugador sentado |
| `test_light_mixer.gd`, `test_graphics_settings.gd` | `set_flashlight_on`; varias GI y sondas |
| `test_user_settings.gd`, `test_main_menu_ui.gd` | `mouse_sensitivity` (ida y vuelta, valores malos, archivo antiguo); la página Controles cabe y tiene foco |

Manual, en las paradas: tacto de andar y de las puertas (paso 4), aspecto (pasos 1 y 8), que la hoja no atraviese ni encaje al jugador (paso 4).

## 8. Criterio de cierre

- Paradas de los pasos 1, 4 y 8 aprobadas por el usuario.
- Benchmark dentro de los objetivos de hito2 D16 en los 4 presets.
- `VERIFY OK` con 20 scripts de test.
- Documentación al día.
- Commit y push.

## 9. Riesgos y límites

- **Pocos modelos de cocina y baño** en Poly Haven: se modelan formas simples.
- **La Q de levantarse** es provisional (D7).

## 10. Decisiones para el usuario

| Id | Pregunta | Propuesta | Si apruebas sin decir nada | Bloquea |
|---|---|---|---|---|
| P1 | ¿Se crea la carpeta `presentation/player/` para el jugador? | Sí | Se crea | Paso 3 |
| P2 | ¿La Q de levantarse va solo en la build de pruebas? Así no se estropea en la normal la sorpresa del zoom out (hito2 D2). | Solo en pruebas | Solo en pruebas | Paso 3 |
| P3 | ¿Quitamos la puerta entre el salón y el comedor? Estaba detrás del sofá. | Quitarla | Se quita | Paso 1 |
| P4 | ¿Lámparas encendidas y tenues en todas las habitaciones, de noche? | Sí, como el salón | Encendidas | Paso 5 |
| P5 | Si 42 horneados de GI pesan demasiado, ¿probamos un solo VoxelGI para todo el piso? | Preguntar entonces | Resuelta (2026-11-23): GI solo en el salón (D9) | — |
| P6 | ¿La tele sigue produciendo mientras andas (salvo en el apagón)? | Sí | Sí | — (va al GDD) |
