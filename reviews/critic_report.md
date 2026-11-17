Status: resolved — interactive breakdown de 19 puntos, todos aceptados (varios corregidos con el usuario: una sola rama de prestigio, confesión en tu piso, menús por final, luces por intensidad, intensidad de efectos en ajustes, autoguardado cada ~5 min, máximo fotorrealismo sin plan B, §10 reescrita). Punto 1 (alternativas) resuelto con los motivos del usuario (§14). GDD reescrito como v0.2.

# Critic Report + resolución — GAME_DESIGN.md (Etapa 7, ronda 1)

**Target:** `GAME_DESIGN.md`, líneas 1-123 (diseño) · **Revisores:** `egm-design` (completado), `egm-structural` (completado), `egm-style` (completado) · **Estándar:** `feature-spec-standard` (design, structural) · **Contexto:** `CLAUDE.md`
También incluye los Major que quedaron abiertos en la etapa 6 (R-1 a R-5). R-6 y R-7 son del plan de hitos y pasan a la etapa 9.
Hallazgos brutos: 52 (+5 de la etapa 6) → **24 puntos**. **Ronda limpia:** no.
Resumen: 17 PROPOSE FIX · 1 CONTEST · 1 ESCALATE · 5 DECLINE.
⚑ = es una decisión de diseño. La propuesta es mi recomendación, no un hecho.

## Prioritized Findings & AI Suggestions

### [1] [`design`, `structural`] — Blocker — Falta la sección "Alternativas consideradas" (todo el diseño)
*   ***AI Suggestion:*** ESCALATE
*   ***Justification:*** El estándar está pensado para especificaciones de software. En un GDD, las alternativas descartadas solo aportan si recogen *tus* motivos reales, y yo no los conozco: inventarlos sería documentación falsa. Opciones: (a) me das los motivos de 3-4 decisiones clave (clicker en la tele, 4 runs, dos ramas, final diegético) y escribo la sección; (b) se acepta como no aplicable a un GDD.

### [2] [`design`, `structural`] — Major — No hay sección de riesgos y mitigaciones
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** añadir al final del diseño una sección `## Riesgos y mitigaciones`, que además recoge los puntos 10, 12 y 13:
    - **Abandono en la run 1** (35 min con solo audio) → cada compra altera el mundo desde la primera y el director coloca ganchos de audio crecientes; se mide en el playtest del hito 4.
    - **Balance de Percepción** (alarga las runs) → rangos por perfil de rama [PENDIENTE]; playtests.
    - **Fotorrealismo solo con CC0 y Blender** → en el hito 2 se fija un listón visual mínimo aceptable como plan B.
    - **Volumen de voz** (confesión de ~20 min con variantes) → estimación de minutos de diálogo [PENDIENTE] antes del hito 6; voces con IA libre o grabadas.
    - **Activar el final sin querer** → mantener pulsado 2 s.
    - **Bloqueos por la mirada** → ver punto 9.
    - **Fotosensibilidad** → ver punto 10.

### [3] ⚑ [`design`, `style`, comprensión R-1] — Major — ¿Una tele o dos? ¿Quién la regaló? (l.20-22 y 42)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Las frases que añadí en la etapa 6 admiten dos lecturas. La lectura que encaja con la regla 3 y con "la misma tele con el mismo progreso" es esta: **un solo juego y dos teles que lo muestran**.
*   ***Proposed Edit:*** sustituir el párrafo "Cómo empezó" por: `**Cómo empezó:** el juego es uno solo y las teles son ventanas a él. La señora del 3.º regaló al protagonista una tele (la nota sin firma de su piso es una pista). El bucle empezó con el primer Reiniciar del protagonista. Para salir, ella necesita que él ocupe su lugar frente a la tele de ella, en su salón: la avería de la run 3 es el cebo.` Regla 3: `…ocupa tu lugar frente a tu tele.` En la l.20 se cambia `Una vecina del 3.º` por `La señora del 3.º`.

### [4] ⚑ [`design`, `style`, comprensión R-4] — Major — Cómo se llega al final secreto (l.99, 101 y 109)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** Escenario 2: `Escalera del 8.º a la planta baja (portal).` Final secreto: `Durante la confesión, el jugador puede dejar la tele y bajar. «Irte» = salir del edificio por el portal sin tocar la caja. «Secreto» = abrir la caja general (solo se puede si se cumplen las condiciones) y cortar la corriente.`

### [5] [`design`, `style`, comprensión R-3] — Major — "Todos los finales terminan en el menú alterado" contradice el final secreto (l.107-111)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.111: `«Liberarla» e «Irte» terminan en el menú principal alterado, sugiriendo que el siguiente en pulsar Reiniciar es el jugador (en «Liberarla», el protagonista ha ocupado el lugar de ella). El «Secreto» termina en un menú con la tele apagada: no enciende.`

### [6] ⚑ [`style`, `design`, comprensión R-2 y R-5] — Major — Qué se pulsa en la confesión y qué significa "deja el mando" (l.105-108)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.105: `La tele muestra dos botones: clic (producción) y Reiniciar. Durante la confesión, Reiniciar pasa a *Reiniciar (último)* y hay que mantenerlo pulsado 2 s; el clic sigue disponible.` En "Irte": `deja el mando y sale` → `se levanta del sillón y sale`. La palabra "mando" queda reservada para el gamepad.

### [7] [`style`] — Major — "Rama elegida", "finales obligatorios" y la condición del secreto escrita de tres maneras (l.55, 94 y 109)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.94: `la rama de power-ups elegida` → `la inversión en la rama Percepción`; `En los finales obligatorios` → `En «Liberarla» e «Irte»`. l.109: `Condición: haber invertido en Percepción al menos el X % de la Carga (§4) y haber encontrado las pistas clave; ambas [PENDIENTE].`

### [8] ⚑ [`design`] — Major — No se define qué permite reiniciar (l.35, 46 y 54-56)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** en la §4: `Reiniciar se habilita al alcanzar el umbral de Energía de cada run [PENDIENTE]; después, el jugador decide cuándo. La tabla de la §3 supone un reparto equilibrado entre ramas; los rangos por perfil de rama son [PENDIENTE].`

### [9] ⚑ [`design`] — Major — "Solo cuando no miras" puede bloquear la partida (l.43 y 70)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** en la §5: `"Mirar" = el objeto está en el cono central de visión y sin obstáculos (raycast). La progresión nunca depende de que un evento de mirada ocurra: si el jugador observa demasiado tiempo, el cambio se hace en el siguiente parpadeo de luz o en otro objeto.`

### [10] [`design`] — Major — No hay previsión para personas fotosensibles (l.43, 50 y 105)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** El riesgo es real: un parpadeo por clic puede superar los 3 destellos por segundo, el límite habitual de accesibilidad (WCAG 2.3.1).
*   ***Proposed Edit:*** en la §6 (o en accesibilidad): `Aviso de fotosensibilidad al iniciar; opción "reducir destellos"; los parpadeos nunca superan 3 por segundo, sea cual sea el ritmo de clic.`

### [11] ⚑ [`design`] — Major — No se define el guardado durante las secuencias ni qué pasa en una partida nueva (l.40-44)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** `Autoguardado al empezar cada run y cada evento. Tras un final, una partida nueva reinicia la Energía, la Carga y la Evidencia; el meta-estado (finales vistos, menú alterado) se conserva.`

### [12] [`design`] — Major — Viabilidad: fotorrealismo, la run 1 y el volumen de voz (l.8, 40 y 119)
*   ***AI Suggestion:*** PROPOSE FIX — queda recogido en la sección de riesgos (punto 2).

### [13] [`style`, `design`] — Major — Duración: el tope de 3 h no tiene respaldo, y "Total ~25 min" es ambiguo (l.8, 42 y 46)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.8: `~2h30–3h` → `~2h35–2h50 según cuánto explore el jugador`. l.42: `Total ~25 min` → `Evento ~25 min`. El riesgo de balance de la l.46 pasa a la sección de riesgos.

### [14] [`style`] — Major — Jumpscare 2 "solo si el final se sostiene con él": falta criterio (l.76)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** `…solo si el final se sostiene con él: **[PENDIENTE]**, se decide con el usuario tras probar el final (hito 6).` Además, l.77: `Desactivados, se sustituyen por un evento de audio sin susto.`

### [15] [`structural`] — Major — La l.77 se pega al ítem 2 de la lista al renderizarse
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Justification:*** Es un error real de CommonMark: la regla de no penalizar y de poder desactivar se leería como si solo afectara al jumpscare 2.
*   ***Proposed Edit:*** añadir una línea en blanco antes de la l.77.

### [16] [`structural`, `style`, `design`] — Major — La leyenda [PENDIENTE]/[DEFECTO] no coincide con CLAUDE.md, y [DEFECTO] no se usa (l.3-4)
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.3-4: `> Estado: lo marcado **[PENDIENTE]** está abierto y se propone al usuario antes de fijarlo; el resto está decidido. Las decisiones técnicas están en CLAUDE.md.` La marca [DEFECTO] se elimina porque no se usa en ninguna parte.

### [17] [`structural`, `style`] — Nit — Redacción
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** l.50: `La producción por segundo se refleja en las luces del piso: parpadeos y bajones.` y `electricidad real del edificio` → `electricidad del edificio`. "Ignorarla" pasa a ser un subpunto propio bajo "Liberarla". `menú inicial` → `menú principal`. Reiniciar siempre en cursiva. Marcar como [PENDIENTE] los niveles de confesión según la Evidencia (l.94). Hito 6 (fuera de rango, se toca de paso): `cambio de piso` → `transformación del salón`.

### [18] [`design`] — Nit — No hay "No objetivos"
*   ***AI Suggestion:*** PROPOSE FIX
*   ***Proposed Edit:*** tras los pilares: `**No objetivos:** multijugador, contenido procedural, combate.`

### [19] [`structural`, `style`] — Nit — La §10 repite el motor y la tele de CLAUDE.md (l.115-122)
*   ***AI Suggestion:*** CONTEST
*   ***Justification:*** La línea del motor se añadió a petición del revisor de comprensión (`comprehension_report.md`, hallazgo 5), que no entendía el diseño sin ella. La tele y el rig `reveal` son mecánicas del diseño, no detalle técnico. La l.115 ya declara que manda CLAUDE.md.

### [20] [`structural`] — Nit — Pseudo-encabezados en negrita · [21] [`structural`] — referencias cruzadas en formatos distintos · [22] [`style`] — frases hiperbólicas o subjetivas ("hacen todo el trabajo", "da más miedo") · [23] [`style`] — "(pilar principal)" y otras redundancias · [24] comprensión — ¿la silla del menú es intencionada?
*   ***AI Suggestion:*** DECLINE
*   ***Justification:*** Son preferencias de formato o intención de diseño expresada a propósito (un GDD transmite tono). La silla del menú de "Liberarla" es la alteración intencionada del menú.
