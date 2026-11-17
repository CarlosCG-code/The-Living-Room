Status: aplicado — el usuario aceptó todas las propuestas (D1-D5, E1-E6).

# Propuesta de correcciones 2 — GAME_DESIGN.md (tras la etapa 6)

Incluye los 12 hallazgos de `comprehension_report.md` y los 3 Major que quedaron abiertos en la re-auditoría de la etapa 5 (R1-R3), porque tratan los mismos temas. No se ha tocado nada todavía.

## D. Decisiones de historia y diseño (tuyas; cada una con mi recomendación)

**D1 · Orden de la historia (comprensión 1).** ¿Cuándo empieza el bucle y cómo llega la tele?
- **(a) Recomendada:** la tele llegó a tu piso como "regalo" de una vecina, y la **nota de una vecina** del piso del jugador es esa pista. El bucle empezó la primera vez que pulsaste *Reiniciar*. La avería de la run 3 es el **cebo**: te hace subir para sentarte frente a **su** tele y ocupar su lugar (regla 3). Así encajan "te atrajo con la avería", la regla 3 y el final "Liberarla".
- (b) El bucle empezó antes de la run 1: ya reparaste una avería en su piso y no lo recuerdas.

Texto (a), añadir tras la línea 20: `**Cómo empezó:** la tele llegó al piso del protagonista como regalo de una vecina (la nota es una pista). El bucle empezó con su primer Reiniciar. La avería de la run 3 es el cebo para que se siente frente a la tele de ella y ocupe su lugar.`

**D2 · El cambio de piso de la run 4 (comprensión 2, R3).**
- **Recomendada:** el salón de la señora se va convirtiendo **en el tuyo, objeto a objeto**, y cada cambio ocurre solo cuando no miras (con la comprobación de mirada del director). Quien va rápido no lo nota. Quien presta atención sí, y eso es **intencionado**: es la recompensa de la atención (pilar 3).
- Texto, línea 41: `Parpadeos en el salón de la señora; su salón se convierte en el tuyo objeto a objeto, solo cuando no miras. Quien va rápido no lo nota; quien observa sí (intencionado: premia la atención)`. En el hito 6 se añade: `cambio de piso de la run 4 (usa la mirada del director)`.

**D3 · Cómo se elige el final (comprensión 3 y 12).**
- **"El último Reiniciar":** durante la confesión, el botón cambia a *Reiniciar (último)* y hay que **mantenerlo pulsado 2 segundos**, para evitar pulsarlo sin querer mientras se sigue clicando.
- **Ignorarla (recomendada):** es una variante de "Liberarla". Si sigues clicando sin mirarla, al terminar la confesión ella misma pulsa *Reiniciar* y se va sin despedirse. Alternativa: ignorarla no tiene consecuencia propia.
- **Secreto:** al cortar la corriente se apaga la tele: no hay bucle que alimentar, y ninguno de los dos ocupa el lugar del otro. Los dos quedan libres, con el edificio a oscuras. Las pistas exactas y el umbral de Evidencia quedan en **[PENDIENTE]**.

**D4 · Ramas de prestigio (comprensión 4, R1).**
- **Recomendada:** las ramas **no se excluyen**: la Carga se reparte entre las dos y las compras son **permanentes** (no se puede cambiar el reparto, para que cada decisión pese). "Rama Percepción", a efectos del final secreto, significa haber invertido en ella al menos un X % de la Carga: **[PENDIENTE]**.
- **Hito 4:** incluye una versión mínima de las ramas (1-2 power-ups por rama) para que el playtest mida el ritmo real. El hito 5 completa las ramas.

**D5 · Recompensa de la Evidencia (R2).**
- **Recomendada:** la Evidencia cambia también **los dos finales obligatorios**. Con más Evidencia, la señora confiesa más verdad y el jugador decide sabiendo más. El final secreto pasa a ser un extra, y la rama Percepción ya no es solo un coste si se recorta el secreto.
- Texto, línea 91: `…y si se desbloquea el final secreto. En los finales obligatorios, la Evidencia cambia cuánto confiesa la señora.`

## E. Aclaraciones (no hay nada que decidir)

- **E1 · Motor (comprensión 5).** En la §10: `- Motor: Godot 4.7.2, renderer Forward+ (detalle técnico en CLAUDE.md).`
- **E2 · Hito 1 (comprensión 6).** `rangos objetivo` → `rangos objetivo [PENDIENTE] (se proponen al empezar el hito 1 a partir de la §3: ~35 min hasta el primer reinicio)`. Además, `meta-estado` → `meta-estado (finales vistos, menú alterado; en el hito 1 solo se reserva su archivo y su formato)`.
- **E3 · Hito 0 (comprensión 7).** `instalar GUT y el addon de capturas` → `instalar GUT (tests) y el addon de capturas (solo para desarrollo, por eso la build debe arrancar sin él)`; `crear ASSETS.md` → `crear ASSETS.md (registro de licencias)`.
- **E4 · Hito 2 (comprensión 8; nit de la etapa 5).** `Fijar un presupuesto de frame y presets de calidad (GI conmutable)` → `Fijar un presupuesto de frame [PENDIENTE] y medir el look-dev con GI activada y desactivada; los presets de calidad van en el hito 7`.
- **E5 · Hito 7 y decisiones abiertas (comprensión 9).** Hito 7: `Pulido, accesibilidad (incl. mando opcional), presets de calidad, optimización.` En la §12 se añaden: técnica de GI y niebla (hito 2), umbral y pistas del final secreto, y rangos de ritmo del hito 1.
- **E6 · Redacción (comprensión 10 y 11).**
  - `Él vive en el 8.º` → `El protagonista vive en el 8.º`.
  - `Zoom out sutil: es un sofá` → `Zoom out sutil: se revela que está sentado en un sofá`.
  - `luces reales del piso` → `luces del piso (dentro del juego)`.
  - `referencia *Visage*` → `referencia *Visage* (videojuego de terror, 2020)`.
