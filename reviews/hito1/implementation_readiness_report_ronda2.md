# Etapa 9, ronda 2 (revisión final): `specs/hito1.md`, §5-§9

Revisores nuevos: **preparación**, **detalles técnicos** y **estilo**. Los tres terminaron.

**Veredicto:** casi lista. Los arreglos de la ronda 1 están aplicados y no hay contradicciones con el diseño. Quedan **4 fallos que habrían roto algo al implementar**, todos con un arreglo pequeño, y varios detalles.

**Verificado contra los archivos reales:** las búsquedas de la comprobación 2 encajan con el resumen real de GUT; GUT rechaza los argumentos desconocidos; los `.ogg` y el `.tres` se exportan; la ruta de guardado del paso 8 es correcta.

## Fallos que habrían roto algo

| # | Problema | Arreglo |
|---|---|---|
| 1 | **El perfil tranquilo nunca compraría *Dial firme*** (los tres): sin sostener, *Dial firme* aporta 0, y el simulador se salta lo que aporta 0 | El perfil tranquilo pasa siempre `holding = true`, que no tiene efecto hasta comprar *Dial firme*. `manual_cps` es 0,5 antes y 0 después |
| 2 | **Los tests de archivo dañado fallarían** (técnicos, verificado en GUT): GUT 9.7.1 cuenta como fallo los errores del motor y los de `push_error`, y `JSON.parse_string` escribe un error del motor | `SaveSystem` usa `JSON.new().parse(text)` y comprueba el `Error` que devuelve; los avisos van con `push_warning`, nunca con `push_error`; comprueba `file_exists` antes de abrir |
| 3 | **La interferencia no se podría atrapar** (técnicos, preparación): el `ColorRect` hijo se queda con el clic | `Static` y `Hint` con `mouse_filter = MOUSE_FILTER_IGNORE` |
| 4 | **Importar no demuestra que el `.tres` esté bien** (técnicos, preparación): una mejora con un `target_id` mal escrito no haría nada y el test de ritmo pasaría igual. Además, al formato le falta `script = ExtResource(...)` en `[resource]` | Se añade la línea `script`. Primer test de `test_pacing.gd`, `test_config_valid`: carga el `.tres` con `load()` y comprueba 6 generadores y 18 mejoras, `id` únicos e iguales a los de la §3.5, `target_id` existentes, `req_generator_count` de 10 o 25 y que todas las claves tienen traducción |

## Importantes

5. **Los minutos objetivo chocan con el rango de 240-420 s** (preparación): 15 → 22 son 420 s, justo en el borde, y el ritmo varía entre simulaciones. **Arreglo:** mandan los rangos de la §3.5. Los objetivos pasan a 0/5/10/15/20,5/26 (centro del rango), y se te enseña la diferencia con `incremental.md` en el paso 8.
6. **Dos ventanas distintas para «algo nuevo»** (preparación): D14 dice «hasta la última aparición» y la tabla, «hasta *Canal 3*». **Arreglo:** «hasta *Canal 3*» en los dos sitios.
7. **Origen del generador aleatorio de la primera run** (los tres): `RunState.new_run` necesita uno antes de que exista `Economy`. **Arreglo:** `new_run(config, run_index, rng)` recibe el de `Economy`. `Economy._init(config, state = null, rng_seed = -1)` crea la run si `state` es `null`. Así hay un solo generador, sembrado por los tests. El parámetro se llama `rng_seed`, porque `seed` tapa una función global.
8. **La tienda no se vacía al reiniciar** (preparación). **Arreglo:** con `run_restarted` se borran las filas.
9. **`TLR_NO_SAVE`** (los tres): solo lo comprueba `Game`, con `OS.get_environment("TLR_NO_SAVE") == "1"`; `SaveSystem` no lo mira. D10 se reformula así: «`Game` no lee ni escribe `run.json`». En el paso 1, el comando de GUT lleva la variable.
10. **Las filas de la UI no cuadran con el texto** (estilo): el orden de `UI_GENERATOR_ROW` es nombre, poseídos, producción y coste. Además, las mejoras `_10` y `_25` se llamarían igual. **Arreglo:** la segunda pasa a ser `%s ×2 (25)`.

## Menores

11. **Simulador:**
    - orden dentro de cada paso: atrapar → clics → compras → `tick`;
    - termina al llegar al umbral;
    - en caso de empate, gana el primero según el orden del `.tres`;
    - la media se lleva a 35 ± 1 min;
    - se dice «la simulación que atrapa», no «el perfil que atrapa».
12. **Lectura:**
    - `X` ilegible y sin `.bak`: partida nueva;
    - solo hay `.bak` y es ilegible: pasa a `.bak.corrupt`;
    - archivo sin `version`: test;
    - `from_dict` acepta números `int` o `float` e ids `String` o `StringName`;
    - `JSON.stringify` con `full_precision = true`;
    - `save_run` crea la carpeta si falta;
    - en vez de «nunca borra una partida legible», «nunca borra `X` ni `X.bak`».
13. **Paso 6:** borrar `run.json*` antes; hacer los clics con `inject_mouse_click` de GoPeak (grupo `testing`) † y, si no sirve, dejar la compra para tu prueba.
14. **Paso 9:** quitar el [PENDIENTE] de la run 1 en el GDD §4 y limitar el pendiente del §12 a las runs 2-4. `specs/incremental.md` se modifica si apruebas cambios en el paso 8.
15. **Textos y estilo:**
    - el § de `ASSETS.md` en el criterio de cierre;
    - leyenda de †;
    - `kind` en mayúsculas en todo el texto;
    - `buy(id: StringName)`;
    - casos de `NumberFormat` como entrada → salida;
    - `rate` redondea también a partir de 100;
    - `Game` carga `res://data/economy_run1.tres`.
