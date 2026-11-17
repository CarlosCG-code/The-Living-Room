# Etapa 5 — Zoom out: `specs/hito0.md`

Revisores: **zoom out** (alcance y simplicidad) y **catalizador** (contradicciones y alternativas). Contexto: `CLAUDE.md`, `GAME_DESIGN.md`.

**Veredicto:** se aprueba si se hacen los cambios de abajo. No hay bloqueantes. El alcance cubre todo lo que pide el GDD §11 para el hito 0, y el nivel de detalle es el adecuado.

**Aviso:** ninguno de los dos revisores pudo comprobar el comportamiento real de Godot 4.7.2 (opciones de línea de comandos, salida del `.exe`, contenido del `.pck`). Los hallazgos 2, 3 y 5 son riesgos que hay que confirmar con context7 o con una prueba rápida, no fallos ya demostrados.

## Hallazgos importantes (🟡)

### 1. Las plantillas de exportación sí van dentro del juego (los dos revisores)
- **Dónde:** §4 `ASSETS.md` (línea 90) y D5.
- **Problema:** la spec pone las plantillas en la tabla «solo desarrollo, no van en la build». Pero el `.exe` exportado *es* la plantilla: el motor Godot va dentro del juego. Su licencia MIT, y las de las librerías que incluye (FreeType, mbedTLS…), obligan a incluir sus avisos de licencia con el juego.
- **Cambio:** en `ASSETS.md`, tres grupos: «en la build» (motor Godot 4.7.2, MIT, más los avisos de terceros), «solo desarrollo» (GUT, `godot_mcp_runtime`) y «assets del juego». Anotar que el texto de licencias se incluye más adelante (créditos o un `.txt` junto al `.exe`; hito 7). En el hito 0 no se hace pantalla de créditos.

### 2. La prueba «la build arranca» puede pasar sin pruebas reales (los dos revisores)
- **Dónde:** D7 (línea 27), `verify.sh` (línea 87), §6.
- **Problema:**
  - Un `.exe` de Windows en modo release es una app de ventana. Lo que escribe en pantalla puede no llegar a la consola, así que `verify.sh` leería un log vacío y daría el visto bueno.
  - Godot sale con código 0 aunque haya `SCRIPT ERROR`.
  - En modo `--headless` (sin gráficos) no se inicia el renderer, así que un fallo gráfico al arrancar tampoco se detectaría.
- **Cambio:**
  - Leer el log de un archivo fijo (`--log-file`, si existe en 4.7.2, o el log de `user://logs/`), no de la consola.
  - Exigir una prueba positiva: `main.gd` imprime `BOOT_OK` al arrancar, y D7 pide ese texto, código 0 y ningún `ERROR`.
  - Fallar si el log está vacío o no existe.
  - Opcional: arrancar también sin `--headless` en el PC de desarrollo, para que el renderer real se inicie.

### 3. No se dice cómo comprobar que el addon no está en el `.pck` (los dos revisores)
- **Dónde:** §6, fila `verify.sh (exclusión)` (línea 115), y `export_presets.cfg`.
- **Problema:** Godot no trae ningún comando para listar el contenido de un `.pck`. La spec tampoco dice si el `.pck` va dentro del `.exe` o aparte.
- **Dos soluciones propuestas (hay que elegir una):**
  - **A (zoom out):** `embed_pck=false` (el `.pck` va aparte) y buscar con `grep` los textos `godot_mcp_runtime` y `addons/gut` dentro del `.pck`. Riesgo: GUT declara clases globales, y su nombre podría quedar en la caché de clases aunque sus archivos no se exporten. Eso daría un falso fallo.
  - **B (catalizador):** exportar también un `.zip` con el mismo preset (`--export-pack`) y listarlo con `unzip -l`. Pasa si no hay *archivos* bajo esas carpetas. Cuesta una exportación extra, de unos segundos.
- **Recomendación:** B. Mira archivos reales y no se confunde con menciones sueltas.

### 4. La suposición clave sobre GoPeak se comprueba demasiado tarde (zoom out)
- **Dónde:** D4, `dev_boot.gd` (línea 77), paso 8.
- **Problema:** D4 supone que GoPeak encuentra el addon en `/root/MCPRuntime` aunque no esté registrado en `project.godot`. Si GoPeak exige ese registro, o lo añade él solo, D4 falla. Pero eso solo se prueba en el paso 8, cuando las plantillas y `verify.sh` ya están hechos alrededor de D4.
- **Cambio:** hacer la captura con GoPeak justo después del paso 4. Añadir un riesgo a la §8: «si GoPeak exige o inyecta el autoload en `project.godot`, se revisa D4 antes de seguir».

### 5. El bloqueo de permisos para ejecutar el `.exe` se resuelve cuando ocurre, no antes (catalizador)
- **Dónde:** §8, riesgo 2; §7.
- **Problema:** se acepta que el agente se quede bloqueado a mitad del hito y tenga que pedir ayuda al usuario. Eso choca con «verifica sin el usuario» de `CLAUDE.md`.
- **Cambio:** al aprobar la spec, pedir al usuario una sola vez un permiso limitado para ejecutar solo `build/TheLivingRoom.exe` (y `$GODOT`) con los argumentos de `verify.sh`. El agente no cambia ajustes por su cuenta.

## Detalles menores (🟢)

6. **Carpetas vacías con `.gdkeep` (§3).** No aportan nada al hito 0 y `.gdkeep` no es una convención de Godot ni de git. Basta con anotar las ubicaciones en `CLAUDE.md` y crear cada carpeta cuando llegue su primer archivo. Si se quieren igualmente, usar `.gitkeep`.
7. **`exclude_filter` con entradas que no hacen nada (línea 85).** `tools/*`, `specs/*` y `reviews/*` no se exportan de todos modos. Dejar solo las tres que importan. Opcional: un `.gdignore` en `specs/` y `reviews/` para que Godot no las escanee.
8. **Tests redundantes (§6).** `test_gut_runs` ya queda probado si pasa cualquier test, y `test_main_scene_set` lo cubre D7, que comprueba más. Quitarlos o dejar uno solo como comprobación mínima.
9. **`icon.svg` propio (§3, §4).** Sin `rcedit` el icono no entra en el `.exe` y nada del hito 0 lo necesita. Se puede dejar para más adelante. Si se mantiene, cuesta poco.
10. **«`Label3D` o un texto en pantalla» (línea 78).** Elegir uno, para que la captura del paso 8 tenga un resultado esperado fijo. Propuesta: `Label3D`.
11. **«GUT 9.7.1 es la última versión» (D2).** Es una afirmación que caduca. Mejor: «9.7.1, validada en el paso 5». Además, pasar a la 9.7.0 si falla es cambiar una dependencia, y `CLAUDE.md` exige pedir confirmación, no solo avisar.
12. **Plantillas (D5).** Del `.tpz` basta instalar las plantillas de Windows x86_64 (release y debug).
13. **Alternativa a `DevBoot` (catalizador, opcional).** Registrar `MCPRuntime` en un `override.cfg` solo de desarrollo y excluir ese archivo al exportar. Así no hace falta `DevBoot`. Está sin verificar en 4.7.2 y es un mecanismo poco conocido. Si se mantiene `DevBoot`, `OS.has_feature("editor")` es una condición más estricta que `OS.is_debug_build()`.

## Correspondencia con los informes originales

| Aquí | Zoom out | Catalizador |
|---|---|---|
| 1 | F1 | F3 |
| 2 | F2 | F1 |
| 3 | F3 | F2 |
| 4 | F4 | — |
| 5 | — | F4 |
| 6–10 | F5–F9 | — |
| 11–13 | — | N3, N2, N1 |
