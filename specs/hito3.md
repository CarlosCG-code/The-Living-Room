# Especificación — Hito 3: audio de la run 1 y director de eventos

> Estado: **v3, con las decisiones del usuario (2026-11-24, §8); pendiente de su aprobación**. v2 tras la revisión EGM (`reviews/hito3/egm_report.md`); la v3 quita el zoom out y no se ha vuelto a revisar. No se escribe código hasta que la apruebe.
>
> Fuentes: `GAME_DESIGN.md` §3-§6, §11 (hito 3) y §12; `CLAUDE.md`; `specs/hito2.md` (D2, D10, D12), `specs/hito4a.md` (D12, D13), `specs/incremental.md` §3 y §4.

**Términos:**
- **Run:** cada vuelta del incremental entre dos *Reiniciar*.
- **Progreso (`p`):** de 0 a 1, cuánto ha avanzado la run (D1).
- **Director:** el que decide qué suceso inquietante ocurre y cuándo.
- **†:** dato que se confirma al implementar; si no coincide, se corrige esta especificación antes de seguir.

## 1. Objetivo

Jugando la run 1 sentado:
- cada máquina comprada añade su sonido a la casa, y el director los suelta con silencios largos;
- las luces de la casa bajan cuando la tele produce más;
- los sonidos de la señora (pastillas, gafas, dentadura) empiezan a colarse;
- un ajuste regula la intensidad de los efectos, y nunca hay más de 3 destellos por segundo.

**La vista no cambia (usuario, 2026-11-24):** sentado, la cámara sigue fija en la tele, sin zoom out ni giro de cabeza. El salón y el sofá se descubren al levantarse para abrir al repartidor (4b). Sustituye al zoom out del GDD §3 y a lo previsto en hito2 D2 y D3.

**Fuera:**
- 4b: la revelación del salón, el repartidor, levantarse animado, aviso de fotosensibilidad, mezcla por run y pasos según el suelo (hito 4a se los dejaba a este hito, pero en la build normal todavía no se anda).
- Hito 7: mostrar los subtítulos (aquí se crean sus textos).
- Runs 2-4: sucesos propios. Hasta entonces usan los de la run 1.
- Final: congelación (D8 solo decide cómo será).
- Música.

## 2. Decisiones

**D1 — Dos medidas, las dos en `Economy`.** No se guarda nada nuevo: salen del estado que ya se guarda.
- **Progreso:** `run_progress() = clamp(log(E / 2000) / log(umbral / 2000), 0, 1)`, con E la Energía producida en la run (E ≤ 2000 → 0). Medido con el simulador de ritmo, el jugador activo pasa por 0 (min 2), 0,30 (min 10), 0,60 (min 20), 0,79 (min 24), 0,92 (min 28) y 1 (min ~30): casi lineal con el tiempo. Lo lee el director.
- **Nivel de producción:** `production_level() = clamp(log(1 + s) / log(1 + 26000), 0, 1)`, con s la producción por segundo. Lo leen las luces y el zumbido de la casa, para que cada compra se note al momento y una apagada de la tele las recupere.
- El zumbido y el dron de la propia tele (`tv.gd`) y el deterioro del mundo de la tele siguen con `E / umbral`, ya aprobados.
- Descartado: `E / umbral` para todo (se queda cerca de 0 hasta el minuto 24 y salta) y el tiempo de juego (avanzaría con la tele parada).

**D2 — Luces.** `LightMixer.set_factor(lerp(1, LIGHT_MIN, production_level()))`, con `LIGHT_MIN` 0,55 (usuario, 2026-11-24), suavizado en ~3 s.
- Multiplica las lámparas (`OmniLight3D`) y, a medias, la luz ambiente. **Deja de** multiplicar la pantalla de la tele (es la que consume) y las farolas.
- Sin producción, el salón se ve exactamente como el aprobado en 4a.
- Cada 10 % de cambio se recaptura la sonda (`_recapture_probe()`, ya existe): si no, los reflejos seguirían al 100 % (hito2 D12).
- El coste de rehacer la GI se mide en el paso 2; si se nota, se aplica en saltos del 2 %.

**D3 — Director.** `fear/event_director.gd`, `RefCounted` sin nodos.

```gdscript
class_name EventDirector
signal event_started(def: FearEventDef, place: StringName)
func _init(p_set: FearEventSet, rng: RandomNumberGenerator)
func tick(delta: float, s: DirectorState)
func busy() -> bool                      # hay un suceso en curso
func reset(s: DirectorState)             # lo borra todo; lo obligatorio ya cumplido se da por hecho
func force(id: StringName)               # trucos: sale en cuanto pueda

class_name DirectorState                 # RefCounted, lo rellena Game.tick
var progress: float; var owned: Dictionary; var tv_event: StringName
var ui_idle: bool                        # false con el árbol, la carta o la Carga
var player_zone: StringName              # living_room si está sentado
var place_zone: Callable                 # (place: StringName) -> StringName
var lamps: Array[StringName]             # lámparas a la vista
```

- **Quién lo mueve:** `Game` lo crea y lo avanza en `tick` tras la economía, y emite `EventBus.fear_event(def, place)`. Lo de la escena sale de `Game.senses`, un objeto que pone `main.gd` y retira en `tree_exiting`. Sin él (tests): sentado y sin lámparas a la vista. `Game` llama a `reset` al crear la partida, al reiniciar y en partida nueva. Continuar desde el menú o salir de la pausa no reinicia nada.
- **Ritmo:** silencio al azar de 90-240 s y después una **tanda**: 1 suceso con `p` < 0,6; 1-3 hasta 1; 2-4 con `p` = 1. Dentro de la tanda, 8-25 s entre el final de uno y el principio del siguiente. Los silencios no se acortan: crece la tanda (esa es la tensión acumulada del GDD). El director empieza siempre en silencio.
- **Presupuesto:** 30 sucesos al azar por run mientras `p` < 1. Pasado el umbral no hay tope: quien espera oye un piso peor (GDD §4).
- **Elegir:** uno al azar entre los posibles (`p` mínimo, máquina, enfriamiento y un lugar válido). No se repiten los últimos `min(2, posibles − 2)` sucesos (mínimo 0) ni el último lugar si hay otro. Si no hay ninguno posible, la tanda acaba y empieza otro silencio. El enfriamiento de los ligados a una máquina se divide por `1 + unidades / 25`.
- **Obligatorios:** los que la historia necesita no quedan al azar. Salen una vez al cumplirse su condición, 4-10 s después y con `ui_idle`, aunque sea silencio; no gastan presupuesto y reinician el silencio. Son la primera unidad de cada máquina (menos la Antena, que es el zumbido), los tres de la señora al llegar a su `p`, `knocks` (Canal 3 o `p` ≥ 0,85) y el fotograma (D7). Hasta salir no entran en el sorteo; después sí (los de sonido), sin mirar ya `requires`.
- **Uno a la vez:** nada empieza hasta que pasa la `duration` del anterior más 0,34 s, tampoco los obligatorios.
- **Sin guardar:** al cargar, los contadores vuelven a cero. Se acepta.

**Sucesos:** `fear/fear_event_def.gd` (`Resource`): `id`, `kind` (`SOUND`, `LAMP`, `TV_FRAME`), `min_progress`, `requires` (id de máquina o vacío), `mandatory` (`NONE`, `ON_PURCHASE`, `ON_PROGRESS`), `mandatory_progress`, `random: bool`, `cooldown`, `duration`, `places: Array[StringName]`, `sounds: Array[AudioStream]`, `volume_db`, `subtitle_key`. Todos en `data/fear_events.tres` (`FearEventSet`: `events`, `silence: Vector2`, `gap: Vector2`, `run_budget: int`). La `duration` de un sonido es la de su archivo más largo.

| id | `requires` | `p` mín. | Obligatorio | Enfr. (s) | Lugares | Qué suena |
|---|---|---|---|---|---|---|
| `wall_ticks` | `valves` | 0 | compra | 180 | `wall`, `corridor_main_m` | chasquidos en la pared |
| `cry` | `audio_frequency` | 0 | compra | 300 | `kitchen` | llanto lejano |
| `voices` | `tuner` | 0 | compra | 300 | `ceiling` | voces apagadas de otra tele |
| `remote` | `remote` | 0 | compra | 300 | `dining_room`, `bedroom_main` | clic de un mando |
| `fall` | `remote` | 0,5 | — | 360 | `workshop`, `bedroom_2`, `gallery` | algo cae al suelo |
| `knocks` | `channel_3` | 0 | compra, o `p` ≥ 0,85 aunque no se compre | 300 | `door_front` | toques en la puerta |
| `pipes` | — | 0,1 | — | 240 | `bathroom`, `service_toilet` | tuberías |
| `steps_above` | — | 0,3 | — | 300 | `ceiling` | pasos en el piso de arriba |
| `creak` | — | 0,4 | — | 360 | `door_bedroom_3`, `door_gallery` | una puerta cruje |
| `pills` | — | 0,35 | `p` | 420 | `bedroom_main`, `bathroom` | pastillas que caen |
| `glasses` | — | 0,55 | `p` | 420 | `dining_room`, `bedroom_main` | gafas que caen |
| `denture` | — | 0,7 | `p` | 420 | `bathroom` | dentadura en un vaso |
| `lamp_flicker` | — | 0 | — | 180 | lámparas a la vista | parpadeo, sin sonido (2,4 s) |
| `tv_frame` | — | 0,7 | interferencia | — | — | D7; no entra en el sorteo |

Cuenta esperada en 30 min: ~7 sueltos hasta `p` 0,6, ~7 en las tandas del final y 9 obligatorios: **unos 23**. El usuario aprueba el ritmo (2026-11-24); se ajusta al probarlo.

**D4 — Lugares.** `flat.get_place(id) -> Vector3`, con el espejo ya resuelto:
- zona: su centro, a 1 m;
- puerta (solo `kind == leaf`): el centro de la hoja, a 1 m, movido 0,4 m hacia `zone_a`;
- `ceiling`: centro del techo del salón; `wall`: pared del salón frente al sofá.

Regla del sonido: nunca en la zona donde está el jugador (`LAYOUT.zone_at(punto)`), salvo `ceiling` y `wall`.

**D5 — Sin comprobación de mirada (usuario, 2026-11-24; GDD §5).** Los cambios de las runs 3 y 4 ocurren fuera de cuadro o en apagones, y se construyen con su hito. En la run 1 no cambia nada a la vista.
- Lo que sí hace falta, las **lámparas**: cuenta una encendida en la zona del jugador (se ve su luz en la pared; en la pose de juego ninguna entra en cuadro) o una que pase el `LightFlicker._visible_lamps` de hoy.

**D6 — Audio.** `audio/house_audio.gd` (`Node`, lo monta `main.gd`): escucha `EventBus.fear_event` y reproduce los `SOUND` con **un solo** `AudioStreamPlayer3D` (van de uno en uno).
- **Bus nuevo `HouseEvents`** (paso bajo, envía a `House`): filtrar `House` apagaría también pasos y puertas. El eco del piso se mantiene.
- **Muros:** como mucho cuenta uno: sin muro, 0 dB y 20 kHz; con muro, −5 dB y 2,5 kHz. Con la tabla de la tele (−24 dB y 300 Hz) unas pastillas no se reconocerían, y el final depende de reconocerlas. La lejanía va en `volume_db` y `unit_size`.
- **Preludio:** en la mitad de los sonidos, al azar, el zumbido de la tele y el de la casa se cortan 1,5 s antes y siguen cortados hasta el final (`EventBus.house_silence(seconds)`). Sustituye a los cortes al azar de `tv.gd`.
- **Capas continuas:** ambiente del edificio (muy bajo) y zumbido eléctrico en la pared del salón desde la primera Antena: de −30 a −18 dB según `production_level()`. Con la partida parada, se quedan en su nivel.
- **Parpadeos:** `LightFlicker` pierde el temporizador de las lámparas y ejecuta `lamp_flicker`. El de la linterna sigue como está (en la build normal no se usa hasta 4b), pero espera si hay una lámpara parpadeando.
- **Sonido de compra:** se queda el actual (ya es CC0 de Freesound).
- **Archivos:** 1-2 por suceso y 2 capas, unos 20. Freesound CC0 y mono, en `ASSETS.md`. `creak` son 2-3 tramos recortados de `door_creak.ogg`. Si un llanto o unas voces CC0 no convencen, se generan con un modelo permitido por `CLAUDE.md`.

**D7 — Fotograma de la tele (aprobado por el usuario, 2026-11-24).** La primera interferencia con `p` ≥ 0,7, 1-1,5 s después de empezar: la pantalla enseña 0,12 s de **tu salón en directo, visto desde detrás del sofá**: es lo primero que se ve del salón. Con la paleta de la tele (`palette.gdshader`).
- Sale de un `SubViewport` de 320 × 240 con una cámara en (0; 1,3; −2,35) del salón, dibujado una sola vez. Así no hay captura en el repositorio (privacidad) y se ve la luz de ese momento.
- Durante 1 s se paran el marcador de la interferencia y el parpadeo de la fábrica.

**D8 — Pausa y final.** La pausa sigue siendo `Game.running = false`, sin `SceneTree.paused`: detiene economía, director y progreso. Un sonido en curso termina. Para el final bastará otra bandera: economía y director se avanzan por separado en `Game.tick`. El autoguardado periódico se aplaza mientras `director.busy()` (GDD §3).

**D9 — Intensidad de efectos.** `UserSettings.effects_intensity`, 0-1 en pasos de 10 %, 1 por defecto; `settings.cfg` sigue en la versión 1. Fila `UI_EFFECTS` en la página Gráficos (`PAGES`, `REPEATABLE`, `_change`, `_refresh`).
- **Parpadeos** (lámparas y linterna): la profundidad se escala; con 0, un solo bajón en rampa de 1,5 s hasta el 75 %.
- **Luces por producción:** el mínimo pasa de 0,55 (con 1) a 0,8 (con 0).
- **Efectos de pantalla:** sacudida de la tele, parpadeo de la fábrica, título del menú y fotograma se escalan; con 0, nada.
- **Tope de 3 destellos por segundo:** 0,34 s entre bajones (ya hecho), uno a la vez (D3), linterna que espera a la lámpara (D6), y separación mínima de 0,34 s en el parpadeo de la fábrica, que hoy no la tiene.

**D10 — Desarrollo.** Truco F1 «suceso ya» (por id), solo en depuración. Para lo demás bastan los trucos que hay.

## 3. Archivos

```
core/economy.gd, core/user_settings.gd        cambiar (D1, D9)
autoload/event_bus.gd, autoload/game.gd       cambiar (fear_event, house_silence; director, senses, autoguardado)
fear/event_director.gd, director_state.gd     crear
fear/fear_event_def.gd, fear_event_set.gd     crear
data/fear_events.tres                         crear
audio/house_audio.gd                          crear
presentation/main.gd                          cambiar (monta HouseAudio, senses y fotograma; luces)
presentation/graphics/light_mixer.gd          cambiar (D2)
presentation/graphics/light_flicker.gd        cambiar (D6, D9)
presentation/tv/tv.gd                         cambiar (house_silence)
presentation/ui/tv_game_ui.gd, factory_view.gd, main_menu_ui.gd   cambiar (fotograma, D9)
world/player_flat/flat.gd                     cambiar (get_place)
default_bus_layout.tres                       cambiar (HouseEvents)
locale/strings.csv                            cambiar (ajuste, subtítulos)
assets/audio/house/*                          crear
tools/dev_cheats.gd                           cambiar
tests/test_event_director.gd                  crear
tests/ test_economy, test_flat, test_light_mixer, test_user_settings, test_main_menu_ui, test_dev_cheats   cambiar
tools/verify.sh                               cambiar (20 → 21 scripts)
ASSETS.md, GAME_DESIGN.md, CLAUDE.md, specs/hito2.md   cambiar
```

## 4. Pasos

Cada paso deja los tests en verde y hace commit y push.

1. **Director.** D1, D3, D4, D8, D10 y claves de subtítulo, sin sonido (se anuncian en el log). La simulación de 30 min es un caso del test.
2. **Luces e intensidad.** D2 y D9; las lámparas pasan al director. Capturas con producción baja, media y alta. Se mide el coste.
3. **Sonidos.** D6 y D7, y los tests de datos de audio. **Parada 1:** el usuario juega 10 minutos reales desde `p` 0,5, clicando y con la tele y la lluvia sonando, y aprueba sonidos, mezcla, luces y ritmo.
4. **Benchmark** en los 4 presets (hito2 D16) y **documentación:** GDD §4-§6 y §12, `CLAUDE.md`, `ASSETS.md`. De paso, lo que arrastra de antes: umbral de la run 1 (45 millones) en el GDD §4, técnica del espejo en `CLAUDE.md` y estado de `specs/hito2.md`.
5. **Parada 2:** el usuario juega la run 1 entera sin trucos (~30 min).

## 5. Tests

| Test | Qué comprueba |
|---|---|
| `test_event_director.gd` | Semilla fija. Nunca dos a la vez; silencios de 90-240 s; tandas según `p`; `min_progress`, `requires`, enfriamiento y presupuesto (solo con `p` < 1); 0, 1, 2 y 3 sucesos posibles sin bloquearse; no repetir; sin lámparas a la vista no hay `lamp_flicker`; sonido nunca en la zona del jugador salvo `ceiling`/`wall`; obligatorios a los 4-10 s, una vez, esperan a `ui_idle`, y al cargar no se repiten los ya cumplidos; `reset` lo borra todo. **30 min** con `p` y compras de D1: 18-30 sucesos, mediana del silencio ≥ 120 s, los 9 obligatorios salen; **10 min con `p` 1**: sigue habiendo |
| `test_event_director.gd` (datos) | Ids únicos; lugares y máquinas existen; claves de subtítulo traducidas; parpadeos de 2,4 s o más. Desde el paso 3: cada `SOUND` con sonidos, `duration` correcta y mono (byte de canales de la cabecera Vorbis †) |
| `test_economy.gd` | `run_progress` (0 con E ≤ 2000, 1 en el umbral, creciente, 0 al reiniciar) y `production_level` |
| `test_light_mixer.gd` | El factor no toca pantalla ni farola (la de prueba pasa a `SpotLight3D`); ambiente a medias; parpadeo con intensidad 0, 0,5 y 1; linterna y lámpara nunca a la vez |
| `test_flat.gd` | `get_place` de zona, puerta, `ceiling` y `wall`, normal y en espejo |
| `test_user_settings.gd`, `test_main_menu_ui.gd` | `effects_intensity` (ida y vuelta, valores malos, archivo antiguo) |
| `test_smoke.gd` | El autoguardado se aplaza con un suceso en curso |

Manual, en las paradas: sonidos, luces y ritmo (1), la run entera (2).

## 6. Criterio de cierre

- Paradas 1 y 2 aprobadas por el usuario.
- Benchmark dentro de hito2 D16 en los 4 presets.
- `VERIFY OK` con 21 scripts de test.
- Documentación al día, commit y push.

## 7. Riesgos

- **Sonidos CC0 que no den miedo:** el paso 3 tiene parada propia.
- **Habituación en 30 min:** la miden las dos paradas y, después, el playtest del 4b.
- **30 min con la vista fija:** todo el miedo de la run 1 queda en el sonido, las luces y el fotograma. Se mide en el playtest del 4b (GDD §13).
- **Los tranquilos tardan 40 min:** `p` va por Energía, así que todo se estira con ellos.

## 8. Decisiones del usuario (2026-11-24)

| Id | Pregunta | Decidido |
|---|---|---|
| P1 | ¿Cómo se mira alrededor sentado? | No se mira: vista fija hasta levantarse (4b). Descartados el botón derecho y sacar el cursor de la pantalla |
| P2 | ¿La cabeza se gira sola hacia la puerta con los primeros toques? | No |
| P3 | ¿El fotograma de la tele es tu salón en directo, desde detrás del sofá? | Sí |
| P4 | ¿Cuánto bajan las luces al máximo de producción? | Hasta el 55 % |
| P5 | ¿Unos 23 sucesos en media hora? | Sí; se ajusta al probarlo |
| P6 | ¿Pasos según el suelo y mezcla por run? | En el 4b |
