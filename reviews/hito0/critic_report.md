# Etapa 7 — Crítica: `specs/hito0.md`, líneas 1-28 (§1 Objetivo, §2 Decisiones)

Ronda 1. Revisores: **diseño**, **estructura** y **estilo**. Estándar: `feature-spec-standard`. Contexto: `CLAUDE.md`, `GAME_DESIGN.md`. Los tres revisores terminaron.

**Veredicto:** hacen falta cambios. Hay 1 bloqueante (no se explican las alternativas descartadas) y 6 importantes. Varios hallazgos repiten los de la etapa 5; aquí se indica cuáles.

**Aviso:** nadie comprobó el código de GoPeak ni el de GUT, ni el comportamiento real de Godot 4.7.2. Los puntos 2, 3 y 4 son afirmaciones sin verificar, no fallos confirmados.

## 🔴 Bloqueante

### 1. No se dicen qué alternativas se descartaron (estructura B1, diseño M1)
- **Dónde:** tabla de la §2 (líneas 19-27).
- **Problema:** cada decisión da una sola propuesta. El estándar de especificación exige mostrar qué otras opciones se consideraron y por qué se rechazaron. Además, el GDD §11 deja precisamente a esta spec «la técnica de exclusión y la instalación de las plantillas».
- **Cambio:** añadir una columna «Alternativas descartadas». Cuando la decisión venga impuesta, poner «forzada por CLAUDE.md §X». Candidatas:
  - **D1:** una subcarpeta `game/` (descartada: rutas distintas entre el repositorio y `res://`).
  - **D2:** GUT 9.7.0, o GUT desde la AssetLib.
  - **D3:** el addon tomado de la última versión del código de GitHub (descartada: podría no coincidir con el servidor 2.4.1).
  - **D4:** (a) registrar `MCPRuntime` y quitarlo al exportar con un plugin de exportación (descartada: necesita un plugin del editor activo al exportar); (b) un `override.cfg` solo de desarrollo (sin verificar en 4.7.2; mecanismo poco conocido); (c) `DevBoot`, que es la propuesta.
  - **D5:** instalar solo las plantillas de Windows.
  - **D6:** archivos gettext `.po` (descartada: `CLAUDE.md` fija CSV).
  - **D7:** ejecución sin gráficos frente a ejecución con ventana, o leer el archivo de log.

## 🟡 Importantes

### 2. La prueba «arranca» (D7) puede pasar sin probar nada (diseño M2, estructura M4, estilo N8; repite la etapa 5 n.º 2)
- **Dónde:** línea 27.
- **Problema:**
  - `--headless` no inicia el renderer, así que no detecta fallos de gráficos.
  - No se dice de dónde sale el «log». Un `.exe` release de Windows puede no escribir en la consola, y un log vacío «no tiene errores».
  - El «120» cuenta fotogramas, no segundos.
  - Poner `SCRIPT ERROR` sobra, porque ya contiene `ERROR`.
- **Cambio:** leer el log de un archivo (`--log-file` o `user://logs/godot.log`); exigir una línea `BOOT_OK` impresa por `main.gd`; fallar si el log está vacío; escribir «120 fotogramas»; añadir una ejecución con ventana para que arranque el renderer real.

### 3. D4 depende de cómo funciona GoPeak, y eso no se ha comprobado (diseño M3, estilo M1-M2, estructura N8; repite la etapa 5 n.º 4)
- **Dónde:** línea 24.
- **Problema:**
  - D4 solo funciona si a GoPeak le basta con un nodo en `/root/MCPRuntime`. Si GoPeak añade el autoload a `project.godot` por su cuenta, vuelve justo el fallo que D4 quiere evitar.
  - El nodo se añade de forma diferida, después de la escena principal. Un autoload normal se carga antes. No se dice si eso le importa a GoPeak.
  - «Lo comprobé en su código» está en primera persona y no cita archivo ni línea.
  - «Así no hay nada que quitar al exportar» contradice la misma celda, que dice que la exportación excluye el addon.
- **Cambio:** citar el archivo y la función de GoPeak 2.4.1 que buscan el runtime, y los del addon que lo desactivan en release. Escribir: «Así `project.godot` no cambia entre desarrollo y release; la exportación solo excluye archivos». Añadir un riesgo en la §8: «si GoPeak inyecta el autoload, se usa la alternativa (a)».

### 4. Versiones y orígenes poco precisos (diseño M4, estilo M5-M6 y N5)
- **Dónde:** D2 y D3 (líneas 22-23).
- **Problema:**
  - **D2:** «es la última versión» caduca y no demuestra compatibilidad con 4.7.2, que es lo que pide el GDD. Una etiqueta de GitHub se puede mover y no se registra ningún hash del zip. Eso contradice la regla de D3, «nada se descarga sin versión fija».
  - **D3:** «ya instalado y verificado» no dice qué se verificó ni en qué ruta está el paquete. Tampoco dice que se copie el `LICENSE` del addon. La razón «nada se descarga» no encaja, porque el addon se copia, no se descarga.
- **Cambio:**
  - **D2:** «9.7.1, compatible con 4.7 desde la 9.7.0», con enlace a las notas de versión. Registrar el SHA-256 del zip en `ASSETS.md`.
  - **D3:** dar la ruta exacta de GoPeak, copiar el `LICENSE` del addon y anotar que hay que volver a copiar el addon si se actualiza GoPeak.

### 5. Al objetivo le faltan entregables y tiene criterios que no se pueden comprobar (estructura M2, diseño N1, estilo M4)
- **Dónde:** líneas 8-13.
- **Problema:**
  - El GDD §11 pide dos cosas que no están en el objetivo: anotar las ubicaciones de carpetas en `CLAUDE.md` y crear `ASSETS.md` con las dependencias (versión, origen y licencia).
  - «Abre e importa sin errores» y «las capturas funcionan» no son medibles. Además, el usuario nunca abre el editor.
- **Cambio:** añadir esos dos puntos. Reescribir: «`$GODOT --headless --import` termina con código 0 y sin líneas `ERROR`» y «el MCP `godot` obtiene una captura del juego en ejecución (build de depuración) mediante el addon `godot_mcp_runtime`».

### 6. Falta una decisión en la tabla: dónde van autoloads, datos, tests y assets (estructura M3)
- **Problema:** `CLAUDE.md` dice que el hito 0 fija esas ubicaciones. La spec lo decide solo dentro del árbol de la §3, sin fila propia ni justificación.
- **Cambio:** añadir **D8** con las rutas (`autoload/`, `data/`, `tests/unit/`, `assets/`), el porqué y las alternativas. Por ejemplo, `core/autoload/` se descarta porque `core/` no lleva nodos.

### 7. D1 se justifica con un acuerdo que no está escrito en ninguna parte (estructura M5, estilo M3, diseño N3)
- **Dónde:** línea 21, «Acordado al ordenar el repositorio».
- **Cambio:** dar una razón técnica: «`res://` = raíz del repositorio, así las rutas de `CLAUDE.md` (`core/`, `presentation/`…) son las mismas». Opcional: citar el commit `5cda33b`. Efecto secundario: Godot escaneará `specs/` y `reviews/`, así que conviene un `.gdignore` en cada una (repite la etapa 5 n.º 7).

## 🟢 Menores

8. **Referencia rota (línea 4):** `CLAUDE.md` no tiene ninguna sección «Verificación»; es «Cómo trabajar».
9. **Las líneas 3 y 4 se juntan al mostrarse**, porque el formato Markdown las une en un solo párrafo. Separarlas con una línea `>` vacía.
10. **D6, idioma «por defecto»:** Godot no tiene un ajuste de idioma por defecto. Usa el del sistema operativo, y el español solo funciona aquí como idioma de reserva. Decir eso o llamar a `TranslationServer.set_locale("es")`. Además, la §4 solo configura el idioma de reserva.
11. **D5:** comprobar con `SHA512-SUMS.txt` del mismo origen demuestra que la descarga está entera, no quién la publicó. Es aceptable, pero hay que decirlo. Si Godot funciona en modo autocontenido (un archivo `._sc_` junto al ejecutable), la ruta `%APPDATA%` es otra: decir que no es el caso.
12. **Seguridad del addon:** decir qué puerto abre en las ejecuciones de depuración y si solo escucha en `127.0.0.1`.
13. **Caché de clases:** si GUT o el addon declaran `class_name`, la caché exportada puede apuntar a scripts excluidos. Anotarlo como riesgo (lo detectaría el log de D7).
14. **Fuera de alcance (línea 15):** añadir integración continua y build firmada; decir que `main.tscn` se sustituye en el hito 2.
15. **Estilo:**
    - «vacío pero completo» → «sin lógica de juego, que cumple:».
    - «los textos salen» → «todo texto visible se obtiene con `tr()` desde `locale/strings.csv`».
    - Añadir «(definido en D7)» tras «arranca».
    - «escenas reales» → «escenas del juego».
    - «el script» en D4 → la ruta exacta.
    - «Gratis» → «Gratuitas (cumple "Todo gratuito y libre")».
    - Usar la misma puntuación final en todas las celdas «Por qué».

## Correspondencia con los informes originales

| Aquí | Diseño | Estructura | Estilo |
|---|---|---|---|
| 1 | M1 | B1 | — |
| 2 | M2 | M4 | N8 |
| 3 | M3 | N8 | M1, M2 |
| 4 | M4 | — | M5, M6, N5 |
| 5 | N1 | M2 | M4 |
| 6 | — | M3 | — |
| 7 | N3 | M5 | M3 |
| 8–9 | — | N6, N7 | — |
| 10 | N5 | N9 | — |
| 11–14 | N4, N6, N6, N2 | — | — |
| 15 | — | — | N1-N4, N6, N7, N8 |
