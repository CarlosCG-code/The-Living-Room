# Etapa 7 — Crítica: `specs/hito2.md`, líneas 1-60 (§1-§3)

Ronda 1. Revisores: **diseño**, **estructura** y **estilo**. Estándar: `feature-spec-standard`. Los tres terminaron. Al de diseño se le pidió que no repitiera lo ya encontrado en las etapas 5 y 6.

**Veredicto:** hacen falta cambios. Hay 1 bloqueante y unos 12 importantes nuevos. Varios necesitan tu opinión (marcados con **[tú]**).

## 🔴 Bloqueante

### 1. La pantalla de la tele no se podría leer desde el sofá (diseño)
- **Problema:** la UI del hito 1 se diseñó para ocupar toda la pantalla. Desde un sofá a 2,5-3 m, una tele de tubo se ve de unos 150-250 píxeles de alto en una imagen 1080p, así que el texto quedaría de pocos píxeles. Con el escalado FSR del preset bajo, peor todavía.
- **Cambio:**
  - Un objetivo medible: el texto más pequeño de la tele mide al menos N píxeles de alto en 1080p, desde la cámara de juego y en todos los presets.
  - De ahí salen el tamaño de la tele, la distancia al sofá y el campo de visión.
  - La UI del hito 1 se adapta a la tele (letras más grandes y menos filas visibles), sin tocar su lógica.
  - La escala de resolución tiene un mínimo.
  - En la parada de la fase 2a lo compruebas con capturas en los presets bajo y alto.

## 🟡 Importantes

2. **La cámara libre desde el sofá estropea el «zoom out» (diseño) [tú].** El GDD dice que la run 1 empieza cerca de la tele y que un zoom out revela poco a poco que estás sentado en un sofá. Con giro libre de ±70° desde el principio, ves el salón en el primer segundo. `CLAUDE.md` ya prevé una cámara con un parámetro `reveal` de 0 a 1.
   - **Cambio:** la cámara sentada es ya esa cámara. Con `reveal` = 0 encuadra la tele de cerca, con giro limitado (lo que además ayuda a leer la pantalla). Con `reveal` = 1 tiene el giro amplio. En este hito se fija a mano; el hito 3 lo anima con la producción.
3. **Apuntar girando la cabeza durante 2,5 horas cansa (diseño) [tú].** Cada clic y cada compra obliga a mover la vista para poner la retícula sobre un botón pequeño.
   - **Cambio:** evaluar una alternativa híbrida. La propuesta: cuando la retícula está sobre la pantalla, la vista se queda quieta y el ratón mueve un cursor dentro de la pantalla. Al salir del borde, vuelves a girar la cabeza. En la parada de 2a se comprueba con una prueba: comprar la quinta fila de la tienda y atrapar una interferencia sin fallar.
4. **El rendimiento se mide solo al final (diseño).** Si el aspecto aprobado no cumple el objetivo, tendrías que volver a aprobar algo peor.
   - **Cambio:** cada ronda del look-dev enseña los milisegundos del preset alto junto a las capturas.
5. **El método de medición está incompleto (diseño, estilo; etapa 5 n.º 6).**
   - **Cambio:** medir sin sincronización vertical ni límite de fps, descartar los primeros fotogramas (compilación de shaders) y anotar el tiempo de la gráfica aparte del total.
   - «Una gráfica con la mitad de potencia llega a 60» y «el bajo sirve para integradas» se escriben como estimaciones, no como hechos: el rendimiento no escala en línea recta.
6. **Medir el peor caso (diseño).** La variante a oscuras, con la linterna y su niebla volumétrica, es la más cara, y la run 2 se juega así unos 25 minutos.
   - **Cambio:** los objetivos de D13 se cumplen en la variante a oscuras. La linterna tiene ajustes propios por preset (sombra sí/no y su resolución, niebla volumétrica sí/no).
7. **Reflejos que no se actualizan (diseño).** Una sonda de reflejos capturada con las luces encendidas seguiría brillando en el apagón.
   - **Cambio:** la sonda se vuelve a capturar al cambiar de estado de iluminación (normal / a oscuras), y se comprueba en las capturas de la variante a oscuras.
8. **«VoxelGI media/alta» quizá no se pueda cambiar en marcha (diseño).** La resolución del VoxelGI se fija al prepararlo, y cada nivel necesitaría su propio bake, dos veces por el espejo.
   - **Cambio:** definirlo †. La propuesta: un solo bake, y que los presets cambien solo la calidad de cálculo, que sí se cambia en marcha.
9. **Preset por defecto y memoria de vídeo (diseño).** Hasta el hito 7 no hay menú, así que un equipo modesto arrancaría en un preset que no puede mover. Además, las texturas 2K pueden no caber en una gráfica integrada.
   - **Cambio:** el preset por defecto es el medio. Se mide la memoria de vídeo por preset. La calidad de texturas se deja fuera de este hito, dicho expresamente: Godot no las reduce en marcha, y se decidirá en el hito 7.
10. **Brillo (diseño).** Un juego oscuro con exposición fija se verá negro en unos monitores y lavado en otros.
    - **Cambio:** `GraphicsSettings` incluye ya un ajuste de brillo. El aspecto se aprueba con el valor por defecto, y la pantalla de calibración se apunta para el hito 7.
11. **Hora del día y qué se ve por la ventana (diseño) [tú].** Son la fuente de luz principal y el GDD no lo dice.
    - **Propuesta:** la run 1 transcurre **de noche** (el repartidor trae la cena), con la ciudad de noche al otro lado de la ventana y la persiana medio bajada. Para el exterior, una imagen panorámica CC0 de Poly Haven. La run 2 es la misma noche, durante el apagón.
12. **Faltan los riesgos en la parte de diseño (estructura).**
    - **Cambio:** la §8 pasa a cubrir también los riesgos del diseño: la luz que se cuela con VoxelGI, la memoria, el reenvío de eventos y la gráfica integrada.
13. **Faltan los flujos entre partes (estructura).** No se dice cómo `tv_input.gd` recibe el rayo de la cámara ni cómo `GraphicsSettings` llega al entorno del salón. `CLAUDE.md` pide no usar referencias directas entre sistemas de escena.
    - **Cambio:** `main.tscn` las conecta, porque la tele, la cámara y los ajustes son de la misma capa de presentación. El salón solo expone sus anclas y su entorno.
14. **Afirmaciones sin pruebas y contradicciones de alcance (estilo, estructura; etapas 5 y 6).**
    - «La mejor» y «la mejor calidad» se reescriben como hechos comprobables, y la afirmación de SDFGI se marca †.
    - «Ajustes gráficos (hito 7)» pasa a «menú de ajustes gráficos (hito 7)», también en el GDD §11.
    - `presentation/graphics/` se añade a D1.

## 🟢 Menores

15. Tabla preset × opción (con el medio y su objetivo, ≤ 6 ms), y las luces de relleno ligadas a «iluminación global desactivada» (etapas 5 y 6).
16. «Director de miedo» → «director de eventos», como en el GDD.
17. Explicar los términos técnicos: *bake* (prepararlo), SSAO, SSIL, FSR y «percentil 95» (el 95 % de los fotogramas tarda como mucho eso).
18. La luz de la pantalla: «ilumina el sofá y la zona delante de la tele». Va en su propia fila de decisión, y su intensidad sigue el estado de la tele.
19. Las líneas de barrido, si llegan (hito 7), no deben producir parpadeos ni moiré y deben respetar el tope de 3 destellos por segundo. El `SubViewport` deja de dibujarse con la tele apagada.
20. En D3 y D10, la columna «alternativas» dice «Ninguna: lo impone `CLAUDE.md`». D3 descarta además `Area3D.input_event`. Todas las filas de alternativas con el mismo formato.
21. Fuentes: añadir los §2 y §12 del GDD. Listar las 5 comprobaciones de `verify.sh` y definir «build exportada».
