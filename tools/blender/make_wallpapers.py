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


def tiles():
    """Azulejo blanco de 15 × 15 cm con su junta, para el zócalo de cocina y baños."""
    n = 16  # 16 azulejos por textura: la textura cubre 2,4 m (uv_world(o, 2.4))
    p, q = (u * n) % 1, (v * n) % 1
    joint = np.maximum(smooth(0.03, 0.015, np.minimum(p, 1 - p)), smooth(0.03, 0.015, np.minimum(q, 1 - q)))
    tile_id = np.floor(u * n) * 31 + np.floor(v * n) * 17
    shade = 0.93 + 0.07 * np.sin(tile_id * 12.9898) ** 2  # cada azulejo con su tono
    rgb = mix(np.ones((N, N, 3)) * np.array((0.78, 0.77, 0.72)) * shade[..., None], (0.36, 0.34, 0.3), joint)
    return rgb, 1 - joint, 0.25 + 0.6 * joint


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
                          ("wallpaper_sprig", sprig, 0.2), ("wall_paint", paint, 0.3), ("wall_tiles", tiles, 0.15)):
    write(img_id, fn, aging)
    print("WALLPAPER_OK", img_id)
