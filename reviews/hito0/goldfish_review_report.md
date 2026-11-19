# Goldfish Annotated Review Report — Etapa 7

**Status: resolved** — 12 arreglos aplicados el 2026-11-17 (1-10, 12, 15); 3 descartados (11, 13, 14).

**Target:** `specs/hito0.md` (líneas 1-28: §1 Objetivo, §2 Decisiones)
**Hallazgos:** `reviews/hito0/critic_report.md` (numeración igual)

Categorías: **PROPOSE FIX** = arreglo propuesto · **CONTEST** = el revisor se equivoca (con prueba) · **DECLINE** = detalle menor, no se toca.

## Comprobaciones hechas para esta resolución

Revisé el paquete instalado `gopeak` (instalación global de bun) (versión 2.4.1, `LICENSE` MIT en la raíz del paquete):
- **GoPeak habla con el juego por TCP:** `build/index.js`, `handleRuntimeCommand` usa `RUNTIME_HOST = "127.0.0.1"` y `RUNTIME_PORT = 7777`. No lee `project.godot` ni busca ningún nodo por su ruta.
- **GoPeak no añade el autoload por su cuenta.** Solo hay dos formas de registrarlo: la herramienta `add_autoload`, si se llama a propósito, o activar el plugin del addon en el editor (`godot_mcp_runtime.gd`, línea 27, `add_autoload_singleton`). Este proyecto no hace ninguna de las dos.
- **El addon se apaga en release:** `mcp_runtime_autoload.gd`, `_start_server()`, línea 75: `if not OS.is_debug_build(): _enabled = false; return`.
- **Solo escucha en local:** `DEFAULT_BIND_ADDRESS = "127.0.0.1"` (línea 8), puerto 7777.
- **El nodo se pone el nombre él solo:** `name = "MCPRuntime"` (línea 24).
- **El addon no trae `LICENSE` propio,** y su `plugin.cfg` dice `version="1.0.0"`.

## Hallazgos

### [1] [`design`, `structural`] - Blocker — Faltan las alternativas descartadas
*   **Affected Scope:** [Líneas 19-27](../../specs/hito0.md#L19-L27) (§2)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El estándar lo exige, y el GDD §11 deja esta elección a la spec.
*   ***Proposed Edit:*** añadir la columna «Alternativas descartadas» a la tabla:
    - **D1:** subcarpeta `game/`. Descartada: las rutas de `CLAUDE.md` dejarían de coincidir con `res://`.
    - **D2:** GUT 9.7.0 (queda como reserva, con confirmación) o GUT de la AssetLib (descartada: necesita el editor).
    - **D3:** el addon desde la rama `main` de GoPeak con su `install-addon.ps1`. Descartada: no tiene versión fija y podría no coincidir con el servidor 2.4.1.
    - **D4:** (a) registrar `MCPRuntime` en `project.godot` y quitarlo al exportar con un `EditorExportPlugin`. Descartada: necesita un plugin del editor activo al exportar, y si falla, la build se rompe. (b) un `override.cfg` solo de desarrollo. Descartada: no está documentado que admita autoloads en 4.7.2 y es un mecanismo poco conocido.
    - **D5:** forzada (el exportador necesita las plantillas de la misma versión).
    - **D6:** forzada por `CLAUDE.md` (Convenciones: CSV de Godot).
    - **D7:** ejecución con ventana en `verify.sh`. Descartada: abre una ventana en el escritorio del usuario en cada verificación, y el renderer real ya se prueba en el paso 8 (captura) y cuando el usuario abre la build.

### [2] [`design`, `structural`, `style`] - Major — D7 puede pasar sin probar nada
*   **Affected Scope:** [Línea 27](../../specs/hito0.md#L27) (D7)
*   ***AI Suggestion:*** PROPOSE FIX (excepto la ejecución con ventana, ver [1])
*   ***Justification:*** un log vacío daría el visto bueno. Hace falta una prueba positiva y un archivo de log fijo. El renderer real ya lo cubren el paso 8 y el usuario.
*   ***Proposed Edit:*** D7 → «La build se ejecuta con `--headless --quit-after 120` (120 fotogramas) y `--log-file build/run.log`. Pasa si sale con código 0, el log contiene la línea `BOOT_OK` que imprime `main.gd` al arrancar y no contiene `ERROR`. Si el log falta o está vacío, falla. Headless no prueba el renderer; eso lo cubren la captura del paso 8 y la prueba del usuario.» Si `--log-file` no existiera en 4.7.2 (se comprueba con context7 antes de implementar), se usaría `user://logs/godot.log`.

### [3] [`design`, `style`, `structural`] - Major — D4 depende de GoPeak sin comprobarlo
*   **Affected Scope:** [Línea 24](../../specs/hito0.md#L24) (D4)
*   ***AI Suggestion:*** PROPOSE FIX. El riesgo de fondo queda descartado con las pruebas de arriba; lo que falta es citarlas.
*   ***Justification:*** el riesgo de que GoPeak inyecte el autoload o dependa del orden de carga no existe: solo se conecta por TCP. Lo que sí falla es el texto: primera persona, sin citas, y una frase que contradice su celda.
*   ***Proposed Edit:***
    - **Propuesta:** «No se registra `MCPRuntime` en `project.godot`. Lo carga el autoload propio `DevBoot` solo si `OS.is_debug_build()` y existe `res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd`. La exportación excluye `addons/godot_mcp_runtime/*`.»
    - **Por qué:** «Un autoload registrado cuyo archivo se excluye rompe la build al arrancar. Así `project.godot` es igual en desarrollo y en release, y la exportación solo excluye archivos. GoPeak solo se conecta por TCP a `127.0.0.1:7777` (`build/index.js`, `handleRuntimeCommand`): no necesita que el autoload esté registrado ni que se cargue antes que la escena. Segunda barrera: el addon no abre el servidor en release (`mcp_runtime_autoload.gd`, `_start_server()`).»

### [4] [`design`, `style`] - Major — Versiones y orígenes poco precisos
*   **Affected Scope:** [Líneas 22-23](../../specs/hito0.md#L22-L23) (D2, D3)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:***
    - **D2, Por qué:** «Compatible con Godot 4.7 desde la 9.7.0 (notas de versión en `github.com/bitwes/Gut/releases`). Versión más reciente a 2026-11-17. Al descargar se registra el SHA-256 del zip en `ASSETS.md`.»
    - **D3, Propuesta:** «`godot_mcp_runtime` (su `plugin.cfg` dice 1.0.0), copiado de GoPeak 2.4.1 instalado en `%USERPROFILE%\.bun\install\global\node_modules\gopeak\build\addon\`, junto con el `LICENSE` MIT del paquete.»
    - **D3, Por qué:** «Copia local de la misma versión que el servidor MCP en uso. Si se actualiza GoPeak, se vuelve a copiar.»

### [5] [`structural`, `design`, `style`] - Major — Faltan entregables en el objetivo y hay criterios no medibles
*   **Affected Scope:** [Líneas 8-13](../../specs/hito0.md#L8-L13) (§1)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** nueva lista de la §1:
    - «`$GODOT --headless --import` termina con código 0 y sin líneas `ERROR`;
    - los tests GUT se ejecutan en headless y pasan;
    - todo texto visible se obtiene con `tr()` desde `locale/strings.csv` (es);
    - el MCP `godot` (GoPeak) obtiene una captura del juego en ejecución (build de depuración) mediante el addon `godot_mcp_runtime`;
    - la build release de Windows arranca (criterio D7) y no contiene el addon;
    - `ASSETS.md` existe con las dependencias (versión, origen, licencia), y las ubicaciones de carpetas quedan anotadas en `CLAUDE.md`.»

### [6] [`structural`] - Major — Falta la decisión de ubicaciones (D8)
*   **Affected Scope:** [Líneas 19-27](../../specs/hito0.md#L19-L27)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** fila nueva **D8**:
    - **Decisión:** ubicación de autoloads, datos, tests y assets.
    - **Propuesta:** `autoload/`, `data/`, `tests/unit/` y `assets/` (`models/`, `textures/`, `audio/`, `fonts/`), en la raíz.
    - **Por qué:** lo pide `CLAUDE.md` (Arquitectura); cada tipo en un único sitio.
    - **Alternativas descartadas:** `core/autoload/` (`core/` no lleva nodos); datos dentro de cada sistema (más difícil de listar y validar).

### [7] [`structural`, `style`, `design`] - Major — D1 se justifica con un acuerdo no escrito
*   **Affected Scope:** [Línea 21](../../specs/hito0.md#L21) (D1)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** Por qué → «Acordado con el usuario (2026-11-17). `res://` = raíz del repositorio, así las rutas de `CLAUDE.md` (`core/`, `presentation/`…) son las mismas en el disco y en Godot. `specs/` y `reviews/` llevan un `.gdignore` para que Godot no las escanee.»

### [8] [`structural`] - Nit — Referencia rota «Verificación»
*   ***AI Suggestion:*** PROPOSE FIX · Línea 4: «Verificación» → «Cómo trabajar».

### [9] [`structural`] - Nit — Las líneas 3 y 4 se juntan
*   ***AI Suggestion:*** PROPOSE FIX · Insertar una línea `>` vacía entre las dos.

### [10] [`design`, `structural`] - Nit — D6 «por defecto»
*   ***AI Suggestion:*** PROPOSE FIX · D6 → «idioma de reserva `es`. Al ser la única traducción, es la que se ve con cualquier idioma del sistema.»

### [11] [`design`] - Nit — D5: el SHA no prueba quién publicó; modo autocontenido
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** comprobar la integridad con el SHA del mismo origen es la práctica oficial de Godot. El modo autocontenido no aplica: la ruta de instalación se comprueba en el paso 6.

### [12] [`design`] - Nit — Puerto y red del addon
*   ***AI Suggestion:*** PROPOSE FIX · Añadir a D4: «En desarrollo abre un servidor TCP sin autenticación en `127.0.0.1:7777` (solo local).»

### [13] [`design`] - Nit — Caché de clases con scripts excluidos
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** si causa un error al arrancar, lo detecta el log de D7. Se revisa con el plan en la etapa 9.

### [14] [`design`] - Nit — Ampliar «fuera de alcance»
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** la integración continua y la firma de código no aparecen en ningún sitio del proyecto, y que `main.tscn` es provisional ya lo dice la línea 78.

### [15] [`style`] - Nit — Redacción
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:***
    - «vacío pero completo» → «sin lógica de juego, que cumple:».
    - «escenas reales» → «escenas del juego».
    - «Gratis» → «Gratuitas».
    - Puntuación final igual en todas las celdas «Por qué».
    - El resto ya queda cubierto por [3] y [5].

## Resumen

| Categoría | Cantidad | Hallazgos |
|---|---|---|
| PROPOSE FIX | 12 | 1-10, 12, 15 |
| DECLINE | 3 | 11, 13, 14 |
| CONTEST / ESCALATE | 0 | — |

**Nota para la etapa 9:** la §4 dice que `/root/MCPRuntime` es «la ruta que espera GoPeak». No es exacto: GoPeak solo necesita el puerto TCP. Se corrige al revisar el plan.
