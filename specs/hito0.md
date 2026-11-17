# Especificación — Hito 0: base del proyecto

> Estado: **borrador, pendiente de revisión EGM y aprobación del usuario**. No se escribe código hasta que se apruebe.
>
> Fuentes: `GAME_DESIGN.md` §11 (hito 0) y `CLAUDE.md` (Arquitectura, Cómo trabajar, Decisiones fijadas).

## 1. Objetivo

Dejar un proyecto Godot 4.7.2 sin lógica de juego, que cumple:
- `$GODOT --headless --import` termina con código 0 y sin líneas `ERROR`;
- los tests GUT se ejecutan en headless y pasan;
- todo texto visible se obtiene con `tr()` desde `locale/strings.csv` (es);
- el MCP `godot` (GoPeak) obtiene una captura del juego en ejecución (build de depuración) mediante el addon `godot_mcp_runtime`;
- la build release de Windows arranca (criterio D7) y no contiene el addon;
- `ASSETS.md` existe con las dependencias (versión, origen, licencia), y las ubicaciones de carpetas quedan anotadas en `CLAUDE.md`.

**Fuera de alcance:** toda lógica de juego (reloj, `EventBus`, economía y guardado son del hito 1), las escenas del juego y sus assets.

## 2. Decisiones que cierra este hito

| # | Decisión | Propuesta | Por qué | Alternativas descartadas |
|---|---|---|---|---|
| D1 | Raíz del proyecto Godot | La raíz del repositorio, junto a `CLAUDE.md` | Acordado con el usuario (2026-11-17). `res://` = raíz del repositorio, así las rutas de `CLAUDE.md` (`core/`, `presentation/`…) son las mismas en el disco y en Godot. `specs/` y `reviews/` llevan un `.gdignore` para que Godot no las escanee. | Subcarpeta `game/`: las rutas de `CLAUDE.md` dejarían de coincidir con `res://`. |
| D2 | Versión de GUT | **9.7.1**, licencia MIT, desde la etiqueta `v9.7.1` de `github.com/bitwes/Gut` | Compatible con Godot 4.7 desde la 9.7.0 (notas de versión en `github.com/bitwes/Gut/releases`). Versión más reciente a 2026-11-17. Al descargar se registra el SHA-256 del zip en `ASSETS.md`. | GUT 9.7.0: queda como reserva si la 9.7.1 falla, con confirmación del usuario (es un cambio de dependencia). GUT de la AssetLib: necesita el editor. |
| D3 | Versión del addon de capturas | `godot_mcp_runtime` (su `plugin.cfg` dice 1.0.0), copiado de GoPeak 2.4.1 instalado en `%USERPROFILE%\.bun\install\global\node_modules\gopeak\build\addon\`, junto con el `LICENSE` MIT del paquete | Copia local de la misma versión que el servidor MCP en uso. Si se actualiza GoPeak, se vuelve a copiar. | El addon de la rama `main` de GoPeak con su `install-addon.ps1`: sin versión fija; podría no coincidir con el servidor 2.4.1. |
| D4 | Cómo se excluye el addon de las builds | **No se registra `MCPRuntime` en `project.godot`**. Lo carga el autoload propio `DevBoot` solo si `OS.is_debug_build()` y existe `res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd`. La exportación excluye `addons/godot_mcp_runtime/*`. En desarrollo el addon abre un servidor TCP sin autenticación en `127.0.0.1:7777` (solo local). | Un autoload registrado cuyo archivo se excluye rompe la build al arrancar. Así `project.godot` es igual en desarrollo y en release, y la exportación solo excluye archivos. GoPeak solo se conecta por TCP a `127.0.0.1:7777` (`build/index.js`, `handleRuntimeCommand`): no necesita que el autoload esté registrado ni que se cargue antes que la escena. Segunda barrera: el addon no abre el servidor en release (`mcp_runtime_autoload.gd`, `_start_server()`). | (a) Registrar `MCPRuntime` y quitarlo al exportar con un `EditorExportPlugin`: necesita un plugin del editor activo al exportar; si falla, la build se rompe. (b) Un `override.cfg` solo de desarrollo: no está documentado que admita autoloads en 4.7.2 y es un mecanismo poco conocido. |
| D5 | Plantillas de exportación | Oficiales de Godot 4.7.2 (`Godot_v4.7.2-stable_export_templates.tpz`, 1,28 GB), verificadas con `SHA512-SUMS.txt` e instaladas en `%APPDATA%\Godot\export_templates\4.7.2.stable\` | Gratuitas y del mismo origen que el motor. Necesarias para exportar y comprobar la build. | Ninguna: forzada, porque el exportador exige plantillas de la misma versión. |
| D6 | Idioma | CSV `locale/strings.csv` con columnas `keys,es`; idioma de reserva `es` | Lo fija `CLAUDE.md` (`tr()` con CSV de Godot). Al ser la única traducción, es la que se ve con cualquier idioma del sistema. | Archivos gettext `.po`: forzada por `CLAUDE.md` (Convenciones). |
| D7 | Qué significa "arranca" | La build se ejecuta con `--headless --quit-after 120` (120 fotogramas) y `--log-file build/run.log`. Pasa si sale con código 0, el log contiene la línea `BOOT_OK` que imprime `main.gd` al arrancar y no contiene `ERROR`. Si el log falta o está vacío, falla. Si `--log-file` no existe en 4.7.2 (se comprueba con context7 antes de implementar), se usa `user://logs/godot.log`. | Es comprobable sin el usuario y exige una prueba positiva, no solo la ausencia de errores. Headless no prueba el renderer; eso lo cubren la captura del paso 8 y la prueba del usuario. | Ejecución con ventana en `verify.sh`: abre una ventana en el escritorio del usuario en cada verificación, y el renderer real ya se prueba en el paso 8. |
| D8 | Ubicación de autoloads, datos, tests y assets | `autoload/`, `data/`, `tests/unit/` y `assets/` (`models/`, `textures/`, `audio/`, `fonts/`), en la raíz | Lo pide `CLAUDE.md` (Arquitectura). Cada tipo en un único sitio. | `core/autoload/`: `core/` no lleva nodos. Datos dentro de cada sistema: más difíciles de listar y validar. |

## 3. Estructura de carpetas

Se crean estas carpetas (con un `.gdkeep` vacío si no llevan archivos todavía):

```
project.godot
icon.svg                     # icono provisional dibujado por Claude (el de Godot es CC-BY 4.0 y no cumple "solo CC0")
export_presets.cfg
.gutconfig.json
ASSETS.md
core/                        # lógica sin nodos (hito 1+)
presentation/                # TV, cámara, UI
  main.tscn                  # escena principal provisional (hito 0)
  main.gd
fear/                        # director de eventos
audio/                       # gestor de audio 3D
world/                       # piso, escalera, piso de la señora, menú
narrative/                   # contenido de pistas y finales
autoload/                    # autoloads (DevBoot ahora; EventBus y reloj en el hito 1)
  dev_boot.gd
data/                        # recursos .tres (mejoras, eventos, pistas)
locale/
  strings.csv
assets/                      # models/, textures/, audio/, fonts/ (vacías)
tests/
  unit/
    test_smoke.gd
tools/
  verify.sh                  # tests + exportación + arranque de la build
addons/
  gut/                       # GUT 9.7.1
  godot_mcp_runtime/         # addon de capturas (solo desarrollo)
```

Al cerrar el hito, estas ubicaciones se anotan en `CLAUDE.md` ("La ubicación de autoloads…").

## 4. Archivos y contenido

- **`project.godot`:**
  - nombre "The Living Room";
  - `config/features` 4.7 y Forward Plus;
  - `run/main_scene="res://presentation/main.tscn"`;
  - renderer `forward_plus`;
  - autoload `DevBoot="*res://autoload/dev_boot.gd"`;
  - `internationalization/locale/translations` con el `.translation` del CSV;
  - locale de reserva `es`.

  GUT no se activa como plugin del editor: el usuario no usa el editor y la línea de comandos no lo necesita.
- **`autoload/dev_boot.gd`:** si `OS.is_debug_build()` y existe `res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd`, lo instancia y lo añade a la raíz del árbol (`get_tree().root`, de forma diferida) para que quede en `/root/MCPRuntime`, la ruta que espera GoPeak. Si no, no hace nada. Es el único sitio que conoce el addon. La carga va en una función que recibe la ruta, para poder probarla con una ruta inexistente. Sin `class_name`, porque es un autoload.
- **`presentation/main.tscn` y `main.gd`:** un `Node3D` con cámara, luz y una `Label3D` o un texto en pantalla que muestra `tr("TITLE")`. Es provisional; se sustituye en el hito 2.
- **`locale/strings.csv`:** `keys,es` / `TITLE,The Living Room`.
- **`.gutconfig.json`:** `dirs: ["res://tests/"]`, `include_subdirs: true`, `prefix: "test_"`, `should_exit: true`, `log_level: 1`.
- **`tests/unit/test_smoke.gd`:** ver la §6.
- **`export_presets.cfg`:**
  - preset "Windows Desktop";
  - `export_path="build/TheLivingRoom.exe"`;
  - `exclude_filter="addons/godot_mcp_runtime/*, addons/gut/*, tests/*, tools/*, specs/*, reviews/*"`;
  - sin firma de código.
- **`tools/verify.sh`:** importa, ejecuta GUT, exporta en release y arranca la build con el criterio D7. Termina con un código distinto de 0 si algo falla, y se usará al cerrar cada hito.
- **`icon.svg`:** icono provisional dibujado por Claude (una tele simple), registrado en `ASSETS.md` como propio.
- **`ASSETS.md`:** dos tablas.
  - **Dependencias** (solo desarrollo, no van en la build): GUT 9.7.1, MIT, con sus fuentes OFL incluidas; `godot_mcp_runtime` (GoPeak 2.4.1), MIT; plantillas de exportación Godot 4.7.2, MIT.
  - **Assets del juego:** vacía, con las columnas que fija `CLAUDE.md`: archivo, fuente (URL), autor, licencia, fecha.
- **`.gitignore`:** ya ignora `.godot/` y `/build/`.

## 5. Pasos

1. Descargar el zip de GUT de la etiqueta `v9.7.1`, comprobar que su `plugin.cfg` dice `version="9.7.1"` y copiar solo `addons/gut/`.
2. Copiar `godot_mcp_runtime/` desde el paquete GoPeak 2.4.1 instalado.
3. Crear las carpetas y los archivos de la §3 y la §4.
4. Importar el proyecto: `$GODOT --headless --path . --import`, sin errores.
5. Ejecutar los tests: `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd`. Todos deben pasar.
6. Descargar las plantillas, verificar su SHA-512 e instalarlas.
7. Ejecutar `tools/verify.sh`: exporta, arranca la build y aplica el criterio D7.
8. Comprobación visual con el MCP `godot`: ejecutar el proyecto en desarrollo, capturar la pantalla y ver el título.
9. Anotar las ubicaciones en `CLAUDE.md`, rellenar `ASSETS.md` y hacer commit y push a GitHub.

## 6. Tests

| Test | Qué comprueba | Resultado esperado |
|---|---|---|
| `test_smoke.gd::test_gut_runs` | GUT funciona en headless | pasa |
| `test_smoke.gd::test_translation_es` | `tr("TITLE")` con locale `es` | "The Living Room" |
| `test_smoke.gd::test_main_scene_set` | `run/main_scene` apunta a una escena existente | `ResourceLoader.exists(...)` es true |
| `test_smoke.gd::test_devboot_skips_without_addon` | `DevBoot` no hace nada si no encuentra el script del addon (se simula con una ruta inexistente) | no añade ningún hijo y no da error |
| `verify.sh` (exportación) | la build release arranca sin el addon | código 0 y log sin errores |
| `verify.sh` (exclusión) | el `.pck` exportado no contiene `godot_mcp_runtime` ni `gut` | no aparecen en la lista de archivos del paquete |
| Captura (paso 8) | el addon funciona en desarrollo | GoPeak devuelve la imagen con el título |

## 7. Criterio de cierre

Todos los tests de la §6 en verde; la captura enseñada al usuario; el usuario abre el juego (la build en `build/`) y lo aprueba; commit y push hechos.

## 8. Riesgos

- **Plantillas de 1,28 GB:** la descarga es larga y se hace en segundo plano. Si el SHA-512 no coincide, no se instalan.
- **El sistema de permisos de Claude Code podría bloquear la ejecución del `.exe` exportado**, como pasó con el instalador de VoiceStudio. En ese caso se pide permiso al usuario o se le dan pasos para ejecutarlo él.
- **GUT 9.7.1 en Godot 4.7.2:** se valida en el paso 5. Si falla, se prueba la 9.7.0 y se le indica al usuario.
- **Sin `rcedit`, la exportación a Windows avisa** de que no puede poner el icono ni los metadatos en el `.exe`. Es un aviso, no un error; el criterio D7 mira el log del juego, no el de la exportación.
