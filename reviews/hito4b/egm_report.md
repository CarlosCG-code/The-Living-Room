# Informe de revisión EGM — Hito 4b

**Objetivo:** `specs/hito4b.md` v1 (2026-11-26). Revisores: `design`, `implementation-readiness`, `codebase-details` y `zoom-out` (los cuatro completados; no se pasaron `comprehension`, `structural`, `style` ni `inventive-catalyst`). Ninguno ejecutó el juego ni comprobó las API del motor con context7.

Veredicto de los cuatro sobre la v1: no lista. La v2 aplica lo siguiente, junto con las respuestas del usuario del 2026-11-26 (espejo desde la run 2, subtítulos sin voz por ahora, playtest desde cero y seguir jugando tras el plomo).

| Hallazgo | Sev. | Revisores | En la v2 |
|---|---|---|---|
| `Economy.restart()` crea una run nueva y solo copia Carga y mejoras: la Evidencia se perdería | Bloq. | 3 | D1: copia `evidence` y pone la secuencia; test en `test_economy` |
| No estaba definido cuándo acaba una secuencia ni qué se guarda en cada paso; `flags` sin reglas | Bloq. | 3 | D1: pasos con nombre y tabla de reentrada; fuera `flags` |
| La Carga, la carta de fin de emisión y `is_idle()` viven en `tv_game_ui.gd`, que no estaba en §3: al cargar se saltaba la secuencia y Q no levantaba en el apagón | Bloq. | 3 | D1, D6: reglas de `running`, Carga al sentarse, Q sin `is_idle` |
| Las animaciones no tenían ancla ni pose de entrada; el FOV sentado no se puede animar desde Blender | Bloq. | 2 | D3: anclas, entrada en tween, salida por `Player.stand_at`, FOV en código |
| Espejo con escala −1: invierte la luz (hito2 D14, `mirror_math.gd`), la cámara vería la imagen al revés y el jugador sería zurdo | Mayor | 4 | D3: el rig no se refleja, solo su ancla (determinante +1) |
| La run 2 se jugaba en la casa normal, contra «la run 2 combina ambas» | Mayor | 3 | Usuario: espejo desde la run 2; se recarga al sentarse tras el vecino; el apagón ya no recarga |
| Recargar `main.tscn` vuelve al menú, pierde el negro y repite el aviso | Mayor | 3 | D8: la variante sale del estado; arranque sin menú tras la recarga; aviso una vez por proceso |
| Tiempos de la secuencia sin dueño (reloj único) y sin señales de `EventBus` | Mayor | 2 | D1, §4: `Sequence` avanza con `Game.tick`; señales `sequence_cue`, `clue_found` |
| Sentarse antes de dar los plomos empezaba la run 2 | Mayor | 1 | D5: el sofá no se usa en `knock`/`door` |
| D10 ya estaba hecho (`main.gd:51-56`) | Mayor | 3 | Quitado; queda un test de raycast → UV en espejo |
| Interruptores: `LightMixer` no tiene encender/apagar y el parpadeo lo devolvería a 1 | Mayor | 1 | D9: `set_light_on`; el parpadeo se salta las apagadas |
| Cajones y puertas: `DoorMath` tiene el tope fijo; los muebles son una sola malla; falta la geometría de los dos pisos y el horneado | Mayor | 4 | D9: lista cerrada, `max_open` en `step`, `Door` para bisagras, `step_linear` para cajones, geometría y GI en §3 |
| Demasiadas animaciones para lo más incierto | Mayor | 1 | D3: una sola subida; `stand_to_door` = giro + `stand`; `hand_over` y `fix_fuse` con poses y tweens |
| Jugador entero modelado cuando solo se ven los brazos | Mayor | 1 | D4: brazos y mangas; el uniforme pasa a pista |
| Tubería MPFB2 → glTF incompleta (rig, piel, recorte, sombra, exportación) | Mayor | 1 | D4 y `tools/blender/export_character.py` |
| Pausa de pie: `MainMenuUI` mide 320×240; Esc de pie hoy te sienta | Mayor | 2 | D13: `SubViewport` a pantalla completa en 4:3 |
| Subtítulos: no hay nada que los muestre | Mayor | 2 | D15: etiqueta de subtítulos |
| Playtest con una sola persona desde el principio | Bloq. | 1 | Usuario: los 5 desde cero |
| La run 2 repite los sucesos de la run 1 | Mayor | 2 | P10 |
| [PENDIENTE] del GDD (qué hace el jugador con el vecino) dado por decidido | Mayor | 1 | P9 |
| Archivos y tests sin listar (user_settings, light_mixer, event_bus, tv_game_ui, test_flat, test_dev_cheats, verify.sh 21 → 22) | Mayor | 3 | §3 y §6 |
| Controles sin enseñar (Q, F, arrastrar) y clics sin respuesta | Menor | 1 | D16 |
| Golpes con un solo reproductor y silencio al azar en `house_audio.gd` | Menor | 1 | D2: `DirectionalSound` propio |
| Los pasos según el suelo ya leen `floor_type` en `player.gd` | Menor | 2 | D14: solo falta la grabación de baldosa |
| Mezcla por run para dos runs | Menor | 1 | Aplazada al hito 5 |
| Trucos: dos de los tres ya existen | Menor | 2 | D17 |
| `narrative/` no existe en git | Menor | 1 | §3: carpeta nueva |

**No aplicado:**
- Cargar siempre sentado (`zoom-out`): guardar la posición está en `PENDIENTES.md`; se pregunta (P12).
- Animar `sit` entera: se queda la transición de 0,5 s, porque desde la run 2 te sientas muchas veces; el usuario pidió el realismo para levantarse.
