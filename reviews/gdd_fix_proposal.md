Status: aplicado — el usuario aceptó todas las propuestas (A1-A4, B, C1-C7).

# Propuesta de correcciones — GAME_DESIGN.md (tras la etapa 5)

Cada punto lleva el número que tiene en `zoom_out_report.md`. No se ha tocado nada todavía.

## A. Alinear con CLAUDE.md (no hace falta decidir nada nuevo)

**A1 · Puntos 1, 2 y 9 — §10 Técnica (l.109-116).** Sustituir toda la sección por:
```markdown
## 10. Técnica

Las decisiones técnicas (motor, versión, arquitectura, verificación y licencias) están en `CLAUDE.md` y mandan sobre este documento. Lo propio del diseño:

- PC (Windows), primera persona; mando opcional **[PENDIENTE]**, se decide en el hito 7.
- Objetivo visual: fotorrealismo oscuro, referencia *Visage*. La técnica de iluminación global (SDFGI, VoxelGI…), la niebla y el postprocesado se eligen en el look-dev del hito 2.
- **TV:** UI del clicker en un `SubViewport` como textura de la pantalla; clic por raycast → UV.
- **Cámara:** rig con valor `reveal` (0–1) que interpola FOV/posición para el zoom out.
- **Assets:** solo CC0 o modelados en Blender, según `CLAUDE.md`.
```
Con esto desaparece la copia desfasada ("Godot 4", Fab/itch.io, PC de desarrollo), la elección de GI deja de hacerse antes de tiempo y el mando queda en [PENDIENTE] (punto 11).

**A2 · Punto 3 — Espejo (l.95).** `el espejo se genera en build` → `la técnica del espejo y de la variante a oscuras se valida en el hito 2`.

**A3 · Puntos 3, 5 y 9 — Hitos 0 y 2 (l.120-123).**
```markdown
0. Proyecto Godot y estructura de carpetas; instalar GUT y el addon de capturas; crear `ASSETS.md`; comprobar que una build exportada arranca sin el addon.
...
2. Tele en habitación + SubViewport + input por raycast.
   - Incluye el **look-dev** del salón en Forward+: validar la calidad visual objetivo (referencia *Visage*) con una sola habitación antes de construir el resto.
   - Validar en esa habitación la técnica del **espejo** y de la variante **a oscuras**.
   - Fijar un presupuesto de frame y presets de calidad (la GI se puede cambiar), para no invalidar el look-dev en el hito 7.
```

**A4 · Punto 14 — Subtítulos (l.81).** Añadir: `Cada evento de audio lleva desde su creación una clave de subtítulo (tr()).`

## B. Asignar sistemas a hitos (punto 4) — propuesta mía, apruébala o cámbiala

```markdown
1. Núcleo incremental + UI plana: reloj, `EventBus`, economía, reinicio básico y guardado (con meta-estado). Validar el ritmo (ver punto C1).
3. Zoom out + audio de la run 1 + **director de eventos** (presupuesto, cooldowns, mirada).
4. Corte vertical: … + Evidencia y pistas del piso del jugador. Playtest con ~5 personas.
5. Run 3 y escalera (incluye jumpscare 1) + ramas de prestigio (Velocidad/Percepción).
```

## C. Decisiones de diseño (son tuyas: doy una recomendación)

**C1 · Punto 6 — Qué valida el hito 1.** *Recomiendo* que valide el **ritmo**: tiempo hasta el primer reinicio y compras por minuto dentro de rangos objetivo, más un efecto provisional (un sonido) en cada compra para notar que "el clicker cambia algo". El "engancha" de verdad se mide en el playtest del hito 4.

**C2 · Punto 7 — Duración.** Las cuentas dan unas 2h35 sin la exploración opcional. *Recomiendo* poner `Duración objetivo: ~2h30–3h según cuánto explore el jugador` (l.8) y `Total estimado: ~2h35 sin exploración opcional; ~2h50 con ella` (l.44). Que Percepción alargue las runs se anota como riesgo de balance [PENDIENTE]: se ajusta con playtests.

**C3 · Punto 8 — Escenarios que faltan.** La **caja de plomos** de la run 2 está en tu piso, así que se añade a "Piso del jugador". El **ascensor** solo aparece roto y no hace falta como escenario. La **caja general** del final secreto: ¿dónde está? *Recomiendo* el **portal / bajo del edificio**, al pie de la escalera, como escenario mínimo. Lo marco [PENDIENTE] si prefieres decidirlo más tarde.

**C4 · Punto 10 — Escalada de miedo.** La tabla pone "objetos que cambian de sitio" en la run 2, pero según la §5 eso es de la run 3. *Recomiendo* mover esa frase de la fila de la run 2 a la de la run 3, para que la run 2 quede en "luces y sonidos" y el espacio (espejo, oscuridad) llegue con el apagón.

**C5 · Punto 12 — Final secreto.** *Recomiendo* que el hito 6 diga: `Run 4 y los finales "Liberarla" e "Irte"; el secreto, si el tiempo lo permite`.

**C6 · Punto 13 — Estado del documento (l.3).** `diseño cerrado en lo esencial` → `diseño cerrado en lo esencial salvo lo marcado [PENDIENTE]`.

**C7 · Punto 15 — Regla 3 frente al final "Irte".** Si te vas, sales sin que nadie ocupe tu lugar, lo que contradice la regla 3. Opciones: (a) es **intencionado**: en "Irte" no sales del bucle aunque lo parezca (bajo los créditos siguen los sonidos de ella). Lo dejo dicho en una línea. (b) Cambiar la regla 3. *Recomiendo* la (a), porque ya encaja con el epílogo actual.
