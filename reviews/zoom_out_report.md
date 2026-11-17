# Zoom Out Report — GAME_DESIGN.md (Etapa 5)

**Target:** `GAME_DESIGN.md`, archivo completo (1-135). Diseño en las líneas 1-117; plan de hitos en las líneas 118-135.
**Revisores:** `egm-zoom-out` (completado), `egm-inventive-catalyst` (completado)
**Estándar:** `zoom-out-standard.md` · **Contexto:** `CLAUDE.md`
**Contexto suficiente (§0):** sí, según los dos revisores.

Hallazgos deduplicados: 23 en bruto → 15 puntos.

## 🔴 Blocker

**1. La política de assets contradice CLAUDE.md**, en la línea 116 (§10). [ambos revisores]
Admite "packs de Fab/itch.io" y pide solo "verificar la licencia". CLAUDE.md, que manda, exige solo CC0 o modelos propios, tipografías CC0 u OFL, y registro en `ASSETS.md`. Tampoco nombra Poly Pizza. Si se sigue el GDD tal como está, pueden entrar en el juego assets con licencias no usables.

## 🟡 Major

**2. La §10 Técnica duplica CLAUDE.md**, en las líneas 109-116. [zoom-out, catalyst]
Repite motor, render, TV, cámara, datos y assets, y esas copias ya están desfasadas: dice "Godot 4" frente a "4.7.2" y repite el PC de desarrollo. Lo más simple es dejar en la §10 solo lo que es de diseño y remitir a CLAUDE.md para lo técnico.

**3. La técnica del espejo se da por cerrada**, en la línea 95, y el hito 2 (líneas 122-123) no la valida. [ambos]
"El espejo se genera en build" es una decisión de implementación. CLAUDE.md la deja abierta para el hito 2, con dos candidatas. El hito 2 debe probar las dos opciones del espejo y la variante a oscuras con la habitación de look-dev.

**4. Hay sistemas centrales sin hito asignado** en la §11. [ambos]
Ningún hito introduce el director de eventos, el reloj, el `EventBus`, el guardado con meta-estado, la Evidencia ni las ramas de prestigio. Sin embargo, el hito 3 (audio de la run 1, eventos que solo pasan si el jugador no mira) y el hito 4 (reinicio con transición) ya los necesitan. CLAUDE.md remite al "hito que introduzca el director", pero ese hito no existe en el plan.

**5. El hito 0 no recoge lo que CLAUDE.md le asigna**, en la línea 120. [ambos]
Falta instalar GUT y `godot_mcp_runtime`, crear `ASSETS.md`, fijar dónde va cada cosa y comprobar que la build exportada arranca sin el addon. Sin GUT no hay tests, y sin tests no se puede cerrar el hito.

**6. El hito 1 valida "que engancha" sin la mecánica que engancha**, en la línea 121 frente a la línea 12. [ambos]
El pilar 2 dice que lo que engancha es que el clicker altere el mundo, y una UI plana no puede comprobarlo. Además, "engancha" no tiene criterio. Propuestas: validar en el hito 1 el ritmo de la economía y del reinicio, o añadir un efecto provisional (sonido o texto) que simule el cambio en el mundo.

**7. Las cuentas de duración no cuadran y dependen de un balance [PENDIENTE]**, en las líneas 38-44 y 8. [ambos]
Sin la exploración opcional salen unas 2h35, por debajo del objetivo de 2h45-3h15. La línea 44 parece contar la exploración dos veces. La rama Percepción reduce la producción, así que alarga justo las runs del jugador al que se quiere premiar. El catalyst propone que el reinicio dependa también de un tiempo mínimo o máximo por run, o de hitos narrativos.

**8. Faltan escenarios** en la §8. [catalyst]
No aparecen la caja general (final secreto), la caja de plomos (apagón) ni el ascensor. Si no están en el piso, ningún hito los construye.

**9. El rendimiento se deja para el final**, en las líneas 111-112 y 128. [catalyst]
Fijar SDFGI/VoxelGI y la niebla volumétrica, validarlo solo en una RTX 5060 Ti y dejar los requisitos mínimos para el hito 7 puede invalidar el look-dev ya aprobado. Propuesta: fijar en el hito 2 un presupuesto de frame, una máquina de referencia mínima y presets de calidad. Según zoom-out, "SDFGI/VoxelGI" se decide antes de tiempo: debería salir del look-dev.

**10. La escalada de miedo no coincide entre §3 y §5**: líneas 39 frente a 60-63. [catalyst]
La §5 dice que la run 2 es "espacio" y la run 3 "entorno" (objetos que se mueven). La tabla de la §3 pone en la run 2 objetos que cambian de sitio. El director no sabe qué presupuesto aplicar en cada run.

## 🟢 Nit

11. **El mando opcional [DEFECTO]** (línea 111) entra en conflicto con el clic en la tele por raycast, que está pensado para ratón. Propuesta: marcarlo [PENDIENTE] o moverlo al hito 7. [zoom-out]
12. **El final secreto es "opcional"** (línea 105), pero el hito 6 promete "los tres finales". Falta un punto de recorte, por ejemplo "dos finales; el secreto si da tiempo". [zoom-out]
13. **"Diseño cerrado en lo esencial"** (línea 3) no cuadra con que la lista de generadores esté [PENDIENTE]. [catalyst]
14. **Subtítulos descriptivos** (líneas 81 y 128): conviene prever el campo de subtítulo (clave `tr()`) en los `.tres` de eventos desde el hito 3. [catalyst]
15. **La regla 3 ("solo se sale si alguien ocupa tu lugar")** frente al final "Irte" (líneas 25 y 104): si la contradicción es intencionada, conviene decirlo. [catalyst]

## No revisado
La coherencia narrativa de §2, §7 y §9 (fuera del alcance de un zoom-out) y la viabilidad técnica de SDFGI y del reflejo en build.

---

# Re-auditoría de la etapa 5 (tras aplicar gdd_fix_proposal.md)

**Revisores:** `egm-zoom-out` (completado), `egm-inventive-catalyst` (completado) · **Target:** líneas 1-139
**Resultado:** 0 Blockers (antes 1). Major: 4 en bruto, que quedan en 3 puntos (antes 9). Los 15 puntos anteriores quedan resueltos.
**Límite:** EGM permite una sola re-auditoría por etapa y ya se ha usado. Lo que queda abierto pasa a la etapa 7 (revisión crítica, con resolución) o se acepta.

## 🟡 Major
**R1. El playtest del hito 4 se hace sin las ramas de prestigio**, que llegan en el hito 5 (líneas 129-130). [ambos revisores]
Son las ramas las que acortan las runs y dan forma al pilar 3. El playtest mediría un ritmo que luego cambia. Opciones: meter en el hito 4 una versión mínima (1-2 power-ups por rama), o añadir un segundo playtest tras el hito 5. Además, la rama Percepción alarga las runs del jugador atento. El catalyst propone que encontrar pistas también dé Energía o Carga, o que el coste del reinicio se adapte al tiempo de la run.

**R2. Casi toda la recompensa de la Evidencia está en el final secreto**, que es justo lo primero que se recortaría (líneas 91, 106 y 131). [catalyst; zoom-out lo plantea como Nit (YAGNI): construir la variable solo cuando haga falta]
Si el final secreto se recorta, la rama Percepción pasa a ser solo un coste. Propuesta: repartir la recompensa entre los finales obligatorios (una línea extra de la señora, un detalle del menú alterado), o retrasar la variable Evidencia hasta el hito 6.

**R3. Cambio de piso de la run 4 "sin que el jugador lo note"** (línea 41). [catalyst]
Depende de que el jugador vaya rápido, y el jugador de Percepción lo notará. ¿Es intencionado? Además, la técnica no tiene hito de validación. Propuesta: cambiar de piso cuando el jugador no mira, usando la comprobación de mirada que ya existe, y validarlo en el hito 2 o nombrarlo en el hito 6.

## 🟢 Nit
- Los rangos de ritmo del hito 1 no tienen cifras: se proponen al empezar el hito, partiendo de las duraciones de la §3. [ambos]
- Las luces y el zumbido dependen de la producción, pero no tienen un canal definido para leerla; deben usar el mismo mecanismo que el director. [catalyst]
- El meta-estado se implementa en el hito 1 aunque no se usa hasta el hito 6: reservar el formato y dejar la lógica para después. [zoom-out]
- Los presets de calidad del hito 2 llegan demasiado pronto: basta con el presupuesto de frame y medir con GI activada y desactivada; los presets van en el hito 7. [zoom-out]
- El "nivel de tensión acumulada" del director (línea 66) no aparece en el hito 3 ni en `CLAUDE.md`. [zoom-out]
- La §8 y la §10 repiten todavía algo de detalle técnico de `CLAUDE.md`. [zoom-out]
