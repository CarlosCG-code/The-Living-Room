# Etapa 9 — Preparación para implementar: `specs/hito0.md`, líneas 32-130 (§3-§8)

Ronda 1. Revisores: **preparación** (`implementation-readiness`), **detalles técnicos** (`codebase-details`) y **estilo**. Estándar: `implementation-readiness-standard`. Contexto: `CLAUDE.md`, `GAME_DESIGN.md`. Los tres terminaron.

**Veredicto:** todavía no está lista. Hay 3 bloqueantes y 11 importantes. El diseño (D1-D8) es bueno; el plan (§3-§8) se queda corto. El estándar exige que quien implemente no tenga que decidir nada, y en `verify.sh`, en el test de `DevBoot` y en los archivos de configuración aún tiene que decidir. También se incluyen los puntos pendientes de la etapa 8 (A-G).

**Comprobado por el revisor de detalles técnicos** (leyó el paquete GoPeak): GoPeak 2.4.1, licencia MIT; `plugin.cfg` 1.0.0; el addon se apaga en release y escucha en `127.0.0.1:7777`; GoPeak solo se conecta por TCP. Coincide con lo que comprobé en la etapa 7.

**Sin comprobar** (nadie tenía Godot ni GUT a mano): si existe `--log-file`, si `--export-release` crea la carpeta, el nombre del archivo de traducción generado, las claves de `.gutconfig.json`, si los autoloads se cargan con `-s`, y cómo se guardan las rutas dentro del `.pck`. Hay que confirmarlo con context7 antes de implementar.

## 🔴 Bloqueantes

### 1. `verify.sh` está descrito en una sola frase (preparación B1, técnicos M2, estilo M6)
- **Dónde:** líneas 90, 105, 117-118.
- **Problema:** faltan los comandos exactos. No dice cómo exportar, si hay que crear `build/`, qué `.exe` ejecutar, cómo leer su código de salida, ni con qué patrón se buscan `BOOT_OK` y `ERROR`. El script se reutiliza para cerrar cada hito, así que no puede quedar a criterio de quien lo escriba.
- **Cambio:** escribir los pasos como comandos: `--import`, GUT, `mkdir -p build`, borrar el `run.log` anterior, `--export-release "Windows Desktop" build/TheLivingRoom.exe`, ejecutar con `--headless --quit-after 120 --log-file build/run.log`, `grep -q '^BOOT_OK'`, `! grep -q 'ERROR'`, con `set -e` y un mensaje por cada fallo. Que el script compruebe también la salida de la importación y de GUT.

### 2. No hay técnica para comprobar que el addon no está en el `.pck` (preparación B2, técnicos M2, estilo M6; etapa 8 B)
- **Dónde:** línea 118; §1 línea 14.
- **Problema:** Godot no tiene ningún comando para listar un `.pck`, y la spec no dice si el `.pck` va dentro del `.exe` o aparte.
- **Opciones:**
  - **A:** `embed_pck=false` y buscar los textos en el `.pck`: `! grep -a -q -E 'godot_mcp_runtime|addons/gut'`, con un control positivo (`grep -a -q 'presentation/main'`) para que no pase si el archivo está vacío. Sin cifrado.
  - **B** (etapa 5): exportar también un `.zip` con `--export-pack` y listarlo con `unzip -l`.
- **Recomendación:** A con control positivo. Es una línea, mira el archivo que de verdad se entrega y no exige una segunda exportación. El riesgo de falsos positivos por la caché de clases (etapa 5) se ve en la primera ejecución; si aparece, se pasa a B.

### 3. El test de `DevBoot` no se puede escribir tal como está (técnicos B1, preparación M4, estilo N5 y N10)
- **Dónde:** líneas 80 y 116.
- **Problema:**
  - No hay nombre, parámetros ni valor de retorno para la función.
  - Si el test mete `DevBoot` en el árbol, su `_ready` carga el addon real (que sí existe) y añade un segundo `MCPRuntime`.
  - El autoload ya añadió uno al empezar los tests.
  - Como el nodo se añade de forma diferida, habría que esperar un fotograma para comprobarlo.
  - `FileAccess.file_exists` no ve los scripts exportados como `.gdc`, y `load()` sobre una ruta inexistente escribe un `ERROR`.
- **Cambio:** fijar `func load_runtime(script_path: String, parent: Node) -> Node`. Devuelve `null` y no añade nada si `not OS.is_debug_build() or not ResourceLoader.exists(script_path)`. Si no, crea el nodo y lo añade diferido a `parent`. `_ready` la llama con la ruta real y `get_tree().root`. El test usa una instancia fuera del árbol, una ruta inexistente y un `Node` nuevo; comprueba que devuelve `null`, espera un fotograma y comprueba que el nodo sigue con 0 hijos.

## 🟡 Importantes

### 4. `main.gd` no imprime `BOOT_OK` y la escena no está definida (preparación M1, estilo M5 y N6, técnicos N2)
- **Dónde:** línea 81.
- **Cambio:** `main.gd`: `extends Node3D`; en `_ready()`, `print("BOOT_OK")` y `$Label3D.text = tr("TITLE")`. Árbol: `Main (Node3D)` > `Camera3D` en (0, 0, 3), `DirectionalLight3D`, `Label3D` en el origen. Se elige `Label3D` y se descarta el texto en pantalla.

### 5. La lista de archivos está incompleta (técnicos M1, preparación M2, M3, N7 y N8, estilo N1)
- **Faltan:**
  - `specs/.gdignore` y `reviews/.gdignore` (D1) y `build/.gdignore`;
  - `addons/godot_mcp_runtime/LICENSE` (D3);
  - el texto exacto que se añade a `CLAUDE.md`.
- **Archivos que genera Godot y que hay que declarar y versionar:** `*.gd.uid`, `*.import` y `locale/strings.es.translation`.
- **Sobre las carpetas vacías:** `.gdkeep` no es una convención. Recomiendo **no crear carpetas vacías**: se anotan en `CLAUDE.md` y se crean con su primer archivo (etapas 5 n.º 6 y 8 G). Basta con `tests/`, sin `unit/`.
- **Cambio:** marcar cada archivo como «crear» o «modificar».

### 6. `project.godot` y `export_presets.cfg` se escriben a mano, pero solo se describen (técnicos M3, preparación N4 y N5, estilo N3 y N4)
- **Cambio:** poner el texto literal de los dos archivos. En `project.godot`: `config_version=5`, `config/name`, `config/features=PackedStringArray("4.7", "Forward Plus")`, `config/icon`, `run/main_scene`, `rendering/renderer/rendering_method="forward_plus"`, `internationalization/locale/translations=PackedStringArray("res://locale/strings.es.translation")` y `internationalization/locale/fallback="es"`. En `export_presets.cfg`: `[preset.0]` con `name`, `platform="Windows Desktop"`, `runnable=true` y `export_filter="all_resources"`, y en `[preset.0.options]`, `binary_format/embed_pck=false`, `binary_format/architecture="x86_64"` y `codesign/enable=false`.

### 7. Las plantillas sí van en la build (los tres; etapa 8 A)
- **Dónde:** línea 93 y D5.
- **Cambio:** en `ASSETS.md`, tres grupos: «va en la build» (plantillas = motor Godot, MIT, más los terceros de `COPYRIGHT.txt`), «solo desarrollo» (GUT, `godot_mcp_runtime`) y «assets del juego». Añadir un paso que compruebe que las licencias de terceros de `COPYRIGHT.txt` están permitidas por `CLAUDE.md`. Añadir a D5 que los avisos de licencia se entregan en el hito 7.

### 8. La descarga e instalación de las plantillas no son concretas (preparación M6, técnicos M5, estilo N12)
- **Cambio:** URL `https://github.com/godotengine/godot/releases/download/4.7.2-stable/` (`.tpz` y `SHA512-SUMS.txt`); `sha512sum -c`; descomprimir el contenido de `templates/` en `%APPDATA%\Godot\export_templates\4.7.2.stable\`; comprobar que existen `windows_release_x86_64.exe` y `version.txt` con `4.7.2.stable`. Si el SHA no coincide: descargar otra vez y, si vuelve a fallar, avisar al usuario.

### 9. GUT y GoPeak: falta el origen exacto (preparación N1, técnicos M7, estilo N9)
- **Cambio:**
  - **Paso 1:** `https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip`, carpeta `Gut-9.7.1/addons/gut/`, `sha256sum` anotado en `ASSETS.md` (añadir la columna SHA-256).
  - **Paso 2:** copiar el addon y el `LICENSE` desde la ruta de D3, y comprobar `plugin.cfg` 1.0.0 y `package.json` 2.4.1.

### 10. Los tests ponen en marcha el servidor TCP del addon (preparación M5, técnicos N5)
- **Problema:** durante GUT, `DevBoot` carga el addon real y abre el puerto 7777. Si hay otra instancia abierta (paso 8), aparece un aviso de puerto ocupado. Es un aviso, no un `ERROR`, como dice el propio addon en su código.
- **Cambio:** aceptarlo y documentarlo en la §8: los tests no se lanzan con el juego abierto, y ese aviso no cuenta como fallo. Es lo más simple; desactivarlo en los tests añadiría lógica a `DevBoot`.

### 11. La primera importación puede dar `ERROR` por la traducción (técnicos M4, preparación N9)
- **Problema:** `project.godot` apunta al `.translation` antes de que exista. Sin comprobar.
- **Cambio:** paso 4: importar dos veces y aplicar el criterio «sin `ERROR`» a la segunda. Anotar el caso en la §8. Si GUT da `ERROR` al importar, se aplica la reserva de D2.

### 12. La §8 contradice D2 sobre GUT 9.7.0 (estilo M3; etapa 8 E)
- **Cambio:** «Si falla, se para y se pide confirmación al usuario antes de probar la 9.7.0.»

### 13. La §6 pide menos que D7 (estilo M4 y N10)
- **Cambio:**
  - Fila de exportación: «cumple D7».
  - `test_translation_es`: fija `TranslationServer.set_locale("es")` y restaura el idioma anterior al acabar.
  - `test_gut_runs` y `test_main_scene_set` se quitan: los cubren los demás tests y D7 (etapa 5 n.º 8).

### 14. El icono propio no llega al `.exe` (estilo M7)
- **Problema:** sin `rcedit`, el `.exe` conserva el icono de Godot, que es CC-BY y justo lo que se quería evitar.
- **Cambio:** decidir. Recomiendo no hacer icono en el hito 0 (etapa 5 n.º 9) y anotar en la §8: «el `.exe` lleva el icono de la plantilla; se resuelve cuando se haga el icono, con `rcedit` (gratuito, herramienta de desarrollo)».

## 🟢 Menores

15. «Con sus fuentes OFL» → «con sus tipografías OFL» (en esta spec, «fuente» significa origen).
16. Línea 80: `/root/MCPRuntime` no es «la ruta que espera GoPeak»; el nombre se lo pone el propio addon (etapa 8 C).
17. D7: el renderer de la build release solo lo prueba el usuario (§7), no la captura del paso 8 (etapa 8 D).
18. `exclude_filter`: quitar `tools/*`, `specs/*` y `reviews/*` (etapa 8 F).
19. Añadir el paso 0: comprobar con context7 `--log-file`, `--export-release`, el nombre del `.translation` y las claves de `.gutconfig.json`.
20. Reserva de D7: `user://logs/` de la build es `%APPDATA%\Godot\app_userdata\The Living Room\logs\`.
21. Adelantar la captura de GoPeak a justo después de la importación (etapas 5 n.º 4 y 8 C).
22. `CLAUDE.md` pide comprobar los errores de GDScript con el LSP (servidor de análisis de código); decir si se usa en este hito.
23. Permiso para ejecutar el `.exe`: pedirlo una vez al aprobar la spec (etapa 5 n.º 5). La §7 no se cierra hasta que D7 pase de forma automática. Quitar la mención a VoiceStudio.
24. Términos: «en desarrollo» frente a «build de depuración»; «en verde» → «pasan»; «la build en `build/`» → `build/TheLivingRoom.exe`. La §7 debe incluir `ASSETS.md` y `CLAUDE.md`.
25. Unir las líneas 72 y 74 (renderer duplicado), poner el CSV como bloque de código y marcar `.gitignore` como «sin cambios».

## Correspondencia

| Aquí | Preparación | Técnicos | Estilo | Etapas anteriores |
|---|---|---|---|---|
| 1 | B1 | M2 | M6 | — |
| 2 | B2 | M2 | M6 | 5 n.º 3, 8 B |
| 3 | M4 | B1 | N5, N10 | — |
| 4 | M1 | N2 | M5, N6 | 5 n.º 10 |
| 5 | M2, M3, N7, N8 | M1 | N1 | 5 n.º 6, 8 G |
| 6 | N4, N5 | M3 | N3, N4 | — |
| 7 | M7 | M6 | M1 | 5 n.º 1, 8 A |
| 8 | M6 | M5 | N12 | — |
| 9 | N1 | M7 | N9 | — |
| 10 | M5 | N5 | — | — |
| 11 | N9 | M4 | — | — |
| 12 | — | — | M3 | 8 E |
| 13 | — | — | M4, N10 | 5 n.º 8 |
| 14 | — | — | M7 | 5 n.º 9 |
| 15-25 | N2, N6, N10 | N1, N3, N4, N6 | M2, N11, N12 | 5 n.º 4, 5, 7; 8 C, D, F |
