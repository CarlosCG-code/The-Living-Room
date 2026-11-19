# ASSETS.md — Registro de licencias

Todo lo que entra en el proyecto se registra aquí (ver `CLAUDE.md`, «Decisiones fijadas»).

## Va en la build

| Nombre | Versión | Origen | SHA-512 | Licencia | Fecha |
|---|---|---|---|---|---|
| Plantillas de exportación Godot (el motor dentro del `.exe`) | 4.7.2-stable | https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz | `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079` | MIT + terceros (ver abajo) | 2026-11-17 |

| Pixel Operator 8 (`assets/fonts/pixel_operator/PixelOperator8.ttf`, con su `LICENSE.txt`) | 2024 (DaFont) | https://dl.dafont.com/dl/?f=pixel_operator (autor: Jayvee Enaguas; fuentes en notabug.org/HarvettFox96/ttf-pixeloperator) | `ba35cd5f69317fb459ae5ce5bcc45ada470f1ff6a57b6d1b9863c7673293a8f42c64a68f061496876cdf1e7a5a851058d143c778bd20fe4c399137ed96216b40` | CC0 1.0 (comprobada en el `LICENSE.txt` del paquete) | 2026-11-18 |

**Licencias de terceros del motor** (de `COPYRIGHT.txt`; aceptadas por la excepción de `CLAUDE.md` si son permisivas). Sus avisos se entregan con el juego en el hito 7.

Fuente: `COPYRIGHT.txt` de https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt (el `.tpz` no lo incluye). Todas son permisivas y permiten uso comercial:

- Expat (= MIT), MIT-0, X11, HarfBuzz (variantes de MIT); BSD-2-clause, BSD-3-clause; Apache-2.0; Zlib; MPL-2.0; BSL-1.0; Unlicense; CC0-1.0.
- Unicode, FTL (FreeType), IJG (libjpeg), glslang, WOL: permisivas con aviso de copyright.
- OFL-1.1: tipografías del editor y del motor.
- **CC-BY-4.0: solo el logotipo de Godot** (`misc/logo/*`), que es el icono del `.exe` mientras no haya uno propio. Se sustituye antes de distribuir (hito 7).

## Hecho por Claude (sin licencia de terceros)

| Archivo | Cómo se hizo | Fecha |
|---|---|---|
| `assets/textures/tv/*.png` (fondo, fábrica, receptor, máquinas e iconos del árbol) | Pixel art dibujado por código con `tools/build_tv_sprites.gd` (sin assets externos) | 2026-11-18 |
| `assets/audio/tv/*.wav` (avisos de los eventos, relé del clic, tono de prueba, zumbido y dron) | Sintetizados por código con `tools/build_tv_sounds.py` (sin muestras externas ni IA) | 2026-11-18 |
| `assets/models/living_room/` (salón definitivo: paredes, suelo, techo, rodapiés, ventana con persiana y cajón, puerta, lámpara de pie; y su versión en espejo) | Modelado en Blender por `tools/blender/build_living_room.py` (`MODE = "final"`); texturas y muebles de Poly Haven (CC0, abajo) | 2026-11-19 |
| `assets/models/tv.glb` (tele de tubo: mueble, marco, panel con rejilla y mandos, piloto, antena de cuernos) | Modelada en Blender por `tools/blender/build_living_room.py` (`MODE = "tv"`), materiales planos sin texturas | 2026-11-18 |

## Solo desarrollo (no van en la build)

| Nombre | Versión | Origen | SHA-256 | Licencia | Fecha |
|---|---|---|---|---|---|
| GUT | 9.7.1 | https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip | `14969aa46adc84aa08cdd21b9f6d1a64addd92ae60b36f02d0521ed305aa4086` | MIT (`addons/gut/LICENSE.md`); tipografías incluidas OFL-1.1 (`addons/gut/fonts/OFL.txt`) | 2026-11-17 |
| `godot_mcp_runtime` (addon de capturas) | 1.0.0 (de GoPeak 2.4.1) | `%USERPROFILE%\.bun\install\global\node_modules\gopeak\build\addon\godot_mcp_runtime\` | — (copia local; versión de `package.json`) | MIT (`addons/godot_mcp_runtime/LICENSE`) | 2026-11-17 |

## Assets del juego

| Archivo | Fuente (URL) | Autor | Licencia | Fecha |
|---|---|---|---|---|
| `assets/audio/ui/purchase.ogg` (provisional, sonido de compra; se sustituye en el hito 3) | https://freesound.org/people/Qvantor/sounds/878236/ («UI Click Crisp», vista previa HQ en `.ogg`; SHA-256 `4ee7498e0636280cc17b7d2c9be2c4981892d5545e15734832ecb76c9341e9dd`) | Qvantor | CC0 1.0 | 2026-11-17 |
| Sofa 03 (2k; en `assets/models/living_room/`) | https://polyhaven.com/a/sofa_03 (`sofa_03_2k.gltf`, SHA-512 `17b6a990faa470170e719825d6ba48fd9caaff76c1224d30193c0a953ebd779c232dd5576b2ce1bcc64a8755c6f94d131aae56d4e5b002e090dfec92382e5258`) | Fran Calvente | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Vintage Cabinet 01 (2k; en `assets/models/living_room/`) | https://polyhaven.com/a/vintage_cabinet_01 (`vintage_cabinet_01_2k.gltf`, SHA-512 `16a357d0cd974fa1d0b3ca566aec7ade947844a06d4edc32199a5bdcd56e69a80bf64fc0c406967767705dd5ea928e6c566dcd5adc48f15f1d034966b3afa287`) | Rico Cilliers | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Arm Chair 01 (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/ArmChair_01 (`ArmChair_01_1k.gltf`, SHA-512 `6decfc0d06cb2e257875347b7d1e20310fa81a6f626dc5d2f7fd1b0316fa00a0d4208019f9796f067f94fd6cfd38cbbf0647917a2fccc28f5a771a192db4ae50`) | Kirill Sannikov | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Wooden Bookshelf Worn (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/wooden_bookshelf_worn (`wooden_bookshelf_worn_1k.gltf`, SHA-512 `9f381519892b548447d6bb2e4734b93ad87a41ec6acde0caf8775a0190feb5ed54be60f3f82dca34027f65c851b656f81c1028e9cf6b1f88f9a60fae28db5ab7`) | Ulan Cabanilla | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Book Encyclopedia Set 01 (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/book_encyclopedia_set_01 (`book_encyclopedia_set_01_1k.gltf`, SHA-512 `70c3da767a89a7150283a9b893ef2e19e1395756ec9f3663014a666a33b8ec69bbd70e5b09bd57d067e5c32085709e3f5f1ecc17af4c7687b881ed6c9bb81ddf`) | John Malcolm | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Small Wooden Table 01 (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/small_wooden_table_01 (`small_wooden_table_01_1k.gltf`, SHA-512 `e0569f18d82fdaf969c5f53ad21cda8646f3e301398a904d883d02c4edca4447be1cc1f4547bd9e40a7511e94f194103095fb3aa67169d3cbdb67b8aeaaeac0f`) | Ulan Cabanilla | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Side Table 01 (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/side_table_01 (`side_table_01_1k.gltf`, SHA-512 `50792f96cf49a02446c271a6429e81dc662ba1f5a32defa40b85b7f899362c9d52e25335b1cda94e341e83cfc3a06de9f54223cbbf2044043e026fa3dcdb27f8`) | James Ray Cock | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Throw Pillows 01 (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/throw_pillows_01 (`throw_pillows_01_1k.gltf`, SHA-512 `ce21fa44020470c0f5f48facea8b50428b92a1ecc4e599c58be40863f3cae4890fbe57e83525a5c6ce7d0593c739aa590037ab5eae87420d559f99df60fa66a3`) | Serhii Khromov | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Potted Plant 02 (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/potted_plant_02 (`potted_plant_02_1k.gltf`, SHA-512 `f3a4fa063f54bbf186ecbc97b5647dfa5b07bba4f75d3dc1b180a4db50405c99134c2bd88a40455451e98a2ea69389c6fe3297e74df632066afb25817501971a`) | Rico Cilliers | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Wall Clock (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/wall_clock (`wall_clock_1k.gltf`, SHA-512 `20b595ed6e50dfc2ea38291fd1c1e02f3f92b3bda68d2607ef9ce199a77bcd58b5dcfec08de0a7cff494d51472c42924505ad71bea6fa0bd2e7d030387b1cab2`) | PierreB3D | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Herringbone Parquet (2k; en `assets/models/living_room/`) | https://polyhaven.com/a/herringbone_parquet (`herringbone_parquet_diff_2k.jpg`, SHA-512 `4ebc394860965875ce5506b874c4869426730669f44f339ecde69fd422c01331513f6dd93718a2d650c959ec3736c4efbac9cbe84503381c93367c5712011241`) | Jenelle van Heerden, Sergej Majboroda | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| Decrepit Wallpaper (2k; en `assets/models/living_room/`) | https://polyhaven.com/a/decrepit_wallpaper (`decrepit_wallpaper_diff_2k.jpg`, SHA-512 `87908993e84f250189e96a645157be431bc84ef7697b1fd205b8e67df2b3a28014a828d95547746eef80d90685d02243ffe94c35dac0334dd1520d4604d030b3`) | Rob Tuytel | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
| White Stucco (1k; en `assets/models/living_room/`) | https://polyhaven.com/a/white_stucco (`white_stucco_diff_1k.jpg`, SHA-512 `67bcd62e5b3f17cd9d3b75e6a8e03e076bbcfdc103c44ce8ce6730df9d03585b1397a477865a205338898bd7e26786348628ef696639e3dfa861ac559bcc2f01`) | Amal Kumar | CC0 1.0 (polyhaven.com/license) | 2026-11-19 |
