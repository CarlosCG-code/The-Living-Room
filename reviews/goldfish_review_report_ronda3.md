Status: resolved — el usuario aceptó cerrar por churn y aplicar la pasada final recomendada (arreglos 5, 7, 8, 9 y 10, migrador con test, reloj como único `_process`, tests del director; `ctx`, pausa y variantes recortados a "se especifica en el hito N" con candidatas). El punto 1 pasa a la revisión de GAME_DESIGN.md. Bucle cerrado tras 3 rondas (aceptado por churn).

# Goldfish Review — CLAUDE.md, ronda 3 (detenida por churn)

**Revisores:** `egm-comprehension`, `egm-style`, `egm-inventive-catalyst` (los tres completados) · **Contexto:** `GAME_DESIGN.md`
**Ronda limpia:** no. Llevamos 0 de 2 rondas limpias seguidas.
**Estado:** el bucle se para y te pide decisión, como marca EGM en caso de churn.

## Por qué se detiene: churn

La regla de EGM considera churn un hallazgo nuevo que cae justo en un arreglo ya aplicado y que se resolvería deshaciendo ese arreglo. Los tres hallazgos Major más repetidos de esta ronda cumplen esa condición:

| Hallazgo de la ronda 3 | Arreglo que lo provocó |
|---|---|
| Quién escribe la instantánea `ctx`, en qué orden y quién es dueño de la "producción" | Ronda 2, Issue 8 |
| La "pausa por canal" no cubre audio, animaciones, física ni `SceneTree.paused` | Ronda 2, Issue 8/11 |
| ¿Hay 3 o 4 variantes del piso? ¿Qué es "build"? ¿Qué son las "excepciones como texto"? ¿Y el "perfil de luces"? | Ronda 2, Issue 4 |

Diagnóstico: cada ronda añade a `CLAUDE.md` más detalle de implementación, y ese detalle genera nuevas preguntas de implementación. `CLAUDE.md` está dejando de ser una guía de trabajo y empieza a parecer la especificación técnica de los hitos. Esas preguntas (`ctx`, pausa, técnica del espejo) tienen que resolverse en la especificación de cada hito, con código delante, no en este documento.

## Hallazgos abiertos (deduplicados), por severidad

### Major
1. **Precedencia CLAUDE.md/GDD sin aplicar** (los tres revisores). El GDD §10 todavía admite Fab/itch.io y dice "Godot 4". → Se corrige en la revisión de `GAME_DESIGN.md`, no aquí.
2. **Flujo de `ctx`** (comprehension, catalyst). → Es churn.
3. **Pausa por canal frente a `SceneTree.paused`** (comprehension, catalyst, style). → Es churn.
4. **Variantes del piso: 3 frente a 4, "build", "excepciones como texto"** (los tres). → Es churn.
5. **"Salvo el caso del punto siguiente" apunta al punto equivocado (l.9 → l.10, cuando la excepción está en l.11)** (comprehension). → Error real y barato de arreglar.
6. **`$GODOT` es sintaxis POSIX y no se explica la relación entre MCP `godot`, GoPeak y el addon** (comprehension). → En parte válido. Bash es la shell real del proyecto, pero `$env:GODOT` en PowerShell también funciona.
7. **Excluir el addon de la exportación no basta: registra un autoload (`MCPRuntime`) en `project.godot`, y la build fallaría al arrancar** (catalyst). → **Real y verificado**: el addon de GoPeak registra ese autoload. Arreglo de una línea.
8. **El guardado no aguanta un cierre a mitad de escritura, y el meta-estado (los finales vistos) se perdería** (catalyst). → Real. Arreglo de una línea: escribir a `.tmp` y renombrar, conservar un `.bak`, y guardar el meta-estado en un archivo aparte.
9. **Assets generados por IA: la l.46 parece permitirlos y la l.47 prohibirlos** (style). → Real. Arreglo: los assets generados por IA no son assets permitidos; los modelos de IA de la l.46 son solo para voces y efectos de sonido, y lo generado se registra en `ASSETS.md` con el modelo y su licencia.
10. **"Lo decidido se respeta" no dice qué acción tomar** (style). → Arreglo barato: "no se cambia sin confirmación".

### Nit (resumen)
Redundancias en l.10, l.19, l.29, l.41 y l.46; "con test" ambiguo en l.31; `_process` del reloj frente a l.38; los tests del director de miedo; el responsable de las preguntas del playtest; quién crea `ASSETS.md`; y la técnica alternativa del espejo (kit modular simétrico en lugar de escala negativa), que es buena idea para el hito 2.

## Recomendación (de Claude, el Elephant)

**Aceptar y seguir, con una pasada final pequeña:**
- Aplicar los arreglos reales y baratos: 5, 7, 8, 9 y 10, además de "cada migrador con su test" y "el reloj es el único `_process` con lógica de juego".
- **Recortar** el detalle de `ctx`, la pausa por canal y las variantes del piso a una sola frase cada uno, con este remite: *"se especifica en el hito N"*. Las alternativas que propusieron los revisores (que el reloj construya `ctx`, usar `SceneTree.paused`, el kit modular simétrico) quedan anotadas como candidatas para esa especificación.
- El punto 1 se resuelve en la revisión de `GAME_DESIGN.md`.
- No lanzar una ronda 4 sobre `CLAUDE.md`: seguiría produciendo churn.
