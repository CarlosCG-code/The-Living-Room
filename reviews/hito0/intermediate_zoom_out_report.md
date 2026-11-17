# Etapa 8 — Zoom out intermedio: `specs/hito0.md`

Revisor: **zoom out**. Comprueba qué cambió en las §1-2 tras la etapa 7 y si encajan con el plan (§3-§8). Contexto: `CLAUDE.md`, `GAME_DESIGN.md` y el informe de la etapa 5.

**Veredicto:** se aprueba con cambios. No hay bloqueantes. Los arreglos de la etapa 7 casi no añaden alcance, y D8 es obligatoria (la pide `CLAUDE.md`). Quedan dos puntos de la etapa 5 sin resolver en las §1-2, y hay contradicciones con el plan, que se corrigen en la etapa 9.

## Estado de los hallazgos de la etapa 5

| Etapa 5 | Estado |
|---|---|
| 1. Las plantillas van dentro del juego | **Sin resolver** en D5 (ver A) |
| 2. Prueba de arranque débil | Resuelto en D7 |
| 3. Cómo probar que el addon no está en el `.pck` | **Sin resolver**: ahora es un objetivo, pero ninguna decisión dice cómo se comprueba (ver B) |
| 4. Suposición sobre GoPeak | Resuelto en D4, pero la §4 lo contradice (ver C) |
| 5. Permiso previo para ejecutar el `.exe` | Pendiente; se revisa en la etapa 9 (§7, §8) |
| 7, 11, 13 | Resueltos en D1, D2 y D4 |

## Hallazgos

### 🟡 A. D5 no dice que la plantilla va dentro del juego (línea 27; §4 línea 93)
- **Problema:** el `.exe` exportado *es* la plantilla, así que el motor Godot y sus librerías van en el juego, con avisos de licencia obligatorios. La §4 sigue poniéndolas en «solo desarrollo».
- **Cambio:** añadir a D5: «La plantilla es el motor que va dentro de la build (Godot, MIT, más los avisos de terceros); esos avisos se incluyen en el hito 7.» Los tres grupos de `ASSETS.md` se corrigen en la etapa 9.

### 🟡 B. No se decide cómo probar que el addon no está en la build (línea 14)
- **Problema:** la §1 lo pone como objetivo y el GDD pide que la spec fije la técnica. Godot no tiene ningún comando para listar un `.pck`.
- **Cambio:** añadirlo a D7 o en una fila propia, con la opción B de la etapa 5: exportar también un `.zip` con el mismo preset (`--export-pack`), listarlo con `unzip -l` y pasar si no hay archivos bajo `addons/godot_mcp_runtime/` ni `addons/gut/`.

### 🟡 C. D4 contradice la §4 (línea 26 frente a la 80)
- **Problema:** D4 dice ahora que GoPeak solo se conecta por TCP. La §4 sigue diciendo que el nodo va en `/root/MCPRuntime`, «la ruta que espera GoPeak». El revisor también pide descartar que GoPeak añada el autoload por su cuenta, y hacer la captura antes.
- **Nota de quien resuelve:** que GoPeak no añade el autoload ya lo comprobé en el código, durante la etapa 7 (ver `goldfish_review_report.md`). Solo lo añade la herramienta `add_autoload` si alguien la llama, o el plugin del editor si se activa. El revisor no tenía ese código entre sus archivos.
- **Cambio (etapa 9):** corregir la §4 (el nombre `MCPRuntime` se lo pone el propio addon, línea 24), adelantar la captura a justo después de la importación y añadir el riesgo a la §8.

### 🟢 Menores
- **D.** D7 dice que la captura del paso 8 cubre el renderer, pero esa captura usa la build de depuración. El renderer de la build release solo lo prueba el usuario (§7). Decirlo.
- **E.** D2 pide confirmación antes de pasar a GUT 9.7.0, pero la §8 dice «se prueba y se le indica». Corregir la §8 (etapa 9).
- **F.** Con el `.gdignore` de D1, `specs/*` y `reviews/*` sobran en `exclude_filter`. Además, los `.gdignore` no aparecen en el árbol de la §3 (etapa 9).
- **G.** D8: `tests/unit/` sugiere que habrá otros tipos de test que nada pide; basta con `tests/`. Las cuatro subcarpetas vacías de `assets/` pueden crearse cuando llegue su primer archivo. Anotar en `CLAUDE.md` que `audio/` es código y `assets/audio/` son sonidos.

**También para la etapa 9:** la fila de exportación de la §6 (línea 117) no incluye `BOOT_OK`.

**No comprobado por el revisor:** el código de GoPeak (no lo tenía entre sus archivos) ni el comportamiento real de Godot 4.7.2 en línea de comandos.
