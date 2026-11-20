# Informe de revisión EGM — Hito 4a

**Objetivo:** `specs/hito4a.md` (completo, líneas 1-155)
**Contexto revisado:** `CLAUDE.md`, `GAME_DESIGN.md` (§2-§14), `specs/hito2.md` y el código que toca el hito (salón, `MirrorMath`, `main.gd`, cámara, `LightMixer`, `GraphicsSettings`, `Benchmark`, `MainMenuUI`, `TvGameUI`, `UserSettings`, trucos, horneado, `build_living_room.py`, `verify.sh`, `.gitignore`, `project.godot`).
**No se ha editado la especificación.**

## Estado de los revisores

| Revisor | Estado |
| --- | --- |
| `design` (arquitectura) | completed |
| `implementation-readiness` | completed |
| `codebase-details` (exactitud técnica) | completed |
| `zoom-out` (alcance) | completed |
| `comprehension` | completed |
| `structural` | completed |
| `style` | completed |

Ninguno tuvo acceso a context7, así que los datos del motor que siguen marcados † (límite de 8 VoxelGI, empuje de `AnimatableBody3D`, sufijos de importación glTF, recaptura de sondas) siguen sin confirmar con la documentación de 4.7.2. El sintetizador ha comprobado contra el código los hallazgos B4 y M15.

**Resumen:** 5 bloqueantes, 17 mayores y 12 menores. Veredicto: **no está lista para aprobar**. La idea es buena y reutiliza bien lo que ya existe (`MirrorMath`, el generador `.py` → `.tres`, la lista de cámaras del benchmark y la tabla `PAGES` del menú). Pero faltan el plano real (quién se conecta con quién), un dueño único de la visibilidad de luces y GI, y el contrato de las puertas. Además, varias decisiones que tiene que tomar el usuario aparecen como si ya estuvieran tomadas.

---

## Hallazgos priorizados

### B1. Dos sistemas escribirían la visibilidad de las mismas luces, GI y sondas. Severidad: Bloqueante
* **Revisores:** design, implementation-readiness, codebase-details, zoom-out, structural
* **Sección:** D3, D8, D9, D10 y §4
* **Problema:**
  * `LightMixer.apply()` hace `light.visible = energy > 0.0` en todas las luces y `_flashlight.visible = _state == &"dark"` (`presentation/graphics/light_mixer.gd:70,77`). Se ejecuta en cada cambio de estado de la tele, así que cada interferencia volvería a encender las luces que `RoomActivation` hubiera apagado.
  * `GraphicsSettings` recibe **un** VoxelGI y **una** sonda y escribe su `visible` según el preset. Al aplicar un preset se encenderían los 17 VoxelGI y se rompería el «máximo 8» de D9. Al revés, activar una habitación encendería la GI en los presets bajo y medio, que la tienen apagada.
  * La tecla F de D10 choca con `LightMixer`, que solo muestra la linterna a oscuras. Hoy no existe ninguna acción F.
  * hito2 D10 establece que `LightMixer` es el único que escribe en las luces. Ni `light_mixer.gd`, ni `graphics_settings.gd`, ni `living_room.gd`, ni sus tests aparecen en §4.
* **Cambio propuesto (el más pequeño que funciona):**
  1. `flat.gd` coloca el VoxelGI de cada zona bajo un contenedor `Rooms/<id>` (un `Node3D`) y `RoomActivation` solo cambia `container.visible`. La visibilidad se hereda, así que `GraphicsSettings` puede seguir escribiendo la del hijo (preset) sin pisarse: visible = activa Y preset.
  2. El planificador **no toca las luces**. Todas las del piso se registran en el único `LightMixer` (así el factor de producción del hito 3 cubre todo el piso), y el coste lo controla el desvanecimiento por distancia (ver M1).
  3. `GraphicsSettings` pasa a recibir `Array[VoxelGI]` y `Array[ReflectionProbe]`.
  4. `LightMixer` recibe `set_flashlight_on(bool)`: visible = a oscuras Y el jugador la tiene encendida.
  5. Añadir a §4 `light_mixer.gd`, `graphics_settings.gd`, `main.gd` (cómo se monta) y sus tests. Añadir el caso «cambiar de preset o de estado de la tele no reactiva zonas inactivas».

### B2. Falta el plano: ids, conexiones, vanos y la puerta del rellano. Severidad: Bloqueante
* **Revisores:** implementation-readiness, comprehension, structural, design
* **Sección:** cabecera («el plano propuesto en el chat»), §2, D1, D8 y §5 (`DoorDef`)
* **Problema:**
  * El plano del chat no está en el repositorio, y el paso 1 lo codificaría adivinando.
  * No se dice adónde abren el baño, la galería, el trastero, el aseo de servicio ni el recibidor. Tampoco si el taller da a los dos pasillos, ni dónde están los «pasos abiertos entre pasillos».
  * §2 se contradice: el taller «ocupa fachada y fondo», pero el pasillo principal va «a lo largo de todo el piso». Además, «alto» ya significa el preset gráfico.
  * `DoorDef.start` solo admite `closed | ajar | locked`, así que no hay forma de representar un vano sin hoja.
  * La puerta de entrada da al rellano, que no es una habitación. Eso rompe el test «cada puerta une dos habitaciones que se tocan».
  * Sin todo esto no se pueden revisar los tests de §7 (ciclos, la zona más lejana, las 9 vecinas).
* **Cambio propuesto:**
  * Añadir a §2:
    * un croquis en texto (rejilla monoespaciada) con el orden a lo largo de los 17,5 m, el eje de cada medida y el patio de luces;
    * una tabla con los 17 ids (`living_room`, `corridor_main`…) y su suelo;
    * una tabla de conexiones con las columnas `id | zona_a | zona_b | tipo (hoja | vano) | estado inicial`.
  * `DoorDef.kind: StringName` (`leaf` | `passage`). Un vano no tiene nodo `Door` y siempre cuenta como abierto.
  * `zona_b = &""` solo para la entrada, que queda fuera de los tests de contacto y de alcance.
  * Corregir la frase del taller y quitar «alto».
  * Sustituir «el plano del chat» por «plano de §2 (acordado el 2026-11-20)».

### B3. El contrato de las puertas no se puede implementar tal como está. Severidad: Bloqueante
* **Revisores:** implementation-readiness, design, codebase-details, comprehension, style
* **Sección:** D4, D5, §5 (`DoorMath`, `Door`) y §7
* **Problema:**
  * `DoorMath.step -> Vector2(angle, velocity)` no puede decir si la puerta ha quedado con pestillo o ha rebotado, y los sonidos lo necesitan.
  * D5 dice que el pestillo cierra siempre, y §5 que solo «si llega despacio». No está definido qué pasa al llegar deprisa a 0.
  * No hay constantes: `MAX_ANGLE`, rozamiento, rebote, velocidad del pestillo, ángulo de entornada.
  * `Door` no tiene señal, y D8 depende de «la señal de la puerta».
  * El signo del arrastre es ambiguo («según el lado desde el que se mira»), y no se dice qué es `from` en `try_grab`.
  * El espejo no sale solo: `MirrorMath` da M·T·M, y M·R_y(θ)·M = R_y(−θ), así que la hoja de una puerta reflejada gira al revés si no se cambia el signo. «La hoja abre hacia el otro lado» puede leerse como «abre hacia la otra habitación», y en un espejo real abre hacia la misma.
* **Cambio propuesto:**
  * `step(...) -> Vector3(angle, velocity, event)`, con `event` 0 = nada, 1 = pestillo, 2 = golpe o rebote.
  * Constantes iniciales con nombre (son ajuste, no †): `MAX_ANGLE` 100°, `LATCH_SPEED`, `FRICTION`, `AJAR_ANGLE` ≈ 5°.
  * A 0°: despacio queda cerrada con pestillo; deprisa golpea, suena el portazo y rebota.
  * Señal `closed_changed(door_id, closed)`.
  * Regla del ratón: «hacia arriba aleja la hoja de ti, desde cualquier lado».
  * `try_grab(eye)` devuelve `false` en una puerta con llave, tras sonar el traqueteo.
  * `DoorMath` no lleva signo. `door.gd` aplica `sign = -1` en espejo y usa la normal reflejada para saber de qué lado está el jugador.
  * Test: la hoja reflejada a θ es igual a `MirrorMath.mirror_transform` de la hoja normal a θ.

### B4. El salón «sin tocar» no deja andar por él: el sofá, la mesa y la estantería no tienen colisión, y la hoja de su puerta está horneada en el glTF. Severidad: Bloqueante
* **Revisores:** codebase-details, implementation-readiness (comprobado en el código)
* **Sección:** §2 («el actual, sin tocar»), D3, D7 y D14
* **Problema:**
  * `build_final()` borra `TvStand-col`, `Sofa-col`, `SofaBack-col`, `CoffeeTable-col` y `Shelf-col` (`tools/blender/build_living_room.py:307-308`). De pie, el jugador atravesaría los muebles, y el clic en el sofá de D7 no tendría nada que tocar.
  * `DoorLeaf` y `DoorHandle` están dentro de `living_room.gltf` y no tienen colisión. Con la puerta de Godot se verían dos hojas.
  * El GI del salón está horneado con la hoja y sin pasillo detrás, así que habría que hornearlo de nuevo.
* **Cambio propuesto:**
  * Decir que el salón cambia **solo** en colisión: cajas invisibles `<Mueble>-colonly` en `build_living_room.py` (modo final), y volver a exportarlo. El sofá va en su propia capa de colisión para el rayo de D7.
  * `flat.gd` oculta `DoorLeaf` y `DoorHandle` en tiempo de ejecución y pone una `Door` en la bisagra actual.
  * Hornear de nuevo el salón dentro del piso.
  * Añadir `build_living_room.py` y el glTF del salón a §4.
  * Test: la bisagra del `DoorDef` del salón coincide con la geometría (pared en x = −2,075, z = −1,6, ancho 0,9).

### B5. No hay una lista de «lo que decide el usuario», y varias decisiones van ocultas como hechas. Severidad: Bloqueante
* **Revisores:** structural, comprehension, design, zoom-out
* **Sección:** preámbulo, §3 y §8
* **Problema:** `CLAUDE.md` exige proponer al usuario lo que está [PENDIENTE] y pedir confirmación antes de crear una carpeta de la arquitectura o de cambiar el orden de los hitos. Solo D13 está marcada. Están abiertas o van como hechas:
  * (a) hacer 4a antes del hito 3, que no consta en GDD §11;
  * (b) la carpeta nueva `presentation/player/`;
  * (c) levantarse con Q en reveal = 0, cuando hito2 D2 descartó mirar alrededor antes del zoom out;
  * (d) si la pausa de pie detiene la partida (la pausa del menú es del hito 3);
  * (e) quitar la puerta entre el salón y el comedor;
  * (f) si las luces de las habitaciones están encendidas de noche y si hay interruptores;
  * (g) el balanceo de cámara activado por defecto (es accesibilidad: mareo);
  * (h) qué puertas empiezan entornadas;
  * (i) 1,3 m/s;
  * (j) el recurso a SDFGI de §9;
  * (k) las luces de las zonas nuevas, que siguen o no a la Energía (GDD §4).
* **Cambio propuesto:** nueva sección «Decisiones para el usuario», una tabla con `Id | Pregunta en lenguaje llano | Propuesta | Qué pasa si apruebas sin decir nada | Paso que bloquea`. Q solo en la build de depuración (`DevBoot`), no en `project.godot` de la exportada. Balanceo desactivado por defecto.

---

### M1. El planificador de zonas es frágil en pasillos largos, y más complicado de lo necesario. Severidad: Mayor
* **Revisores:** design, zoom-out, implementation-readiness, comprehension
* **Sección:** D8, D9, §5 (`RoomActivation`), §7 y §9
* **Problema:**
  * Un pasillo de unos 17,5 m es una sola zona. Las «8 más cercanas» se eligen al entrar y no se recalculan al recorrerlo.
  * La distancia no está definida, y nada obliga a incluir la zona actual.
  * No queda claro si el tope de 8 incluye la actual: D8 y §5 dicen cosas distintas.
  * Un VoxelGI de 17,5 m tiene celdas de unos 14 cm, del grosor de un muro, así que la luz se filtraría a través de las paredes.
  * Solo se activa a una puerta de distancia, así que una habitación vista a través de dos huecos se ve sin luz ni GI. En alto, con el ambiente rebajado por hito2 D9, se ve aún más oscura que en bajo.
  * Depender del estado de las puertas añade una señal, más tests y el riesgo de §9 («salto de luz»), y ahorra poco: lo que hay tras una puerta cerrada no ocupa píxeles.
* **Cambio propuesto:**
  * Partir cada pasillo en 2-3 tramos unidos por vanos. Eso arregla el desbordamiento de 9 vecinas, la elección caducada y el tamaño de celda.
  * Activas = zona actual (siempre, la primera) + vecinas por cualquier hoja o vano, **sin mirar si la puerta está abierta**, ordenadas por distancia del punto al rectángulo y luego por id, hasta 8 en total.
  * Recalcular solo al cambiar de zona. Desaparecen la señal de la puerta hacia el planificador y el riesgo de §9.
  * Opcional, como **pregunta** al usuario: un único VoxelGI para todo el piso serían 2 horneados en vez de 34 y nada de planificador, con riesgo de que la luz se cuele por los muros (habría que probarlo).

### M2. El presupuesto de rendimiento no se puede medir y puede romper los ~120 fps. Severidad: Mayor
* **Revisores:** zoom-out, design, implementation-readiness, codebase-details, structural
* **Sección:** §1, D8, §6 paso 5 y §8
* **Problema:**
  * «+25 % sobre el salón en alto» sustituye a los objetivos absolutos que el usuario aprobó en hito2 D16 (p95 por preset). Si el salón ya está cerca del objetivo de alto, se rompería el objetivo de ~120 fps y la especificación aun así se daría por cumplida.
  * Solo se mide en alto, y el preset por defecto es medio.
  * La referencia es ambigua (¿el salón antes de 4a o dentro del piso?).
  * «Cualquier vista» no es medible.
  * `Benchmark` cambia de cámara, pero la activación depende del jugador, así que mediría el pasillo con las zonas activas del salón.
  * No se mide la VRAM, y los 17 volúmenes y sus sondas siguen cargados aunque estén ocultos.
* **Cambio propuesto:**
  * Criterio = objetivos de hito2 D16 en los 4 presets, en normal y a oscuras con la linterna, más la VRAM. Las vistas son las 4 del salón y las nuevas que se listen.
  * Al cambiar de cámara, el benchmark llama a `flat.set_active(RoomActivation.active(..., posición de la cámara))`.
  * Quitar el 25 %, o proponerlo al usuario como decisión nueva.

### M3. El orden de los pasos obliga a repetir trabajo, y falta una parada para probar el tacto. Severidad: Mayor
* **Revisores:** zoom-out, implementation-readiness, structural
* **Sección:** §6
* **Problema:**
  * El horneado y el benchmark (paso 5) van antes de los muebles (paso 6), así que habría que hornear y medir otra vez, y la parada final aprobaría cifras viejas.
  * El paso 1 pide una captura en Blender cuando todavía no hay geometría.
  * Si `flat.gd` crea los VoxelGI desde el paso 2, habrá más de 8 activos hasta el paso 5.
  * La velocidad al andar, el tacto de las puertas y la sensibilidad, que son cuestión de gusto, se prueban por primera vez al final.
  * No hay un paso 0 que confirme los † (hito2 sí lo tenía).
  * No hay un paso de documentación.
* **Cambio propuesto:**
  * Paso 0: confirmar los † con context7.
  * Paso 1: dibujar los rectángulos planos en Blender.
  * Orden: plano → geometría → jugador → puertas (**parada: el usuario anda y abre puertas en el piso vacío**) → muebles → activación + horneado + benchmark → documentación → parada final.
  * Los nodos de GI llegan en el paso de activación.

### M4. La hoja no empuja de forma fiable al `CharacterBody3D`, y entraría en el horneado. Severidad: Mayor
* **Revisores:** codebase-details, design, implementation-readiness
* **Sección:** D5 y D9
* **Problema:**
  * Un `AnimatableBody3D` que gira no empuja al personaje de forma física. El personaje solo se separa en su propio `move_and_slide`, lo que provoca tirones, que la hoja lo atraviese o que lo aplaste contra un muro de 15 cm. El resultado cambia entre GodotPhysics y Jolt, y `project.godot` no fija cuál se usa.
  * `DoorMath` no sabe que algo la bloquea.
  * Las hojas por defecto son `GI_MODE_STATIC`, así que se hornearían en su pose inicial y dejarían una sombra fantasma al abrirlas.
* **Cambio propuesto:**
  * Antes de cada paso, `door.gd` prueba el giro (`PhysicsServer3D.body_test_motion` o `ShapeCast3D`). Si choca con el jugador o un mueble, la velocidad pasa a 0 y la hoja se para, como en *Visage*.
  * Quitar «empuja al jugador», o marcarlo †.
  * La hoja con `gi_mode = GI_MODE_DYNAMIC`.
  * Decir qué motor de física se usa.
  * Comprobación visual: «la hoja no atraviesa ni encaja al jugador».

### M5. VoxelGI y horneado: un límite no previsto, y rutas sin especificar. Severidad: Mayor
* **Revisores:** codebase-details, implementation-readiness, design
* **Sección:** D2, D9 y §9
* **Problema:**
  * Además del límite de 8 por vista, cada malla mezcla como mucho 2 VoxelGI (†). Un suelo o una pared que cruce varias zonas, o piezas unidas con `join()`, se quedaría a oscuras en parte.
  * `bake_voxel_gi.gd` instancia `living_room.tscn` y hornea un solo volumen. Si la activación corre en `_ready`, el resto de zonas estarían ocultas durante el horneado.
  * No hay rutas para los 34 archivos, ni regla en `.gitignore` (hoy solo cubre `voxel_gi_data*.res`).
  * No se dice qué pasa en ejecución si falta un archivo.
  * No se estiman el tiempo ni el tamaño.
* **Cambio propuesto:**
  * D2: la geometría va partida por zona (suelo, techo y tramos de pared dentro del rectángulo de cada zona más su margen).
  * `flat.gd` con `@export var bake_mode` (todo visible).
  * Rutas `world/player_flat/gi/<id>[_mirror].res` y `.gitignore` en §4.
  * Si falta un archivo: sin GI y sin `ERROR`.
  * Margen y `subdiv` por volumen (el salón usa 4,6 × 5,6 para 4 × 5).
  * §9: estimar el tiempo y el tamaño de la exportación.

### M6. Las sondas de reflejos se quedan obsoletas a oscuras y dan tirones al encenderse. Severidad: Mayor
* **Revisores:** design, codebase-details
* **Sección:** D8 y D9
* **Problema:** `_recapture_probe` (`presentation/main.gd`) solo vuelve a capturar la sonda del salón al cambiar el estado de la luz (hito2 D12). Las 16 sondas nuevas guardarían reflejos de lámparas encendidas durante el apagón. Además, ocultar y mostrar una sonda `UPDATE_ONCE` puede volver a capturar sus 6 caras (†), lo que daría un tirón al cambiar de zona.
* **Cambio propuesto:** dejar las sondas siempre visibles (34 caben en el atlas de 64 por defecto) y que el planificador cambie solo los VoxelGI. Al cambiar el estado de la luz, recapturar todas repartidas en varios fotogramas. Añadir el riesgo a §9.

### M7. La pausa de pie (D12) duplica al dueño de la pausa y no está especificada. Severidad: Mayor
* **Revisores:** zoom-out, design, implementation-readiness, codebase-details
* **Sección:** D12 y §4
* **Problema:**
  * La pausa es un `MainMenuUI` hijo de `TvGameUI` dentro del `SubViewport`, que solo recibe la entrada que reenvía `GameCamera` cuando es la cámara actual.
  * «Menú principal» usa el método privado `_change_channel`.
  * Una tercera instancia a pantalla completa necesitaría su propia conexión, escalar los 320 px fijos y decidir si se para la partida, el jugador y la inercia de las puertas. `CLAUDE.md` deja la pausa del menú para el hito del director.
  * Esc choca con la salida del modo libre de los trucos.
* **Cambio propuesto (el mínimo):** en 4a, Esc de pie hace la misma transición que sentarse y abre la pausa de la tele que ya existe. Cero interfaz nueva. La pausa de pie de verdad va con el apagón (resto del hito 4). Si el usuario la quiere ya: mostrar la textura del `SubViewport` de la tele a pantalla completa y llamar a `open_pause()`/`close_pause()`, con un solo menú.

### M8. D13 contradice el apagón y no dice qué se construye mientras tanto. Severidad: Mayor
* **Revisores:** design, implementation-readiness, comprehension, zoom-out
* **Sección:** D13
* **Problema:**
  * «Sigue produciendo» choca con GDD §2: la tele va con la electricidad del edificio, así que durante el apagón no puede producir.
  * No dice qué pasa con los eventos de la tele (las chispas caducan sin verse) ni con un clic mantenido (`Game.set_holding`).
  * Está bajo «Decisiones que cierra este hito» sin una pregunta explícita.
* **Cambio propuesto:**
  * Pregunta llana al usuario, con valor por defecto: «Si apruebas sin decir nada: sigue produciendo, salvo durante el apagón».
  * Comportamiento provisional en 4a: `Game.running` sigue en `true`, y al levantarse `set_holding(false)`.
  * Actualizar GDD §12 cuando se decida.

### M9. La regla de `EventBus` y quién calcula la zona actual. Severidad: Mayor
* **Revisores:** design, implementation-readiness, structural, codebase-details
* **Sección:** D3, D6, D8, §5 (`Player`) y §7
* **Problema:**
  * `Player` emite `room_changed`, pero no conoce `FlatLayout` ni si el piso está en espejo.
  * `CLAUDE.md` exige `EventBus` entre sistemas de escena.
  * `RoomActivation.active()` es pura y recibe `room_id`, así que no puede cumplir el test «fuera de toda zona se mantiene la última».
  * D8 dice que `RoomActivation` sabe en qué zona está un punto, y §5 pone `room_at` en `FlatLayout`.
* **Cambio propuesto:**
  * `flat.gd` lee la posición del jugador en su `_physics_process` y llama a `layout.room_at`. Guarda `_current` (si `room_at` devuelve `&""`, se queda la última) y avisa solo cuando cambia.
  * `EventBus.player_room_changed(id)`, `player_stood_up` y `player_sat_down`, porque el director, el audio y la Evidencia los querrán. `autoload/event_bus.gd` va a §4.
  * Las señales de puerta → piso se quedan locales (mismo sistema), y se dice explícitamente.
  * Una línea: el director recibirá la zona por el estado que arma el reloj.

### M10. El espejo del piso entero está bien planteado, pero le faltan reglas. Severidad: Mayor
* **Revisores:** design, codebase-details, implementation-readiness, zoom-out
* **Sección:** D2, D4 y D14
* **Problema:**
  * La reflexión en x = 0 es correcta: `MirrorMath` no usa escala negativa, y la GI y las sondas solo cambian el signo de `origin.x`.
  * «`FlatLayout` expone las posiciones ya reflejadas» duplica `room_at(p, mirrored)`.
  * `mirror_all` solo funciona si la rotación de cada objeto ya está aplicada, y esto no se dice para los muebles.
  * hito2 D14 pide que los objetos con texto y el fondo de ciudad los coloque Godot. D14 no lo repite.
  * Si `flat.gd` refleja usando el grupo de nodos, reflejaría dos veces los nodos del salón.
  * Faltan los oclusores en la lista de lo que se refleja.
* **Cambio propuesto:**
  * En espejo, `room_at` refleja el punto (`p.x = -p.x`) y no se guarda ningún dato reflejado.
  * Indicar en D2 que la rotación va aplicada antes de `mirror_all`.
  * Repetir en D14 la regla de los objetos con texto.
  * `flat.gd` refleja solo los nodos que crea él.

### M11. Los datos de las luces no bastan para el modo a oscuras. Severidad: Mayor
* **Revisores:** design, implementation-readiness, codebase-details, comprehension
* **Sección:** §5 (`RoomDef.lights`) y D3
* **Problema:** `Array[Vector3]` no tiene tipo, color, energía, alcance, atenuación ni los metadatos `base_normal` y `base_dark` que necesita `LightMixer`. Tampoco hay valores de desvanecimiento.
* **Cambio propuesto:**
  * Cada luz con `{pos, color, base_normal, base_dark, range, attenuation}`. Por defecto, los valores del aplique del salón.
  * Desvanecimiento con distancias concretas (†).
  * Las luces generadas entran en el grupo `room_lights`.

### M12. `build_flat.py` no puede reutilizar `build_living_room.py` tal como está, y el `.tres` y el glTF pueden desincronizarse. Severidad: Mayor
* **Revisores:** codebase-details, design, implementation-readiness
* **Sección:** D1 y D2
* **Problema:**
  * Las funciones de ayuda (`box`, `tex_mat`, `mirror_all`, `import_model`) viven en un script que llama a `main()` al cargarse y se ejecuta con `exec()`, así que importarlo reconstruiría el salón.
  * «Texturas compartidas» es falso: `export_final` copia las texturas junto a cada glTF, así que el parquet y el papel estarían duplicados en disco y en VRAM.
  * `flat_layout.py` y `build_flat.py` generan el `.tres` y el glTF en ejecuciones separadas, y el usuario no puede detectar si no cuadran.
  * No se dicen el origen ni los ejes (Blender o Godot, z = −y).
* **Cambio propuesto:**
  * Sacar las funciones de ayuda a `tools/blender/blender_common.py`.
  * `flat_layout.py` sin `bpy`, ejecutable con `python`, con coordenadas de Blender y una sola conversión al escribir el `.tres`. Origen = centro del salón.
  * `build_flat.py` regenera siempre el `.tres` en la misma ejecución y escribe un hash del plano en los dos. Un test falla si no coinciden.
  * Decidir si las texturas van a una carpeta compartida.

### M13. Faltan casos de test, y varios no se pueden medir. Severidad: Mayor
* **Revisores:** implementation-readiness, structural, design, comprehension
* **Sección:** §7
* **Problema y cambio propuesto:**
  * **Definiciones medibles:**
    * ciclos: quitar cualquiera de lateral, oficio o taller deja unidos los dos pasillos;
    * «la más lejana»: distancia BFS desde el salón, empate no permitido, con un campo `fuse_box_room`;
    * «se tocan»: hueco de 0,15 ± 0,01 m y solape ≥ el ancho de la puerta;
    * `DoorMath`: tolerancia concreta (≤ 1° tras 1 s, comparando dt = 1/30 con 1/144).
  * **Casos que faltan:**
    * `room_at` en huecos de muro y en bordes;
    * un punto reflejado da la misma zona;
    * dos zonas con dos puertas;
    * la puerta con llave no cuenta;
    * entornada cuenta como abierta;
    * empates en el tope de 8;
    * la zona actual siempre incluida;
    * la puerta reflejada (B3);
    * `try_grab` con llave;
    * llegar deprisa a 0;
    * claves nuevas con valores malos;
    * `TLR_SPAWN` con un id desconocido;
    * D15 (al cargar, el jugador está sentado).
  * **Archivos de test:**
    * `tests/test_flat.gd`: instancia en normal y en espejo, 17 VoxelGI, tantas puertas como en el plano y las bisagras reflejadas;
    * cambiar `test_light_mixer.gd`, `test_graphics_settings.gd` y `test_dev_cheats.gd`;
    * `verify.sh`: de 17 a 20 scripts (o los que salgan).
  * **Manuales:** marcar D6, D7, D12 y D14 como «manual en la parada X».

### M14. Al jugador le faltan medidas y reglas. Severidad: Mayor
* **Revisores:** implementation-readiness, codebase-details
* **Sección:** D6, D7, D10, D11 y §5 (`Player`)
* **Problema y cambio propuesto:**
  * **Faltan en la especificación:**
    * dónde se levanta (por ejemplo, el ancla del asiento + 0,6 m hacia la tele, ojos a 1,6 m);
    * cápsula (0,25 m × 1,75 m);
    * duración de la transición;
    * cuándo vale Q (sin tienda ni árbol abiertos y sin pausa);
    * cómo se detecta el sofá;
    * alcance del rayo (2 m);
    * cómo sabe el jugador el suelo (`set_floor` desde `flat.gd`).
  * **Movimiento y trucos:**
    * Mover a 60 Hz en `_physics_process` da tirones a 144-240 fps: activar `physics/common/physics_interpolation` y llamar a `reset_physics_interpolation()` al levantarse y al sentarse.
    * Con `Engine.time_scale` ×60 de los trucos, el jugador atraviesa muros: dividir por `time_scale` o congelarlo.
    * Ignorar la entrada mientras esté activo el modo libre.
  * **Cámara y linterna:**
    * `game_camera.gd` deja de reenviar el ratón a la tele estando de pie.
    * La linterna es el mismo nodo, que pasa de una cámara a otra.
  * **Ajustes (D11):**
    * 10 valores concretos en rad/px, con el valor por defecto en 0,0012 (el actual de los trucos);
    * comparación con `is_equal_approx`;
    * releer al recibir `settings_changed`;
    * test de que la lista de 5 botones cabe.

### M15. Es falso que «solo la luz de la calle y la linterna hagan sombras». Severidad: Mayor
* **Revisores:** codebase-details (comprobado)
* **Sección:** D8
* **Problema:** `ScreenLight` de la tele también tiene `shadow_enabled = true` (`presentation/tv/tv.tscn:25`).
* **Cambio propuesto:** «Solo la luz de la calle, la de la pantalla de la tele y la linterna hacen sombras, como hoy; ninguna luz nueva del piso las hace».

### M16. Faltan archivos en §4 y la actualización del GDD y de `CLAUDE.md`. Severidad: Mayor
* **Revisores:** structural, codebase-details, design, implementation-readiness, zoom-out
* **Sección:** §4 y §8
* **Problema:** faltan:
  * `presentation/graphics/light_mixer.gd`, `graphics_settings.gd` y `benchmark.gd`;
  * `presentation/ui/tv_game_ui.gd`;
  * `presentation/camera/game_camera.gd`;
  * `world/player_flat/living_room.gd` y `.tscn`;
  * `tools/blender/build_living_room.py` y el glTF del salón;
  * `autoload/event_bus.gd`;
  * `.gitignore` (texturas, `.bin`, `art_source/flat.blend` y la GI);
  * los tests correspondientes;
  * `GAME_DESIGN.md`: §8 (el plano), §11 (4a/4b y su orden) y §12 (D13);
  * `CLAUDE.md`: `presentation/player/` y la excepción de orden.
  * `crosshair.gd`, la acción de la linterna, `TLR_SPAWN` y los trucos no tienen ninguna decisión detrás.
* **Cambio propuesto:** completar §4 con una ruta por línea. Añadir un paso «Documentación». Añadir una decisión corta de «interacción y retícula» y otra de «herramientas de desarrollo» (`TLR_SPAWN`: id de zona; centro del rectángulo; id desconocido = error y sentado; solo en depuración). Reescribir §8 como lista (paradas aprobadas, capturas, documentación, `VERIFY OK` con N scripts, commit y push).

### M17. Sobra ingeniería para 4a: lo que se puede quitar o aplazar. Severidad: Mayor
* **Revisores:** zoom-out, design
* **Sección:** D5, D6, D8, D11 y §4
* **Recomendación (sin tocar las decisiones del usuario: un VoxelGI por zona activo cerca, solo andar lento, 3-6 muebles):**
  * **Aplazar:**
    * D6: los pasos por tipo de suelo. Un solo juego CC0 ahora, y quitar `RoomDef.floor`; la madera y la baldosa van con el audio del hito 3.
    * D8: los oclusores de caja. Solo si el benchmark final no llega a los objetivos (hay que partirlos en cada puerta, y no está claro que reduzcan el coste de las luces o de la GI).
    * D11: invertir Y, que va con el menú completo del hito 7.
  * **Quitar:**
    * D5: el rebote a 100°, salvo el golpe al cerrar rápido;
    * D5: el test de «pasos de tiempo distintos» si `DoorMath` va a paso fijo;
    * D11: el balanceo de cámara, o al menos dejarlo apagado por defecto;
    * los nombres de habitación en `strings.csv` «para los trucos», que no usan `tr()`.
  * **Simplificar:**
    * D12: la pausa (ver M7);
    * D8: la dependencia de las puertas (ver M1).
  * **Mantener:** la retícula mínima (hace falta para apuntar a la hoja).

### M18. Falta el apartado de alternativas descartadas. Severidad: Mayor
* **Revisores:** structural, design, style
* **Sección:** §3
* **Problema:** hito2 tenía una columna «Alternativas descartadas», y el estándar de especificación la exige. Aquí solo aparece SDFGI, de pasada, en §9.
* **Cambio propuesto:** una línea «Descartado:» en D1 (plano hecho en Godot), D5 (`RigidBody3D` + `HingeJoint3D`, o abrir con un clic), D8 (`Area3D` por zona o portales), D9 (SDFGI, LightmapGI o un único VoxelGI) y D12 (reutilizar la pausa de la tele).

---

### N1. Referencias que chocan y términos con varios sentidos. Severidad: Menor
* **Revisores:** style, comprehension
* **Sección:** cabecera, §1, D3, D8, D11 y Términos
* **Problema:**
  * «D14, D15, D16» de hito2 chocan con D14 y D15 de esta especificación, y «el benchmark de D16» no existe aquí.
  * «Paso» tiene cinco sentidos.
  * «Habitación» a veces incluye los pasillos y a veces no.
  * «Puerta» y «hoja» se mezclan.
  * «Ronda 3» y «la ronda anterior» no se sabe a qué remiten.
* **Cambio propuesto:**
  * Escribir siempre «hito2 D16».
  * Añadir a Términos: *zona* (habitación o pasillo; en código, `RoomDef`), *vano* (hueco sin puerta), *vecina* (a un salto).
  * Regla: *hoja* para la física y *puerta* para el estado.
  * «10 niveles» en vez de «10 pasos».

### N2. Glosario para el usuario. Severidad: Menor
* **Revisores:** comprehension
* **Sección:** Términos
* **Cambio propuesto:**
  * Glosas de una línea:
    * VoxelGI: luz rebotada precalculada de una habitación;
    * sonda: foto de la habitación para los brillos;
    * oclusor;
    * Forward+;
    * SDFGI: luz rebotada automática, más cara;
    * horneado;
    * «alto»: el preset;
    * `TLR_*`.
  * Una frase: «los nombres de clases y de archivos son para quien implementa».

### N3. Cuantificadores vagos. Severidad: Menor
* **Revisores:** style
* **Sección:** D5, D6, D7, D8 y D9
* **Problema:** «unos grados», «un poco», «ligero», «corta», «pequeño margen», «se desvanece con la distancia».
* **Cambio propuesto:** constantes con nombre y valor inicial.

### N4. Mal uso de †. Severidad: Menor
* **Revisores:** style, comprehension
* **Sección:** línea 13, D6 y §5
* **Problema:** † está pensado para hechos del motor. «1,3 m/s †» y «si llega despacio †» son valores de ajuste.
* **Cambio propuesto:**
  * Escribir «valor inicial, se ajusta probando» en esos dos.
  * Marcar † lo que falta: el empuje de `AnimatableBody3D`, `BoxOccluder3D` y el límite de 2 VoxelGI por malla.
  * Avisar al usuario si un † cambia algo que se nota.

### N5. Oclusores. Severidad: Menor
* **Revisores:** implementation-readiness, codebase-details
* **Sección:** D8
* **Cambio propuesto:** si se mantienen, `flat.gd` los deriva de `RoomDef.rect` menos los huecos de las puertas. Clave: `rendering/occlusion_culling/use_occlusion_culling=true`.

### N6. Audio. Severidad: Menor
* **Revisores:** implementation-readiness, codebase-details
* **Sección:** D5 y D6
* **Problema:** no se dice a qué bus van los pasos y las puertas. La reverberación `RoomAcoustics` solo cubre el salón, así que los pasos sonarán secos en el resto del piso.
* **Cambio propuesto:** decir el bus y si hay reverberación en las demás zonas.

### N7. Detalles del salón y de la fachada. Severidad: Menor
* **Revisores:** codebase-details
* **Sección:** D2 y D14
* **Problema y cambio propuesto:**
  * `build_flat` tiene que rellenar los postes de 15 × 15 cm que quedan abiertos en las esquinas exteriores del salón.
  * La cara de los muros del salón que da al pasillo lleva el papel del salón.
  * `WindowBackdrop` mide 10 m y no cubre una fachada de 17,5 m.

### N8. Quitar la puerta entre el salón y el comedor. Severidad: Menor
* **Revisores:** design
* **Sección:** §2
* **Cambio propuesto:** planteársela al usuario como pregunta en la parada 1, no como un cambio ya hecho (ya está en la tabla de B5).

### N9. Histéresis en los vanos. Severidad: Menor
* **Revisores:** design
* **Sección:** §7 y D8
* **Problema:** si el jugador se queda quieto en un vano, la zona actual puede cambiar sin parar.
* **Cambio propuesto:** aceptar el hueco de 15 cm, en el que se mantiene la última zona, y decirlo.

### N10. Formato. Severidad: Menor
* **Revisores:** structural, style
* **Sección:** cabecera, §1, §4 y D13
* **Cambio propuesto:**
  * §4 con una ruta por línea.
  * Línea de estado como en hito2 («no se escribe código hasta que el usuario lo apruebe» y la ruta de la revisión).
  * Lista «Fuera de alcance» y una lista «Supuestos».
  * Negrita solo en las etiquetas.
  * Una sola marca para los textos de la interfaz («»).

### N11. Términos de las builds y concordancias. Severidad: Menor
* **Revisores:** style
* **Sección:** D7, D9, §6 y §8
* **Cambio propuesto:**
  * «build de depuración (`Jugar (pruebas).bat`)» en vez de «build de pruebas».
  * «lo vuelve a sentar» (D7).
  * «como mucho 8 VoxelGI encendidos» (D9).

### N12. El horneado como paso explícito. Severidad: Menor
* **Revisores:** comprehension
* **Sección:** D9 y §6
* **Problema:** «Los datos horneados van fuera de git» deja implícito un paso.
* **Cambio propuesto:** decir en §6 que se hornea antes de cada build de depuración que vaya a probar el usuario. Sin eso, el piso no tiene luz rebotada.

---

## Comprobado y correcto (sin hallazgo)
- `MirrorMath` refleja en el plano x = 0 con M·T·M, sin escala negativa. El salón está centrado en x = 0. Reflejar el piso entero es una isometría válida, con la salvedad de las puertas (B3) y los objetos con texto (M10).
- `mirror_all`, `WorldEnvironment` único, la linterna en la cámara, `TLR_DARK`, `TLR_SHOT`, el benchmark de hito2 D16 y `settings.cfg` versionado (las claves nuevas tienen valor por defecto, sin subir la versión) existen como dice la especificación.
- El horneado ya exige un renderer real y no puede ejecutarse en headless.
- El razonamiento de D6 (`_physics_process` = física de presentación) es compatible con la regla del reloj único.
- `FlatLayout`, `RoomDef`, `DoorDef`, `RoomActivation` y `DoorMath` están bien en `world/`, no en `core/`.
- D13 está bien marcada [PENDIENTE] (GDD §12), aunque su propuesta necesita las correcciones de M8.
- La tabla de §2 suma exactamente 14 habitaciones; con 3 pasillos, 17, igual que §1, §7 y §9.
