# Etapa 6 — Prueba de comprensión: `specs/hito1.md`

Un lector nuevo leyó **solo la spec** y la explicó con sus palabras. Diseño = líneas 1-89; implementación = líneas 90-158.

## What this proposes

El hito 1 permite jugar la run 1 entera en una UI 2D plana, antes de que exista la tele 3D.
- Al hacer clic en el dial se gana Energía.
- La tienda vende 6 generadores y 18 mejoras de un solo uso: 12 de generador y 6 de clic o de clic automático.
- Una interferencia temporal se puede «atrapar» con un clic para ganar una recompensa instantánea.
- Al producir 550.000 de Energía en la run, *Reiniciar* vacía la run y suma 1 al contador; por ahora, las runs 2+ usan la configuración de la run 1.

**Cómo está construido:**
- La lógica vive en clases sin escena (`core/`). Tres autoloads la conectan con la UI: `EventBus` (solo señales discretas), `Game` (posee el núcleo y guarda solo) y `GameClock` (el único `_process` con lógica).
- El guardado es JSON con versión, en `run.json` y en un `meta.json` reservado. La escritura es atómica y conserva un `.bak`. Si los dos archivos fallan, se renombran a `.corrupt` y se empieza de nuevo.
- Un test determinista ajusta los números del `.tres` hasta cumplir los rangos de tiempo aprobados.

El hito se cierra con los tests en verde, `VERIFY OK`, una captura y la aprobación del usuario tras jugar.

## How the existing system works, per this document

Existe el proyecto Godot del hito 0:
- el autoload `DevBoot`;
- `main.tscn`, con cámara, luz y `Label3D`, y `main.gd`, que imprime `BOOT_OK`;
- GUT con `test_smoke.gd`;
- `tools/verify.sh`, con comprobaciones numeradas; la 2 depende del número de tests.

`CLAUDE.md` fija la arquitectura y el formato de guardado. `GAME_DESIGN.md` y `specs/incremental.md` contienen el diseño aprobado, incluidos los rangos de ritmo. El hito 0 definió los procedimientos del LSP y de las capturas con GoPeak, que esta spec reutiliza.

**Conclusión:** la paráfrasis coincide con lo que se pretende. Lo que falta es concreción en varios puntos, no comprensión del diseño.

## Hallazgos

> Los puntos 7 (`.bak`) y 3 de la etapa 5 coinciden con los que aquí se numeran 7 y 5.

### 🟡 Importantes

1. **No se ven los rangos que comprueba el test de ritmo** (§1, §3, §6 paso 3, §7). Solo se citan como «`specs/incremental.md` §8 / §2». **Cambio:** copiar en la spec una tabla corta con los rangos y los minutos de las mejoras de clic, y decir que `incremental.md` sigue siendo la fuente.
2. **No se puede reconstruir la lista de mejoras** (§3, §5, D4). No se dice que hay dos «×2 al clic» (*Pulso* y *Pulso fuerte*), D4 dice «20 archivos para 20 filas» cuando son 24 (6 generadores + 18 mejoras) y no se listan los `id`. **Cambio:** añadir una tabla de mejoras (id, nombre, requisito, coste, efecto) y usar esos `id` en el ejemplo de JSON.
3. **La interferencia está poco definida** (D7, §5, §7).
   - No se dice qué es «atraparla», ni si el dial se bloquea mientras está.
   - «Cada 120-240 s» y «la primera no antes del minuto 2» se solapan.
   - No se dice desde cuándo se cuenta el intervalo, en qué momento se calcula la recompensa, qué pasa si se acaba el tiempo ni a qué valor vuelve el temporizador al reiniciar.

   **Cambio:** fijar cada uno de esos puntos.
4. **Formato de números** (D13). Las producciones con decimales (0,2/s) saldrían como 0, y no se dice si se redondea o se trunca. **Cambio:** un decimal por debajo de 100 para las producciones, y redondeo.
5. **El test de ritmo no está definido del todo** (§7).
   - Falta la fórmula de «mejor retorno» y en qué se basa la regla de los 30 s.
   - «0,5 y 6 clics por segundo» se puede leer como tres perfiles (0; 5; 6).

   **Cambio:** dar la fórmula y listar las simulaciones una a una.
6. **Referencias externas sin explicar** (§6). GoPeak, `$GODOT`, `DevBoot` y los procedimientos del hito 0 solo se nombran, y la nueva regla de la comprobación 2 de `verify.sh` es vaga. **Cambio:** una línea para cada uno y el patrón exacto del log.

### 🟢 Menores

7. **`.corrupt` y `.bak`:** dar los nombres exactos de los archivos resultantes y apartar el archivo dañado antes de la siguiente escritura (ver la etapa 5, punto 1).
8. **Cómo se combinan los multiplicadores:** decir que se multiplican entre sí (dos ×2 dan ×4) y si soltar el dial con *Dial firme* activo cuenta también como un clic.
9. **Guardado periódico:** decir si los «5 min de juego» se miden con `play_time`, si `play_time` vuelve a cero al reiniciar y cuándo se escribe `meta.json`.
10. **Contexto y build:** una frase con la premisa del juego, y decir qué build juega el usuario en el paso 8.
11. **«Los `id` de los `.tres`»:** son el campo `id` de cada `GeneratorDef` y `UpgradeDef` dentro de un solo `.tres`.
