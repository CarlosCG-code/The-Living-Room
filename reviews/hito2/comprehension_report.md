# Etapa 6 — Prueba de comprensión: `specs/hito2.md`

Un lector nuevo leyó **solo la spec** y la explicó con sus palabras. Diseño = líneas 1-60; implementación = líneas 61-132.

## What this proposes

El hito 2 pasa el incremental del hito 1 a una tele de tubo 3D dentro del salón del jugador.
- **Juego:** el jugador está sentado en el sofá, en primera persona, con el ratón capturado y una retícula en el centro. Un rayo desde la cámara toca la pantalla; `TvScreenMath` convierte el punto a coordenadas del `SubViewport`, y se le envían eventos de ratón reales, así que la UI del hito 1 funciona sin cambios.
- **Aspecto («fotorrealismo oscuro», referencia *Visage*):** VoxelGI con SSAO y SSIL, niebla volumétrica ligera, AgX, gradación fría, sondas de reflejos y assets CC0 más modelos de Blender. Se aprueba con rondas de capturas desde cuatro puntos de vista fijos.
- **Variantes:** el salón reflejado, exportado desde Blender como segunda escena y con los objetos de texto sin reflejar, y el salón a oscuras, un ajuste de luces con linterna.
- **Rendimiento:** `GraphicsSettings` con cuatro presets y objetivos de tiempo de fotograma en el PC de desarrollo a 1080p.
- **Fases:** 2a (tele jugable en graybox), 2b (look-dev) y 2c (variantes y rendimiento), cada una con una parada para la aprobación del usuario.

## How the existing system works, per this document

El hito 1 dejó una UI incremental plana (`tv_game_ui.tscn`): un dial, mantener pulsado, compras, *Reiniciar* e interferencias.
- **Herramientas:** Godot 4.7.2 (`$GODOT`); el MCP `godot` (GoPeak) ejecuta, inyecta clics y captura; el MCP `blender` controla Blender 5.3 con la ventana abierta; `verify.sh` hace cinco comprobaciones.
- **Carpetas:** la arquitectura pone el piso en `world/` y la tele y la cámara en `presentation/`.

**Conclusión:** la paráfrasis coincide con lo que se pretende; todo se entiende y encaja. Lo que falta son números y comportamientos concretos que un test o la implementación necesitan.

## Hallazgos

> Los puntos 2, 4, 5, 6, 7 y 12 coinciden con la etapa 5 (puntos 7, 1, 5, 2, 9 y 13).

### 🟡 Importantes

1. **«Fuera de alcance» dice que los ajustes gráficos son del hito 7** (línea 29), pero el objetivo y D15 los hacen ahora. **Cambio:** «el menú de ajustes gráficos y el pulido de la UI retro (hito 7)».
2. **El preset medio no tiene objetivo** (D13), así que su test no puede pasar ni fallar.
3. **No hay tabla de presets**: no se dice qué opción lleva cada preset, así que el test no sabe qué comprobar. Además, si el medio también quita la iluminación global, se quedaría sin ella y sin luces de relleno. **Cambio:** tabla preset × opción, y el relleno ligado a «iluminación global desactivada», no al preset bajo.
4. **Curvatura frente a clics; falta definir el espacio de coordenadas** de `hit_to_screen` (origen y unidades).
5. **Reenvío de eventos sin definir:** soltar mirando fuera de la tele; si mover el ratón gira la cámara y mueve el puntero a la vez; cómo se suelta el ratón capturado (Esc).
6. **Espejo:** falta el segundo bake; no se dice quién recoloca la tele y la cámara, ni cómo se carga la escena reflejada en este hito.
7. **VoxelGI y objetos que se mueven:** la justificación no se sostiene sin volver a preparar la iluminación global.
8. **El «recorrido de 30 s» del benchmark no está definido**, porque la cámara está sentada. **Cambio:** un barrido guiado por los cuatro puntos de vista de D14, N segundos cada uno.

### 🟢 Menores

9. Términos sin definir: run, pilar 4, zoom out, «producción», *Visage*. Una línea o la sección del GDD para cada uno.
10. Un resumen de una línea de la UI del hito 1 (dial, Antena, interferencias, *Reiniciar*).
11. Listar las 5 comprobaciones de `verify.sh` y nombrar el addon.
12. Añadir `presentation/graphics/` a D1.
13. Hay dos tipos de «preset»: el de luz (normal / a oscuras) y el gráfico. **Cambio:** llamar al de luz «estados de iluminación».
14. «La pantalla ilumina la cara del jugador»: la cara no se ve. **Cambio:** «ilumina el sofá y la zona delante de la tele».
15. La línea de `CLAUDE.md` que deja abierta la técnica del espejo: citarla.
16. Las capturas del paso 10 (una por preset) también se aprueban: añadirlo a los tests.
17. Explicar qué es EGM y enlazar la documentación de Godot citada.
