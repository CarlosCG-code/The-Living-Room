# Comprehension Report — GAME_DESIGN.md (Etapa 6)

**Revisor:** `egm-comprehension` (completado) · **FeatureRange:** líneas 1-119 · **DetailedRange:** líneas 120-139 · **Contexto:** ninguno (el documento se lee solo)

## Qué propone
Un juego de terror psicológico en primera persona para PC, de unas 2h30–3h. Un clicker/incremental que se juega en una tele antigua es la mecánica central. Cada reinicio (prestigio) del incremental dispara un evento narrativo: el repartidor, un apagón con la casa en espejo, la llamada de la vecina del 3.º y, por último, su confesión. El miedo es escalonado (audio, espacio, entorno, identidad) y lo gestiona un director de eventos, sin enemigos ni derrota. La exploración opcional suma "Evidencia". Junto con la rama de prestigio (Velocidad o Percepción), esa Evidencia decide cuánta información tiene el jugador y si se desbloquea un final secreto. Hay tres finales con acción diegética: Liberarla, Irte y Secreto. El plan de desarrollo va en 8 hitos (0-7), con un corte vertical y un playtest en el hito 4.

## Cómo funciona el sistema existente, según este documento
No hay sistema existente: es un diseño nuevo. Lo único previo es `CLAUDE.md`, que según el documento fija motor, versión, arquitectura, verificación y licencias, y tiene prioridad sobre este documento. En la ficción, el "sistema" es el bucle: el juego de la tele consume la electricidad del edificio y cada reinicio deja al jugador más "dentro". Solo se sale si otro ocupa tu lugar frente a la tele. La vecina lleva cientos de reinicios y atrajo al protagonista, un electricista, con una avería.

## Hallazgos

**1. 🟡 Major — Líneas 20, 27 y 38-40 (causalidad del bucle).** La señora "te atrajo a propósito con la avería", pero la avería que se repara es la de la run 3. En la run 1 el protagonista ya está jugando a la tele en su propio piso. No queda claro si el bucle empezó antes de la run 1 (con una avería anterior) o si la run 3 ocurre "antes" en la ficción. Tampoco se explica cómo llegó la tele, o el juego, a su piso. *Razón:* la historia no se puede parafrasear en orden cronológico, y sin ese orden el diálogo de "doble lectura" no tiene a qué anclarse.

**2. 🟡 Major — Líneas 41 y 63 (run 4).** "Cambio de piso sin que el jugador lo note por ir rápido" es ambiguo. No dice de qué piso a cuál cambia, si es un cambio físico o solo de ambientación, ni qué ve el jugador que va lento. "¿De quién es esta casa?" sugiere que el piso de la señora se convierte en el del jugador, pero no se afirma. *Razón:* es el pilar de "identidad" y el paso previo al final.

**3. 🟡 Major — Líneas 102-106 (cómo se elige el final).** "Ignorarla es una respuesta" no se asigna a ningún final. Tampoco se define qué hace que un *Reiniciar* sea "el último", ni qué impide pulsarlo sin querer mientras el clicker sigue activo. El final secreto solo dice "ciertas pistas", sin umbral ni lista, y no está marcado como [PENDIENTE]. *Razón:* es el clímax, y un lector nuevo no puede explicar qué acción lleva a cada final.

**4. 🟡 Major — Líneas 50-53, 91 y 106 (¿ramas exclusivas?).** No se dice si las ramas Velocidad y Percepción se excluyen entre sí, si la elección se puede cambiar entre reinicios, ni cuánta inversión cuenta como "rama Percepción". *Razón:* de esto dependen el final secreto y el balance de la línea 44.

**5. 🟡 Major — Línea 112 (dependencia de `CLAUDE.md`).** Las decisiones técnicas se delegan a `CLAUDE.md`, sin resumen ni enlace. Las líneas 81, 115 y 116 ya usan términos de un motor concreto (`tr()`, `SubViewport`, SDFGI), pero Godot solo se nombra en la línea 122. *Razón:* el diseño no se entiende por sí solo en lo técnico. Bastaría una línea: "motor: Godot 4.x, Forward+; ver `CLAUDE.md`".

**6. 🟡 Major — Línea 123 (criterios del hito 1).** Se piden "rangos objetivo" sin dar cifras y sin marcarlos como [PENDIENTE]. "Meta-estado" no se define. *Razón:* un criterio de validación sin umbral no se puede comprobar.

**7. 🟢 Nit — Línea 122 (hito 0).** No se definen "GUT", "el addon de capturas" ni para qué sirve `ASSETS.md`. Tampoco se explica por qué la build tiene que arrancar sin el addon.

**8. 🟢 Nit — Líneas 127 y 129.** El "presupuesto de frame" no tiene cifra. La Evidencia del hito 4 depende de unas ramas que no llegan hasta el hito 5, y no se menciona.

**9. 🟢 Nit — Líneas 114, 132 y 134-139.** La línea 114 dice que el mando se decide en el hito 7, pero el hito 7 no lo menciona. La lista de decisiones abiertas omite el mando, la técnica de GI y niebla, y el umbral del final secreto.

**10. 🟢 Nit — Línea 40.** En "Él vive en el 8.º", el sujeto es ambiguo justo después de mencionar a "la señora". Se refiere al protagonista.

**11. 🟢 Nit — Líneas 38, 48 y 115.** "Zoom out sutil: es un sofá" es críptico. "Luces reales del piso" significa luces dentro del juego, no reales en sentido literal. *Visage* se cita sin aclarar que es un videojuego.

**12. 🟢 Nit — Líneas 106 y 108.** No se dice qué pasa al cortar la corriente en el final secreto. Aunque los epílogos estén pendientes, el resultado básico de ese final debería aparecer.

## Veredicto del revisor
No hay Blockers: se pudo parafrasear todo el documento. Hay 6 Major que afectan a que el documento se entienda por sí solo, en la narrativa y en las mecánicas.

---

# Re-auditoría de la etapa 6 (tras aplicar gdd_fix_proposal_2.md)

**Revisor:** `egm-comprehension` nuevo (completado) · FeatureRange 1-123 · DetailedRange 124-146
**Resultado:** 0 Blockers; 7 Major y 6 Nit. Los 6 Major anteriores quedan resueltos, salvo matices en la historia (R-1). El revisor pudo resumir todo el documento.
**Límite:** la única re-auditoría de esta etapa ya está usada. Lo que queda abierto pasa a la etapa 7.

## Qué propone (paráfrasis del revisor)
Terror psicológico en primera persona para PC (Godot 4.7.2), de unas 2h30–3h. El clicker se juega en una tele antigua: la Energía sale del edificio, cada compra altera el mundo, y el *Reiniciar* da Carga para dos ramas permanentes. Cada run termina con un evento (repartidor, apagón con la casa en espejo, llamada de la señora, cambio del salón). El miedo crece por capas y lo gestiona un director, sin enemigos y con 2 jumpscares como máximo. Las pistas suman Evidencia. Hay tres finales y un plan de 8 hitos.

## Cómo funciona el sistema existente, según el documento
No hay nada implementado; `CLAUDE.md` manda en lo técnico. En la ficción: la tele, regalo de una vecina, consume la corriente; cada reinicio vacía a quien juega; solo se sale si otro ocupa tu lugar. La señora usa la avería como cebo.

## Hallazgos abiertos
**🟡 R-1 · ¿Una tele o dos? ¿"Una vecina" es la señora?** (líneas 20, 22 y 42). Las frases añadidas en D1 admiten dos lecturas: "frente a la tele de ella" choca con "la misma tele con el mismo progreso". Tampoco se dice de quién es "su primer Reiniciar". Es el giro central de la historia.
**🟡 R-2 · Qué se pulsa en la confesión** (líneas 105-107). No queda claro si hay un botón de clic y otro de prestigio, ni cómo se distingue "seguir clicando" de mantener pulsado *Reiniciar (último)*.
**🟡 R-3 · Estado final de cada personaje** (líneas 107-111 frente a la regla 3). "Todos los finales terminan en el menú alterado; el siguiente eres tú" choca con el secreto ("ambos libres"). En "Liberarla" no se dice que el protagonista quede atrapado.
**🟡 R-4 · Cómo se llega a la caja general** (líneas 99, 101 y 109). La escalera va del 8.º al 3.º, pero la caja está en el portal. No se dice cuándo se puede bajar (¿abandonando el clicker en mitad de la confesión?), y ningún hito construye ese tramo.
**🟡 R-5 · "Deja el mando"** (línea 108). No se define con qué objeto juega el protagonista dentro de la ficción, y "mando" en la línea 118 significa gamepad.
**🟡 R-6 · El "engancha" del hito 4** (línea 127). Va entre comillas sin definir, y no se dice cómo se mide.
**🟡 R-7 · "El addon de capturas"** (línea 126). No se dice qué es ni para qué sirve.
**🟢 Nits:** "Total ~25 min" ambiguo (l.42); qué reparto de Carga suponen las duraciones (l.46 y 56); ¿la silla del menú es una alteración intencionada? (l.107 frente a "sofá"); qué son el "reloj" y el `EventBus` (l.127); "cambio de piso" puede leerse como cambio de planta (l.135); la §10 depende de `CLAUDE.md` (l.115-122).
