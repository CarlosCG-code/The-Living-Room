Status: resolved — ronda 2: auto accept; 13 fixes aplicados (Issues 1-13); 2 declined (14, 15); 0 contested; 0 escalated.

# Goldfish Annotated Review Report

**Target:** `CLAUDE.md` (full file, líneas 1-51) · **Ronda:** 2 (la ronda 1 está en `goldfish_review_report_ronda1.md`)
**Revisores:** `egm-comprehension` (completado), `egm-inventive-catalyst` (completado), `egm-style` (completado)
**Contexto dado a los revisores:** `GAME_DESIGN.md`
**Ronda limpia:** no (8 Major sin resolver). Rondas limpias seguidas: 0 de 2.

Hallazgos deduplicados: 28 hallazgos brutos → 16 puntos. Uno ya estaba resuelto en la ronda 1 ("Testeable." redundante, que se descartó) y no se reabre.

Resumen: 13 PROPOSE FIX · 0 CONTEST · 0 ESCALATE · 2 DECLINE

## Prioritized Findings & AI Suggestions

### [Issue 1] [`comprehension`, `inventive-catalyst`, `style`] - Severity: Major
*   **Affected Scope:** [Línea 3](CLAUDE.md#L3-L3) y [líneas 46-47](CLAUDE.md#L46-L47)
*   **Discrepancy Description:** No se dice qué documento manda cuando CLAUDE.md y el GDD se contradicen. Por ejemplo, el GDD §10 todavía admite packs de Fab/itch.io. Además, la línea 46 prohíbe "nada que exija cuenta", pero la línea 47 admite Freesound, que exige cuenta.
*   **Rationale:** Cualquier agente puede justificar decisiones opuestas.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Crítica válida. La intención del usuario fue "nada de pago", no "nada con cuenta": ya tiene una cuenta gratuita de Freesound con clave de API configurada. El GDD se corregirá en su propia revisión.
*   ***Proposed Edit:***
    *   l.3: añadir al final: `Si CLAUDE.md y el GDD difieren, manda CLAUDE.md y se corrige el GDD.`
    *   l.46: `nada no comercial (NC) ni que exija cuenta o compra` → `nada de pago ni no comercial (NC); las cuentas gratuitas ya configuradas (Freesound) se permiten`.

### [Issue 2] [`style`, `comprehension`, `inventive-catalyst`] - Severity: Major
*   **Affected Scope:** [Línea 51](CLAUDE.md#L51-L51)
*   **Discrepancy Description:** Dice que el criterio de salida del hito 4 es "el del GDD", pero el GDD solo dice "Playtest con ~5 personas" y no define cuándo se supera. Tampoco queda claro cómo encaja el playtest con la regla general de cierre.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El texto promete una definición que no existe. Las métricas del playtest son una decisión de diseño pendiente, así que van al GDD como [PENDIENTE].
*   ***Proposed Edit:*** l.51: `…su alcance es el del GDD e incluye un playtest con ~5 personas, cuyas preguntas se definen antes de hacerlo; con su resultado el usuario decide si el hito se cierra.`

### [Issue 3] [`style`] - Severity: Major
*   **Affected Scope:** [Líneas 9-11](CLAUDE.md#L9-L11)
*   **Discrepancy Description:** "El usuario no toca código ni el editor", en negrita, choca con la línea 11, que prevé darle pasos para el editor.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.9: `**El usuario no edita código ni usa el editor**, salvo el caso del punto siguiente.`

### [Issue 4] [`style`, `comprehension`, `inventive-catalyst`] - Severity: Major
*   **Affected Scope:** [Línea 12](CLAUDE.md#L12-L12) y [línea 23](CLAUDE.md#L23-L23)
*   **Discrepancy Description:** La línea 12 promete más de lo que dice el GDD ("por script desde una sola fuente", "se especifica en el hito 4") y mete una decisión de arquitectura en el punto de "Herramientas". El GDD dice que la run 2 es a la vez apagón y espejo, así que las variantes no son tres opciones excluyentes. Reflejar la geometría afecta a las normales, al texto y a la GI, y si se aplaza al hito 4 puede obligar a rehacer el look-dev del hito 2.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El análisis técnico es correcto: reflejar con escala negativa invierte el orden de los vértices, invierte el texto y obliga a hornear la GI de nuevo. Decidir la técnica junto al look-dev evita rehacer trabajo.
*   ***Proposed Edit:***
    *   l.12: quitar la última frase (`Las variantes del piso… hito 4.`).
    *   l.23: `` - `world/` — piso del jugador, escalera, piso de la señora, menú principal (tele y silla). Variantes del piso = orientación (normal / espejo, generada en build, GDD §8) × iluminación (normal / a oscuras, perfil de luces). La técnica del espejo (normales, excepciones como texto, GI) se valida en el hito 2 junto al look-dev. `` (incluye el Issue 13).

### [Issue 5] [`style`, `comprehension`] - Severity: Major
*   **Affected Scope:** [Línea 46](CLAUDE.md#L46-L46)
*   **Discrepancy Description:** "Herramientas y modelos" es ambiguo: modelos 3D o de IA. Además, la lista de licencias queda abierta ("…").
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Crítica válida, y hay además un hueco que el revisor no vio. Blender es GPL. Usarlo como herramienta es libre, pero el código GPL no puede ir dentro del juego sin obligar a publicar su código fuente. Hay que separar lo que se usa para desarrollar de lo que se distribuye con el juego.
*   ***Proposed Edit:*** sustituir la segunda frase de la l.46 por: `Herramientas de desarrollo: cualquier licencia libre (incluida GPL, p. ej. Blender). Lo que va dentro del juego (código, librerías, addons): MIT, Apache-2.0, BSD, Zlib, MPL-2.0 o CC0. Modelos de IA que generan contenido: licencia que permita uso comercial de lo generado (MIT, Apache-2.0). Los assets se rigen por el punto siguiente.`

### [Issue 6] [`comprehension`] - Severity: Major
*   **Affected Scope:** [Línea 10](CLAUDE.md#L10-L10) y [línea 8](CLAUDE.md#L8-L8)
*   **Discrepancy Description:** No se dice qué es GoPeak, cuándo se instalan GUT y el addon `godot_mcp_runtime`, ni si están aprobados. Además, `godot` no está en el PATH.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Crítica válida. Hay otro riesgo que el revisor no podía conocer: el addon de capturas abre un servidor TCP dentro del juego, así que hay que excluirlo de las builds que se publiquen.
*   ***Proposed Edit:*** l.10: `godot --headless` → `` `$GODOT --headless` (ruta en la variable de entorno `GODOT`) ``; `MCP godot/GoPeak` → `MCP godot (servidor GoPeak)`; y añadir al final: `GUT y el addon godot_mcp_runtime se instalan en el hito 0; el addon se excluye de toda exportación.`

### [Issue 7] [`comprehension`] - Severity: Major
*   **Affected Scope:** [Línea 19](CLAUDE.md#L19-L19)
*   **Discrepancy Description:** "Meta-estado entre partidas": no se define "partida". No queda claro si es una run o la partida completa, y eso cambia qué se guarda y cuándo se resetea.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.19: `meta-estado entre partidas` → `estado por run y meta-estado que persiste entre partidas completas (p. ej. el menú alterado tras un final)`.

### [Issue 8] [`inventive-catalyst`, `style`, `comprehension`] - Severity: Major
*   **Affected Scope:** [Línea 29](CLAUDE.md#L29-L29), [línea 32](CLAUDE.md#L32-L32) y [línea 21](CLAUDE.md#L21-L21)
*   **Discrepancy Description:** El director de miedo (`fear/`) necesita la mirada, que se calcula en `presentation/`. "Se consulta" implica una referencia directa entre sistemas de escena, lo que está prohibido, y emitirla por el bus contradice la regla. Además, `core.tick()` trata como objeto lo que es una carpeta, y "adaptador fino" no dice dónde vive.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** La contradicción es real. Una instantánea que pasa el reloj resuelve el problema sin referencias cruzadas.
*   ***Proposed Edit:***
    *   l.29: `Un adaptador fino reenvía` → `Un adaptador (autoload) reenvía`; `El estado continuo (producción, mirada) se consulta, no se emite.` → `El estado continuo (producción, mirada) no se emite: viaja en la instantánea del reloj.`
    *   l.32: `` - Un único reloj (autoload) llama a la fachada de `core/` con `tick(delta)` y a `director.tick(delta, ctx)`, donde `ctx` es una instantánea de solo lectura (mirada, producción) que `presentation/` actualiza cada frame. Escala de tiempo por canal (`core`, `fear`); pausar = escala 0 (el final necesita el clicker activo mientras se para lo demás). Los tests llaman a `tick()` con delta fijo. `` (incluye el Issue 11).

### [Issue 9] [`style`] - Severity: Nit
*   **Affected Scope:** [Línea 12](CLAUDE.md#L12-L12)
*   **Discrepancy Description:** La versión del motor se nombra de tres formas ("Godot 4", "4.7", "4.7.2").
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.12: `documentación de Godot 4.7` → `documentación de Godot 4.7.2`. En la l.3 se mantiene "Godot 4" como descripción general.

### [Issue 10] [`style`] - Severity: Nit
*   **Affected Scope:** [Línea 10](CLAUDE.md#L10-L10)
*   **Discrepancy Description:** "Aspecto visual" y "look" designan lo mismo, y "feedback" es un anglicismo innecesario.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** `nunca valides el look con él` → `nunca valides el aspecto visual con él`; `da feedback` → `da su opinión`.

### [Issue 11] [`inventive-catalyst`, `style`] - Severity: Nit
*   **Affected Scope:** [Línea 32](CLAUDE.md#L32-L32)
*   **Discrepancy Description:** "La pausa pasa por él" no dice cómo funciona, y el final necesita que el clicker siga activo mientras se para lo demás.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Queda resuelto dentro del Issue 8 (escala por canal).

### [Issue 12] [`inventive-catalyst`] - Severity: Nit
*   **Affected Scope:** [Línea 33](CLAUDE.md#L33-L33) y [línea 20](CLAUDE.md#L20-L20)
*   **Discrepancy Description:** La conversión de raycast a UV de la tele es la lógica crítica del input y se queda sin test, aunque es matemática pura y no necesita render.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.33: `` - Tests (GUT, en headless) para todo `core/` y para la conversión raycast → UV de la tele, extraída a una función pura. ``

### [Issue 13] [`comprehension`] - Severity: Nit
*   **Affected Scope:** [Línea 23](CLAUDE.md#L23-L23)
*   **Discrepancy Description:** La escena del menú (tele y silla), que cambia según el final, no tiene carpeta asignada.
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Queda resuelto dentro del Issue 4.

### [Issue 14] [`style`] - Severity: Nit
*   **Affected Scope:** [Línea 8](CLAUDE.md#L8-L8) y [línea 41](CLAUDE.md#L41-L41)
*   **Discrepancy Description:** "No cambiar sin preguntar" aparece dos veces.
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** La l.8 es la lista de disparadores y el título de la l.41 avisa en el punto exacto donde se lee. Repetirlo ahí ayuda más de lo que molesta.

### [Issue 15] [`style`] - Severity: Nit
*   **Affected Scope:** [Línea 12](CLAUDE.md#L12-L12)
*   **Discrepancy Description:** "Sin su generación por IA de pago" repite lo que dice la regla de la l.46.
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** Es el único caso concreto en que una herramienta instalada ofrece una función prohibida. Recordarlo donde se nombra la herramienta evita usarla por error.
