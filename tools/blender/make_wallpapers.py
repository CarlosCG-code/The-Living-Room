"""Papeles pintados de los años 40 y azulejo blanco, dibujados por código (usuario, 2026-11-21: no hay papel de
época con licencia CC0). Solo matemáticas con numpy, sin IA generativa. Cada textura cubre 2,5 m de pared (como
uv_world(o, 2.5)) y se repite sin costura: todo es periódico en [0, 1).

Blender sin ventana (usa su numpy y guarda los .jpg):
    blender -b --factory-startup --python-expr "ROOT = r'<proyecto>'; exec(open(ROOT + '/tools/blender/make_wallpapers.py').read())"

Salida: art_source/generated/<id>/<id>_{diff,nor_gl,rough}_2k.png, con la misma forma que las de Poly Haven para
que tex_mat las cargue igual (tex_mat(..., root=GEN)).
"""
import os

import bpy
import numpy as np

ROOT = globals().get("ROOT", os.getcwd())
GEN = os.path.join(ROOT, "art_source", "generated")
N = 2048
rng = np.random.default_rng(1940)
v, u = np.meshgrid(np.arange(N) / N, np.arange(N) / N, indexing="ij")  # v hacia arriba de la pared, u a lo ancho


def blur(a, sigma_px):
    """Desenfoque gaussiano periódico (por FFT): el resultado sigue repitiéndose sin costura."""
    f = np.fft.fftfreq(N)
    g = np.exp(-2 * (np.pi * sigma_px) ** 2 * (f[:, None] ** 2 + f[None, :] ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g))


def norm01(a):
    return (a - a.min()) / (a.max() - a.min() + 1e-9)


def smooth(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)


# Envejecido común: manchas grandes y suaves, más amarillo con los años, y papel con algo de grano.
STAINS = norm01(blur(rng.standard_normal((N, N)), 90)) * 0.6 + norm01(blur(rng.standard_normal((N, N)), 25)) * 0.4
GRAIN = blur(rng.standard_normal((N, N)), 1.2)
GRAIN /= GRAIN.std()


def age(rgb, amount=0.22):
    k = 1.0 - amount * smooth(0.35, 0.95, STAINS)
    yellow = np.stack([np.ones_like(k), 0.97 + 0.03 * k, 0.88 + 0.12 * k], -1)
    return rgb * k[..., None] * yellow * (1 + 0.025 * GRAIN[..., None])


def mix(a, b, t):
    return np.asarray(a) * (1 - t[..., None]) + np.asarray(b) * t[..., None]


def cells(cols, rows, half_drop=True):
    """Coordenadas locales (-0,5..0,5) en una rejilla; las columnas impares bajan media fila."""
    x = u * cols
    col = np.floor(x)
    y = v * rows + (0.5 * (col % 2) if half_drop else 0)
    return x - col - 0.5, y - np.floor(y) - 0.5


def damask():
    """Salón, comedor, dormitorio principal y recibidor: flor de cuatro pétalos con rombo, en ocre oliva."""
    x, y = cells(8, 7)
    x = x * (2.5 / 8) / (2.5 / 7)  # celda casi cuadrada en metros
    r, th = np.hypot(x, y), np.arctan2(y, x)
    petals = 0.30 * (0.45 + 0.55 * np.abs(np.cos(2 * th)) ** 1.5)
    shape = np.maximum(smooth(0.006, -0.006, r - petals), smooth(0.006, -0.006, np.abs(x) * 2.4 + np.abs(y) - 0.46))
    hole = smooth(0.006, -0.006, r - 0.06)
    outline = smooth(0.012, 0.0, np.abs(r - petals - 0.03)) * (1 - shape)
    motif = np.clip(shape - 0.6 * hole, 0, 1)
    pin = smooth(0.0016, 0.0, np.abs((u * 8 + 0.5) % 1 - 0.5) / 8 - 0.0)  # filete entre columnas
    rgb = mix((0.34, 0.31, 0.22), (0.45, 0.4, 0.28), motif)
    rgb = mix(rgb, (0.28, 0.25, 0.18), np.clip(outline * 0.7 + pin * 0.8, 0, 1))
    return rgb, motif * 0.6 + outline * 0.3, 0.8 - 0.12 * motif


def stripes():
    """Pasillos: rayas anchas en dos tonos de beis con un filete fino y una línea de puntos."""
    p = (u * 20) % 1  # 12,5 cm por raya doble
    band = smooth(0.003, 0.0, np.abs(p - 0.25) - 0.25)
    pin = smooth(0.006, 0.0, np.abs(p - 0.75))
    dots = smooth(0.0015, 0.0, np.hypot((p - 0.62) * 2.5 / 20, ((v * 60) % 1 - 0.5) * 2.5 / 60) - 0.004)  # en metros
    rgb = mix((0.44, 0.39, 0.3), (0.37, 0.32, 0.24), band)
    rgb = mix(rgb, (0.27, 0.23, 0.17), np.clip(pin + dots, 0, 1))
    return rgb, band * 0.25 + pin * 0.3, 0.83 - 0.05 * band


def sprig():
    """Dormitorios pequeños: florecillas rosa viejo con dos hojas, en rejilla al tresbolillo."""
    x, y = cells(14, 14)
    r, th = np.hypot(x, y), np.arctan2(y, x)
    flower = smooth(0.01, -0.01, r - 0.16 * (0.6 + 0.4 * np.abs(np.cos(2.5 * th))))
    centre = smooth(0.01, -0.01, r - 0.045)
    leaf = lambda cx, cy, a: smooth(0.01, -0.01, np.hypot(((x - cx) * np.cos(a) + (y - cy) * np.sin(a)) / 0.13,
                                                          (-(x - cx) * np.sin(a) + (y - cy) * np.cos(a)) / 0.05) - 1)
    leaves = np.clip(leaf(0.17, -0.12, -0.6) + leaf(-0.17, -0.12, 0.6), 0, 1) * (1 - flower)
    rgb = mix((0.47, 0.41, 0.36), (0.42, 0.27, 0.25), flower)
    rgb = mix(rgb, (0.52, 0.42, 0.3), centre)
    rgb = mix(rgb, (0.3, 0.33, 0.24), leaves)
    return rgb, (flower + leaves) * 0.4, 0.82 - 0.05 * flower


def paint():
    """Cocina, baños, despensa, taller, trastero y galería: pintura al temple vieja, lisa, con brochazos."""
    strokes = np.repeat(rng.standard_normal((N // 64, N)), 64, axis=0)  # brochazos verticales
    brush = norm01(blur(strokes, 6) + 0.6 * blur(rng.standard_normal((N, N)), 14))
    rgb = np.ones((N, N, 3)) * np.array((0.5, 0.48, 0.42)) * (0.95 + 0.08 * brush[..., None])
    return rgb, brush * 0.5, 0.88 + 0.0 * brush


def hash01(i):
    return (np.sin(i * 12.9898 + 4.1414) * 43758.5453) % 1.0


def tiles():
    """Zócalo de baño y cocina de los años 30-40 (usuario, 2026-11-21: el blanco liso parecía de 2026): azulejo
    crema de 15 × 15 cm biselado y cuarteado, rodapié verde botella, cenefa azul de cobalto a 1,2 m y junta sucia.
    La textura cubre 2,4 m (uv_world(o, 2.4)) y v = 0 es el suelo: fila 0 = rodapié, fila 8 = cenefa."""
    n = 16
    p, q = (u * n) % 1, (v * n) % 1
    row, tid = np.floor(v * n), np.floor(u * n) * 31 + np.floor(v * n) * 17
    edge = np.minimum(np.minimum(p, 1 - p), np.minimum(q, 1 - q))
    joint = smooth(0.022, 0.012, edge)
    bevel = smooth(0.012, 0.09, edge)  # el canto redondeado del azulejo de entonces
    tone = 0.9 + 0.1 * hash01(tid)
    rgb = np.ones((N, N, 3)) * np.array((0.7, 0.64, 0.5)) * tone[..., None]
    rgb = np.where((row == 0)[..., None], np.array((0.03, 0.09, 0.055)) * (0.85 + 0.3 * hash01(tid))[..., None], rgb)
    # Cenefa: rombo con flor en el centro y cuartos de círculo en las esquinas, que se enlazan de un azulejo a otro.
    x, y = p - 0.5, q - 0.5
    d, c = np.abs(x) + np.abs(y), np.minimum(np.hypot(p, q), np.minimum(np.hypot(1 - p, q), np.minimum(np.hypot(p, 1 - q), np.hypot(1 - p, 1 - q))))
    ink = np.maximum.reduce([smooth(0.04, 0.02, np.abs(d - 0.36)), smooth(0.13, 0.1, np.hypot(x, y)), smooth(0.04, 0.02, np.abs(c - 0.2))])
    band = (row == 8) * ink
    rgb = mix(rgb, (0.025, 0.07, 0.2), band * 0.92)
    # Cuarteado del vidriado: los cruces por cero de un ruido son líneas finas como las grietas del esmalte.
    craze = smooth(0.06, 0.0, np.abs(blur(rng.standard_normal((N, N)), 7)) / 0.02) * (hash01(tid + 7) > 0.35)
    rgb *= (1 - 0.22 * craze)[..., None]
    chip = (hash01(tid + 3) > 0.93) * smooth(0.16, 0.12, np.minimum.reduce([np.hypot(p, q), np.hypot(1 - p, 1 - q)]))
    rgb = mix(rgb, (0.38, 0.3, 0.22), chip)  # algún azulejo desconchado en la esquina, el bizcocho al aire
    # Suciedad de muchos años (usuario, 2026-11-22: «más sucias/desgastadas»): roña junto al suelo, manchas grandes y
    # chorretones verticales que bajan desde la cenefa, y la junta casi negra.
    runs = norm01(blur(np.repeat(rng.standard_normal((1, N)), N, axis=0), 2.5))
    runs = smooth(0.62, 0.9, runs) * smooth(0.55, 0.2, v) * (0.6 + 0.4 * norm01(blur(rng.standard_normal((N, N)), 40)))
    dirt = np.clip(0.15 + smooth(0.22, 0.0, v) * 0.6 + 0.7 * smooth(0.25, 0.9, STAINS) + 0.7 * runs, 0, 1)
    rgb = mix(rgb, (0.06, 0.05, 0.035), joint * 0.95)
    rgb = rgb * (1 - 0.65 * dirt)[..., None] * mix(np.ones((N, N, 3)), (1.0, 0.9, 0.72), dirt)  # oscurece y amarillea
    return rgb, bevel * (1 - 0.4 * chip) - 0.05 * craze, 0.15 + 0.7 * joint + 0.6 * chip + 0.45 * dirt


def floor_hydraulic():
    """Baldosa hidráulica de 20 × 20 cm (cocina, baños, galería): rosetón rojo y ocre que se cierra entre cuatro
    baldosas, rombo negro en el centro y cenefa crema, gastada por el paso. La textura cubre 2 m (uv_world(f, 2.0))."""
    n = 10
    p, q = (u * n) % 1, (v * n) % 1
    x, y = p - 0.5, q - 0.5
    tid = np.floor(u * n) * 13 + np.floor(v * n) * 7
    r_corner = np.minimum(np.minimum(np.hypot(p, q), np.hypot(1 - p, q)), np.minimum(np.hypot(p, 1 - q), np.hypot(1 - p, 1 - q)))
    ang = np.arctan2(q - np.round(q), p - np.round(p))
    petal = r_corner < 0.36 + 0.06 * np.cos(ang * 8)
    rgb = np.ones((N, N, 3)) * np.array((0.42, 0.36, 0.27))  # fondo crema
    rgb = np.where(petal[..., None], np.array((0.28, 0.06, 0.04)), rgb)
    rgb = np.where((r_corner < 0.17)[..., None], np.array((0.45, 0.28, 0.08)), rgb)
    rgb = np.where(((np.abs(x) + np.abs(y)) < 0.16)[..., None], np.array((0.03, 0.03, 0.03)), rgb)
    ring = np.abs(np.maximum(np.abs(x), np.abs(y)) - 0.43) < 0.012
    rgb = np.where(ring[..., None], np.array((0.08, 0.1, 0.1)), rgb)
    edge = np.minimum(np.minimum(p, 1 - p), np.minimum(q, 1 - q))
    joint = smooth(0.012, 0.004, edge)
    wear = smooth(0.3, 0.9, STAINS) * 0.5 + 0.08 * hash01(tid)
    rgb = mix(rgb, (0.35, 0.32, 0.28), wear) * (0.92 + 0.08 * hash01(tid + 1))[..., None]
    rgb = mix(rgb, (0.08, 0.07, 0.06), joint)
    return rgb, 1 - joint, 0.6 + 0.3 * joint - 0.1 * (1 - wear)


def floor_checker():
    """Despensa y fresquera: baldosa de barro rojo y negra al tresbolillo (20 cm), más basta que la hidráulica."""
    n = 10
    tid = np.floor(u * n) + np.floor(v * n)
    p, q = (u * n) % 1, (v * n) % 1
    dark = (tid % 2 == 1)[..., None]
    k = (0.85 + 0.15 * hash01(np.floor(u * n) * 13 + np.floor(v * n) * 7))[..., None]
    rgb = np.where(dark, np.array((0.04, 0.035, 0.03)), np.array((0.3, 0.1, 0.05))) * k
    joint = smooth(0.015, 0.005, np.minimum(np.minimum(p, 1 - p), np.minimum(q, 1 - q)))
    rgb = mix(rgb, (0.12, 0.1, 0.08), joint) * (1 - 0.3 * smooth(0.4, 0.95, STAINS))[..., None]
    return rgb, 1 - joint, 0.75 + 0.2 * joint


def porcelain():
    """Loza y esmalte viejos para bañera, inodoro, lavabo y palangana (usuario, 2026-11-22: lo liso parecía de 2026;
    la textura de yeso parecía granito y la de chapa oxidada, una bañera podrida): vidriado crema, cuarteado fino,
    roña en manchas y algún desconchón con el hierro negro al aire. Cubre 0,6 m (made(..., uv=0.6))."""
    craze = smooth(0.05, 0.0, np.abs(blur(rng.standard_normal((N, N)), 5)) / 0.03)
    grime = smooth(0.35, 0.95, STAINS)
    chips = smooth(0.9, 0.97, norm01(blur(rng.standard_normal((N, N)), 3)))
    rgb = np.ones((N, N, 3)) * np.array((0.74, 0.71, 0.62)) * (0.96 + 0.04 * GRAIN[..., None] * 0.3)
    rgb *= (1 - 0.18 * craze)[..., None]
    rgb = mix(rgb, (0.42, 0.34, 0.2), grime * 0.45)
    rgb = mix(rgb, (0.03, 0.03, 0.03), chips)
    return rgb, 1 - 0.6 * chips - 0.05 * craze, 0.12 + 0.3 * grime + 0.6 * chips


def save(img_id, kind, arr):
    folder = os.path.join(GEN, img_id)
    os.makedirs(folder, exist_ok=True)
    rgba = np.concatenate([np.clip(arr, 0, 1), np.ones((N, N, 1))], -1).astype(np.float32)
    img = bpy.data.images.new("%s_%s" % (img_id, kind), N, N, alpha=False)
    img.pixels.foreach_set(rgba.ravel())  # Blender guarda las filas de abajo arriba: v = 0 es el pie de la pared
    # PNG: Godot rechazaba los JPG que escribe Blender (ERR_FILE_CORRUPT al importar el glTF).
    img.filepath_raw = os.path.join(folder, "%s_%s_2k.png" % (img_id, kind))
    img.file_format = "PNG"
    img.save()


def normal_from_height(h, strength):
    gy, gx = np.gradient(h)
    n = np.stack([-gx * strength, -gy * strength, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def write(img_id, fn, aging):
    rgb, height, rough = fn()
    srgb = np.clip(age(rgb, aging), 0, 1) ** (1 / 2.2)  # los colores de arriba son lineales; el jpg es sRGB
    save(img_id, "diff", srgb)
    h = blur(height, 2.0) + 0.01 * blur(GRAIN, 2)  # relieve suave: con el grano fuerte la pared parecía gotelé
    save(img_id, "nor_gl", normal_from_height(h, 4.0))
    r = np.clip(rough + 0.03 * GRAIN, 0, 1)
    save(img_id, "rough", np.repeat(r[..., None], 3, -1))


for img_id, fn, aging in (("wallpaper_damask", damask, 0.22), ("wallpaper_stripes", stripes, 0.22),
                          ("wallpaper_sprig", sprig, 0.2), ("wall_paint", paint, 0.3), ("wall_tiles", tiles, 0.35),
                          ("floor_hydraulic", floor_hydraulic, 0.1), ("floor_checker", floor_checker, 0.1),
                          ("porcelain_old", porcelain, 0.1)):
    write(img_id, fn, aging)
    print("WALLPAPER_OK", img_id)
