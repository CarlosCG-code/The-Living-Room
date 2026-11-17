# Goldfish Annotated Review Report — Hito 1, etapas 5-7

**Status: resolved** — 21 arreglos aplicados el 2026-11-17; 1 descartado (Z13).

**Target:** `specs/hito1.md` (§1-§4 y lo que de la §5-§9 depende de ellas)
**Hallazgos:** `zoom_out_report.md` (Z), `comprehension_report.md` (C) y `critic_report.md` (K) de `reviews/hito1/`.

Categorías: **PROPOSE FIX** = arreglo propuesto · **CONTEST** = el revisor se equivoca · **DECLINE** = no se toca.

Comprobado con Godot 4.7.2: JSON devuelve todos los números como `float` y corrompe enteros de 64 bits; `DirAccess.rename_absolute` sobrescribe en Windows.

| # | Hallazgo | Sugerencia | Qué cambia en la especificación |
|---|---|---|---|
| K1 / Z2 | Estado aleatorio en JSON | PROPOSE FIX | Sin `rng` en el guardado; nueva semilla al cargar; semilla inyectable solo en tests |
| K2 / C2 / K10 | Ids y tabla de mejoras | PROPOSE FIX | Tabla de generadores con `id`; tabla de las 18 mejoras (id, requisito, coste inicial, efecto); *Pulso* con coste ≤ 7; *Dial solo II* requiere *Dial solo* |
| K3 | Validar el archivo cargado | PROPOSE FIX | Validación de tipos; clave ausente o de otro tipo → ilegible; negativos → 0; enteros convertidos desde `float` |
| K4 / Z1 | El `.bak` puede destruirse | PROPOSE FIX | Lo ilegible pasa a `.corrupt` al cargar; se borra el `.tmp` sobrante; primera vez sin aviso |
| Z5 | Tests y verify tocan la partida real | PROPOSE FIX | Opción `--no-save` (argumento de usuario) que usan `verify.sh` y GUT |
| K5 / C4 / Z10 | Costes y números en pantalla | PROPOSE FIX | `ceil` en costes; Energía truncada; producción con 1 decimal por debajo de 100; formatos > 10⁹ en el hito 4 |
| K6 / C3 | Reglas de la interferencia | PROPOSE FIX | `catch_interference()` (solo activa, una vez, no es clic del dial, sin clics automáticos); intervalo sorteado al terminar; *Reiniciar* la cancela |
| K7 | Mantener pulsado + clics | PROPOSE FIX | Al sostener no hay clics manuales. Perfil activo: 6 clics/s sin sostener. Perfil tranquilo: 0,5 clics/s, y sostiene tras *Dial firme* |
| K8 / Z4 | Valores iniciales y ajuste | PROPOSE FIX | Fórmula `base × factor^posición`; umbral ≥ coste acumulado (≥ 10⁷); ajuste en orden: medir → cerrar la diferencia con las mejoras de clic → fijar la media con el umbral y la escala; D5 reformulada |
| Z3 / C5 / C1 | Test de ritmo bien definido | PROPOSE FIX | Un generador aparece al comprar el anterior; «nuevo» = primera vez visible; retorno = ΔEnergía/s del perfil ÷ coste; regla de los 30 s con los ingresos actuales; 4 simulaciones (2 perfiles × con/sin interferencias); el simulador devuelve una línea de tiempo; tabla de rangos copiada de `incremental.md` §8 |
| K9 | Fuera de alcance | PROPOSE FIX | Sin producción con el juego cerrado; sin comprar ×10 ni vender |
| K11 | Riesgos y justificaciones | PROPOSE FIX | Riesgos de guardado y números en la §9; D9 corregida; D7 sin cita circular; D4 con 24 filas |
| Z6 | Guardar al cerrar | PROPOSE FIX | `auto_accept_quit = false`: se guarda y se cierra; si el guardado falla, se cierra igual |
| Z7 / K16 | Dial pegado | PROPOSE FIX | Se suelta al perder el foco |
| Z8 | Riesgo del test lento | PROPOSE FIX | Se quita (son menos de 1 s) |
| Z9 / K15 | `meta.json` | PROPOSE FIX | Solo se documenta su formato (`last_ending`: `""` o id de un final); no se crea en este hito |
| Z11 | Señales sin uso | PROPOSE FIX | El `EventBus` queda con `purchase_made` y `run_restarted` |
| Z12 | Valores en el GDD | PROPOSE FIX | El GDD solo anota el umbral y remite al `.tres` |
| Z13 | `id` desconocido al cargar | DECLINE | Es una línea y evita perder una partida si se renombra algo; se queda |
| C6 | Referencias externas | PROPOSE FIX | Una línea para `$GODOT`, GoPeak/MCP y `DevBoot`; patrón exacto de la comprobación 2 de `verify.sh` |
| C10 / K17 | Premisa, porqué y build | PROPOSE FIX | Una frase de contexto y del porqué del hito; el usuario juega la build exportada |
| K12-K14, K18-K19, C8-C9, C11 | Detalles | PROPOSE FIX | Multiplicadores que se multiplican; `tick(delta, holding)`; `play_time` por run y contador propio de 5 min; estilo; fuentes |

**Resumen:** 21 PROPOSE FIX, 1 DECLINE, ningún CONTEST.
