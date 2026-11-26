# Especificación — Hito 2: la tele en el salón del jugador

> Estado: **aprobada por el usuario (2026-11-17)**; implementada y **cerrada** (usuario, 2026-11-26), tras aprobarla sobre la marcha en los hitos 4a y 3. Lo que sigue es el registro de la fase 2a: verificada (`VERIFY OK`, 70 tests). Resultados del paso 4: clic, mantener, soltar fuera, compra, interferencia y espejo comprobados con GoPeak; la rueda, con test. D6: con la pantalla retro de 320 × 240 y letra de 8 px, el texto mide 15,0 px en el preset bajo (67 %) y 22,3 px en el alto. Las filas de la tienda parten líneas para no sacar el dial de la pantalla. Revisión EGM en `reviews/hito2/`. EGM es el proceso de revisión con revisores independientes que se usa antes de aprobar cada especificación. No se escribe código hasta que el usuario lo apruebe.
>
> Fuentes: `GAME_DESIGN.md` §1-§3, §5, §8, §10, §11 (hito 2) y §12; `CLAUDE.md` (Arquitectura, Decisiones fijadas); `specs/hito1.md` (la UI plana que pasa a la tele).

**Contexto:** el incremental del hito 1 se juega hoy en una pantalla plana: un dial que da Energía al hacer clic (o al mantenerlo pulsado), una tienda con generadores (Antena…) y mejoras, el botón *Reiniciar* y las interferencias, una estática que se atrapa con un clic. En este hito pasa a la pantalla de una tele de tubo, dentro del salón del jugador. Es también el hito del **look-dev**: fijar el aspecto visual (fotorrealismo oscuro; referencia: *Visage*, videojuego de terror de 2020) iterando con capturas hasta que el usuario lo apruebe. El rendimiento es prioritario: el juego debe ir bien en equipos modestos (petición del usuario, 2026-11-17). Va antes del audio y del director de eventos (hito 3) porque los dos ocurren en esta habitación.

**Términos:** *run* = cada vuelta del incremental entre dos *Reiniciar* (GDD §3); *zoom out* = la cámara que se aleja poco a poco y revela que el jugador está sentado en un sofá (GDD §3, hito 3); *producción* = Energía por segundo del incremental.

**Herramientas (de los hitos 0 y 1):**
- `$GODOT` es el ejecutable de Godot 4.7.2.
- El MCP `godot` (GoPeak) ejecuta el juego, inyecta clics y hace capturas con renderer real.
- El MCP `blender` controla Blender 5.3. Claude lo abre él mismo: la conexión solo funciona con la ventana abierta.
- `tools/verify.sh` hace 5 comprobaciones: importación sin errores, tests GUT, exportación, que el paquete no lleve el addon de capturas `godot_mcp_runtime` ni los tests, y que la build arranque.

**Builds:** la **build de depuración** es el proyecto ejecutado con `$GODOT` sin exportar; la **build exportada** es la generada en `build/`.

**†:** marca lo que se confirma al implementar (con context7 o probándolo); si no coincide, se corrige esta especificación antes de seguir.

## 1. Objetivo

- El salón del jugador existe en 3D, de noche: paredes, suelo, techo, ventana, puerta, sofá, mesa baja, mueble de la tele y algunos objetos cotidianos.
- La tele de tubo muestra el incremental del hito 1 y se juega con el ratón sobre su pantalla: clic, mantener pulsado, comprar, desplazar la tienda, *Reiniciar* y atrapar interferencias funcionan igual que en la UI plana, y todo el texto se lee desde la cámara de juego.
- El aspecto visual (iluminación global, niebla, materiales, color) está fijado y **el usuario lo aprueba** con capturas.
- La técnica de las variantes **en espejo** y **a oscuras** del piso (GDD §8) está validada en esta habitación, con capturas.
- Los **ajustes gráficos** escalan de un preset bajo a uno ultra; el **presupuesto de fotogramas** de cada preset está medido en el PC de desarrollo y aprobado por el usuario (D15, D16).
- Los tests pasan y `tools/verify.sh` termina con `VERIFY OK`.

**Fuera de alcance:**
- el resto del piso (cocina, pasillo, dormitorio, caja de plomos) y andar (hito 4);
- el zoom out animado, el desbloqueo de mirar alrededor, el audio del piso, el director de eventos y las luces que bajan con la producción (hito 3);
- el menú de ajustes gráficos, la pantalla de calibración del brillo, la calidad de texturas y el pulido de la UI retro de la pantalla (curvatura, líneas de barrido) (hito 7).

## 2. Fases

Tres fases, cada una con una parada para el usuario. Lo técnicamente más incierto (el espejo desde Blender y preparar la iluminación global por script) se prueba en la primera, con cajas, para no rehacer nada después de aprobar el aspecto.

| Fase | Qué se hace | Termina cuando |
|---|---|---|
| **2a — Tele jugable y tubería** | Salón en bloques (*graybox*) generado ya con el script de Blender, en sus dos versiones (normal y espejo); tele con `SubViewport`; cámara de juego; cursor sobre la pantalla; un primer bake de iluminación global por script; colisiones reflejadas comprobadas; tests | El usuario juega en la tele del graybox, lee todos los textos y lo aprueba |
| **2b — Look-dev** | Geometría y objetos definitivos, materiales, iluminación global, niebla, color. Rondas de capturas desde los puntos de vista fijos, cada una con los milisegundos del preset alto | El usuario aprueba el aspecto en los presets alto y medio |
| **2c — Variantes y rendimiento** | Variantes en espejo y a oscuras con el aspecto final; medición de los cuatro presets | El usuario aprueba las variantes, los presets y las cifras |

## 3. Decisiones que cierra este hito

| # | Decisión | Propuesta | Por qué | Alternativas descartadas |
|---|---|---|---|---|
| D1 | Carpetas y conexiones | `world/player_flat/` (salón: geometría, luces, entorno, sondas, anclas), `presentation/tv/` (tele), `presentation/camera/` (cámara de juego) y `presentation/graphics/` (ajustes gráficos y mezcla de luces; carpeta nueva). `presentation/main.tscn` instancia el salón, la tele y la cámara; coloca la tele y la cámara en las **anclas** del salón (`TvAnchor`, `SeatAnchor`) y conecta la tele, la cámara y los ajustes, que son todos de la capa de presentación. El salón no conoce a nadie: solo expone anclas, entorno y luces. **Punto de montaje:** `presentation/main.gd` lee las anclas (después de aplicar el espejo), crea `LightMixer` con las luces del salón (grupo `room_lights`), la luz de la pantalla y la linterna, y aplica el preset por defecto. El salón tiene un `living_room.gd` con la opción `mirrored`. La tele lee su estado (interferencia activa) de `Game.economy`, igual que la UI del hito 1 | Arquitectura de `CLAUDE.md`. Las anclas hacen que la tele y la cámara sigan al salón también en el espejo y en el piso de la señora (hito 5) | Colocar la tele y la cámara a mano en `main.tscn`: quedarían mal en el espejo |
| D2 | Cámara de juego | Se coloca sobre `SeatAnchor` en la pose de `reveal` = 0 de `CLAUDE.md`. Con `reveal` = 0 (inicio de la run 1) la cámara está **fija**: encuadra la tele de cerca y apenas se ve algo del fondo detrás de ella; no se puede girar. La interpolación de `reveal` (posición y campo de visión) y su pose final llegan en el hito 3. Animarlo con la producción y decidir cuándo se desbloquea mirar alrededor es del hito 3 (propuesta: al terminar el zoom out o al levantarse para abrir al repartidor) | Idea del usuario (2026-11-17). Oír cosas sin poder girarse crea tensión, y el zoom out es lo único que revela dónde estás. El encuadre cerrado hace legible la pantalla | Giro libre desde el inicio: se ve el salón en el primer segundo y se pierde la revelación |
| D3 | Cómo se apunta a la pantalla | **Híbrido** (elegido por el usuario). Con la cámara fija, el ratón es un cursor normal: un rayo desde la cámara pasa por el cursor y, si toca la pantalla, se envían al `SubViewport` los mismos eventos de ratón (pulsar, soltar, mover, rueda). Cuando la cámara pueda girar (hito 3), con la retícula sobre la pantalla la vista se queda quieta y el ratón mueve un cursor dentro de la tele; al salir por el borde se vuelve a girar la cabeza. **Soltar siempre se envía**, en el último punto válido de la pantalla, aunque el cursor haya salido de ella, para que el dial no se quede pulsado. `tv_input` recibe un rayo (origen y dirección) y los eventos de botón y rueda; la cámara decide de dónde sale el rayo (ahora, el cursor del sistema; en el hito 3, el cursor virtual) | Cómodo para 2,5 h de clics y sin romper la primera persona; reenviar eventos reales hace que la UI del hito 1 funcione sin cambios | Solo retícula: cansa apuntar girando la cabeza a botones pequeños. `Area3D.input_event`: no permite reenviar el soltar fuera de la pantalla |
| D4 | Conversión del punto de la pantalla | Una función pura `TvScreenMath.hit_to_screen(local_hit: Vector3, screen_size: Vector2, viewport_size: Vector2i) -> Vector2` y `is_inside(...) -> bool`. `local_hit` está en el espacio local del plano de la pantalla: origen en el centro, ejes X e Y del plano, en metros; `screen_size` en metros. Con tests | `CLAUDE.md` exige esta función pura y sus tests | Ninguna: la impone `CLAUDE.md` |
| D5 | Pantalla de la tele | Tele de tubo 4:3. `SubViewport` de 960 × 720 con la escena `tv_game_ui.tscn` del hito 1; su lógica no cambia, pero su tema (tamaño de letra, filas visibles de la tienda) se adapta a la tele hasta cumplir D6. Material de pantalla con emisión y una viñeta leve, **sin curvar la imagen**, para que el clic caiga donde se ve el botón. El `SubViewport` deja de dibujarse con la tele apagada | Una tele antigua (GDD §1). La curvatura y las líneas de barrido son pulido del hito 7; si llegan, la misma fórmula irá en `TvScreenMath` y en el shader, con un test | Tele plana moderna: no encaja con la historia. Una segunda UI para la tele: duplica la UI | **Cambiado el 2026-11-18 (usuario): la imagen se curva (crt-lottes, k = 0,031/0,041) y el clic usa la misma función (`TvScreenMath.warp`), con test.**
| D6 | Legibilidad | El texto más pequeño de la tele mide al menos **14 píxeles de alto en una imagen de 1920 × 1080**, desde la cámara de juego con `reveal` = 0, en todos los presets. De ahí salen el tamaño de la tele, su distancia y el campo de visión. El preset bajo tiene una escala de resolución mínima del 67 % † | Si no se lee la pantalla, no se puede jugar | Sin objetivo medible: la pantalla podría quedar ilegible en el preset bajo |
| D7 | Hora del día y ventana | La run 1 es **de noche** (el repartidor trae la cena); la run 2 es la misma noche, durante el apagón. Por la ventana se ve una ciudad de noche: una imagen CC0 de Poly Haven sobre un plano detrás de la ventana (no como cielo del entorno, para no cambiar la luz ambiente de D9). Persiana medio bajada | Decisión del usuario. La noche permite la oscuridad que busca el terror y fija la luz principal: lámparas del salón, la pantalla y algo de luz de la calle | Atardecer: más contraste, pero más difícil mantener la oscuridad y cambia durante la run |
| D8 | Iluminación global (*GI*) | **VoxelGI**: se prepara una vez (*bake*) sobre la geometría fija, desde un script ejecutado con renderer real †, y se guarda como recurso; las luces cambian en tiempo real sin volver a prepararla. Los objetos que se moverán en otras runs no entran en la preparación. Un solo bake por versión del salón (normal y espejo); los presets cambian solo la calidad de cálculo, que se cambia en marcha † | El GDD necesita luces que cambian: bajan con la producción, parpadean y hay una linterna (run 2). VoxelGI las admite sin volver a prepararse; se comprueba con capturas con y sin ella | **LightmapGI:** calidad alta, pero fija: no reacciona a las luces que bajan ni a la linterna. **SDFGI:** sin preparación, pero en interiores pequeños puede dejar pasar luz entre paredes y mostrar saltos † |
| D9 | Luz base sin iluminación global | Todos los presets tienen una luz ambiente barata de base: la luz ambiente del `WorldEnvironment` (un color fijo por estado de iluminación); la sonda de reflejos solo hace reflejos. Con la iluminación global activa, esa luz ambiente se baja. Sin luces de relleno extra | Un solo montaje de luces sirve para todos los presets; el salón se ve bien sin iluminación global (el usuario lo aprueba con capturas) | Luces de relleno colocadas a mano para el preset bajo: duplican el trabajo del look-dev y chocan con el apagón |
| D10 | Quién decide la intensidad de cada luz | Una clase `LightMixer` (en `presentation/graphics/`) es la única que escribe la intensidad de las luces: `intensidad = base(estado de iluminación) × factor`. Los estados de iluminación son «normal» y «a oscuras» (D13). En este hito el factor vale 1; cómo leen la producción las luces lo decide la especificación del hito 3 (propuesta: usar este factor). La luz de la pantalla (que ilumina el sofá y la zona delante de la tele) también pasa por aquí y sigue el estado de la tele: encendida, interferencia, apagada | Evita que los estados de iluminación, los ajustes gráficos y el hito 3 se pisen | Que cada sistema encienda y apague luces: en el apagón se encenderían luces que no deben |
| D11 | Niebla | Niebla volumétrica global muy ligera (polvo en el aire, haces de luz de la ventana y de la linterna). Su densidad se ajusta en el look-dev. En todos los presets, a menos resolución en bajo y medio (usuario, 2026-11-22: que todos los presets se vean como el alto; antes se apagaba en bajo y medio) | Da profundidad al aire en la oscuridad | Niebla de profundidad simple: no da haces de luz. Volúmenes de niebla locales: más trabajo; se pueden revisar en 2b |
| D12 | Color, exposición, reflejos y brillo | Tonemapper AgX †, exposición fija, gradación suave hacia tonos fríos y verdosos. `ReflectionProbe` del salón, que se vuelve a capturar al cambiar de estado de iluminación. `GraphicsSettings` incluye un multiplicador de exposición (**brillo**), fijo en 1 hasta que el hito 7 añada el menú y la pantalla de calibración | Fotorrealismo oscuro sin que la imagen se queme ni se vea plana. Sin recapturar, los objetos brillarían en el apagón. El brillo compensa monitores distintos | Exposición automática: deshace la oscuridad. Sonda que se actualiza siempre: demasiado cara |
| D13 | Estilo del salón y estados de iluminación | Piso de un edificio antiguo en España, de los años 80-90, algo descuidado: papel pintado, suelo de terrazo o parqué gastado, sofá de tela, mueble de madera con la tele, mesa baja, lámpara de pie, estantería, ventana con persiana. **Decoración de los años 40 al estilo de *Visage*** (usuario, 2026-11-19): zócalo de madera, reloj de pie, crucifijo, apliques de tela y paredes llenas de cuadros y platos; el piso sigue siendo el de los 80-90, amueblado con cosas antiguas. **Un solo ambiente de luz en toda la casa** (usuario, 2026-11-19): oscuro, frío y apagado como las capturas de *Visage* que pasó el usuario; las lámparas son charcos de luz tenues, sin puntos quemados ni velas encendidas, y todo se sigue viendo. Unos 4 × 5 m y techo de 2,6 m. Estados de iluminación: **normal** (lámparas, pantalla y luz de la calle) y **a oscuras** (todo apagado salvo una luz de calle muy tenue y una linterna `SpotLight3D` en la cámara) | El protagonista es un electricista que vive en un 8.º (GDD §2-§3). Lo mundano da más miedo (pilar 4 del GDD §1) | Un salón moderno: choca con la tele de tubo y con la historia. Una escena aparte para el apagón: duplica el salón |
| D14 | Técnica del espejo | **Una sola escena del salón.** Desde Blender se exportan dos versiones de la geometría, la normal y la reflejada en X (normales recalculadas y colisiones reflejadas). Con la variante en espejo, la escena carga la geometría reflejada y refleja por código la posición y la orientación del resto de nodos (luces, sondas, anclas, cámaras de captura, objetos con texto), con una función pura `MirrorMath.mirror_transform(t: Transform3D) -> Transform3D` que no usa escala negativa. Los objetos con texto (libros, calendario, mando) se colocan en su sitio reflejado sin invertirse. En este hito el espejo se carga para las capturas y la medición; el hito 4 lo usa en la run 2 | Una sola fuente de verdad para todo lo que no es geometría. Sin escala negativa no hay problemas con colisiones ni textos invertidos. Resuelve la técnica que `CLAUDE.md` (Arquitectura) deja para este hito: «kit modular colocado en simetría, o reflejo de geometría en build» | **Una segunda escena reflejada:** duplica luces, sondas y cámaras, que habría que mantener a mano. **Escala negativa en Godot:** invierte los textos y las colisiones no la admiten †. **Kit modular en simetría:** más piezas que mantener alineadas |
| D15 | Ajustes gráficos y presets | `GraphicsSettings` (en `presentation/graphics/`) aplica cada opción por separado y cuatro presets. El preset **por defecto es el medio** (decisión del usuario), hasta que el menú del hito 7 permita cambiarlo; por eso la parada del look-dev aprueba capturas del alto y del medio. Valores iniciales, que se ajustan en 2c: ver la tabla de debajo | El usuario quiere que el juego sea jugable en equipos modestos con los mejores gráficos posibles. Hacerlo desde ahora evita rehacer el salón después | Dejar los presets para el hito 7: obligaría a revisar toda la iluminación al final |
| D16 | Presupuesto de fotogramas | Se mide en el PC de desarrollo a 1920 × 1080, **en la variante a oscuras con la linterna** (el peor caso), sin sincronización vertical ni límite de fps, descartando los primeros 5 s (compilación de shaders), y anotando el tiempo de la gráfica (GPU) aparte del total †. Objetivos para el percentil 95 del tiempo de fotograma (el 95 % de los fotogramas tarda como mucho eso): **ultra** ≤ 16,6 ms (60 fps), **alto** ≤ 8,3 ms, **medio** ≤ 6 ms, **bajo** ≤ 4 ms. También se anota la memoria de vídeo de cada preset. Estimación, no medida: con ese margen, una gráfica con la mitad de potencia llegaría a unos 60 fps en alto. El preset bajo en gráficas integradas no se puede comprobar en este hito: no hay una integrada disponible; si la hay, se mide allí; si no, se confirma en el playtest del hito 4 anotando el equipo de cada probador | El rendimiento es prioritario. Medir el peor caso evita sorpresas en la run 2 | Medir con sincronización vertical: los tiempos quedan topados por el monitor |
| D17 | Puntos de vista para las capturas | Cuatro cámaras fijas en el salón: desde el sofá mirando la tele, hacia la ventana, hacia la puerta y una vista general desde una esquina. Más la cámara de juego con `reveal` = 0 | Comparar rondas del look-dev con los mismos encuadres; ver el salón entero aunque el jugador no pueda girar | Capturas libres: no se pueden comparar |
| D18 | Origen de los modelos y texturas | Texturas y objetos CC0 de Poly Haven y ambientCG (Kenney o Poly Pizza CC0 si encajan). Paredes, suelo y tele, modelados por Claude en Blender. Texturas de 2K como máximo. Cada archivo, en `ASSETS.md`. Nada de Sketchfab salvo modelos CC0, ni generación con IA | Lo exige `CLAUDE.md` (Decisiones fijadas) | Ninguna: la impone `CLAUDE.md` |
| D19 | Pantalla retro de la tele (pedido del usuario, 2026-11-18; referencias: su boceto, juegos de 8-16 bits, Scritchy Scratchy y Bills Must Be Paid) | La tele dibuja a **320 × 240** sin suavizar, con fuente pixelada (Pixel Operator 8, CC0) y **pixel art propio** generado por `tools/build_tv_sprites.gd` en `assets/textures/tv/` (paleta fría de 8 bits). Escena: **bosque nevado de noche**, la **fábrica en el centro** y alrededor las máquinas de cada generador (el hueco k aparece con 1, 5, 10, 25 o 50 unidades), unidas a la fábrica por cables con pulsos de electricidad. **Se clican las máquinas** para sintonizar (y un **receptor** fijo, para poder clicar desde el principio); cada clic hace botar la máquina y saca el «+N»; con *Dial solo*, botan solas. **Pulsar la fábrica abre el árbol de mejoras** (nodos unidos a su padre, `requires_id` del `.tres`); arriba, una barra con Energía, producción, valor del clic y avance hacia *Reiniciar*. **La interferencia son chispas en un cable con corriente.** **Teclado:** Espacio sintoniza (mantenerlo = mantener pulsado), E abre y cierra las mejoras, Esc las cierra, flechas e Intro navegan y compran | Interacción con objetos del mundo y respuesta visible en cada acción, como en los incrementales de referencia; cada compra se ve en la tele (GDD §2) | Botón grande de clic (rechazado por el usuario). Líneas tipo tiza y renders de Blender (versiones anteriores, descartadas). Lista de mejoras (sustituida por el árbol) |
| D20 | Estilo del incremental (pedido del usuario, 2026-11-18: «sigue pareciendo hecho por IA») | La interfaz es el **OSD de la propia tele**: Energía, ritmo, barra de reinicio en segmentos, avisos («+ Antena») y tecla de mejoras en fósforo verde pálido con sombra dura, pegados a las esquinas (`tv_osd.gd`). Sin etiquetas flotando sobre la escena. Las mejoras, como el menú azul de una tele de los 90 (azul, texto claro, selección ámbar). El mundo, con paleta nocturna fría y un solo acento cálido (la luz de la fábrica sobre la nieve); máquinas con sombra en el suelo; cables de goma oscura con pulsos ámbar. Esc abre la pausa en la tele en cualquier momento (Reanudar, Ajustes, Menú principal, Salir) | Un solo lenguaje visual diegético (la tele), coherente con el filtro CRT/VHS | HUD de juego genérico sobre la escena |
| D21 | Menú integrado, carta de ajuste y eventos visibles (usuario, 2026-11-18; fase 1 de la mejora del incremental) | El menú es un canal de la tele en `presentation/main.tscn` (se borra `world/main_menu/`); el salón tiene la misma luz que en la partida (usuario, 2026-11-19; antes había un estado de luz «menu» a oscuras). Partida nueva: carta de ajuste en el OSD («Ratón o Espacio: sintoniza. Si ves algo raro en la pantalla, tócalo.») que se va con el primer clic, y la primera interferencia a los 90 s. Los eventos atrapables llevan esquinas de OSD que laten a 2 Hz, sonido propio sintetizado (`tools/build_tv_sounds.py`) y zona de clic de 48 × 40; la estrella es mayor y dura 5 s; la silueta (en la nieve, con ojos que brillan) **se quitó** por decisión del usuario el 2026-11-19, junto con su mejora «No apartes la vista». Sigue sin texto salvo la Señal clara (D19) | Que el menú no parezca algo aparte y que el jugador aprenda a mirar la tele sin tutoriales largos | Escena de menú aparte |

**Presets iniciales (D15):**

| Opción | Bajo | Medio | Alto | Ultra |
|---|---|---|---|---|
| Iluminación global (VoxelGI) | sí, calidad baja (usuario, 2026-11-22) | sí, calidad baja | sí, calidad baja (`VOXEL_GI_QUALITY_LOW`) | sí, calidad alta (`VOXEL_GI_QUALITY_HIGH`) |
| Niebla volumétrica (celdas de lado y fondo) | sí, 32 (2026-11-22: sin ella bajo y medio salían hasta un 50 % más oscuros) | sí, 48 | sí, 64 | sí, 64 |
| Atlas de sombras de las luces (tamaño) | 1024 | 2048 | 4096 | 8192 |
| Filtro de sombras | duro | suave bajo | suave medio | suave alto |
| Sombras suaves por tamaño de la luz (`light_size`) | no: sin TAA salían con grano (usuario, 2026-11-20) | sí | sí | sí |
| Sombra de la linterna | sí | sí | sí | sí |
| Oclusión ambiental (SSAO) | no | sí, calidad baja | sí, calidad media | sí, calidad alta |
| Luz indirecta en pantalla (SSIL) | no | no | sí, calidad media | sí, calidad alta |
| Reflejos (sonda del salón) | sí | sí | sí | sí |
| Antialiasing | FXAA | TAA (antes FXAA: grano en sombras y SSAO, usuario 2026-11-20) | TAA | TAA |
| Escala de resolución 3D (FSR 1 †) | 0,67 | 0,85 | 1,0 | 1,0 |

SSAO = sombras suaves en rincones y uniones; SSIL = luz rebotada calculada sobre la imagen; FSR = escalado de AMD, que renderiza a menos resolución y reescala.

## 4. Archivos

```
art_source/.gdignore                        crear (vacío: Godot no escanea esta carpeta)
art_source/living_room.blend                crear (fuente de Blender; solo los .glb van al proyecto)
assets/models/living_room.glb               crear (geometría del salón, colisiones con sufijo -col †)
assets/models/living_room_mirror.glb        crear (la misma, reflejada en x = 0)
assets/models/tv.glb                        crear (tele de tubo; la pantalla es una malla aparte llamada Screen)
assets/models/props/...                     crear (objetos CC0 descargados; nombres según la fuente)
assets/textures/...                         crear (texturas CC0, 2K como máximo, compresión VRAM)
assets/textures/night_city.(exr|jpg)        crear (ciudad de noche, CC0, para el plano de la ventana)
world/mirror_math.gd                        crear (class_name MirrorMath)
world/player_flat/living_room.tscn          crear (geometría, luces, WorldEnvironment, VoxelGI, ReflectionProbe, anclas, cámaras de captura, plano de la ventana)
world/player_flat/living_room.gd            crear (opción mirrored)
world/player_flat/voxel_gi_data.res         generado (preparación del salón normal)
world/player_flat/voxel_gi_data_mirror.res  generado (el del salón normal, volteado)
presentation/tv/tv.tscn                     crear (tv.glb, SubViewport con tv_game_ui.tscn, material de pantalla, luz de pantalla)
presentation/tv/tv.gd                       crear (estado de la tele, textura y modo de actualización del SubViewport)
presentation/tv/tv_input.gd                 crear (reenvío de eventos al SubViewport)
presentation/tv/tv_screen_math.gd           crear (class_name TvScreenMath)
presentation/tv/tv_screen.gdshader          crear (emisión y viñeta; sin curvatura)
presentation/camera/game_camera.tscn        crear
presentation/camera/game_camera.gd          crear (pose de reveal = 0, rayo, linterna)
presentation/graphics/graphics_settings.gd  crear (class_name GraphicsSettings)
presentation/graphics/light_mixer.gd        crear (class_name LightMixer)
presentation/graphics/benchmark.gd          crear (class_name Benchmark; lo lanza main.gd con TLR_BENCHMARK)
presentation/ui/tv_game_ui.tscn             modificar (tema para la tele: tamaño de letra; ≥ 5 filas de tienda visibles)
presentation/main.tscn                      modificar (quita la instancia de TvGameUI; instancia salón, tele y cámara)
presentation/main.gd                        modificar (punto de montaje de D1 y variables TLR_*; sigue imprimiendo BOOT_OK)
project.godot                               modificar (ventana 1920 × 1080)
export_presets.cfg                          modificar (exclude_filter añade tools/* y art_source/*)
tools/blender/build_living_room.py          crear (construye el salón y exporta los .glb; parámetro graybox/final)
tools/bake_voxel_gi.gd                      crear (prepara los dos VoxelGI)
tools/verify.sh                             modificar (comprobación 2: 11 scripts; comprobación 4: también tools/ y art_source/)
tests/test_tv_screen_math.gd                crear
tests/test_mirror_math.gd                   crear
tests/test_graphics_settings.gd             crear
tests/test_light_mixer.gd                   crear
tests/test_tv_input.gd                      crear
ASSETS.md                                   modificar (cada modelo, textura e imagen)
GAME_DESIGN.md                              modificar (paso 11)
CLAUDE.md                                   modificar (paso 11)
specs/hito2.md                              modificar (línea de estado y valores finales de la tabla de presets)
```

Archivos que genera Godot y que se versionan, como en los hitos anteriores: el `.uid` de cada script y el `.import` de cada modelo, textura e imagen.

**Variables de desarrollo** (solo en la build de depuración; la exportada las ignora, como ya hace con `TLR_NO_SAVE`): `TLR_PRESET` (`low`, `medium`, `high`, `ultra`), `TLR_MIRROR=1`, `TLR_DARK=1`, `TLR_GI=0` (quita la iluminación global sin cambiar el resto del preset), `TLR_OFF=ssil,fog,…` (apaga esas claves del preset para medir su coste), `TLR_VIEW` (`game`, `sofa`, `window`, `door`, `corner`: activa esa cámara) y `TLR_BENCHMARK=1`. Se usan variables de entorno porque GUT rechaza argumentos que no conoce.

## 5. Interfaces

**`TvScreenMath`** (`RefCounted`, funciones estáticas)
- `hit_to_screen(local_hit: Vector3, screen_size: Vector2, viewport_size: Vector2i) -> Vector2`. `local_hit` está en el espacio local del plano de la pantalla (origen en el centro, +X a la derecha, +Y arriba, metros). Devuelve píxeles del `SubViewport` (origen arriba a la izquierda, Y hacia abajo).
- `is_inside(local_hit: Vector3, screen_size: Vector2) -> bool`.
- `ray_plane(origin: Vector3, dir: Vector3, plane_xform: Transform3D) -> Variant`: el punto de corte en espacio local del plano, o `null` si no lo hay. Se hace por cálculo, sin física.

**`MirrorMath`** (`RefCounted`, función estática)
- `mirror_transform(t: Transform3D) -> Transform3D`: refleja en el plano x = 0 del salón con `M · t · M` (M = invertir X). El resultado no tiene escala negativa (determinante +1).

**`living_room.gd`** (en la raíz de `living_room.tscn`)
- `@export var mirrored: bool`. Se fija antes de añadir la escena al árbol. En `_ready`: si `mirrored`, carga `living_room_mirror.glb` en lugar de `living_room.glb` como hijo `Geometry`, asigna `voxel_gi_data_mirror.res` al `VoxelGI` y aplica `MirrorMath` a los nodos del grupo `mirror_transform` (luces, sonda, anclas, cámaras de captura, plano de la ventana, objetos con texto).
- Expone `get_anchor(name: StringName) -> Node3D` (`TvAnchor`, `SeatAnchor`), `get_capture_camera(name: StringName) -> Camera3D`, `get_environment() -> WorldEnvironment`, `get_voxel_gi() -> VoxelGI`, `get_reflection_probe() -> ReflectionProbe` y `get_lights() -> Array[Light3D]`.
- Cada luz del salón lleva sus valores base en metadatos: `base_normal` y `base_dark` (`float`, energía en cada estado de iluminación). La luz de calle tiene `base_dark` > 0; las lámparas, 0.

**`tv.gd`** (raíz de `tv.tscn`)
- En `_ready`: asigna `$SubViewport.get_texture()` a la textura de emisión del material de la pantalla, por código, porque una `ViewportTexture` puesta en la escena escribe un `ERROR` al cargar †.
- `power: bool` (encendida por defecto). Apagada: `render_target_update_mode = UPDATE_DISABLED` y pantalla negra. Encendida: `UPDATE_ALWAYS`.
- En `_process` (solo presentación) lee `Game.economy.interference_active()` y emite `screen_state_changed(state: StringName)` (`on`, `interference`, `off`) cuando cambia.
- Expone `get_screen_node() -> Node3D`, `get_screen_size() -> Vector2`, `get_subviewport() -> SubViewport` y `get_screen_light() -> Light3D`.

**`tv_input.gd`** (hijo de `tv.tscn`)
- `forward(origin: Vector3, dir: Vector3, event: InputEventMouse) -> void`: calcula el corte con `TvScreenMath.ray_plane` y la posición en píxeles. Duplica el evento, pone `position` y `global_position` en esos píxeles y lo envía con `SubViewport.push_input(ev, true)` †.
- **Soltar siempre:** guarda los botones pulsados. Un soltar fuera de la pantalla se envía igual, a la posición `Vector2(-1, -1)`: el control se suelta (`button_up`) sin contar un clic.
- Al salir el cursor de la pantalla, envía a la pantalla la notificación de «el ratón ha salido» †.
- Con `NOTIFICATION_APPLICATION_FOCUS_OUT`, envía un soltar por cada botón que siga pulsado.

**`game_camera.gd`** (raíz de `game_camera.tscn`, `Camera3D`)
- Se coloca en la pose de `reveal` = 0 relativa a `SeatAnchor`; sin giro en este hito. El cursor es visible.
- En `_unhandled_input`, para cada `InputEventMouse` calcula el rayo con `project_ray_origin(event.position)` y `project_ray_normal(event.position)` y llama a `tv_input.forward(...)`. Usa la posición del evento, no la del cursor del sistema, porque GoPeak inyecta eventos sin mover el cursor.
- Tiene una linterna (`SpotLight3D`, hija), apagada salvo en el estado a oscuras.

**`LightMixer`** (`RefCounted`)
- `_init(room_lights: Array[Light3D], screen_light: Light3D, flashlight: Light3D, environment: Environment, ambient: Dictionary)` (`ambient`: los metadatos `ambient_normal` y `ambient_dark` del salón).
- `set_state(state: StringName)` (`normal`, `dark`), `set_tv_state(state: StringName)` (`on`, `interference`, `off`) y `set_factor(f: float)` (1 en este hito).
- Es el único que escribe `light_energy` y `visible` de esas luces: `energía = base(estado) × factor`. Pantalla: base 1 encendida, 1,6 con interferencia, 0 apagada. Linterna: encendida solo en `dark`.
- También escribe la luz ambiente del `WorldEnvironment` (color y energía por estado, en metadatos de la raíz del salón: `ambient_normal` y `ambient_dark`), multiplicada por `ambient_gi_scale`, que le pasa `GraphicsSettings` (1 sin iluminación global, 0,4 con ella).

**`GraphicsSettings`** (`RefCounted`)
- `_init(viewport: Viewport, environment: Environment, voxel_gi: VoxelGI, probe: ReflectionProbe, flashlight: SpotLight3D, mixer: LightMixer)`. Sin `lights`: las luces solo las escribe `LightMixer`.
- `apply_preset(name: StringName)` (`low`, `medium`, `high`, `ultra`); `overrides` (claves del preset forzadas, p. ej. `TLR_GI=0` o `TLR_OFF`) y los ajustes del jugador `brightness` (multiplicador de exposición) y `max_rows` (filas de la resolución elegida: el 3D se dibuja justo a esa resolución; 0 = auto, la escala del preset) sobreviven a cada `apply_preset` (2026-11-20; sin escala 3D aparte desde 2026-11-22, a petición del usuario).
- `current: Dictionary`: los valores aplicados. Escribe propiedades de nodos y recursos (que los tests leen sin gráficos) y, para lo que solo existe en el servidor de render (calidad de VoxelGI, de SSAO, de SSIL y del filtro de sombras), llama a `RenderingServer` y lo guarda en `current`.

**`Benchmark`** (`Node`, lo añade `main.gd` con `TLR_BENCHMARK=1`)
- Desactiva la sincronización vertical y el límite de fps. Recorre las cámaras `game`, `sofa`, `window`, `door` y `corner`: en cada una descarta 5 s y mide 10 s.
- Mide el tiempo de fotograma total, el de GPU (`RenderingServer.viewport_get_measured_render_time_gpu`, con la medida activada †) y la memoria de vídeo (`Performance.RENDER_VIDEO_MEM_USED`).
- Imprime una línea `BENCH preset=… mirror=… dark=… gi=… avg_ms=… p95_ms=… gpu_p95_ms=… vram_mb=…` y cierra el juego.

**`main.gd`** (punto de montaje)
1. Lee las variables `TLR_*` (solo en la build de depuración) e instancia el salón con `mirrored`.
2. Coloca la tele en `TvAnchor` y la cámara en `SeatAnchor`, y conecta la cámara con `tv_input`.
3. Crea `LightMixer` y `GraphicsSettings`, aplica el preset (`medium` por defecto) y el estado de iluminación (`normal`, o `dark` con `TLR_DARK`). Conecta `tv.screen_state_changed` con `LightMixer.set_tv_state`.
4. Al cambiar de estado de iluminación, vuelve a capturar la sonda de reflejos (`UPDATE_ONCE`) †.
5. Activa la cámara de `TLR_VIEW`, añade `Benchmark` si toca, e imprime `BOOT_OK`.
6. Si no hay pantalla (`DisplayServer.get_name() == "headless"`), no toca la ventana.

## 6. Pasos

**Fase 2a — Tele jugable y tubería**
1. Comprobar con context7 todo lo marcado con †, en particular:
   - preparar el VoxelGI desde un script;
   - AgX;
   - la calidad de VoxelGI y de SSAO en marcha;
   - volver a capturar una sonda con `UPDATE_ONCE`;
   - `push_input` y sus coordenadas;
   - la notificación de «el ratón ha salido» en un `SubViewport`;
   - la `ViewportTexture` en una escena;
   - el tiempo de GPU;
   - la escala de resolución con FSR y su mínimo;
   - el sufijo `-col` del importador de glTF;
   - la escala negativa en colisiones;
   - y si GoPeak puede pulsar, mover y soltar por separado.
2. Crear `TvScreenMath`, `MirrorMath`, `LightMixer`, `GraphicsSettings`, `tv_input.gd` y sus tests. Cambiar `verify.sh` (11 scripts; `tools/` y `art_source/` en la comprobación 4) y `export_presets.cfg`. Hasta que existan los 11 scripts, los tests se ejecutan con GUT directamente (`TLR_NO_SAVE=1`).
3. **Graybox:**
   - Abrir Blender y ejecutar `tools/blender/build_living_room.py` en modo graybox con `execute_blender_code` (`exec(open(ruta).read())`). Genera cajas para las paredes, el suelo, el techo, el sofá, la mesa y el mueble, y una tele simple. Guarda `art_source/living_room.blend` y exporta los tres `.glb`.
   - Montar `living_room.tscn`, `tv.tscn`, `game_camera.tscn` y `main.tscn`. Ventana de 1920 × 1080 en `project.godot`.
   - Preparar los dos VoxelGI con `"$GODOT" --path . -s tools/bake_voxel_gi.gd`, sin `--headless`, porque necesita render real. El script instancia el salón en cada modo, espera dos fotogramas, prepara y guarda con `ResourceSaver` en las dos rutas de §4. De momento no hay objetos que excluir. Si no funciona por script, se para y se le enseñan al usuario las opciones, con capturas, antes de cambiar D8.
4. **Comprobaciones de la fase 2a:**
   - Antes, borrar `run.json*` como en el hito 1. Las ejecuciones con GoPeak usan una partida nueva.
   - **Con GoPeak:** clic en el dial; mantener pulsado; pulsar, sacar el cursor y soltar (el dial se para) †; desplazar la tienda con la rueda; atrapar una interferencia (aparece entre los minutos 2 y 4: se espera).
   - **Lo mismo con el espejo:** se repite con `TLR_MIRROR=1`. La tele y la cámara quedan en las anclas reflejadas y los clics funcionan igual.
   - **Legibilidad (D6):** se calcula con la altura en píxeles de la pantalla proyectada (`unproject_position` de sus esquinas) por el tamaño de letra más pequeño, dividido entre 720, en los presets bajo (el peor, al 67 %) y alto. Se confirma con capturas.
   - **La quinta fila de la tienda:** se compra desde la UI plana del hito 1 (que obliga a desplazarse) con una partida preparada, y en la tele se comprueba que se ve y se pulsa.
5. `verify.sh`: `VERIFY OK`. Si el render vacío de la comprobación 5 escribe `ERROR` con la escena 3D, se protegen las llamadas que lo provocan. **Parada:** el usuario juega en el graybox, en la build exportada, comprueba que lee todo y lo aprueba.

**Fase 2b — Look-dev**
6. En Blender, la geometría definitiva y la tele (modo final del script). Los objetos con texto y los que se moverán en otras runs son nodos de Godot, no geometría exportada. Se importa un primer lote de objetos CC0; el resto, entre rondas.
7. Montar los materiales (dentro del glTF; ajustes de Godot en `.tres` solo si hace falta), las luces con sus metadatos base, la niebla, el color, la sonda y el plano de la ventana con la ciudad de noche. Volver a preparar los dos VoxelGI.
8. **Rondas de look-dev:**
   - Capturas desde los puntos de vista de D17, en los presets **alto y medio**, y en el alto también sin iluminación global.
   - En cada ronda, el benchmark del preset alto en la variante normal (`TLR_BENCHMARK=1 TLR_PRESET=high`).
   - Propuesta de cambios y nueva ronda. La primera ronda, con el primer lote de objetos, para que el usuario vea pronto hasta dónde llega la calidad con assets gratuitos.
   - **Parada:** el usuario aprueba el aspecto en los presets alto y medio.

**Fase 2c — Variantes y rendimiento**
9. **Variantes con el aspecto final**, desde los mismos puntos de vista:
   - a oscuras (`TLR_DARK=1`), comprobando que los objetos no muestran reflejos del estado normal;
   - en espejo (`TLR_MIRROR=1`), comprobando que los textos de los objetos no salen invertidos;
   - espejo y a oscuras juntos, que es la run 2.
10. **Benchmark de los cuatro presets** en la variante a oscuras (`TLR_DARK=1`), según D16. Capturas de cada preset desde la cámara de juego.
    - Si un preset no cumple, se baja la opción que más milisegundos ahorre según la medición, sin bajar de la escala mínima de D6. Se le enseñan al usuario las capturas antes y después, y se actualizan la tabla de D15 y `test_graphics_settings.gd`.
    - Si el preset bajo no cumple con la escala al 67 %, se consulta al usuario.
    - **Parada:** el usuario aprueba las variantes, los presets y las cifras.
11. **Documentación:**
    - **GDD:** en el §10, la iluminación global, la niebla y los presets; en el §11, el hito 7 queda con «el menú de ajustes gráficos» y el hito 2 sin [PENDIENTE]; en el §12, cerrar «Técnica de GI y niebla; presupuesto de frame».
    - **`CLAUDE.md`, Arquitectura:** la técnica del espejo elegida.
    - Completar `ASSETS.md` y la línea de estado de esta especificación.
    - Commit y push.

## 7. Tests

| Test | Qué comprueba |
|---|---|
| `test_tv_screen_math.gd` | El centro del plano da el centro del viewport; las cuatro esquinas dan (0, 0), (960, 0), (0, 720) y (960, 720); un punto en el borde superior (+Y) da y = 0; fuera del plano, `is_inside` es falso; con otro `viewport_size` siguen cuadrando; `ray_plane` corta un plano conocido y da `null` si el rayo es paralelo |
| `test_mirror_math.gd` | Reflejar dos veces devuelve el original; el determinante es +1; un punto en x pasa a -x; un nodo que mira a +X pasa a mirar a -X; con una rotación cualquiera la base sigue siendo ortonormal |
| `test_light_mixer.gd` | Con luces creadas en el test: en `dark` solo quedan la luz de calle y la linterna; el factor multiplica la base; la pantalla se apaga con `off` y sube con `interference`; la luz ambiente cambia con el estado y con `ambient_gi_scale` |
| `test_graphics_settings.gd` | Cada preset deja en el entorno, el viewport y las luces los valores de la tabla de D15 (o en `current` lo que solo existe en el servidor de render); aplicar el bajo y luego el ultra deja el ultra entero; una clave de `overrides` cambia solo esa clave y sobrevive a otro `apply_preset`; `final_scale` y el brillo del jugador. Se actualiza con los valores finales de 2c |
| `test_factory_view.gd` | Cada hueco aparece al llegar a su umbral y el cable tiene corriente con al menos una unidad; tras reiniciar no queda ninguna máquina; cada generador del `.tres` tiene su grupo; las chispas salen del cable con corriente y pulsarlas avisa |
| `test_upgrade_tree.gd` | Hay un nodo por mejora y generador; los estados (bloqueado, disponible, asequible, comprado) siguen a la economía; pulsar un nodo pide comprarlo |
| `test_tv_input.gd` | Con un `SubViewport` y un botón en el árbol: pulsar dentro y soltar fuera hace `button_up` sin `pressed`; perder el foco suelta el botón; un clic dentro hace `pressed`; la rueda desplaza un `ScrollContainer` solo dentro de la pantalla (GoPeak no simula la rueda, así que esta comprobación del paso 4 la cubre el test) |
| Los de los hitos 0 y 1 | Siguen pasando |
| `verify.sh` | `VERIFY OK`: 13 scripts de test (11 + `test_factory_view.gd` y `test_upgrade_tree.gd`); la escena 3D arranca en la build exportada; el paquete no lleva el addon, los tests, `tools/` ni `art_source/` |
| Capturas (pasos 4, 8, 9 y 10) | Lo que aprueba el usuario en cada parada |
| Benchmark (pasos 8 y 10) | Cifras de los cuatro presets frente a D16, anotadas y aprobadas por el usuario |

## 8. Criterio de cierre

- Los tests pasan y `verify.sh` termina con `VERIFY OK`.
- El usuario ha aprobado las tres paradas, incluidas las cifras del benchmark.
- `ASSETS.md`, el GDD, `CLAUDE.md` y esta especificación están actualizados (paso 11).
- Commit y push.

## 9. Riesgos y límites

- **Preparar el VoxelGI necesita el editor:** se comprueba en el paso 3. Si no se puede por script, se para y se consulta al usuario con capturas antes de cambiar D8.
- **Luz que se cuela entre paredes con VoxelGI:** las paredes de Blender tienen grosor real (≥ 10 cm).
- **Memoria de vídeo:** si un preset pasa de 2 GB en la medición, se le dice al usuario y se reduce el tamaño de las texturas.
- **GoPeak no sabe pulsar y soltar por separado:** la prueba de mantener pulsado queda en `test_tv_input.gd`, y el usuario la comprueba en la parada.
- **Las gráficas integradas:** no se pueden medir en este hito salvo que el usuario active la del procesador (D16); si no, se confirma en el playtest del hito 4.
- **El juego exportado pesa más por las texturas:** 2K como máximo y compresión VRAM. Si pasa de 1 GB, se avisa al usuario.
- **El render vacío de `verify.sh` escribe errores con la escena 3D:** se protegen las llamadas que lo provocan (paso 5).
