# Etapa 9 — Preparación para implementar: `specs/hito2.md`, §4-§8

Ronda 1. Revisores: **preparación**, **detalles técnicos** (leyó el código real: `verify.sh`, `main.tscn`, la UI, `game.gd` y el addon de GoPeak) y **estilo**. Los tres terminaron.

**Veredicto:** todavía no está lista. El diseño (§1-§3) se sostiene, pero el plan deja demasiado por decidir. Todo se arregla escribiendo más concreto: ningún hallazgo obliga a cambiar el diseño.

## 🔴 Bloqueantes

1. **`verify.sh` fallará** (los dos técnicos). Comprueba que GUT ejecute 6 scripts de test, y el hito añade 4 (más uno nuevo, ver 7). **Arreglo:** `verify.sh` pasa a esperar 11 scripts y se añade a la lista de archivos. Hasta que existan todos, los tests se ejecutan con GUT directamente, como en el hito 1.
2. **Faltan las interfaces de las clases** (preparación, técnicos). No se dicen los métodos de `LightMixer`, `GraphicsSettings`, `tv_input`, la cámara ni `living_room.gd`. Tampoco quién escribe la luz ambiente ni cómo sabe `LightMixer` cuál es la luz de calle. **Arreglo:** una sección de interfaces, como la del hito 1.
3. **No hay forma de poner el juego en un preset, en espejo, a oscuras o en una cámara de captura** para las pruebas, las capturas y el benchmark. Además, la ventana mide 1152 × 648 y las medidas piden 1920 × 1080. **Arreglo:**
   - variables de entorno solo de desarrollo, como `TLR_NO_SAVE`: `TLR_PRESET`, `TLR_MIRROR`, `TLR_DARK`, `TLR_VIEW`, `TLR_GI` y `TLR_BENCHMARK`, que la build exportada ignora;
   - la ventana pasa a 1920 × 1080.

## 🟡 Importantes

4. **El benchmark no está definido y se usa antes de crearse** (los tres). **Arreglo:**
   - se crea en la fase 2a;
   - lo lanza `main.gd` con `TLR_BENCHMARK` en la build de depuración, desde la cámara de juego y las cuatro de captura, 10 s en cada una tras descartar 5;
   - mide el tiempo total, el de GPU † y la memoria de vídeo, y escribe una línea con el resultado;
   - en la fase 2b mide la variante normal en el preset alto.
5. **Falta un script de la tele** (los tres). Alguien tiene que leer el estado de la tele (interferencia o apagada), avisar a `LightMixer`, encender y apagar el `SubViewport` y asignar su textura por código, porque si se hace en la escena Godot escribe un `ERROR`. **Arreglo:** `presentation/tv/tv.gd`.
6. **Perder el foco con el dial pulsado lo deja «enganchado»** (técnicos). Si cambias de ventana con el dial pulsado, la pantalla de la tele no se entera y el siguiente clic va al dial. Además, soltar «en el último punto válido» podría contar un clic de más. **Arreglo:**
   - al perder el foco, `tv_input` suelta todos los botones;
   - el soltar fuera de la pantalla se envía a una posición fuera de ella, así el dial se suelta sin contar un clic;
   - al salir el cursor, la pantalla recibe «el ratón ha salido».
7. **«Soltar siempre» solo se prueba a mano** (preparación). **Arreglo:** un test sin gráficos, `test_tv_input.gd`, más la prueba con GoPeak. La parte de mantener pulsado depende de que GoPeak sepa pulsar, mover y soltar por separado †; si no sabe, se cubre con el test.
8. **Cómo se apunta, en concreto** (técnicos). GoPeak inyecta los clics sin mover el cursor del sistema, así que el rayo debe salir de la posición del evento. **Arreglo:** el rayo corta el plano de la pantalla por cálculo, sin física. El evento se copia con su posición pasada a píxeles de la pantalla y se envía con `push_input`.
9. **La UI plana del hito 1 seguiría encima** (técnicos). Taparía la vista 3D y se quedaría todos los clics. **Arreglo:** se quita de `main.tscn`, porque ahora vive dentro de la tele.
10. **Herramientas de desarrollo dentro del juego exportado** (técnicos). Los scripts `tools/*.gd` se exportarían. **Arreglo:** se añade `tools/*` al filtro de exclusión y a la comprobación 4 de `verify.sh`.
11. **Un `.blend` dentro del proyecto rompería la importación** (técnicos). Godot intentaría importarlo y escribiría errores. **Arreglo:** el `.blend` vive en `art_source/`, una carpeta con `.gdignore`; solo los `.glb` van a `assets/models/`.
12. **Nombres de archivo y tubería de modelos** (preparación, técnicos). **Arreglo:**
    - los nombres fijos: `assets/models/living_room.glb`, `living_room_mirror.glb` y `tv.glb`;
    - las colisiones, con el sufijo `-col` de Blender †;
    - los materiales van dentro del glTF, y los ajustes de Godot en `.tres` solo si hace falta;
    - el plano del espejo es x = 0 del salón, en Blender y en Godot;
    - los objetos con texto y los que se moverán son nodos de Godot, no geometría exportada;
    - la ciudad de la ventana es una imagen sobre un plano detrás de la ventana, no el cielo del entorno, para no cambiar la luz ambiente fijada.
13. **Cómo se prepara la iluminación global** (los dos técnicos). **Arreglo:** el comando concreto (sin `--headless`), cómo prepara las dos versiones, dónde las guarda y qué objetos quedan fuera (de momento, ninguno). Si no funciona por script, se para y se consulta (no se elige solo otra técnica).
14. **Cómo se comprueban las colisiones sin un jugador que ande** (preparación, técnicos). **Arreglo:** un test que carga el salón en las dos versiones y lanza rayos contra paredes y suelo desde puntos conocidos.
15. **Cómo se mide la legibilidad** (preparación). **Arreglo:** por cálculo. La altura en píxeles de la pantalla proyectada (con `Camera3D.unproject_position` de sus esquinas) por el tamaño de letra más pequeño, dividido entre 720. Se confirma con una captura. Bastan los presets bajo (el peor, al 67 %) y alto. La tienda debe mostrar al menos 5 filas.
16. **Tabla de presets con valores concretos** (técnicos). **Arreglo:** números y enumeraciones de Godot en lugar de «corta» o «baja». El test lee lo que se puede leer sin gráficos, y lo que solo existe en el servidor de render se comprueba por el preset guardado.
17. **Cierre y benchmark se contradicen** (estilo). **Arreglo:** las cifras se anotan y las apruebas tú, cumplan o no; si un preset no cumple, se baja lo que más milisegundos ahorre según la medición, sin bajar de la escala mínima.
18. **Pasos de la §1 a la §8 que contradicen el diseño** (estilo, preparación): en el paso 1 sobra «luz ambiente de la sonda» y falta «volver a capturar la sonda» †; el riesgo de las integradas cita una estimación que no existe.

## 🟢 Menores

19. Los archivos generados (`.uid`, `.import`) y la línea de estado, en la lista.
20. **Términos:** «graybox» en todo el texto; «preparar» como único verbo para el *bake*; «variante a oscuras (estado de iluminación de D13)»; ¿se captura también espejo + a oscuras juntos, que es la run 2? Sí, en el paso 9.
21. **Primera ronda con pocos objetos:** un primer lote, y el resto entre rondas.
22. **Comprobaciones con criterio claro:**
    - las del espejo: la tele y la cámara en las anclas reflejadas y los clics funcionan igual;
    - la del apagón: los objetos no muestran reflejos del estado normal;
    - las de `TvScreenMath` y `MirrorMath`, con casos concretos.
23. **La comprobación 5 de `verify.sh` con la escena 3D:** puede que el render vacío escriba errores con VoxelGI o con la pantalla †. Si pasa, las llamadas de ventana se protegen cuando no hay pantalla.
24. Riesgos sin acción y repetidos: cada uno con su límite y su acción, o fuera.
25. El paso 11 nombra las ediciones exactas del GDD (§10, §11 y §12).
26. La parada 2a se juega en la build exportada, como en el hito 1.
