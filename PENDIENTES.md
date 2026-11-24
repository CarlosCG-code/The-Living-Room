# Pendientes del proyecto

Lo que falta para terminar *The Living Room*, en el orden en que se hará. Se actualiza en el mismo commit que cierra o abre algo. El porqué de cada cosa está en `GAME_DESIGN.md` (§11, el plan) y en `specs/`.

**Estado (2026-11-24):** hitos 0, 1 y 4a cerrados; el 2 hecho, falta cerrarlo en el papel. Siguiente: **hito 3**.

## Espera una respuesta del usuario

- [ ] Empezar el hito 3 (`specs/hito3.md`, v3 con sus decisiones).
- [ ] Dar por cerrado el hito 2 (todo aprobado sobre la marcha; `specs/hito2.md` dice que falta la parada).
- [x] Textos en el piso en espejo: al revés, como todo lo demás (usuario, 2026-11-24).
- [ ] Desde la run 2, ¿levantarse cuando se quiera? (GDD §12; 4b)
- [ ] Zoom out al pulsar *Reiniciar*, antes de que llamen a la puerta: ¿sí o no? (4b; hoy, no)
- [ ] Copia de seguridad: texturas, geometría y descargas solo están en el PC (fuera de git desde el 2026-11-19).

## Hito 3 — Audio de la run 1 y director de eventos

- [ ] 1. Director de eventos, sin sonido.
- [ ] 2. Luces que bajan con la producción y ajuste «Intensidad de efectos».
- [ ] 3. Sonidos, preludio y fotograma de la tele. **Prueba del usuario: 10 minutos.**
- [ ] 4. Benchmark y documentación (de paso: umbral de la run 1 en el GDD §4 y estado de `specs/hito2.md`).
- [ ] 5. **Prueba del usuario: la run 1 entera.**

## Hito 4b — Corte vertical

- [ ] Especificación, con las preguntas de arriba.
- [ ] Repartidor: llaman a la puerta, levantarse animado (sustituye a la Q), recoger la comida y dejarla en la mesa.
- [ ] Run 2: apagón, linterna como mecánica, caja de plomos (modelarla) y fusible, en el piso en espejo.
- [x] Piso en espejo al día con el normal (2026-11-24); normales, ciudad, lluvia, puertas y tele (salvo la imagen de la pantalla) también reflejadas; comparado en las 21 zonas; desde ahora se cambian los dos a la vez.
- [ ] Evidencia: pistas del piso del jugador (GDD §7) y su registro.
- [ ] Guardado ampliado, con migración y test; guardar la posición.
- [ ] Pausa de pie e invertir el eje Y.
- [ ] Pasos según el suelo y mezcla de sonido por run.
- [ ] Incremental en la run 2: la tele se ve como en el piso normal (usuario, 2026-11-24); aviso previo de «Tus ojos».
- [ ] Aviso de fotosensibilidad al arrancar.
- [ ] **Playtest con ~5 personas** (Claude propone las preguntas).

## Hito 5 — Run 3 y escalera

- [ ] Señora del 3.º, escalera a oscuras del 8.º al 3.º, jumpscare 1 y su sustituto de audio.
- [ ] Piso de la señora (salón y recibidor), avería, café y la tele con el mismo progreso.
- [ ] Cambios del entorno: fuera de cuadro o en apagones (GDD §5).
- [ ] Incremental: más mejoras, árboles que desaparecen, balance de las runs 2-4 y test de duración de las cuatro runs.
- [ ] Balance: `gain_if_bought` infravalora un poco las sinergias (`core/economy.gd`).

## Hito 6 — Run 4 y finales

- [ ] Salón de la señora que se convierte en el del jugador (GDD §5).
- [ ] Confesión con niveles según la Evidencia, y sus voces (minutos de diálogo antes de empezar).
- [ ] *Reiniciar (último)* manteniendo 2 s; finales «Liberarla», «Ignorarla» e «Irte»; menús alterados y partida nueva.
- [ ] Final secreto (caja general) y jumpscare 2: el usuario decide al cerrar el hito.
- [ ] Epílogos, niveles de confesión y umbral de Evidencia: por escribir.
- [ ] Cifras de runs anteriores en la tele de la run 4.

## Hito 7 — Pulido

- [ ] Accesibilidad: subtítulos descriptivos, desactivar jumpscares, ajustes completos, mando opcional.
- [ ] Música (si la hay), idiomas y voces.
- [ ] Optimización final en los 4 presets y prueba en una gráfica modesta o integrada (nunca medida).

## Antes de distribuir

- [ ] Borrar las 138 texturas sin uso (91 MB) de `assets/models/living_room/textures`.
- [ ] Avisos de licencia junto al juego (ya se generan para la versión de pruebas).
- [ ] Probar en otro PC.
