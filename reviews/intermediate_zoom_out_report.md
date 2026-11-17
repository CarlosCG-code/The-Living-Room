Status: resolved — correcciones aplicadas vía gdd_fix_proposal_3.md.

# Intermediate Zoom Out Report — GAME_DESIGN.md v0.2 (Etapa 8)

**Revisor:** `egm-zoom-out` (completado) · **Target:** líneas 1-174 · **Estándar:** `zoom-out-standard.md` · **Contexto:** `CLAUDE.md` y `zoom_out_report.md`
**Veredicto del revisor:** 0 Blockers, 3 Major y 7 Nit. Las mitigaciones son en su mayoría razonables, y quitar la rama Percepción simplifica el diseño y resuelve los R1 y R2 de la etapa 5.

## 🟡 Major
**M1. "Mirar" mal definido para la run 4** (líneas 71 y 44). "Centro de la vista + raycast" deja que un objeto en el borde de la pantalla cambie a la vista del jugador. El requisito debería ser *"el objeto no está en pantalla o está tapado"*, y la técnica concreta la decide el hito 3.
**M2. "Ignorarla" exige clic más mirada para llegar al mismo final, y queda un caso sin definir** (líneas 109-114): el jugador ni reinicia, ni se va, ni clica. Propuesta del revisor: *"al terminar la confesión, si el jugador no ha pulsado Reiniciar (último) ni ha salido, ella pulsa Reiniciar y se va"*. Cubre todos los casos sin depender de la mirada.
**M3. El límite de destellos llega en el hito 7, pero los efectos que limita se construyen en los hitos 3-4** (líneas 81, 142-146). El playtest del hito 4 se haría sin él. Propuesta: el hito 3 incluye el tope de 3 destellos por segundo y un parámetro de intensidad; el menú y el aviso se quedan en el hito 7.

## 🟢 Nit
- **N1.** Hay dos mecanismos de reserva cuando el jugador mira demasiado: "pasa a otro objeto" (l.71) y "lo que falte cambia en la transición" (l.44). Basta con el segundo.
- **N2.** El meta-estado guarda "finales vistos", pero nada lo usa: el menú solo depende del último final.
- **N3.** Al hito 7 le faltan los subtítulos descriptivos y el ajuste para desactivar los jumpscares.
- **N4.** No queda claro dónde ocurre la confesión: ¿el salón de ella (3.º) transformado, o tu piso real (8.º)? Además, se llama sofá, sillón y silla a lo que debería ser el mismo asiento.
- **N5.** No se dice cómo leen la producción las luces y el zumbido (`CLAUDE.md` solo lo define para el director), ni si la intensidad de efectos al 0 % anula también el oscurecimiento por producción.
- **N6.** La "tensión acumulada" del director no aparece en el hito 3.
- **N7.** Hay duplicados: el motor (l.127) y la §13 repiten la §5 y la §9. Además, el presupuesto de frame no tiene una máquina de referencia.

---

# Re-auditoría de la etapa 8 (tras la propuesta 3)

**Revisor:** `egm-zoom-out` nuevo (completado) · **Resultado:** 0 Blockers, 4 Major, 6 Nit. Casi todo lo de la etapa 5 queda resuelto.
**Límite:** la única re-auditoría de la etapa ya está usada. Lo que sigue abierto pasa a la etapa 9 o queda como riesgo aceptado.

## Hallazgos abiertos
- **M1 · La Evidencia solo se recompensa en lo caro o recortable** (los niveles de confesión, que exigen variantes de voz, y el final secreto). En el hito 4 se construye la Evidencia, pero nada la usa hasta el hito 6. Propuestas: en el hito 4 guardar solo qué pistas se han encontrado; los niveles de confesión como frases añadidas a un tronco común; y una recompensa mínima que no dependa del secreto.
- **M2 · "Autoguardado al empezar cada evento" es ambiguo** (¿incluye los sustos del director?) y choca con el aplazamiento del guardado periódico. Propuesta: guardar solo al empezar cada run y cada evento de transición; si se carga a mitad de un evento, este se repite desde su inicio.
- **M3 · El ritmo de las runs 2-4 no se valida en ningún hito.** Además, la referencia "(hito 1)" de la l.56 es incorrecta. Propuesta: fijar los rangos de las mejoras en el hito 4 o 5, y medir las duraciones al cerrar el hito 5 con un test de `core/` con `tick()` simulado.
- **M4 · Salir del piso durante la confesión y volver** no está definido. Propuesta: salir del piso es un punto de no retorno; la puerta se cierra y solo quedan "Irte" o el secreto.

## Ya resueltos (no se reabren)
- **N1:** los dos mecanismos de reserva de la mirada; se mantuvieron con motivo en la propuesta 3.
- **N2:** la línea del motor; se mantuvo a petición del revisor de comprensión.
- **N5:** la etiqueta [DEFECTO]; se mantuvo en la etapa 7 para coincidir con CLAUDE.md.

## Nits nuevos
- **N3:** VoxCPM2 y MOSS-TTS se nombran en un riesgo; mejor remitir a CLAUDE.md.
- **N4:** el mando aparece como [PENDIENTE] pero falta en la §12.
- **N6:** sigue sin definirse cómo leen la producción las luces y el zumbido (hito 3).
