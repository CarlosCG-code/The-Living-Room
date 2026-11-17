# Goldfish Annotated Review Report — Etapa 9

**Status: resolved** — los 25 arreglos aplicados el 2026-11-17 (aprobados por el usuario).

**Target:** `specs/hito0.md` (líneas 32-130: §3-§8; más los arrastres de la etapa 8 en D5 y D7)
**Hallazgos:** `reviews/hito0/implementation_readiness_report.md` (numeración igual)

Categorías: **PROPOSE FIX** = arreglo propuesto · **CONTEST** = el revisor se equivoca · **DECLINE** = no se toca.

## Cómo se aplicará

Las §3-§8 se reescriben enteras, con los arreglos de abajo y la misma numeración de secciones. Los textos literales de `project.godot`, `export_presets.cfg` y `verify.sh` van dentro de la spec, en bloques de código. Antes de implementar (paso 0), se comprueba con context7 todo lo que nadie ha podido verificar.

## Hallazgos

| # | Sev. | Hallazgo | Sugerencia | Qué cambia en la spec |
|---|---|---|---|---|
| 1 | 🔴 | `verify.sh` en una frase | PROPOSE FIX | §4 incluye el script completo: `set -euo pipefail`; importa (dos veces, ver 11); ejecuta GUT; `mkdir -p build`; borra `run.log`; exporta; comprueba la exclusión (2); arranca con D7; busca `^BOOT_OK` y `ERROR`; da un mensaje y un código distinto de 0 en cada fallo. |
| 2 | 🔴 | Sin técnica de exclusión | PROPOSE FIX | `embed_pck=false`, sin cifrado. Pasa si el control positivo encuentra `presentation/main` en el `.pck` **y** no aparece ni `godot_mcp_runtime` ni `addons/gut`. Si la caché de clases da un falso positivo, se pasa a la opción `--export-pack` + `unzip -l` (anotado en la §8). |
| 3 | 🔴 | Test de `DevBoot` | PROPOSE FIX | `func load_runtime(script_path: String, parent: Node) -> Node`, con `ResourceLoader.exists`. El test usa una instancia fuera del árbol, una ruta inexistente y un `Node` nuevo, espera un fotograma y comprueba que devuelve `null` y que hay 0 hijos. |
| 4 | 🟡 | `main.gd` y su escena | PROPOSE FIX | Árbol fijo: `Main` > `Camera3D` (0, 0, 3), `DirectionalLight3D`, `Label3D`. En `_ready()`: `print("BOOT_OK")` y el texto de `tr("TITLE")`. |
| 5 | 🟡 | Lista de archivos | PROPOSE FIX | Cada archivo marcado como **crear** o **modificar**. Se añaden los `.gdignore` (`specs/`, `reviews/`, `build/`), `addons/godot_mcp_runtime/LICENSE` y el texto exacto para `CLAUDE.md`. Se declaran los archivos que genera Godot y se versionan (`*.uid`, `*.import`, `.translation`). **No se crean carpetas vacías ni `.gdkeep`**: las carpetas de arquitectura se anotan en `CLAUDE.md` y se crean con su primer archivo. `tests/unit/` pasa a `tests/`. |
| 6 | 🟡 | Configuración solo descrita | PROPOSE FIX | Texto literal de `project.godot` y `export_presets.cfg` con las claves del informe. |
| 7 | 🟡 | Las plantillas van en la build | PROPOSE FIX | Tres grupos en `ASSETS.md` y un paso que compara las licencias de terceros de `COPYRIGHT.txt` con las permitidas. D5 añade: «la plantilla es el motor dentro de la build; sus avisos de licencia se entregan en el hito 7». |
| 8 | 🟡 | Instalación de las plantillas | PROPOSE FIX | URL, `sha512sum -c`, descompresión de `templates/` y comprobación de `version.txt`. Si el SHA falla, se descarga otra vez; si vuelve a fallar, se avisa al usuario. |
| 9 | 🟡 | Origen de GUT y GoPeak | PROPOSE FIX | URL del zip, carpeta interna, SHA-256 en `ASSETS.md` (columna nueva), y las versiones comprobadas en `plugin.cfg` y `package.json`. |
| 10 | 🟡 | Servidor TCP durante los tests | PROPOSE FIX | No se toca `DevBoot`. La §8 anota que el aviso de «puerto ocupado» no es un fallo y que no se lanzan los tests con el juego abierto. |
| 11 | 🟡 | `ERROR` en la primera importación | PROPOSE FIX | Se importa dos veces y el criterio «sin `ERROR`» se aplica a la segunda. Anotado en la §8. |
| 12 | 🟡 | La §8 contradice D2 | PROPOSE FIX | «Se para y se pide confirmación antes de probar la 9.7.0.» |
| 13 | 🟡 | La §6 pide menos que D7 | PROPOSE FIX | Exportación «cumple D7». El test de traducción fija y restaura el idioma. Se quitan `test_gut_runs` y `test_main_scene_set`. |
| 14 | 🟡 | El icono no llega al `.exe` | PROPOSE FIX | **No hay icono propio en el hito 0.** No se pone `config/icon` y se quita `icon.svg` de la spec y de `ASSETS.md`. La §8 anota que el `.exe` lleva el icono de la plantilla hasta que se haga uno propio con `rcedit`. |
| 15 | 🟢 | «fuentes OFL» | PROPOSE FIX | → «tipografías OFL». |
| 16 | 🟢 | «la ruta que espera GoPeak» | PROPOSE FIX | → «el addon se pone el nombre `MCPRuntime` (`mcp_runtime_autoload.gd`, `_ready`)». |
| 17 | 🟢 | D7 y el renderer release | PROPOSE FIX | D7: «el renderer de la build release lo prueba el usuario (§7)». |
| 18 | 🟢 | `exclude_filter` redundante | PROPOSE FIX | Solo `addons/godot_mcp_runtime/*, addons/gut/*, tests/*`. |
| 19 | 🟢 | Paso 0 con context7 | PROPOSE FIX | Paso 0 nuevo: confirmar `--log-file`, `--export-release`, el nombre del `.translation`, las claves de `.gutconfig.json` y la carga de autoloads con `-s`. |
| 20 | 🟢 | Ruta de reserva del log | PROPOSE FIX | D7: `%APPDATA%\Godot\app_userdata\The Living Room\logs\godot.log`. |
| 21 | 🟢 | Captura de GoPeak antes | PROPOSE FIX | Va justo después de la importación y de GUT, antes de las plantillas. Si falla, se revisa D4 antes de seguir. |
| 22 | 🟢 | Comprobación con LSP | PROPOSE FIX | Paso nuevo: diagnóstico LSP de los scripts propios con el MCP `godot` (cero errores). No va en `verify.sh`, porque necesita el servidor del editor. |
| 23 | 🟢 | Permiso para el `.exe` | PROPOSE FIX | §8: al aprobar la spec se pide al usuario permiso para ejecutar `build/TheLivingRoom.exe`; la §7 no se cierra sin D7 automático. Se quita la mención a VoiceStudio. |
| 24 | 🟢 | Términos | PROPOSE FIX | «build de depuración» en todo el texto; «pasan»; `build/TheLivingRoom.exe`; la §7 incluye `ASSETS.md` y `CLAUDE.md`. |
| 25 | 🟢 | Duplicados y formato | PROPOSE FIX | Renderer en una sola línea, CSV en un bloque de código, `.gitignore` «sin cambios». |

**Resumen:** 25 PROPOSE FIX, ningún CONTEST ni DECLINE. Los hallazgos 5 y 14 cambian el alcance: quitan las carpetas vacías y el icono. Como no son «Decisiones fijadas», basta con tu aprobación.
