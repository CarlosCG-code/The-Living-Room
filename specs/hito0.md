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
| D5 | Plantillas de exportación | Oficiales de Godot 4.7.2 (`Godot_v4.7.2-stable_export_templates.tpz`, 1,28 GB), verificadas con `SHA512-SUMS.txt` e instaladas en `%APPDATA%\Godot\export_templates\4.7.2.stable\` | Gratuitas y del mismo origen que el motor. Necesarias para exportar y comprobar la build. La plantilla es el motor que va dentro de la build (Godot, MIT, más los terceros de su `COPYRIGHT.txt`); sus avisos de licencia se entregan con el juego en el hito 7. | Ninguna: forzada, porque el exportador exige plantillas de la misma versión. |
| D6 | Idioma | CSV `locale/strings.csv` con columnas `keys,es`; idioma de reserva `es` | Lo fija `CLAUDE.md` (`tr()` con CSV de Godot). Al ser la única traducción, es la que se ve con cualquier idioma del sistema. | Archivos gettext `.po`: forzada por `CLAUDE.md` (Convenciones). |
| D7 | Qué significa "arranca" | La build se ejecuta con `--headless --quit-after 120` (120 fotogramas) y `--log-file build/run.log`. Pasa si sale con código 0, el log contiene la línea `BOOT_OK` que imprime `main.gd` al arrancar y no contiene `ERROR`. Si el log falta o está vacío, falla. Si `--log-file` no existe en 4.7.2 (se comprueba con context7 antes de implementar), se usa `user://logs/godot.log` (`%APPDATA%\Godot\app_userdata\The Living Room\logs\godot.log`). | Es comprobable sin el usuario y exige una prueba positiva, no solo la ausencia de errores. Headless no prueba el renderer: la captura del paso 7 lo prueba en la build de depuración, y el renderer de la build release lo prueba el usuario (§7). | Ejecución con ventana en `verify.sh`: abre una ventana en el escritorio del usuario en cada verificación, y el renderer real ya se prueba en el paso 7. |
| D8 | Ubicación de autoloads, datos, tests y assets | `autoload/`, `data/`, `tests/` y `assets/` (`models/`, `textures/`, `audio/`, `fonts/`), en la raíz. Cada carpeta se crea con su primer archivo | Lo pide `CLAUDE.md` (Arquitectura). Cada tipo en un único sitio. | `core/autoload/`: `core/` no lleva nodos. Datos dentro de cada sistema: más difíciles de listar y validar. |

## 3. Archivos

Solo se crean los archivos de esta lista. Las carpetas de arquitectura sin contenido todavía (`core/`, `fear/`, `audio/`, `world/`, `narrative/`, `data/`, `assets/…`) no se crean: se anotan en `CLAUDE.md` (D8) y cada una se crea con su primer archivo.

```
project.godot                      crear
export_presets.cfg                 crear
.gutconfig.json                    crear
ASSETS.md                          crear
CLAUDE.md                          modificar (paso 10)
.gitignore                         sin cambios (ya ignora .godot/ y /build/)
presentation/main.tscn             crear (escena provisional; se sustituye en el hito 2)
presentation/main.gd               crear
autoload/dev_boot.gd               crear
locale/strings.csv                 crear
tests/test_smoke.gd                crear
tools/verify.sh                    crear
addons/gut/                        copiar (GUT 9.7.1)
addons/godot_mcp_runtime/          copiar (addon de capturas, solo build de depuración)
addons/godot_mcp_runtime/LICENSE   copiar (LICENSE MIT del paquete GoPeak)
specs/.gdignore                    crear (vacío; Godot no escanea la carpeta)
reviews/.gdignore                  crear (vacío)
```

**Archivos que genera Godot** al importar, que se versionan en git: `*.uid` (junto a cada script), `*.import` (junto a cada recurso importado) y `locale/strings.es.translation`. La carpeta `.godot/` la ignora `.gitignore`. `verify.sh` crea `build/` y `build/.gdignore`, también ignorados.

## 4. Contenido de los archivos

Los nombres de claves y opciones marcados con † se confirman con context7 en el paso 0 antes de escribirlos.

**`project.godot`:**

```ini
config_version=5

[application]
config/name="The Living Room"
run/main_scene="res://presentation/main.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")

[autoload]
DevBoot="*res://autoload/dev_boot.gd"

[internationalization]
locale/translations=PackedStringArray("res://locale/strings.es.translation")
locale/fallback="es"

[rendering]
renderer/rendering_method="forward_plus"
```

Sin `config/icon`: en el hito 0 no hay icono propio (ver §8). GUT no se activa como plugin del editor: el usuario no usa el editor y la línea de comandos no lo necesita.

**`export_presets.cfg`** †:

```ini
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter="addons/godot_mcp_runtime/*, addons/gut/*, tests/*"
export_path="build/TheLivingRoom.exe"
encrypt_pck=false
encrypt_directory=false

[preset.0.options]
binary_format/embed_pck=false
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=false
```

`embed_pck=false` deja el paquete aparte (`build/TheLivingRoom.pck`), y sin cifrar, para poder comprobar la exclusión. `modify_resources=false` evita el aviso por no tener `rcedit`.

**`autoload/dev_boot.gd`** (es el único script que conoce el addon; sin `class_name`, porque es un autoload):

```gdscript
extends Node

const RUNTIME_SCRIPT := "res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd"


func _ready() -> void:
	load_runtime(RUNTIME_SCRIPT, get_tree().root)


## Devuelve null y no añade nada fuera de la build de depuración o si el script no existe.
func load_runtime(script_path: String, parent: Node) -> Node:
	# ResourceLoader.exists, no FileAccess.file_exists: en la build los scripts se exportan como .gdc.
	if not OS.is_debug_build() or not ResourceLoader.exists(script_path):
		return null
	var runtime: Node = (load(script_path) as GDScript).new()
	parent.add_child.call_deferred(runtime)
	return runtime
```

El nodo se llama `MCPRuntime` porque el propio addon se pone ese nombre (`mcp_runtime_autoload.gd`, `_ready`). GoPeak no lo busca por su ruta: se conecta por TCP (D4).

**`presentation/main.tscn` y `main.gd`:**
- Árbol: `Main` (`Node3D`, script `main.gd`) > `Camera3D` en (0, 0, 3) mirando al origen, `DirectionalLight3D`, `Label3D` en el origen.
- `main.gd` (`extends Node3D`), en `_ready()`: `$Label3D.text = tr("TITLE")` y después `print("BOOT_OK")` (D7). El `.tscn` no lleva texto literal.

**`locale/strings.csv`:**

```csv
keys,es
TITLE,The Living Room
```

**`.gutconfig.json`** †: `dirs: ["res://tests/"]`, `include_subdirs: true`, `prefix: "test_"`, `should_exit: true`, `log_level: 1`.

**`tests/test_smoke.gd`:** ver la §6.

**`tools/verify.sh`** (se ejecuta con Git Bash; se usará al cerrar cada hito):

```bash
#!/usr/bin/env bash
# Comprueba importación, tests, exportación, exclusión del addon y arranque de la build (D7).
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:?GODOT debe apuntar a Godot_v4.7.2-stable_win64_console.exe}"
fail() { echo "VERIFY FAIL: $1" >&2; exit 1; }

mkdir -p build && touch build/.gdignore
rm -f build/run.log

# 1. Importación. La primera genera el .translation; el criterio se aplica a la segunda.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --import >build/import.log 2>&1 || fail "importación (build/import.log)"
! grep -q 'ERROR' build/import.log || fail "líneas ERROR en build/import.log"

# 2. Tests GUT.
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd >build/gut.log 2>&1 || fail "tests GUT (build/gut.log)"

# 3. Exportación release.
"$GODOT" --headless --path . --export-release "Windows Desktop" build/TheLivingRoom.exe \
	>build/export.log 2>&1 || fail "exportación (build/export.log)"
[ -f build/TheLivingRoom.pck ] || fail "no existe build/TheLivingRoom.pck"

# 4. Exclusión. Control positivo: la escena principal sí debe estar.
grep -a -q 'presentation/main' build/TheLivingRoom.pck || fail "el .pck no contiene la escena principal"
! grep -a -q -E 'godot_mcp_runtime|addons/gut' build/TheLivingRoom.pck || fail "el .pck contiene el addon o GUT"

# 5. Arranque (D7).
./build/TheLivingRoom.exe --headless --quit-after 120 --log-file build/run.log >/dev/null 2>&1 \
	|| fail "la build salió con un código distinto de 0"
[ -s build/run.log ] || fail "build/run.log falta o está vacío"
grep -q '^BOOT_OK' build/run.log || fail "falta BOOT_OK en build/run.log"
! grep -q 'ERROR' build/run.log || fail "líneas ERROR en build/run.log"

echo "VERIFY OK"
```

Si en el paso 0 resulta que `--log-file` no existe, el paso 5 lee `%APPDATA%\Godot\app_userdata\The Living Room\logs\godot.log` (D7).

**`ASSETS.md`**, con tres tablas:
- **Va en la build:** plantillas de exportación Godot 4.7.2 (son el motor: el `.exe` exportado es la plantilla). MIT, más los componentes de terceros que lista su `COPYRIGHT.txt`. Los avisos de licencia se entregan con el juego en el hito 7.
- **Solo desarrollo** (no van en la build): GUT 9.7.1 (MIT, con sus tipografías OFL) y `godot_mcp_runtime` 1.0.0 de GoPeak 2.4.1 (MIT). Columnas: nombre, versión, origen (URL o ruta), SHA-256, licencia, fecha.
- **Assets del juego:** vacía, con las columnas que fija `CLAUDE.md`: archivo, fuente (URL), autor, licencia, fecha.

**`CLAUDE.md`** (paso 10): la frase «La ubicación de autoloads, datos `.tres`, tests y assets se fija en el hito 0 y se anota aquí. En el hito 0 se instalan GUT y el addon `godot_mcp_runtime` y se crea `ASSETS.md`.» se sustituye por:

> Ubicaciones (fijadas en el hito 0): autoloads en `autoload/`, datos `.tres` en `data/`, tests GUT en `tests/`, assets en `assets/` (`models/`, `textures/`, `audio/`, `fonts/`). `audio/` en la raíz es el código del gestor de audio; los sonidos van en `assets/audio/`. Cada carpeta se crea con su primer archivo. GUT está en `addons/gut/` y el addon de capturas en `addons/godot_mcp_runtime/` (solo build de depuración; lo carga `autoload/dev_boot.gd`). Cada hito se comprueba con `tools/verify.sh`.

## 5. Pasos

0. **Comprobar con context7** (Godot 4.7.2 y GUT 9.7): que existen `--log-file`, `--export-release` y `--quit-after` (en fotogramas); el nombre del `.translation` que genera el CSV; las claves de `export_presets.cfg` y de `.gutconfig.json`; que los autoloads se cargan con `-s`; y el nombre de la espera de un fotograma en GUT. Lo que no coincida se corrige en la spec antes de seguir.
1. **GUT:** descargar `https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip`, anotar su SHA-256 (`sha256sum`) en `ASSETS.md`, comprobar que `Gut-9.7.1/addons/gut/plugin.cfg` dice `version="9.7.1"` y copiar solo `addons/gut/` (con su `LICENSE`, si está dentro).
2. **Addon de capturas:** copiar `godot_mcp_runtime/` y el `LICENSE` del paquete desde `%USERPROFILE%\.bun\install\global\node_modules\gopeak\` (`build/addon/godot_mcp_runtime/` y `LICENSE`). Comprobar que `package.json` dice 2.4.1 y `plugin.cfg` dice 1.0.0.
3. Crear los archivos de la §3 con el contenido de la §4.
4. **Importar dos veces** (`$GODOT --headless --path . --import`). La segunda termina con código 0 y sin líneas `ERROR`.
5. **Tests:** `$GODOT --headless --path . -s addons/gut/gut_cmdln.gd`. Todos pasan.
6. **LSP:** diagnóstico de `dev_boot.gd`, `main.gd` y `test_smoke.gd` con el LSP del editor headless (MCP `godot`, `lsp-diagnostics`): cero errores. No va en `verify.sh`, porque necesita el servidor del editor.
7. **Captura:** ejecutar el proyecto (build de depuración) con el MCP `godot` y capturar la pantalla; debe verse el título. Va antes de las plantillas para validar D4 pronto: si GoPeak no conecta, se revisa D4 antes de seguir.
8. **Plantillas:** descargar `Godot_v4.7.2-stable_export_templates.tpz` y `SHA512-SUMS.txt` de `https://github.com/godotengine/godot/releases/download/4.7.2-stable/` y comprobar con `sha512sum -c`. Si no coincide, se descarga otra vez; si vuelve a fallar, se avisa al usuario. Descomprimir el contenido de `templates/` en `%APPDATA%\Godot\export_templates\4.7.2.stable\` y comprobar que `version.txt` dice `4.7.2.stable` y que existe `windows_release_x86_64.exe`. Comprobar que todas las licencias de terceros de `COPYRIGHT.txt` están entre las permitidas por `CLAUDE.md`; si alguna no lo está, se para y se avisa al usuario.
9. Ejecutar `tools/verify.sh`: termina con `VERIFY OK`.
10. Sustituir la frase de `CLAUDE.md` (§4), completar `ASSETS.md`, hacer commit y push a GitHub.

## 6. Tests

| Test | Qué comprueba | Resultado esperado |
|---|---|---|
| `test_smoke.gd::test_translation_es` | Guarda el idioma actual, fija `TranslationServer.set_locale("es")`, lee `tr("TITLE")` y restaura el idioma | "The Living Room" |
| `test_smoke.gd::test_devboot_skips_without_addon` | Crea una instancia de `dev_boot.gd` fuera del árbol y un `Node` vacío propio. Llama a `load_runtime("res://no_existe.gd", nodo)`, espera un fotograma † y libera ambos | devuelve `null` y el nodo sigue con 0 hijos |
| `verify.sh` (importación) | La segunda importación | código 0, sin `ERROR` |
| `verify.sh` (exclusión) | El `.pck` contiene `presentation/main` y no contiene `godot_mcp_runtime` ni `addons/gut` | las dos condiciones se cumplen |
| `verify.sh` (arranque) | La build release arranca sin el addon | cumple D7 |
| LSP (paso 6) | Los scripts propios no tienen errores de GDScript | cero errores |
| Captura (paso 7) | El addon funciona en la build de depuración | GoPeak devuelve la imagen con el título |

## 7. Criterio de cierre

- Los tests de la §6 pasan y `verify.sh` termina con `VERIFY OK`, ejecutado por Claude sin el usuario.
- La captura se ha enseñado al usuario.
- El usuario abre `build/TheLivingRoom.exe` y lo aprueba. Es la única prueba del renderer en la build release.
- `ASSETS.md` y `CLAUDE.md` están actualizados.
- Commit y push hechos.

## 8. Riesgos

- **Permiso para ejecutar el `.exe`:** el sistema de permisos de Claude Code puede bloquear la ejecución de `build/TheLivingRoom.exe`. Al aprobar esta spec se pide al usuario un permiso limitado a ese archivo. El hito no se cierra hasta que D7 pase de forma automática.
- **GUT 9.7.1 en Godot 4.7.2:** se valida en los pasos 4 y 5. Si falla (tests rotos o líneas `ERROR` al importar), se para y se pide confirmación al usuario antes de probar la 9.7.0.
- **Puerto 7777 durante los tests:** en la build de depuración, `DevBoot` carga el addon también al ejecutar GUT, y el addon abre su servidor. Si el juego ya está abierto, el addon avisa de que el puerto está ocupado y sigue sin servidor. Es un aviso, no un `ERROR`, y no cuenta como fallo. Los tests no se lanzan con el juego abierto.
- **Falso fallo en la exclusión:** si la caché de clases deja en el `.pck` el texto `addons/gut` sin que haya archivos de GUT, se cambia la comprobación a exportar también un `.zip` (`--export-pack`) y listar sus archivos con `unzip -l`.
- **Icono:** sin icono propio y sin `rcedit`, el `.exe` lleva el icono de la plantilla (el logotipo de Godot, CC-BY 4.0). Se acepta porque la build del hito 0 no se distribuye. Antes de distribuir (hito 7) se hace un icono propio y se pone con `rcedit` (gratuito, herramienta de desarrollo).
