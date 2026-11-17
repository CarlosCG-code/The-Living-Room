# Etapa 9, ronda 2 (revisión final): `specs/hito0.md`, §3-§8

Revisores nuevos: **preparación**, **detalles técnicos** y **estilo**. Los tres terminaron.

**Veredicto:** casi lista. El diseño y casi todo el plan aguantan. Hay **1 fallo que rompería el hito** y unos pocos más que harían fallar pasos concretos. Todos tienen arreglo pequeño.

**Comprobado contra los archivos reales** (detalles técnicos):
- `DevBoot` funciona con el addon tal como está escrito: el addon no necesita ser autoload ni cargarse antes de la escena.
- La lógica de `verify.sh` con `set -euo pipefail` es correcta.
- Git Bash trae `unzip`, `sha256sum` y `sha512sum`.
- La captura de GoPeak abre una ventana real, así que prueba el renderer.

## Hallazgos y propuesta de arreglo

| # | Sev. | Problema | Arreglo propuesto |
|---|---|---|---|
| 1 | 🔴 | **La comprobación de exclusión fallaría siempre** (los tres revisores). Busca el texto `godot_mcp_runtime` en el `.pck`, pero ese texto está también en `dev_boot.gd` (que sí se exporta) y, muy probablemente, en las cachés de Godot (`uid_cache.bin` y la caché de clases). El control positivo tampoco sirve: `presentation/main` siempre aparece, porque `project.godot` lo menciona. | Pasar a la comprobación por **lista de archivos**: exportar también un `.zip` con el mismo preset (`--export-pack`), listarlo con `unzip -Z1` y exigir que no haya archivos bajo `addons/godot_mcp_runtime/`, `addons/gut/` ni `tests/`, y que sí esté `presentation/main.tscn` (o su versión convertida). Escrito literal en `verify.sh` y marcado † (paso 0). Se quita el riesgo de la §8 que ya no aplica. |
| 2 | 🟡 | `verify.sh` no borra la build anterior: si la exportación falla sin dar código de error, se comprobaría el `.exe` viejo. | Borrar `.exe`, `.pck`, `.zip` y `run.log` antes de exportar, y comprobar que el `.exe` existe. |
| 3 | 🟡 | `sha512sum -c` fallaría siempre: `SHA512-SUMS.txt` lista todos los archivos de la versión y solo se descarga uno. | `sha512sum -c --ignore-missing SHA512-SUMS.txt`. |
| 4 | 🟡 | **La comprobación de licencias pararía el hito con seguridad.** El motor Godot incluye librerías con licencias que no están en la lista de `CLAUDE.md`: Expat (es la MIT con otro nombre), ISC, FreeType (FTL), Unicode y BSL-1.0, todas permisivas, más el logotipo CC-BY 4.0. **Esto toca una «Decisión fijada»: decides tú** (ver abajo). | Ver la pregunta al final. |
| 5 | 🟡 | Comprobación LSP: no se dice cómo arrancar y parar el servidor, y el nombre de la herramienta es incorrecto (es `lsp_get_diagnostics`). | Arrancar `$GODOT --headless --editor --path . --lsp-port 6005` en segundo plano, esperar hasta 30 s a que el puerto responda, llamar a `lsp_get_diagnostics` (con `projectPath` absoluto) para cada script y cerrar el proceso. |
| 6 | 🟡 | La licencia de GUT se copia «si está dentro», sin decir qué hacer si no lo está. | Si `addons/gut/` no trae licencia, copiar `Gut-9.7.1/LICENSE.md` a `addons/gut/LICENSE.md` (añadido a la §3). |
| 7 | 🟡 | La frase de `CLAUDE.md` que queda sigue hablando de «su autoload `MCPRuntime`», que D4 descartó. El GDD §11 repite esa frase. | El paso 10 sustituye también esa frase («El addon (nodo `MCPRuntime`, que añade `DevBoot`) se excluye de toda build exportada…») y corrige el GDD §11, como manda `CLAUDE.md` cuando los dos no coinciden. |
| 8 | 🟡 | «Paso 5» significa dos cosas: un paso de la §5 y un bloque de `verify.sh`. | Los bloques de `verify.sh` pasan a llamarse «comprobación 1-5». |
| 9 | 🟡 | `ASSETS.md`: no se dice qué SHA registrar del addon (es una carpeta copiada) y la tabla «Va en la build» no tiene columnas. | Addon: «— (copia local; versión de `package.json`)». Tabla de la build: nombre, versión, origen, SHA-512, licencia, fecha. |
| 10 | 🟢 | GUT podría pasar sin ejecutar ningún test, si no los encuentra. | `verify.sh` comprueba además que el log de GUT indica 2 tests pasados (texto exacto en el paso 0). |
| 11 | 🟢 | La captura puede pedirse antes de que el addon esté listo. | Reintentar cada segundo, hasta 10 veces, y cerrar el juego después (`stop_project`). |
| 12 | 🟢 | Los pasos no recogen tu prueba y aprobación de la build, y el push iría antes. | Paso nuevo antes del commit: enseñar la captura y que abras `build/TheLivingRoom.exe` y lo apruebes. |
| 13 | 🟢 | Varios detalles de redacción: definir «build de depuración» (el proyecto ejecutado sin exportar), la leyenda †, usar una ruta absoluta en `--log-file`, «crear los archivos marcados "crear"», si GoPeak no conecta «se para y se avisa al usuario», la ruta en formato bash, «GUT 9.7.1», «especificación» en vez de «spec» y otras pequeñas correcciones. | Se aplican todos. |

## La decisión que necesito de ti (punto 4)

`CLAUDE.md` dice que dentro del juego solo puede ir código con licencia MIT, Apache-2.0, BSD, Zlib, MPL-2.0 o CC0. Pero **el propio motor Godot**, que va dentro de todo juego hecho con Godot, incluye librerías con otras licencias. Todas son gratuitas, permiten uso comercial y solo piden incluir su aviso de licencia (algo que ya está previsto para el hito 7). La excepción es el logotipo de Godot (CC-BY 4.0), que solo está en el icono del `.exe` y se sustituye antes de distribuir.

Propuesta: **aceptar las licencias de terceros del motor Godot** como excepción a esa lista, con dos condiciones: que sean permisivas (como las de arriba) y que sus avisos se incluyan con el juego. Si en `COPYRIGHT.txt` aparece alguna que no sea permisiva, se para y se te avisa. Habría que añadir una línea a `CLAUDE.md`.

La alternativa es no poder usar Godot, porque no existe una build del motor sin esas librerías.
