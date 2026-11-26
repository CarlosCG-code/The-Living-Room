# Pendientes del proyecto

Lo que falta para terminar *The Living Room*, en el orden en que se hará. Se actualiza en el mismo commit que cierra o abre algo. El porqué de cada cosa está en `GAME_DESIGN.md` (§11, el plan) y en `specs/`.

**Estado (2026-11-26):** hitos 0, 1 y 4a cerrados; el 2 hecho, falta cerrarlo en el papel. En marcha: **hito 3**, falta la prueba de la run 1 entera.

## Espera una respuesta del usuario

- [x] **Parada 1 del hito 3:** luces, cosas que se mueven y ritmo aprobados (usuario, 2026-11-26).
- [x] Sonidos de ambiente elegidos por el usuario (2026-11-25): grifo del baño y armario del dormitorio, hechos. Los demás propuestos, descartados por ahora.
- [x] Despertador del dormitorio: esfera a la vista (2026-11-25).
- [x] Eco de pasos y puertas: ligero, se queda así (usuario, 2026-11-26).
- [x] Lluvia del salón: se queda como está; es el modelo de realismo para los demás sonidos (usuario, 2026-11-25).
- [ ] Dar por cerrado el hito 2 (todo aprobado sobre la marcha; `specs/hito2.md` dice que falta la parada).
- [x] Textos en el piso en espejo: al revés, como todo lo demás (usuario, 2026-11-24).
- [ ] Desde la run 2, ¿levantarse cuando se quiera? (GDD §12; 4b)
- [ ] Zoom out al pulsar *Reiniciar*, antes de que llamen a la puerta: ¿sí o no? (4b; hoy, no)
- [x] Copia de seguridad: `tools/backup.sh <hito>` la deja en otro disco, por hito y fecha, y la comprueba (2026-11-24).

## Hito 3 — Audio de la run 1 y director de eventos

- [x] 1. Director de eventos, sin sonido.
- [x] 2. Luces que bajan con la producción y ajuste «Intensidad de efectos».
- [x] 3. Sonidos, preludio y fotograma de la tele; prueba de 10 minutos aprobada (2026-11-26).
- [x] 4. Benchmark en los 4 presets (2026-11-26: todos con margen; cifras fuera del repositorio) y documentación: umbral de la run 1 en el GDD §4 y estado de `specs/hito2.md`.
- [ ] 5. **Prueba del usuario: la run 1 entera.**

## Hito 4b — Corte vertical

- [ ] Especificación, con las preguntas de arriba.
- [ ] Repartidor: llaman a la puerta, levantarse animado (sustituye a la Q), recoger la comida y dejarla en la mesa.
- [ ] Run 2: apagón, linterna como mecánica, caja de plomos (modelarla) y fusible, en el piso en espejo.
- [ ] Cosas interactuables (usuario, 2026-11-25): fusibles e inventario pequeño para la run 2; grifos, puertas de armarios, cajones, interruptores y la radio; coger objetos, solo si aporta miedo.
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
