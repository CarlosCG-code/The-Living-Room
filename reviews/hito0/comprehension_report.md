# Etapa 6 — Prueba de comprensión: `specs/hito0.md`

Un lector nuevo leyó **solo la spec**, sin `CLAUDE.md` ni el GDD, y la explicó con sus palabras. Diseño = líneas 1-28; implementación = líneas 29-127.

## What this proposes

El hito 0 monta un proyecto Godot 4.7.2 vacío pero funcional para «The Living Room», con el proyecto en la raíz del repositorio. Incluye:
- GUT 9.7.1 (framework de tests), que se ejecuta sin gráficos desde la línea de comandos.
- Un addon de capturas (`godot_mcp_runtime`, copiado de una instalación local de GoPeak 2.4.1) que solo funciona en builds de depuración. Lo carga un autoload propio, `DevBoot`, solo si la build es de depuración y el script existe. El filtro de exportación también lo quita, así que las builds release nunca lo mencionan.
- Los textos salen de un CSV de traducción en español, y una escena principal provisional muestra el título traducido.
- `tools/verify.sh` importa el proyecto, ejecuta los tests, exporta una build release de Windows y comprueba que arranca: se ejecuta sin gráficos con `--quit-after 120`, debe salir con código 0 y su log no debe contener `ERROR`.

El hito se cierra cuando todos los tests pasan, se ha enseñado la captura al usuario, el usuario ha abierto y aprobado la build, y se ha hecho commit y push.

## How the existing system works, per this document

Por ahora el repositorio solo tiene documentos de diseño (`CLAUDE.md`, `GAME_DESIGN.md`) y un `.gitignore` que ya ignora `.godot/` y `/build/`. Todavía no hay proyecto Godot.

Fuera del repositorio hay un paquete GoPeak 2.4.1 instalado, que funciona como «el servidor MCP en uso». Puede hacer capturas de un proyecto en ejecución y espera encontrar un nodo en `/root/MCPRuntime`.

El usuario no usa el editor de Godot: Claude hace todo desde la línea de comandos. `CLAUDE.md` tiene reglas fijas que la spec cita sin repetirlas, como «solo CC0» para los assets o las columnas de la tabla de assets.

**Conclusión:** la paráfrasis coincide con lo que se pretende. El diseño se entiende sin leer otros documentos.

## Hallazgos

> **Nota:** este lector no tenía acceso a `CLAUDE.md` a propósito. Algunas cosas que marca como «no definidas» sí lo están ahí: la variable `GODOT`, qué es GoPeak, el MCP `godot` y EGM. Aun así, una línea de requisitos en la spec la hace autosuficiente y cuesta poco.

### 🟡 Importantes

1. **GoPeak, «el servidor MCP» y «el MCP `godot`» no se definen** (D3, `dev_boot.gd`, pasos 2 y 8, §6).
   - **Problema:** no se dice qué es GoPeak, dónde está su paquete instalado, ni si «MCP `godot`» es lo mismo. El paso 2 («copiar desde el paquete instalado») no se puede hacer sin la ruta.
   - **Cambio:** una frase que defina GoPeak (servidor MCP que controla Godot y hace capturas a través del nodo `MCPRuntime` del juego), la ruta absoluta del paquete, y que «MCP `godot`» es el nombre con el que está registrado GoPeak.

2. **`$GODOT` y la shell de `verify.sh`** (pasos 4-5, `verify.sh`).
   - **Problema:** no se dice a qué ejecutable apunta `$GODOT` ni quién lo define. Además, `verify.sh` es un script de bash en un proyecto de Windows, y no se dice con qué se ejecuta (Git Bash, WSL…).
   - **Cambio:** una línea de «Requisitos»: `GODOT` apunta al ejecutable de consola de Godot 4.7.2 (con su ruta), y `verify.sh` se ejecuta con Git Bash.

3. **La prueba de arranque (D7) y la de exclusión no se pueden reproducir** (D7, `export_presets.cfg`, §6).
   - **Problema:** no se dice en qué unidad va el «120» (`--quit-after` cuenta fotogramas, no segundos), ni cómo se captura el log, ni con qué herramienta se lista el `.pck`, ni si el `.pck` va dentro del `.exe` o aparte.
   - **Cambio:** fijar la unidad, la forma de capturar el log y el método para listar el `.pck`. Coincide con los hallazgos 2 y 3 de la etapa 5.

4. **Falta la URL de descarga de las plantillas** (D5, paso 6).
   - **Problema:** se da el nombre del archivo y la carpeta de destino, pero no la URL oficial ni de dónde sale `SHA512-SUMS.txt`.
   - **Cambio:** poner las URL oficiales del `.tpz` y de `SHA512-SUMS.txt`.

### 🟢 Menores

5. **D4: por qué «no se registra» `MCPRuntime`.** Explicar que la instalación normal del addon añade un autoload `MCPRuntime` y que aquí ese paso se omite a propósito. «Lo comprobé en su código» no dice quién lo comprobó ni dónde: citar el archivo o la función que desactiva el addon en release.
6. **`.gdkeep` (§3).** No es una convención conocida; usar `.gitkeep` o explicarlo. Coincide con el hallazgo 6 de la etapa 5.
7. **Referencias sin explicar:** «revisión EGM», «Decisiones fijadas», «solo CC0», «el instalador de VoiceStudio», `EventBus`. Añadir unas palabras a cada una o citar la sección de `CLAUDE.md`.
8. **«`Label3D` o un texto en pantalla».** Elegir uno. Coincide con el hallazgo 10 de la etapa 5.
9. **Test de `DevBoot`:** decir el nombre de la función que recibe la ruta, que el padre es el nodo raíz, y que el test espera un fotograma antes de comprobar (porque el nodo se añade de forma diferida).
10. **Recurso de traducción:** dar la ruta exacta del archivo generado (p. ej. `locale/strings.es.translation`) y decir que lo crea el paso de importación (paso 4).

**No comprobado por el revisor:** si las secciones citadas de `CLAUDE.md` y del GDD existen o concuerdan, ni si las afirmaciones técnicas son ciertas (versiones de GUT, `--quit-after`, desactivación del addon en release).
