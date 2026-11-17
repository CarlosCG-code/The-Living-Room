Status: resolved — auto accept; 15 fixes aplicados (1-15), 1 contested (16). Revisión EGM de GAME_DESIGN.md concluida (etapas 5-9).

# Implementation Readiness Report + resolución — GAME_DESIGN.md §11 (Etapa 9, ronda 1)

**Target:** líneas 134-147 (plan de hitos) · **Revisores:** `egm-implementation-readiness` (completado), `egm-codebase-details` (completado), `egm-style` (completado) · **Estándar:** `implementation-readiness-standard` · **Contexto:** `CLAUDE.md`
Incluye los 4 Major abiertos de la re-auditoría de la etapa 8.
Hallazgos brutos: 45 (+4 de la etapa 8) → **16 puntos**. **Veredicto de los revisores:** no pasa; la §11 es una hoja de ruta, no un plan de implementación.
Resumen: 15 PROPOSE FIX · 1 CONTEST · 0 ESCALATE · 0 DECLINE. ⚑ = decisión de diseño; la propuesta es mi recomendación.

## Prioritized Findings & AI Suggestions

### [1] [`impl-readiness`, `codebase-details`] — Blocker — Ningún hito tiene archivos, pasos ni casos de test
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Es cierto, pero escribir ahora el detalle de los 8 hitos sería trabajo que se tiraría: el código y las decisiones de cada hito cambian lo siguiente. El propio revisor propone la solución: **cada hito empieza con su especificación de implementación** (archivos, pasos, decisiones [PENDIENTE] que hay que cerrar y casos de test), revisada con EGM y aprobada por el usuario. `CLAUDE.md` ya obliga a confirmar un plan antes de empezar cada hito; esto lo concreta.
*   ***Proposed Edit:*** al principio de la §11: `Cada hito empieza con su especificación de implementación (archivos, pasos, decisiones [PENDIENTE] a cerrar y casos de test), que se revisa con EGM y el usuario aprueba antes de escribir código. Al cerrar cada hito se comprueba que la build exportada arranca.` También se añade a "Orden de trabajo" en `CLAUDE.md`.

### [2] [`codebase-details`, `impl-readiness`] — Blocker — No se define cómo se quitan el addon y su autoload `MCPRuntime` de la build
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El riesgo es real y lo comprobé ayer: el plugin de GoPeak registra `MCPRuntime` en `project.godot`, así que filtrar sus archivos no basta. Se decide en la especificación del hito 0 con documentación de Godot 4.7.2 (Context7). Candidatas: un `EditorExportPlugin` que quite el autoload al exportar, o cargar el addon solo en compilaciones de depuración.
*   ***Proposed Edit:*** hito 0: `…comprobar que la build exportada arranca sin el addon de capturas (godot_mcp_runtime) ni su autoload MCPRuntime (sale con código 0 y sin errores en el log); la técnica de exclusión y la instalación de las plantillas de exportación se fijan en su especificación.`

### [3] ⚑ [`impl-readiness`, `codebase-details`] — Blocker — El hito 1 construye una economía que sigue [PENDIENTE]
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** hito 1, primer paso: `Proponer al usuario la lista de generadores (con su efecto en el mundo), sus costes, el umbral de Energía de la run 1 y los rangos de ritmo.`

### [4] [`codebase-details`, `impl-readiness`, etapa 8 M3] — Major — El *Reiniciar* del hito 1 y la Carga no cuadran entre la §4 y la §11; el ritmo de las runs 2-4 no se mide nunca
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** §4 l.56: `(hito 1)` → `(hito 4)`. Hito 1: `En el hito 1, Reiniciar vacía la Energía y suma una run; la Carga y las mejoras llegan en el hito 4.` Hito 5: `Al cerrar el hito, un test de core/ simula las runs 1-4 con tick() y comprueba que las duraciones caen en los rangos de la §3.` La validación de ritmo del hito 1 se hace igual: con una simulación determinista y una forma de comprar fija.

### [5] [`codebase-details`, `impl-readiness`] — Major — Faltan sistemas sin hito asignado
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:***
    - **Hito 0:** traducción (CSV, idioma `es`, `tr()` desde el primer texto).
    - **Hito 1:** el adaptador entre `core/` y el `EventBus`.
    - **Hito 2:** apuntar y clicar en la tele en primera persona.
    - **Hito 4:** controlador en primera persona (andar, mirar), interacciones (puerta, comida, linterna, caja de plomos, fusible), la animación de levantarse y el menú principal básico.
    - **Hito 6:** las variantes del menú por final y la partida nueva que conserva el meta-estado.

### [6] [`codebase-details`, `impl-readiness`, etapa 8 M3 previo] — Major — La fotosensibilidad llega después del playtest
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Hay personas externas en el playtest del hito 4 y los parpadeos existen desde el hito 3. Es un riesgo de seguridad.
*   ***Proposed Edit:*** hito 4: `+ aviso de fotosensibilidad y ajuste de intensidad de efectos (antes del playtest)`. El hito 7 se queda con el menú de ajustes completo.

### [7] [`codebase-details`, `impl-readiness`] — Major — El hito 3 no recoge las decisiones que tiene asignadas
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** hito 3: `Su especificación decide: técnica de la mirada, cómo se arma el estado que recibe el director, la pausa del menú y la congelación parcial del final (CLAUDE.md), qué controla el zoom out y dónde se guarda la intensidad de efectos. Cada evento de audio lleva su clave de subtítulo desde que se crea.` (Incluye el hallazgo de los subtítulos.)

### [8] [`codebase-details`, `impl-readiness`] — Major — El hito 6 omite partes del final y deja el secreto ambiguo
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** hito 6: `Run 4 (transformación del salón; usa la mirada), escalera hasta el portal, confesión con niveles según la Evidencia y sus voces, Reiniciar (último) con pulsación de 2 s, finales «Liberarla», «Ignorarla» e «Irte», variantes del menú y partida nueva. Final secreto: el usuario decide al cerrar el hito 6 si entra ahora o se pospone. Decidir el jumpscare 2.`

### [9] [`codebase-details`, `impl-readiness`, `style`] — Major — El hito 2: criterio de salida, GI y máquina de referencia
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El objetivo de "máximo fotorrealismo" lo fijaste tú y se mantiene; lo que faltaba era el criterio de cierre, que es tu aprobación. La máquina de referencia ya la fija `CLAUDE.md` (el PC de desarrollo).
*   ***Proposed Edit:*** `Look-dev del salón del jugador: iterar hacia el máximo fotorrealismo alcanzable con assets gratuitos, Blender y Godot, comprobándolo con capturas, hasta que el usuario lo apruebe. Su especificación elige la GI (SDFGI, VoxelGI o LightmapGI) y la niebla. Presupuesto de frame [PENDIENTE] sobre el PC de desarrollo (CLAUDE.md).` Además, `Tele en habitación` → `Tele en el salón del jugador`.

### [10] [`codebase-details`, `impl-readiness`] — Major — Dependencias del hito 0 sin versión ni licencia
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** hito 0: `GUT (versión compatible con 4.7.2) y godot_mcp_runtime: versión, origen y licencia se fijan en su especificación y se registran en ASSETS.md (sección de dependencias). Las ubicaciones elegidas se anotan en CLAUDE.md.`

### [11] [`codebase-details`, `impl-readiness`] — Major — El formato de guardado del hito 1 no está definido
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** hito 1: `Su especificación fija las rutas user://, el esquema JSON (versión 1), el formato reservado del meta-estado (último final) y qué hacer con un archivo corrupto (cargar el .bak). El hito 4 amplía el esquema con una migración a la versión 2 y su test.`

### [12] ⚑ [etapa 8 M2] — Major — "Autoguardado al empezar cada evento" es ambiguo
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** §3: `cada evento` → `cada evento de transición (repartidor, apagón, avería, confesión), no los sustos del director`. Y añadir: `Si se carga a mitad de un evento, este se repite desde su inicio.`

### [13] ⚑ [etapa 8 M4] — Major — Salir del piso durante la confesión y volver
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** §9: `Salir del piso es un punto de no retorno: la puerta se cierra detrás del jugador y la decisión queda entre «Irte» y el final secreto.`

### [14] ⚑ [etapa 8 M1] — Major — La Evidencia solo se recompensa en lo caro o lo recortable
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** §7: `Los niveles de confesión son frases añadidas a un tronco común, no versiones completas (menos voz que grabar o generar).` Hito 4: `Evidencia = registro de qué pistas se han encontrado.` Y la recompensa mínima que no depende del final secreto: `con más Evidencia, la señora confiesa más`. Esa recompensa ya existe y deja de depender del secreto.

### [15] [`style`] — Nit — Redacción del plan
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** `El "engancha"` → `Si los jugadores quieren seguir tras el primer reinicio (pregunta del playtest)`; `addon de capturas` → `addon de capturas (godot_mcp_runtime)`; quitar la frase repetida "por eso la build debe arrancar sin él"; `(1-2)` → `1-2 mejoras de prestigio`; `desde el principio` → `implementados en este hito`; hito 7: `optimización hasta el presupuesto de frame del hito 2`.

### [16] [`codebase-details`] — Nit — El sonido provisional del hito 1 no tiene licencia definida
*   ***AI Suggestion:*** CONTEST
*   ***Justification:*** `CLAUDE.md` ya obliga a que todo asset sea CC0 y quede registrado en `ASSETS.md`, sin excepciones. Repetirlo en cada hito duplicaría la regla.
