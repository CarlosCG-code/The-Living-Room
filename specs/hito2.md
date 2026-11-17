# Especificación — Hito 2: la tele en el salón del jugador

> Estado: **borrador, en revisión EGM** (etapas 5-7 aplicadas; informes en `reviews/hito2/`). EGM es el proceso de revisión con revisores independientes que se usa antes de aprobar cada especificación. No se escribe código hasta que el usuario lo apruebe.
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
| **2b — Look-dev** | Geometría y objetos definitivos, materiales, iluminación global, niebla, color. Rondas de capturas desde los puntos de vista fijos, cada una con los milisegundos del preset alto | El usuario aprueba el aspecto |
| **2c — Variantes y rendimiento** | Variantes en espejo y a oscuras con el aspecto final; medición de los cuatro presets | El usuario aprueba las variantes, los presets y las cifras |

## 3. Decisiones que cierra este hito

| # | Decisión | Propuesta | Por qué | Alternativas descartadas |
|---|---|---|---|---|
| D1 | Carpetas y conexiones | `world/player_flat/` (salón: geometría, luces, entorno, sondas, anclas), `presentation/tv/` (tele), `presentation/camera/` (cámara de juego) y `presentation/graphics/` (ajustes gráficos y mezcla de luces; carpeta nueva). `presentation/main.tscn` instancia el salón, la tele y la cámara; coloca la tele y la cámara en las **anclas** del salón (`TvAnchor`, `SeatAnchor`) y conecta la tele, la cámara y los ajustes, que son todos de la capa de presentación. El salón no conoce a nadie: solo expone anclas, entorno y luces | Arquitectura de `CLAUDE.md`. Las anclas hacen que la tele y la cámara sigan al salón también en el espejo y en el piso de la señora (hito 5) | Colocar la tele y la cámara a mano en `main.tscn`: quedarían mal en el espejo |
| D2 | Cámara de juego | Implementa ya el parámetro `reveal` (0-1) de `CLAUDE.md`, que interpola posición y campo de visión. Con `reveal` = 0 (inicio de la run 1) la cámara está **fija**: encuadra la tele de cerca y apenas se ve algo del fondo detrás de ella; no se puede girar. En este hito `reveal` se fija por código (0 para jugar, otros valores para probar). Animarlo con la producción y decidir cuándo se desbloquea mirar alrededor es del hito 3 (propuesta: al terminar el zoom out o al levantarse para abrir al repartidor) | Idea del usuario (2026-11-17). Oír cosas sin poder girarse crea tensión, y el zoom out es lo único que revela dónde estás. El encuadre cerrado hace legible la pantalla | Giro libre desde el inicio: se ve el salón en el primer segundo y se pierde la revelación |
| D3 | Cómo se apunta a la pantalla | **Híbrido** (elegido por el usuario). Con la cámara fija, el ratón es un cursor normal: un rayo desde la cámara pasa por el cursor y, si toca la pantalla, se envían al `SubViewport` los mismos eventos de ratón (pulsar, soltar, mover, rueda). Cuando la cámara pueda girar (hito 3), con la retícula sobre la pantalla la vista se queda quieta y el ratón mueve un cursor dentro de la tele; al salir por el borde se vuelve a girar la cabeza. **Soltar siempre se envía**, en el último punto válido de la pantalla, aunque el cursor haya salido de ella, para que el dial no se quede pulsado | Cómodo para 2,5 h de clics y sin romper la primera persona; reenviar eventos reales hace que la UI del hito 1 funcione sin cambios | Solo retícula: cansa apuntar girando la cabeza a botones pequeños. `Area3D.input_event`: no permite reenviar el soltar fuera de la pantalla |
| D4 | Conversión del punto de la pantalla | Una función pura `TvScreenMath.hit_to_screen(local_hit: Vector3, screen_size: Vector2, viewport_size: Vector2i) -> Vector2` y `is_inside(...) -> bool`. `local_hit` está en el espacio local del plano de la pantalla: origen en el centro, ejes X e Y del plano, en metros; `screen_size` en metros. Con tests | `CLAUDE.md` exige esta función pura y sus tests | Ninguna: la impone `CLAUDE.md` |
| D5 | Pantalla de la tele | Tele de tubo 4:3. `SubViewport` de 960 × 720 con la escena `tv_game_ui.tscn` del hito 1; su lógica no cambia, pero su tema (tamaño de letra, filas visibles de la tienda) se adapta a la tele hasta cumplir D6. Material de pantalla con emisión y una viñeta leve, **sin curvar la imagen**, para que el clic caiga donde se ve el botón. El `SubViewport` deja de dibujarse con la tele apagada | Una tele antigua (GDD §1). La curvatura y las líneas de barrido son pulido del hito 7; si llegan, la misma fórmula irá en `TvScreenMath` y en el shader, con un test | Tele plana moderna: no encaja con la historia. Una segunda UI para la tele: duplica la UI |
| D6 | Legibilidad | El texto más pequeño de la tele mide al menos **14 píxeles de alto en una imagen de 1920 × 1080**, desde la cámara de juego con `reveal` = 0, en todos los presets. De ahí salen el tamaño de la tele, su distancia y el campo de visión. El preset bajo tiene una escala de resolución mínima del 67 % † | Si no se lee la pantalla, no se puede jugar | Sin objetivo medible: la pantalla podría quedar ilegible en el preset bajo |
| D7 | Hora del día y ventana | La run 1 es **de noche** (el repartidor trae la cena); la run 2 es la misma noche, durante el apagón. Por la ventana se ve una ciudad de noche: imagen panorámica (HDRI) CC0 de Poly Haven. Persiana medio bajada | Decisión del usuario. La noche permite la oscuridad que busca el terror y fija la luz principal: lámparas del salón, la pantalla y algo de luz de la calle | Atardecer: más contraste, pero más difícil mantener la oscuridad y cambia durante la run |
| D8 | Iluminación global (*GI*) | **VoxelGI**: se prepara una vez (*bake*) sobre la geometría fija, desde un script ejecutado con renderer real †, y se guarda como recurso; las luces cambian en tiempo real sin volver a prepararla. Los objetos que se moverán en otras runs no entran en la preparación. Un solo bake por versión del salón (normal y espejo); los presets cambian solo la calidad de cálculo, que se cambia en marcha † | El GDD necesita luces que cambian: bajan con la producción, parpadean y hay una linterna (run 2). VoxelGI las admite sin volver a prepararse; se comprueba con capturas con y sin ella | **LightmapGI:** calidad alta, pero fija: no reacciona a las luces que bajan ni a la linterna. **SDFGI:** sin preparación, pero en interiores pequeños puede dejar pasar luz entre paredes y mostrar saltos † |
| D9 | Luz base sin iluminación global | Todos los presets tienen una luz ambiente barata de base: la luz ambiente de la sonda de reflejos del salón † (un color fijo por estado de iluminación). Con la iluminación global activa, esa luz ambiente se baja. Sin luces de relleno extra | Un solo montaje de luces sirve para todos los presets; el salón se ve bien sin iluminación global (el usuario lo aprueba con capturas) | Luces de relleno colocadas a mano para el preset bajo: duplican el trabajo del look-dev y chocan con el apagón |
| D10 | Quién decide la intensidad de cada luz | Una clase `LightMixer` (en `presentation/graphics/`) es la única que escribe la intensidad de las luces: `intensidad = base(estado de iluminación) × factor`. Los estados de iluminación son «normal» y «a oscuras» (D13). El factor queda en 1 en este hito; el hito 3 lo usará para las luces que bajan con la producción y los parpadeos, sin tocar lo demás. La luz de la pantalla (que ilumina el sofá y la zona delante de la tele) también pasa por aquí y sigue el estado de la tele: encendida, interferencia, apagada | Evita que los estados de iluminación, los ajustes gráficos y el hito 3 se pisen | Que cada sistema encienda y apague luces: en el apagón se encenderían luces que no deben |
| D11 | Niebla | Niebla volumétrica global muy ligera (polvo en el aire, haces de luz de la ventana y de la linterna). Su densidad se ajusta en el look-dev; se apaga en los presets bajo y medio | Da profundidad al aire en la oscuridad | Niebla de profundidad simple: no da haces de luz. Volúmenes de niebla locales: más trabajo; se pueden revisar en 2b |
| D12 | Color, exposición, reflejos y brillo | Tonemapper AgX †, exposición fija, gradación suave hacia tonos fríos y verdosos. `ReflectionProbe` del salón, que se vuelve a capturar al cambiar de estado de iluminación. `GraphicsSettings` incluye ya un ajuste de **brillo**; el aspecto se aprueba con su valor por defecto | Fotorrealismo oscuro sin que la imagen se queme ni se vea plana. Sin recapturar, los objetos brillarían en el apagón. El brillo compensa monitores distintos | Exposición automática: deshace la oscuridad. Sonda que se actualiza siempre: demasiado cara |
| D13 | Estilo del salón y estados de iluminación | Piso de un edificio antiguo en España, de los años 80-90, algo descuidado: papel pintado, suelo de terrazo o parqué gastado, sofá de tela, mueble de madera con la tele, mesa baja, lámpara de pie, estantería, ventana con persiana. Unos 4 × 5 m y techo de 2,6 m. Estados de iluminación: **normal** (lámparas, pantalla y luz de la calle) y **a oscuras** (todo apagado salvo una luz de calle muy tenue y una linterna `SpotLight3D` en la cámara) | El protagonista es un electricista que vive en un 8.º (GDD §2-§3). Lo mundano da más miedo (pilar 4 del GDD §1) | Un salón moderno: choca con la tele de tubo y con la historia. Una escena aparte para el apagón: duplica el salón |
| D14 | Técnica del espejo | **Una sola escena del salón.** Desde Blender se exportan dos versiones de la geometría, la normal y la reflejada en X (normales recalculadas y colisiones reflejadas). Con la variante en espejo, la escena carga la geometría reflejada y refleja por código la posición y la orientación del resto de nodos (luces, sondas, anclas, cámaras de captura, objetos con texto), con una función pura `MirrorMath.mirror_transform(t: Transform3D) -> Transform3D` que no usa escala negativa. Los objetos con texto (libros, calendario, mando) se colocan en su sitio reflejado sin invertirse. En este hito el espejo se carga para las capturas y la medición; el hito 4 lo usa en la run 2 | Una sola fuente de verdad para todo lo que no es geometría. Sin escala negativa no hay problemas con colisiones ni textos invertidos. Resuelve la técnica que `CLAUDE.md` (Arquitectura) deja para este hito: «kit modular colocado en simetría, o reflejo de geometría en build» | **Una segunda escena reflejada:** duplica luces, sondas y cámaras, que habría que mantener a mano. **Escala negativa en Godot:** invierte los textos y las colisiones no la admiten †. **Kit modular en simetría:** más piezas que mantener alineadas |
| D15 | Ajustes gráficos y presets | `GraphicsSettings` (en `presentation/graphics/`) aplica cada opción por separado y cuatro presets. El preset **por defecto es el medio**, hasta que el menú del hito 7 permita cambiarlo. Valores iniciales, que se ajustan en 2c: ver la tabla de debajo | El usuario quiere que el juego sea jugable en equipos modestos con los mejores gráficos posibles. Hacerlo desde ahora evita rehacer el salón después | Dejar los presets para el hito 7: obligaría a revisar toda la iluminación al final |
| D16 | Presupuesto de fotogramas | Se mide en el PC de desarrollo (RTX 5060 Ti) a 1920 × 1080, **en la variante a oscuras con la linterna** (el peor caso), sin sincronización vertical ni límite de fps, descartando los primeros 5 s (compilación de shaders), y anotando el tiempo de la gráfica (GPU) aparte del total †. Objetivos para el percentil 95 del tiempo de fotograma (el 95 % de los fotogramas tarda como mucho eso): **ultra** ≤ 16,6 ms (60 fps), **alto** ≤ 8,3 ms, **medio** ≤ 6 ms, **bajo** ≤ 4 ms. También se anota la memoria de vídeo de cada preset. Estimación, no medida: con ese margen, una gráfica con la mitad de potencia llegaría a unos 60 fps en alto. El preset bajo en gráficas integradas no se puede comprobar en este hito: la integrada del Ryzen 5 9600X no aparece en Windows (está desactivada en la BIOS o le falta el controlador); si el usuario la activa, se mide allí; si no, se confirma en el playtest del hito 4 anotando el equipo de cada probador | El rendimiento es prioritario. Medir el peor caso evita sorpresas en la run 2 | Medir con sincronización vertical: los tiempos quedan topados por el monitor |
| D17 | Puntos de vista para las capturas | Cuatro cámaras fijas en el salón: desde el sofá mirando la tele, hacia la ventana, hacia la puerta y una vista general desde una esquina. Más la cámara de juego con `reveal` = 0 | Comparar rondas del look-dev con los mismos encuadres; ver el salón entero aunque el jugador no pueda girar | Capturas libres: no se pueden comparar |
| D18 | Origen de los modelos y texturas | Texturas y objetos CC0 de Poly Haven y ambientCG (Kenney o Poly Pizza CC0 si encajan). Paredes, suelo y tele, modelados por Claude en Blender. Texturas de 2K como máximo. Cada archivo, en `ASSETS.md`. Nada de Sketchfab salvo modelos CC0, ni generación con IA | Lo exige `CLAUDE.md` (Decisiones fijadas) | Ninguna: la impone `CLAUDE.md` |

**Presets iniciales (D15):**

| Opción | Bajo | Medio | Alto | Ultra |
|---|---|---|---|---|
| Iluminación global (VoxelGI) | no | no | sí, calidad baja | sí, calidad alta |
| Niebla volumétrica | no | no | sí | sí |
| Sombras (resolución / distancia) | 1024 / corta | 2048 / media | 4096 / media | 4096 / larga |
| Sombra de la linterna | no | sí, baja | sí | sí, alta |
| Oclusión ambiental (SSAO) | no | sí, baja | sí | sí, alta |
| Luz indirecta en pantalla (SSIL) | no | no | sí | sí |
| Reflejos (sonda del salón) | no | sí | sí | sí |
| Antialiasing | FXAA | FXAA | TAA | TAA |
| Escala de resolución 3D (FSR) | 67 % | 85 % | 100 % | 100 % |

SSAO = sombras suaves en rincones y uniones; SSIL = luz rebotada calculada sobre la imagen; FSR = escalado de AMD, que renderiza a menos resolución y reescala.

## 4. Archivos

```
world/player_flat/living_room.tscn          crear (geometría, luces, WorldEnvironment, VoxelGI, ReflectionProbe, anclas, cámaras de captura; opción «espejo»)
world/player_flat/voxel_gi_data.res         generado (bake del salón normal)
world/player_flat/voxel_gi_data_mirror.res  generado (bake del salón reflejado)
world/mirror_math.gd                        crear (class_name MirrorMath: función pura de D14)
presentation/tv/tv.tscn                     crear (modelo, SubViewport con tv_game_ui.tscn, pantalla, luz de pantalla)
presentation/tv/tv_screen.gdshader          crear (emisión y viñeta; sin curvatura)
presentation/tv/tv_input.gd                 crear (rayo, conversión y reenvío de eventos al SubViewport, soltar siempre)
presentation/tv/tv_screen_math.gd           crear (class_name TvScreenMath: D4)
presentation/camera/game_camera.tscn        crear
presentation/camera/game_camera.gd          crear (reveal 0-1, cursor visible con reveal = 0, linterna)
presentation/graphics/graphics_settings.gd  crear (class_name GraphicsSettings: opciones, presets y brillo)
presentation/graphics/light_mixer.gd        crear (class_name LightMixer: D10)
presentation/ui/tv_game_ui.tscn             modificar (tema para la tele: tamaño de letra y filas; D5-D6)
presentation/main.tscn                      modificar (salón, tele y cámara en las anclas)
presentation/main.gd                        sin cambios (imprime BOOT_OK)
assets/models/...                           crear (glTF exportados desde Blender y modelos CC0)
assets/textures/...                         crear (texturas CC0, 2K como máximo)
assets/hdri/...                             crear (ciudad de noche, CC0)
tools/blender/build_living_room.py          crear (script de Blender: construye el salón y exporta las dos versiones)
tools/bake_voxel_gi.gd                      crear (prepara los dos VoxelGI con renderer real)
tools/benchmark.gd                          crear (D16)
tests/test_tv_screen_math.gd                crear
tests/test_mirror_math.gd                   crear
tests/test_graphics_settings.gd             crear
tests/test_light_mixer.gd                   crear
ASSETS.md                                   modificar (cada modelo, textura e imagen)
GAME_DESIGN.md                              modificar (§10-§12: técnicas validadas y presupuesto; §11: el hito 7 queda con el menú)
CLAUDE.md                                   modificar (Arquitectura: técnica del espejo elegida)
```

## 5. Pasos

**Fase 2a — Tele jugable y tubería**
1. Comprobar con context7 lo marcado con †: el bake de VoxelGI desde un script, el tonemapper AgX, la luz ambiente de la sonda, la calidad de VoxelGI en marcha, la escala negativa en colisiones, el envío de eventos a un `SubViewport` (`push_input`), la medida del tiempo de GPU y la escala de resolución mínima.
2. Crear `TvScreenMath`, `MirrorMath`, `LightMixer`, `GraphicsSettings` y sus tests.
3. Abrir Blender y generar con `tools/blender/build_living_room.py` el salón en cajas, en sus dos versiones. Montar la escena con anclas, la tele, la cámara de juego y `tv_input.gd`. Hacer un primer bake de los dos VoxelGI con `tools/bake_voxel_gi.gd`.
4. Comprobar con GoPeak: clic en el dial, mantener pulsado, pulsar y sacar el cursor de la pantalla antes de soltar (el dial se para), comprar la quinta fila de la tienda, desplazar la tienda con la rueda y atrapar una interferencia. Medir el tamaño del texto más pequeño (D6) en capturas con los presets bajo y alto. Cargar el espejo y comprobar que las colisiones y las anclas funcionan.
5. `verify.sh`: `VERIFY OK`. **Parada:** el usuario juega en el graybox, comprueba que lee todo y lo aprueba.

**Fase 2b — Look-dev**
6. Construir en Blender la geometría definitiva y la tele; importar los objetos CC0; exportar las dos versiones.
7. Montar materiales, luces, VoxelGI, niebla, color, reflejos y la imagen de la ventana. Volver a preparar los VoxelGI.
8. Rondas de look-dev: capturas desde los puntos de vista de D17, con y sin iluminación global, y los milisegundos del preset alto en cada ronda; propuesta de cambios; repetir. La primera ronda, con pocos objetos, para ajustar expectativas pronto. **Parada:** el usuario aprueba el aspecto.

**Fase 2c — Variantes y rendimiento**
9. Estado a oscuras (D13) y variante en espejo (D14) con el aspecto final: capturas desde los mismos puntos de vista; comprobar que la sonda de reflejos no brilla en el apagón y que los textos se leen.
10. Medir los cuatro presets con `tools/benchmark.gd` según D16. Capturas de cada preset desde el mismo punto de vista, para ver qué se pierde. Si un preset no cumple, se baja primero lo más caro (niebla, calidad de la iluminación global, escala de resolución) y se vuelve a medir. **Parada:** el usuario aprueba las variantes, los presets y las cifras.
11. Actualizar el GDD y `CLAUDE.md`; completar `ASSETS.md`. Commit y push.

## 6. Tests

| Test | Qué comprueba |
|---|---|
| `test_tv_screen_math.gd` | El centro de la pantalla da el centro del viewport; las esquinas dan las esquinas; un punto fuera no está dentro; el eje Y se invierte bien; funciona con otra resolución |
| `test_mirror_math.gd` | Reflejar dos veces devuelve el original; el resultado no tiene escala negativa (determinante positivo); un punto en x pasa a -x |
| `test_light_mixer.gd` | En «a oscuras» solo quedan la linterna y la luz de calle; el factor multiplica la base; la luz de la pantalla se apaga con la tele apagada |
| `test_graphics_settings.gd` | Cada preset fija los valores de la tabla de D15; aplicar el bajo y luego el ultra deja el ultra entero; el brillo cambia la exposición |
| Los de los hitos 0 y 1 | Siguen pasando |
| `verify.sh` | `VERIFY OK`: la escena 3D arranca en la build exportada y el paquete no lleva el addon ni los tests |
| Capturas (pasos 4, 8, 9 y 10) | La tele se juega y se lee; el aspecto, las variantes y los presets, aprobados por el usuario |
| Benchmark (paso 10) | Los cuatro presets cumplen D16 |

## 7. Criterio de cierre

- Los tests pasan y `verify.sh` termina con `VERIFY OK`.
- El usuario ha aprobado las tres paradas.
- `ASSETS.md`, el GDD y `CLAUDE.md` están actualizados.
- Commit y push.

## 8. Riesgos y límites

- **Luz que se cuela o memoria de VoxelGI:** paredes con grosor real en Blender; se mide la memoria de vídeo por preset (D16).
- **El bake de VoxelGI necesita el editor:** se comprueba en 2a. Si no se puede hacer desde un script, se prepara al cargar la escena (unos segundos al arrancar) o se pasa a SDFGI, comparando capturas.
- **Reenviar eventos rompe mantener pulsado:** se comprueba en 2a (soltar fuera de la pantalla).
- **El look-dev no llega a lo esperado con assets gratuitos:** primera ronda con pocos objetos para ajustar expectativas pronto.
- **Las gráficas integradas no llegan al preset bajo:** se estima, no se mide (D16); se confirma en el playtest del hito 4.
- **El juego exportado pesa más** por las texturas: 2K como máximo y compresión de Godot.
- **Un preset no cumple su objetivo:** se baja primero lo más caro y se le enseñan al usuario las capturas antes y después.
- **Blender necesita su ventana abierta:** Claude la abre y la cierra; el usuario no tiene que hacer nada.
