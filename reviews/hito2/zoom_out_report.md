# Etapa 5 — Zoom out: `specs/hito2.md`

Revisores: **zoom out** (alcance y simplicidad) y **catalizador** (contradicciones y alternativas). Contexto: `CLAUDE.md`, `GAME_DESIGN.md`, `specs/hito1.md`.

**Veredicto:** se aprueba con cambios. No hay bloqueantes. Los dos revisores dan por buenas las tres fases con parada y reutilizar la UI del hito 1 dentro de la tele. Hay cinco puntos que conviene arreglar **antes** de empezar, porque si no se tendrían que rehacer cuando ya hayas aprobado el aspecto.

## Importantes (🟡)

### 1. La curvatura de la pantalla desviaría los clics (los dos)
- **Problema:** si el shader curva la imagen, el jugador ve los botones en un sitio y el clic cae en otro, sobre todo en los bordes, donde están la tienda y *Reiniciar*. Los tests pasarían igualmente.
- **Cambio:** en este hito, la pantalla lleva emisión y viñeta, sin curvar la imagen. La curvatura y las líneas de barrido, si se quieren, llegan en el hito 7 (pulido de la UI retro). En ese caso, la misma fórmula iría en `TvScreenMath` y en el shader, con un test.

### 2. El espejo duplica toda la escena, no solo la geometría (los dos)
- **Problema:** un segundo `living_room_mirror.tscn` obliga a mantener dos veces las luces, la iluminación global, las cámaras de captura y, desde el hito 4, las interacciones. Además, la tele y la cámara se colocan en `main.tscn`, así que en el salón reflejado quedarían en el sitio equivocado.
- **Cambio:**
  - Una sola escena del salón. Solo se refleja la geometría exportada de Blender.
  - El resto de nodos (luces, sondas, cámaras, objetos con texto) se coloca reflejado por código. Reflejar una posición así no usa escala negativa, así que las colisiones y los textos quedan bien. Es una función pura con su test.
  - El salón expone **anclas** (`TvAnchor`, `SeatAnchor` y los puntos de captura), y la tele y la cámara se colocan en ellas.
  - El reflejado necesita su propio bake de iluminación global.

### 3. Lo más incierto se prueba al final (catalizador)
- **Problema:** el espejo desde Blender y la preparación de la iluminación global por script son las dos incógnitas técnicas más grandes, y quedaban para la fase 2c, después de construir y aprobar todo el salón.
- **Cambio:** el graybox de la fase 2a se hace ya con el script de Blender (cajas, que es trivial). En 2a se prueban las colisiones reflejadas y una preparación de la iluminación global por script. La fase 2b solo cambia las cajas por la geometría real. La primera parada se retrasa una sesión, más o menos.

### 4. Tres sistemas tocarían la misma intensidad de las luces (los dos)
- **Problema:** los presets de luz (normal / a oscuras), los ajustes gráficos (luces de relleno en el preset bajo) y, en el hito 3, las luces que bajan con la producción. Por ejemplo, en «bajo + a oscuras», las luces de relleno iluminarían el apagón.
- **Cambio:** un solo sitio escribe la intensidad de cada luz: `base (estado de luz) × relleno activo (preset y estado) × factor`. El hito 3 añade el factor sin tocar lo demás. Test: en «bajo + a oscuras», el relleno queda apagado.

### 5. Soltar el dial mirando fuera de la tele lo dejaría pulsado (zoom out)
- **Cambio:** soltar el botón del ratón siempre se envía a la pantalla, en el último punto válido, aunque se mire fuera. Se añade a la prueba con GoPeak: pulsar, mirar fuera, soltar, y el dial se para.

### 6. Medir el preset bajo de verdad (catalizador)
- **Problema:** medirlo en tu RTX 5060 Ti dice poco de un equipo modesto. A unos 4 ms limita el procesador, no la gráfica, y una gráfica integrada no escala igual.
- **Hallazgo:** tu Ryzen 5 9600X trae una gráfica integrada (Radeon, pequeña), pero **ahora mismo no aparece en Windows**: está desactivada en la BIOS o le falta el controlador.
- **Cambio:** las mediciones se hacen sin sincronización vertical y separando el tiempo de la gráfica del total. Si activas la gráfica integrada (te daría los pasos), el objetivo real del preset bajo sería «≥ 60 fps en la gráfica integrada del 9600X». Si no, se mide en la RTX como aproximación, se deja anotado como no verificado y se confirma con el playtest del hito 4 (anotando el equipo de cada probador).

### 7. Presets: alcance y el «medio» sin objetivo (zoom out)
- **Problema:** el zoom out propone dejar solo bajo y alto en este hito y el resto para el hito 7. Además, el preset medio no tiene objetivo de rendimiento, así que su test no puede pasar ni fallar.
- **Respuesta:** **se mantienen los cuatro presets en este hito**, porque lo pediste expresamente. Se arregla el hueco: el medio tiene su propio objetivo (≤ 6 ms en la RTX). En el hito 7 se añade el menú y se revisan las cifras con el resto del piso.

## Menores (🟢)

8. **Una base de luz barata para todos los presets** (catalizador): usar la luz ambiente de la sonda de reflejos del salón †, en lugar de colocar a mano luces de relleno extra para el preset bajo. Con la iluminación global activa, esa luz ambiente se baja. Así hay un solo montaje de luces.
9. **VoxelGI y objetos que se mueven:** la justificación se reformula. VoxelGI reacciona a las luces que cambian, pero los objetos movidos después de prepararla no actualizan los rebotes de luz. Los que se muevan (runs 3-4) se excluyen de la preparación.
10. **La luz de la pantalla:** su intensidad sigue el estado de la tele (encendida, interferencia, apagada en la variante a oscuras) a través del mismo sistema del punto 4.
11. **GoPeak con el ratón capturado:** un clic siempre cae en el centro de la vista. Hace falta una utilidad solo de desarrollo (cargada por `DevBoot`, fuera de la build) que apunte la cámara a un punto antes del clic.
12. **Legibilidad a 960 × 720:** en la parada de 2a, comprobar desde el sofá que todos los textos se leen. Si no, el tamaño de letra se sube solo en la tele, sin tocar la lógica del hito 1.
13. **Carpeta `presentation/graphics/`:** es nueva y debe figurar en D1, para que tu aprobación la cubra (lo pide `CLAUDE.md`).

## Correspondencia

| Aquí | Zoom out | Catalizador |
|---|---|---|
| 1 | M4 | 5 |
| 2 | M2, M3 | 3 |
| 3 | — | 2 |
| 4 | N2 | 4 |
| 5 | M5 | — |
| 6 | N1 | 1 |
| 7 | M1 | — |
| 8-13 | N4, N3 | 6, 7, 8, 9, 10 |
