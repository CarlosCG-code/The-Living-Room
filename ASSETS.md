# ASSETS.md — Registro de licencias

Todo lo que entra en el proyecto se registra aquí (ver `CLAUDE.md`, «Decisiones fijadas»).

## Va en la build

| Nombre | Versión | Origen | SHA-512 | Licencia | Fecha |
|---|---|---|---|---|---|
| Plantillas de exportación Godot (el motor dentro del `.exe`) | 4.7.2-stable | https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz | `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079` | MIT + terceros (ver abajo) | 2026-11-17 |

**Licencias de terceros del motor** (de `COPYRIGHT.txt`; aceptadas por la excepción de `CLAUDE.md` si son permisivas). Sus avisos se entregan con el juego en el hito 7.

Fuente: `COPYRIGHT.txt` de https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt (el `.tpz` no lo incluye). Todas son permisivas y permiten uso comercial:

- Expat (= MIT), MIT-0, X11, HarfBuzz (variantes de MIT); BSD-2-clause, BSD-3-clause; Apache-2.0; Zlib; MPL-2.0; BSL-1.0; Unlicense; CC0-1.0.
- Unicode, FTL (FreeType), IJG (libjpeg), glslang, WOL: permisivas con aviso de copyright.
- OFL-1.1: tipografías del editor y del motor.
- **CC-BY-4.0: solo el logotipo de Godot** (`misc/logo/*`), que es el icono del `.exe` mientras no haya uno propio. Se sustituye antes de distribuir (hito 7).

## Solo desarrollo (no van en la build)

| Nombre | Versión | Origen | SHA-256 | Licencia | Fecha |
|---|---|---|---|---|---|
| GUT | 9.7.1 | https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip | `14969aa46adc84aa08cdd21b9f6d1a64addd92ae60b36f02d0521ed305aa4086` | MIT (`addons/gut/LICENSE.md`); tipografías incluidas OFL-1.1 (`addons/gut/fonts/OFL.txt`) | 2026-11-17 |
| `godot_mcp_runtime` (addon de capturas) | 1.0.0 (de GoPeak 2.4.1) | `%USERPROFILE%\.bun\install\global\node_modules\gopeak\build\addon\godot_mcp_runtime\` | — (copia local; versión de `package.json`) | MIT (`addons/godot_mcp_runtime/LICENSE`) | 2026-11-17 |

## Assets del juego

| Archivo | Fuente (URL) | Autor | Licencia | Fecha |
|---|---|---|---|---|
