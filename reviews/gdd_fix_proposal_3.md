Status: aplicado — el usuario aceptó toda la propuesta 3 (M1-M3, N2-N7; N1 y parte de N7 se mantienen).

# Propuesta de correcciones 3 — GAME_DESIGN.md (tras la etapa 8)

Contrastada con todas las decisiones de la etapa 7. No se ha tocado nada todavía.

## Decisiones tuyas

**M2 · Qué pasa si no haces nada al final de la confesión.** Ahora "Ignorarla" exige seguir clicando sin mirarla, y no se dice qué pasa si te quedas quieto.
- *Recomiendo* la versión simple del revisor: `Si al terminar la confesión no has pulsado *Reiniciar (último)* ni has salido del piso (clicando o no), ella misma pulsa *Reiniciar* y se va sin despedirse.` Ignorarla sigue existiendo y tiene el mismo final que "Liberarla", pero ya no depende de la mirada y cubre todos los casos.

**N4 · ¿Dónde ocurre la confesión?** Acordamos que el salón de ella "se convierte en tu piso" y que tú quedas frente a *su* tele.
- *Recomiendo:* **físicamente es su salón (3.º), transformado hasta ser idéntico al tuyo**. Para el jugador es "su piso", pero la tele es la de ella, y así se cumple la regla 3. Para "Irte" y el secreto bajas del 3.º al portal (la escalera ya llega a la planta baja).
- Además, el asiento se llama siempre **sofá** (ahora aparece como sofá, sillón y silla). La **silla** del menú de "Liberarla" se mantiene, porque es la alteración del menú.

## Arreglos (sin decisión nueva)

- **M1 · "Mirar" (§5):** `"Mirar" = el objeto está en pantalla y nada lo tapa; "no mirar" = fuera de pantalla o tapado. La técnica concreta se decide en el hito 3.`
- **M3 · Fotosensibilidad desde el principio:** el hito 3 incluye el tope de 3 destellos por segundo y el parámetro de intensidad en el director. El menú de ajustes y el aviso se quedan en el hito 7.
- **N2 · Meta-estado:** `finales vistos` → `el último final (decide el menú alterado)`, porque nada usa la lista de finales vistos.
- **N3 · Hito 7:** añadir los subtítulos descriptivos y el ajuste para desactivar jumpscares.
- **N5 · Intensidad de efectos:** `al 0 % no elimina el oscurecimiento por producción (es parte de la mecánica); solo limita cuánto bajan las luces`.
- **N6 · Hito 3:** el director incluye la `tensión acumulada`.
- **N7 · Presupuesto de frame (hito 2):** `máquina de referencia y presupuesto de frame [PENDIENTE], fijados en el hito 2`.

## Se mantienen (rebatidos)

- **N1 · Dos mecanismos de reserva:** no son redundantes. "Pasa a otro objeto" sirve para todos los eventos del director (por ejemplo, los objetos que se mueven en la run 3); "cambia en la transición" es solo para garantizar que la run 4 termina en tu piso.
- **N7 · Línea del motor y la §13:** la línea del motor la pidió el revisor de comprensión. La §13 es el resumen de riesgos que aprobaste en el punto 2, con enlaces a las secciones donde se detallan.
