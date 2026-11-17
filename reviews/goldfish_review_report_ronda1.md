Status: resolved — ronda 1: 17 fixes aceptados en interactive breakdown (punto 7 revisado con el usuario: todo gratuito y libre, assets CC0, tipografías CC0/OFL); 4 declined; 0 contested; 0 escalated.

# Goldfish Annotated Review Report

**Target:** `CLAUDE.md` (full file, líneas 1-46) · **Ronda:** 1
**Revisores:** `egm-comprehension` (completado), `egm-inventive-catalyst` (completado), `egm-style` (completado)
**Contexto dado a los revisores:** `GAME_DESIGN.md`
**Ronda limpia:** no (1 Blocker y varios Major sin resolver)

Hallazgos deduplicados: 47 hallazgos brutos de 3 revisores → 21 puntos. Cada punto indica qué revisores lo levantaron.

Resumen de sugerencias: 17 PROPOSE FIX · 0 CONTEST · 0 ESCALATE · 4 DECLINE

## Prioritized Findings & AI Suggestions

### [Issue 1] [`inventive-catalyst`, `comprehension`, `style`] - Severity: Blocker
*   **Affected Scope:** [Línea 10](CLAUDE.md#L10-L10) (Cómo trabajar)
*   **Discrepancy Description:** Se piden "capturas de pantalla para revisar el look" con `godot --headless`. En Godot 4, `--headless` usa drivers de pantalla y render vacíos ("dummy"), así que las capturas salen vacías. Tampoco se indica la versión exacta de Godot, ni la ruta del ejecutable en Windows, ni el comando de GUT.
*   **Rationale:** El look-dev del hito 2 depende de este bucle, y el usuario no abre el editor.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** La crítica es correcta. Desde hoy hay un método verificado con renderer real: el MCP `godot` (GoPeak) lanza el juego con Forward+ en la GPU y devuelve la captura (probado: 1152×648 en la RTX 5060 Ti). También detecta errores de GDScript con el LSP del editor en modo headless (probado). El comando de GUT aún no existe porque GUT se instala en el hito 0.
*   ***Proposed Edit:***
    *   Location: línea 10
    *   Change: sustituir por:
        `- Verifica sin el usuario: importación y tests GUT con `godot --headless`; errores de GDScript con el LSP del editor headless (`--editor --lsp-port 6005`); el aspecto visual con capturas del juego ejecutado con renderer real (MCP `godot`/GoPeak, addon `godot_mcp_runtime`). Headless no renderiza: nunca valides el look con él. El usuario solo abre el juego para probarlo y da feedback.`

### [Issue 2] [`inventive-catalyst`, `comprehension`, `style`] - Severity: Major
*   **Affected Scope:** [Línea 46](CLAUDE.md#L46-L46) (Orden de trabajo)
*   **Discrepancy Description:** "El primer objetivo es el corte vertical" choca con "no empezar un hito sin cerrar el anterior": el corte vertical es el hito 4. Además, el paréntesis omite el espejo de la run 2 y el playtest con ~5 personas, que es el criterio de salida del hito 4 en el GDD.
*   **Rationale:** Un agente que solo lea CLAUDE.md no sabe por dónde empezar y cerraría un corte vertical incompleto.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Es una paráfrasis desviada del GDD §11. Es mejor remitir al hito que parafrasearlo.
*   ***Proposed Edit:***
    *   Location: línea 46
    *   Change: `Seguir los hitos de `GAME_DESIGN.md` §11 en orden, empezando por el hito 0. El primer entregable jugable es el **corte vertical (hito 4)**; su alcance y su criterio de salida (playtest con ~5 personas) son los del GDD.`

### [Issue 3] [`style`, `comprehension`, `inventive-catalyst`] - Severity: Major
*   **Affected Scope:** [Línea 8](CLAUDE.md#L8-L8) y [línea 46](CLAUDE.md#L46-L46)
*   **Discrepancy Description:** "Cambios grandes", "pocas líneas" y "cerrar" un hito no tienen criterio.
*   **Rationale:** Estas reglas deciden cuándo parar y esperar al usuario. Si son ambiguas, el comportamiento cambia de una sesión a otra.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Crítica válida. El criterio de cierre propuesto refleja cómo trabajáis ya: el usuario prueba y da feedback.
*   ***Proposed Edit:***
    *   Location: línea 8, más una frase en la línea 46
    *   Change (l.8): `- Para y espera confirmación, con el plan en ≤5 líneas, antes de: empezar un hito, crear o borrar un sistema o carpeta de la arquitectura, cambiar el formato de guardado, añadir una dependencia o addon, o tocar algo de "Decisiones fijadas".`
    *   Change (añadir a l.46): `Un hito se cierra cuando sus tests pasan en headless y el usuario lo aprueba tras probarlo.`

### [Issue 4] [`comprehension`, `inventive-catalyst`] - Severity: Major
*   **Affected Scope:** [Línea 18](CLAUDE.md#L18-L18) y [línea 26](CLAUDE.md#L26-L26) (Arquitectura)
*   **Discrepancy Description:** `core/` no tiene nodos, pero toda la comunicación va por el autoload `EventBus`, que sí es un nodo del árbol. No se explica cómo emite `core/` sin depender del árbol. Además, un bus global para estado continuo (producción por segundo, mirada) se llenaría de señales en cada frame.
*   **Rationale:** Las piezas no encajan: el aislamiento de `core/`, que es lo que lo hace testeable, se rompe.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Es una contradicción real. Un `RefCounted` puede declarar sus propias señales, así que `core/` sigue siendo testeable sin árbol.
*   ***Proposed Edit:***
    *   Location: línea 26
    *   Change: `- `core/` declara sus propias señales (los `RefCounted` pueden) y no conoce el árbol. Un adaptador fino reenvía al autoload `EventBus` solo los eventos discretos (compra, reinicio, pista hallada). El estado continuo (producción, mirada) se consulta, no se emite. Entre sistemas de escena: `EventBus`, no referencias directas.`

### [Issue 5] [`inventive-catalyst`] - Severity: Major
*   **Affected Scope:** [Línea 18](CLAUDE.md#L18-L18) y [línea 34](CLAUDE.md#L34-L34)
*   **Discrepancy Description:** No se dice quién lleva el reloj del incremental. `core/` no puede usar `_process()`, y la línea 34 desaconseja `_process()`. El riesgo es acabar con `Timer` sueltos y desincronizados.
*   **Rationale:** Un reloj único hace los tests deterministas, porque basta con llamar a `tick(delta)` con un delta fijo.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Hueco real en un juego cuya mecánica central depende del tiempo.
*   ***Proposed Edit:***
    *   Location: añadir tras la línea 28
    *   Change: `- Un único reloj (autoload) llama a `core.tick(delta)` y al director de miedo con el mismo delta; la pausa pasa por él. Los tests llaman a `tick()` con delta fijo.`

### [Issue 6] [`comprehension`, `style`] - Severity: Major
*   **Affected Scope:** [Línea 3](CLAUDE.md#L3-L3)
*   **Discrepancy Description:** "Respétalo" no distingue lo decidido de lo marcado como [PENDIENTE] o [DEFECTO] en el GDD. El hito 1 depende de una lista de generadores que está [PENDIENTE].
*   **Rationale:** Sin una regla, el primer hito con lógica se bloquea o se decide de forma arbitraria.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Crítica válida.
*   ***Proposed Edit:***
    *   Location: línea 3, segunda frase
    *   Change: `El diseño completo está en `GAME_DESIGN.md`: léelo antes de cualquier cambio. Lo decidido se respeta; lo marcado **[PENDIENTE]** se propone al usuario antes de fijarlo; lo marcado **[DEFECTO]** se aplica salvo que el usuario diga otra cosa.`

### [Issue 7] [`comprehension`, `inventive-catalyst`, `style`] - Severity: Major
*   **Affected Scope:** [Línea 12](CLAUDE.md#L12-L12) y [línea 42](CLAUDE.md#L42-L42)
*   **Discrepancy Description:** La regla de assets está duplicada y solo cubre CC0 descargable por script. El GDD añade Kenney (CC0) y packs de Fab/itch.io, que tienen otras licencias y suelen exigir cuenta. No hay procedimiento para esos packs ni formato definido para `ASSETS.md`.
*   **Rationale:** Queda ambiguo si esos packs están permitidos, y descargarlos choca con "el usuario no toca nada".
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Crítica válida. Se unifica en una sola regla.
*   ***Proposed Edit:***
    *   Location: borrar la línea 12 y sustituir la línea 42
    *   Change (l.42): `- Assets: solo con licencia comprobada. CC0 (Poly Haven, ambientCG, Freesound, Kenney): descarga por script. Packs de Fab/itch.io: el usuario los descarga a `assets/_inbox/` siguiendo pasos numerados y Claude los importa. Cada asset tiene una entrada en `ASSETS.md`: archivo, fuente (URL), autor, licencia, fecha.`

### [Issue 8] [`comprehension`] - Severity: Major
*   **Affected Scope:** [Líneas 16-23](CLAUDE.md#L16-L23) y [línea 33](CLAUDE.md#L33-L33)
*   **Discrepancy Description:** No se dice dónde van el `EventBus`, los `.tres`, los tests, los textos y los assets, ni con qué mecanismo se separan los textos del código.
*   **Rationale:** Si queda implícito, cada sesión crea estructuras distintas.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El detalle de carpetas se decide en el hito 0. Basta con fijar el mecanismo de textos y obligar a documentar la estructura al cerrar el hito 0.
*   ***Proposed Edit:***
    *   Location: línea 33 y añadir tras la línea 23
    *   Change (l.33): `- GDScript con tipado estático; nombres en inglés; textos del juego en español mediante `tr()` y archivos de traducción CSV de Godot, nunca literales en el código.`
    *   Change (tras l.23): `La ubicación de autoloads, datos `.tres`, tests y assets se fija en el hito 0 y se anota aquí.`

### [Issue 9] [`inventive-catalyst`] - Severity: Major
*   **Affected Scope:** [Línea 9](CLAUDE.md#L9-L9) y [línea 41](CLAUDE.md#L41-L41)
*   **Discrepancy Description:** Escribir a mano en `.tscn` escenas fotorrealistas es lento y frágil, y el documento no dice cómo se generan las variantes del piso (espejo, a oscuras).
*   **Rationale:** El objetivo visual depende de cómo se producen las escenas.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El hueco existe, pero ya hay herramientas instaladas que el revisor no podía conocer: Blender MCP para modelar y exportar glTF, y GoPeak para editar escenas. Basta con nombrarlas. El método de generación del espejo es materia de la especificación del hito 4, no de este documento.
*   ***Proposed Edit:***
    *   Location: añadir tras la línea 11
    *   Change: `- Herramientas: modelado y props en Blender (MCP `blender`) exportados a glTF; escenas y verificación con el MCP `godot`; documentación de Godot 4.7 con el MCP `context7`. Las variantes del piso (espejo, a oscuras) se generan por script desde una sola fuente; se especifica en el hito 4.`

### [Issue 10] [`comprehension`, `style`] - Severity: Nit
*   **Affected Scope:** [Línea 18](CLAUDE.md#L18-L18) y [línea 40](CLAUDE.md#L40-L40)
*   **Discrepancy Description:** Se usan "prestigio" y "reinicio" sin decir que son lo mismo.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El arreglo es barato.
*   ***Proposed Edit:*** l.18: `prestigio` → `prestigio (= reinicio)`.

### [Issue 11] [`comprehension`, `style`] - Severity: Nit
*   **Affected Scope:** [Línea 22](CLAUDE.md#L22-L22)
*   **Discrepancy Description:** "espejo" parece un objeto cuando es una variante del piso, y falta la variante "a oscuras".
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** `- `world/` — piso del jugador (normal / espejo / a oscuras), escalera, piso de la señora.`

### [Issue 12] [`comprehension`, `style`] - Severity: Nit
*   **Affected Scope:** [Línea 11](CLAUDE.md#L11-L11)
*   **Discrepancy Description:** Cambia de tercera a primera persona ("dame"), y "de verdad" y "como último recurso" son relleno.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** `- Si algo exige el editor, da al usuario pasos concretos y numerados.`

### [Issue 13] [`style`] - Severity: Nit
*   **Affected Scope:** [Línea 7](CLAUDE.md#L7-L7)
*   **Discrepancy Description:** "Desarrollador senior" no describe ninguna conducta, y "concisas" y "sin relleno" dicen lo mismo.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** `- Respuestas concisas.`

### [Issue 14] [`style`, `comprehension`] - Severity: Nit
*   **Affected Scope:** [Línea 3](CLAUDE.md#L3-L3) y [línea 41](CLAUDE.md#L41-L41)
*   **Discrepancy Description:** "Godot 4" no fija la versión menor, aunque los flags y GUT dependen de ella. El PC de desarrollo no es una decisión de diseño, y le falta la CPU.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.41: `- Motor: **Godot 4.7.2, renderer Forward+**. Objetivo visual: fotorrealismo oscuro tipo *Visage*.` Y añadir al final de "Cómo trabajar": `- PC de desarrollo: Ryzen 5 9600X + RTX 5060 Ti 16 GB (referencia de rendimiento, no requisito mínimo).`

### [Issue 15] [`comprehension`] - Severity: Nit
*   **Affected Scope:** [Líneas 37-42](CLAUDE.md#L37-L42)
*   **Discrepancy Description:** Faltan decisiones que el GDD da por tomadas: primera persona, PC con Windows y sin estado de derrota.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.39: `- Terror psicológico: **sin enemigos ni estado de derrota**, máximo 2 jumpscares, desactivables. Primera persona, PC (Windows).` (también quita "puro", según `style`).

### [Issue 16] [`inventive-catalyst`] - Severity: Nit
*   **Affected Scope:** [Líneas 18, 23 y 28](CLAUDE.md#L18-L28)
*   **Discrepancy Description:** La Evidencia y el meta-estado entre partidas (el menú alterado) son estado, pero Evidencia está en `narrative/`. Además, el guardado versionado no dice cómo se migra.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.18: añadir `Evidencia, meta-estado entre partidas` a `core/`. l.23: `- `narrative/` — contenido de pistas y finales.` l.28: `- Guardado en JSON con campo de versión y un migrador por versión, con test.`

### [Issue 17] [`style`] - Severity: Nit
*   **Affected Scope:** [Líneas 19, 20 y 23](CLAUDE.md#L19-L23)
*   **Discrepancy Description:** `reveal`, "comprobación de mirada" y "Evidencia" no se entienden sin el GDD.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.19: `rig de cámara (`reveal` 0–1 interpola FOV/posición)`. l.20: `comprobación de mirada (eventos que solo ocurren si el jugador no mira)`. (Evidencia queda glosada en el Issue 16.)

### [Issue 18] [`style`] - Severity: Nit
*   **Affected Scope:** [Línea 18](CLAUDE.md#L18-L18)
*   **Discrepancy Description:** "Testeable." repite la regla de la línea 29.
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** Justifica por qué `core/` no tiene nodos, y quitarlo no aporta claridad.

### [Issue 19] [`style`, `comprehension`] - Severity: Nit
*   **Affected Scope:** [Línea 9](CLAUDE.md#L9-L9)
*   **Discrepancy Description:** "Exportación" es un proceso, no un archivo. Requiere plantillas de exportación y `export_presets.cfg`.
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** La exportación pertenece al hito 7, y sus requisitos se documentarán entonces.

### [Issue 20] [`inventive-catalyst`] - Severity: Nit
*   **Affected Scope:** [Línea 46](CLAUDE.md#L46-L46)
*   **Discrepancy Description:** El orden estricto de hitos descubre tarde los riesgos técnicos. Propone prototipos desechables fuera de orden.
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** El GDD ya adelanta el riesgo visual al hito 2 (look-dev). Permitir prototipos fuera de orden contradice la regla secuencial que el usuario fijó, y es decisión suya.

### [Issue 21] [`inventive-catalyst`] - Severity: Nit
*   **Affected Scope:** [Línea 41](CLAUDE.md#L41-L41)
*   **Discrepancy Description:** El aspecto visual se ajusta al PC de desarrollo sin presets de calidad.
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** El GDD §10 deja los requisitos mínimos para más adelante, y el hito 7 cubre la optimización.
