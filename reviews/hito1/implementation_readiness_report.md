# Etapa 9 — Preparación para implementar: `specs/hito1.md`, §5-§9

Ronda 1. Revisores: **preparación**, **detalles técnicos** (leyó el código real del repositorio y de GUT) y **estilo**. Los tres terminaron.

**Veredicto:** todavía no está lista. Hay 3 bloqueantes y unos 12 importantes. El plan no contradice el diseño (D1-D14 y §3-§4), pero deja demasiadas decisiones a quien lo implemente.

## 🔴 Bloqueantes

### 1. `--no-save` hace que GUT no arranque (técnicos B1) — verificado en el código de GUT
- **Problema:** GUT también lee los argumentos que van después de `--`. Si encuentra uno que no conoce, escribe «Unknown arguments» y sale con código 1 antes de ejecutar ningún test (`optparse.gd` líneas 637-644 y 444-455; `gut_cli.gd` líneas 259 y 271-273). La comprobación 2 de `verify.sh` fallaría siempre.
- **Cambio:** el modo sin guardado se activa con una variable de entorno, `TLR_NO_SAVE=1`, en las dos ejecuciones (GUT y la build), y se quita `--no-save`.

### 2. Faltan las interfaces de las clases (preparación B1)
- **Problema:** no se dicen los métodos de `Economy`, `RunState`, `SaveSystem`, `Game` ni `NumberFormat`: constructor, nombre de la compra, parámetros de las señales, consultas que necesita la UI, qué devuelve una carga fallida, cómo ve un test los avisos ni quién suma `play_time`.
- **Caso difícil:** el test de ritmo mide una compra «aplicándola sobre una copia», pero la compra falla si no hay Energía.
- **Cambio:** una tabla con las firmas de cada clase. `Economy` ofrece `income_per_second(manual_cps, holding)` y `gain_if_bought(id, manual_cps, holding)`, que calcula sin comprar.

### 3. Los rangos de ritmo no se pueden convertir en comprobaciones sin decidir (preparación B2)
- **Problema:** no se dice si «3-8 compras por minuto» se mira minuto a minuto o como media, ni hasta cuándo dura cada ventana, ni si cada rango vale para las 4 simulaciones.
- **Choque:** con la última aparición hacia el minuto 28 y *Reiniciar* hacia el 35, «algo nuevo como mucho cada 3 min» fallaría al final de la run.
- **Cambio:** cada rango, con su unidad y su ventana: medias por tramo, de t = 0 hasta la última aparición (no hasta *Reiniciar*), en las 4 simulaciones.

## 🟡 Importantes

4. **El simulador del test de ritmo está a medio definir** (preparación M3, técnicos M4, estilo N1). Falta decir:
   - qué hacer con los clics fraccionarios: un acumulador que llama a `click()` cada vez que llega a 1;
   - si el perfil tranquilo hace clic mientras sostiene: no;
   - cuándo se atrapa la interferencia: en el primer tick en que está activa;
   - la semilla: 1;
   - el tiempo máximo: 60 min, y si se pasa, el test falla;
   - que una compra que no añade nada se salta;
   - que se pueden hacer varias compras por tick;
   - que la línea de tiempo se imprime en `gut.log`;
   - que el paso es `tick(0.25, holding)` con punto decimal, porque `tick(0,25)` es código erróneo.
5. **Las fases no dejan el proyecto en un estado comprobable** (los tres). La comprobación 2 actual de `verify.sh` («2 tests») falla en cuanto se añade un test, y `test_pacing` necesita el `.tres` y el ajuste.
   - **Cambio:** la comprobación 2 se cambia en el paso 1. `test_pacing` se escribe en el paso 3. `test_economy` usa su propia configuración, creada en el código, para no romperse con el ajuste.
6. **La comprobación 2 nueva puede pasar aunque un archivo de test esté roto** (técnicos M1, verificado en GUT): un script con errores se descarta sin contar como fallo.
   - **Cambio:** exigir además `Scripts` igual a 6 y que no haya `SCRIPT ERROR` ni `Parse Error` en el log.
7. **Las ejecuciones de depuración escriben tu partida real** (los tres). La build de depuración y la exportada comparten `user://`, así que la sesión de GoPeak del paso 6 dejaría una partida con una Antena comprada.
   - **Cambio:** el paso 6 se hace con `TLR_NO_SAVE=1`, y antes del paso 8 se borran `run.json*` en `%APPDATA%/Godot/app_userdata/The Living Room/`.
8. **El ajuste no cubre todos los rangos** (preparación M2, estilo M3-M4).
   - Falta un subpaso para los requisitos de aparición y los costes de las mejoras de generador.
   - Falta definir «diferencia» (umbral más tardío menos el más temprano de las 4 simulaciones) y «media» (objetivo: 35).
   - **Regla de parada general:** si algún rango falla al final, se para y se te enseña.
9. **Caso de lectura que falta:** solo existe el `.bak` (preparación M4). Ocurre si el juego se corta entre los dos renombrados.
   - **Cambio:** si falta `X`, se intenta el `.bak` sin crear ningún `.corrupt`. Se añade su test.
10. **Faltan campos, tipos y formato del `.tres`** (preparación M7, estilo N3, técnicos N3).
    - **Cambio:** una tabla de campos con su tipo y valor inicial. Incluye 120/240 s, 8 s, los factores de D7 (60 y 50), el valor base del clic (1) y los 5 min del guardado. También un ejemplo de bloque `[sub_resource]`, marcado †, a confirmar al implementar.
11. **Faltan las claves de traducción y los textos** (preparación M8).
    - **Cambio:** listar cada clave con su texto en español. Las mejoras de generador siguen una regla: «{generador} ×2 (10)». Se mantiene `TITLE`.
12. **La UI no tiene árbol de nodos** (preparación M9, estilo M5 y N8).
    - **Cambio:** una lista de nodos. La capa de interferencia es entera un botón; *Reiniciar* llama a `Game.restart()`; la tienda indica la producción total de cada generador; las filas se crean una vez y se actualizan; el `Game` suelta el dial con `NOTIFICATION_APPLICATION_FOCUS_OUT`. El medidor de señal de `incremental.md` queda fuera de este hito.
13. **`main.tscn` y `main.gd`** (técnicos M3, preparación N1).
    - **Cambio:** la raíz pasa a ser `Main` (`Node`); `main.gd` hereda de `Node` y solo imprime `BOOT_OK`, porque la línea `$Label3D` daría error; el hijo `TvGameUI` es la instancia de la UI.
14. **La lista de archivos está incompleta** (preparación M6, estilo N11): faltan `GAME_DESIGN.md` (§4 y §12), los `*.uid`, `purchase.ogg.import` y `strings.es.translation` regenerado, y la línea de estado de esta especificación.

## 🟢 Menores

15. **Nombres del MCP** (técnicos M6): no es un error. Las dos formas existen; GoPeak da un alias corto a cada herramienta (`lsp-diagnostics` = `lsp_get_diagnostics`, `editor-run` = `run_project`). Se usarán los nombres largos, como en el hito 0, y se mantienen los 10 reintentos de la captura.
16. La Energía se muestra truncada; el límite 99,95 → 100; punto de miles en la producción ≥ 1.000 (`1.555/s`).
17. **Redacción:**
    - «nunca borra nada» → «nunca borra una partida legible»;
    - la aprobación del ritmo se basa en la línea de tiempo, no en jugar 35 minutos;
    - enseñarte la captura del paso 6;
    - comprobar en una segunda captura que la producción pasa a `0,2/s`.
18. **Kenney:** nombrar el archivo exacto y su URL. **Tests de guardado:** carpeta `user://test_save/`, que se borra en `after_each`.
19. **Elementos de tipo incorrecto dentro de `generators` o `upgrades`:** hacen ilegible el archivo.
20. **Efectos aprobados:** si el ajuste cambia alguno de los efectos aprobados (4 clics/s, ×2), se te enseña en el paso 8.
21. Las mejoras de generador tienen `req_energy_produced = 0`.
