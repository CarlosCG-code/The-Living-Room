# CLAUDE.md — The Living Room

Juego de terror psicológico con un incremental como mecánica central, hecho en **Godot 4 (GDScript)**. El diseño completo está en `GAME_DESIGN.md`: léelo antes de cualquier cambio. Lo decidido no se cambia sin confirmación del usuario; lo marcado **[PENDIENTE]** se propone al usuario antes de fijarlo; lo marcado **[DEFECTO]** se aplica salvo que el usuario diga otra cosa. Si CLAUDE.md y el GDD difieren, manda CLAUDE.md y se corrige el GDD.

## Cómo trabajar

- Respuestas concisas.
- Para y espera confirmación, con el plan en ≤5 líneas, antes de: empezar un hito, crear o borrar un sistema o carpeta de la arquitectura, cambiar el formato de guardado, añadir una dependencia o addon, o tocar algo de "Decisiones fijadas".
- **El usuario no edita código ni usa el editor**, salvo el caso del punto siguiente. Claude escribe todo como texto: scripts (`.gd`), escenas (`.tscn`), recursos (`.tres`), materiales, `project.godot`, tests y exportación.
- Si algo exige el editor, da al usuario pasos concretos y numerados.
- Verifica sin el usuario: importación y tests GUT con el ejecutable de la variable de entorno `GODOT` en modo `--headless`; errores de GDScript con el LSP del editor headless (`--editor --lsp-port 6005`); el aspecto visual solo con capturas del juego ejecutado con renderer real (MCP `godot`, servidor GoPeak, que usa el addon `godot_mcp_runtime`). Headless no renderiza.
- Herramientas: modelado y props en Blender (MCP `blender`, sin su generación por IA de pago) exportados a glTF; escenas y verificación con el MCP `godot`; documentación de Godot 4.7.2 con el MCP `context7`.
- PC de desarrollo: referencia de rendimiento, no requisito mínimo. Sus datos no se escriben en el repositorio.
- **Privacidad:** nada del usuario ni de su PC va a GitHub: nombre, correo, rutas locales de su usuario, hardware, cifras de benchmark, capturas o partidas. Los commits usan el correo noreply de GitHub; el hook `tools/hooks/pre-commit` bloquea lo demás.

## Arquitectura

Separar siempre la lógica de la presentación:

- `core/` — sin nodos ni escena (`RefCounted`/`Resource`): estado por run y meta-estado que persiste entre partidas completas (p. ej. el menú alterado tras un final), economía, prestigio (= reinicio), Evidencia, guardado. Testeable.
- `presentation/` — TV (`SubViewport` + raycast → UV), rig de cámara (`reveal` 0–1 interpola FOV/posición), UI.
- `fear/` — director de eventos (presupuesto, cooldowns, comprobación de mirada: eventos que solo ocurren si el jugador no mira).
- `audio/` — gestor de audio 3D y mezcla por run.
- `world/` — piso del jugador, escalera, piso de la señora, menú principal (tele y silla). Variantes del piso: espejo y a oscuras (la run 2 combina ambas); su técnica se especifica y valida en el hito 2 junto al look-dev (candidatas: kit modular colocado en simetría, o reflejo de geometría en build con normales y textos corregidos).
- `narrative/` — contenido de pistas y finales.

Ubicaciones (fijadas en el hito 0): autoloads en `autoload/`, datos `.tres` en `data/`, tests GUT en `tests/`, assets en `assets/` (`models/`, `textures/`, `audio/`, `fonts/`). `audio/` en la raíz es el código del gestor de audio; los sonidos van en `assets/audio/`. Cada carpeta se crea con su primer archivo. GUT está en `addons/gut/` y el addon de capturas en `addons/godot_mcp_runtime/` (solo build de depuración; lo carga `autoload/dev_boot.gd`, que añade el nodo `MCPRuntime`). `DevBoot` carga también los trucos de prueba (`tools/dev_cheats.gd`, F1), solo en depuración: el usuario los abre con `Jugar (pruebas).bat`, no con la build de `build/`. El addon se excluye de toda build exportada, y cada hito se comprueba con `tools/verify.sh`, que verifica además que la build arranca sin él.

Reglas:
- `core/` declara sus propias señales y no conoce el árbol. Un adaptador (autoload) reenvía al autoload `EventBus` solo los eventos discretos (compra, reinicio, pista hallada). El estado continuo (producción, mirada) no se emite: el director lo recibe del reloj en cada tick. Entre sistemas de escena: `EventBus`, no referencias directas.
- Datos (mejoras, eventos, pistas) en recursos `.tres` (`Resource` con `class_name`), no hardcodeados.
- Guardado en JSON con campo de versión; cada migrador con su test. Escritura atómica (`.tmp` y renombrar, conservando un `.bak`); el meta-estado va en un archivo aparte del de la run.
- Un único reloj (autoload) hace avanzar `core/` y el director con el mismo delta; es el único `_process()` con lógica de juego. Los tests llaman a `tick()` con delta fijo. Cómo se arma el estado que recibe el director, la pausa del menú y la congelación parcial del final (el clicker sigue activo) se especifican en el hito que introduzca el director (candidatas: que el reloj construya el estado leyendo `core/` y un proveedor de mirada; `SceneTree.paused` con `process_mode` para el menú; escalas por canal para el final).
- Tests (GUT, en headless) para todo `core/`, el planificador del director (`RefCounted`) y la conversión raycast → UV de la tele, extraída a una función pura.

## Convenciones

- GDScript con tipado estático; nombres en inglés; textos del juego en español mediante `tr()` y archivos de traducción CSV de Godot, nunca literales en el código.
- Un archivo por clase (`class_name`). Sin lógica de juego en `_process()` salvo el reloj.
- Comentarios solo donde el *porqué* no sea evidente.

## Decisiones fijadas (no cambiar sin preguntar)

- Terror psicológico: **sin enemigos ni estado de derrota**, máximo 2 jumpscares, desactivables. Primera persona, PC (Windows).
- El reinicio del incremental dispara los eventos de transición.
- Motor: **Godot 4.7.2, renderer Forward+**. Objetivo visual: fotorrealismo oscuro tipo *Visage*.
- **Todo gratuito y libre.** Sin pagos salvo Claude (la única IA de pago): ni assets, ni servicios, ni IAs de pago, y nada con licencia no comercial (NC). Las cuentas gratuitas ya configuradas (Freesound) se permiten. Herramientas de desarrollo: cualquier licencia libre (incluida GPL, p. ej. Blender). Lo que va dentro del juego (código, librerías, addons): MIT, Apache-2.0, BSD, Zlib, MPL-2.0 o CC0. Excepción: las licencias de terceros que trae el propio motor Godot (las de su `COPYRIGHT.txt`) se aceptan si son permisivas, y sus avisos de licencia van con el juego; si aparece una que no lo sea, se para y se avisa al usuario. Modelos de IA: solo para voces y efectos de sonido, con licencia que permita uso comercial de lo generado (MIT, Apache-2.0); cada archivo generado se registra en `ASSETS.md` con el modelo y su licencia. No se generan modelos 3D ni texturas con IA.
- Assets: solo **CC0** (Poly Haven, ambientCG, Kenney, Freesound filtrado a CC0, Poly Pizza filtrado a CC0) o modelados por Claude en Blender; tipografías CC0 u OFL. Claude descarga, verifica la licencia de cada uno y lo registra en `ASSETS.md`: archivo, fuente (URL), autor, licencia, fecha.

## Orden de trabajo

Seguir los hitos de `GAME_DESIGN.md` §11 en orden, empezando por el hito 0. Cada hito empieza con su especificación de implementación (archivos, pasos, decisiones [PENDIENTE] a cerrar y casos de test), revisada con EGM y aprobada por el usuario antes de escribir código. Un hito se cierra cuando sus tests pasan en headless y el usuario lo aprueba tras probarlo. El primer entregable jugable es el **corte vertical (hito 4)**, que además exige un playtest con ~5 personas: Claude propone las preguntas, el usuario las aprueba y, con el resultado, decide si el hito se cierra.
