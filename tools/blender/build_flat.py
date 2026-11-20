"""Construye el piso sin el salón y exporta flat.gltf y flat_mirror.gltf (specs/hito4a.md D2), y escribe
data/flat_layout.tres en la misma ejecución (D1).

Blender sin ventana:
    blender -b --factory-startup --python-expr "ROOT = r'<proyecto>'; exec(open(ROOT + '/tools/blender/build_flat.py').read())"

Los muros van a eje, de 15 cm, uno por tabique (como los del salón). Cada tramo de muro separa como mucho dos
zonas, así que cada píxel mezcla como mucho 2 VoxelGI. Las hojas de las puertas las pone Godot (door.tscn).
Las ventanas dejan un Marker (empty «Window_<zona>») para que Godot ponga el fondo de ciudad (hito2 D14).
"""
import os
import sys

import bpy

ROOT = globals().get("ROOT", os.getcwd())
sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
import flat_layout as L  # noqa: E402

# Funciones de ayuda del salón (box, give, tex_mat, uv_world, mat, mirror_all, export_final…), sin construirlo.
_helpers = {"ROOT": ROOT, "MODE": "final", "RUN_MAIN": False, "__file__": os.path.join(ROOT, "tools", "blender", "build_living_room.py")}
exec(open(_helpers["__file__"], encoding="utf-8").read(), _helpers)
box, give, tex_mat, uv_world, mat = _helpers["box"], _helpers["give"], _helpers["tex_mat"], _helpers["uv_world"], _helpers["mat"]
reset, mirror_all, export_final = _helpers["reset"], _helpers["mirror_all"], _helpers["export_final"]

T, H = L.T, L.H
DOOR_TOP = 2.1
WIN_W, WIN_BOT, WIN_TOP = 1.2, 0.9, 2.1
# Ventanas: zona -> posición a lo largo del muro exterior. Fachada (py = Y0) y patio de luces (py = Y5).
WINDOWS = {"bedroom_main": ("h", L.Y0, 2.2), "dining_room": ("h", L.Y0, 11.8), "workshop": ("h", L.Y0, 15.8),
           "gallery": ("h", L.Y5, 1.5), "kitchen": ("h", L.Y5, 12.3)}
OUT = os.path.join(ROOT, "assets", "models", "living_room")  # misma carpeta que el salón: comparten texturas


def to_b(px, py):
    return L.to_blender(px, py)


def subtract(intervals, cut):
    a, b = cut
    out = []
    for x, y in intervals:
        if b <= x or a >= y:
            out.append((x, y))
            continue
        if a > x:
            out.append((x, a))
        if b < y:
            out.append((b, y))
    return out


def merge(intervals):
    out = []
    for x, y in sorted(intervals):
        if out and x <= out[-1][1] + 1e-6:
            out[-1] = (out[-1][0], max(out[-1][1], y))
        else:
            out.append((x, y))
    return out


def wall_box(name, axis, coord, a, b, z0, z1):
    """Caja de muro sobre la línea del plano (axis 'h': py = coord, a lo largo de px; 'v': px = coord)."""
    if b - a < 1e-3 or z1 - z0 < 1e-3:
        return None
    if axis == "h":
        (bx, by) = to_b((a + b) / 2, coord)
        return box(name, (T, b - a, z1 - z0), (bx, by, (z0 + z1) / 2))
    (bx, by) = to_b(coord, (a + b) / 2)
    return box(name, (b - a, T, z1 - z0), (bx, by, (z0 + z1) / 2))


def lines():
    """Todos los tramos de muro: línea -> lista de intervalos, sin los del salón (ya existen) ni las juntas abiertas."""
    walls = {}
    for zid, _, rect, _ in L.ZONES:
        px0, py0, px1, py1 = rect
        for key, span in ((("h", py0), (px0, px1)), (("h", py1), (px0, px1)), (("v", px0), (py0, py1)), (("v", px1), (py0, py1))):
            walls.setdefault(key, []).append(span)
    walls = {k: merge(v) for k, v in walls.items()}
    # Los horizontales llegan medio muro más allá para tapar las esquinas; los verticales se quedan medio muro antes.
    for (axis, c), spans in walls.items():
        walls[(axis, c)] = [(x - T / 2, y + T / 2) if axis == "h" else (x + T / 2, y - T / 2) for x, y in spans]
    # El salón ya tiene sus muros (del interior de cada lado).
    lr = L.zone("living_room")[2]
    for key, span in ((("h", lr[1]), (lr[0] + T / 2, lr[2] - T / 2)), (("h", lr[3]), (lr[0] + T / 2, lr[2] - T / 2)),
                      (("v", lr[0]), (lr[1] + T / 2, lr[3] - T / 2)), (("v", lr[2]), (lr[1] + T / 2, lr[3] - T / 2))):
        walls[key] = subtract(walls[key], span)
    # Juntas entre tramos de pasillo: abiertas a lo ancho del interior del vecino.
    for a, b in L.OPEN_SEAMS:
        ia, ib = L.interior(L.zone(a)[2], a), L.interior(L.zone(b)[2], b)
        conn = (None, a, b, "passage", None, "open")
        axis, coord, _ = L.wall_of(conn)
        span = (max(ia[0], ib[0]), min(ia[2], ib[2])) if axis == "h" else (max(ia[1], ib[1]), min(ia[3], ib[3]))
        walls[(axis, coord)] = subtract(walls[(axis, coord)], span)
    return walls


def build():
    wallpaper = tex_mat("Wallpaper", "decrepit_wallpaper", "2k")
    parquet = tex_mat("Parquet", "herringbone_parquet", "2k")
    tiles = tex_mat("Tiles", "dirty_tiles", "2k")
    ceiling = tex_mat("Gotele", "white_stucco", "1k", tint=(0.6, 0.57, 0.52))
    door_wood = mat("DoorWood", (0.16, 0.085, 0.04), 0.4)
    white_frame = mat("WindowFrame", (0.5, 0.49, 0.46), 0.35, metallic=0.2)
    glass = mat("Glass", (0.6, 0.65, 0.7), 0.05)
    gb = next(n for n in glass.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    gb.inputs["Alpha"].default_value = 0.12
    glass.surface_render_method = "BLENDED"

    # Suelos y techos por zona, hasta los ejes de sus muros (cubren también el hueco de las puertas).
    for zid, _, rect, floor in L.ZONES:
        if zid == "living_room":
            continue
        px0, py0, px1, py1 = rect
        (bx0, by0), (bx1, by1) = to_b(px0, py0), to_b(px1, py1)
        cx, cy, sx, sy = (bx0 + bx1) / 2, (by0 + by1) / 2, abs(bx1 - bx0), abs(by1 - by0)
        f = box("Floor_%s-col" % zid, (sx, sy, T), (cx, cy, -T / 2))
        give(f, tiles if floor == "tile" else parquet)
        uv_world(f, 2.0 if floor == "tile" else 3.4)
        c = give(box("Ceiling_%s" % zid, (sx, sy, T), (cx, cy, H + T / 2)), ceiling)
        uv_world(c, 2.0)

    walls = lines()
    lintels = []
    # Puertas y vanos: hueco hasta 2,1 m y dintel encima; marco de madera en las hojas y en el vano del recibidor.
    for conn in L.CONNECTIONS:
        cid, a, b, kind, pos, start = conn[:6]
        if pos is None or cid == "door_living":  # juntas abiertas; la puerta del salón ya tiene su hueco y su marco
            continue
        axis, coord, _ = L.wall_of(conn)
        w = L.DOOR_W if kind == "leaf" else L.PASSAGE_W
        span = (pos - w / 2, pos + w / 2)
        walls[(axis, coord)] = subtract(walls[(axis, coord)], span)
        lintels.append(wall_box("Lintel_%s-col" % cid, axis, coord, span[0], span[1], DOOR_TOP, H))
        j = 0.07
        e = 0.003  # el marco entra 3 mm en el hueco: si su cara coincidiera con el canto del muro, parpadearían
        for name, (a0, a1), z0, z1 in (("JambA", (span[0] - j, span[0] + e), 0, DOOR_TOP), ("JambB", (span[1] - e, span[1] + j), 0, DOOR_TOP),
                                       ("JambTop", (span[0] - j, span[1] + j), DOOR_TOP - e, DOOR_TOP + j)):
            o = wall_box("%s_%s" % (name, cid), axis, coord, a0, a1, z0, z1)
            o.scale = (1.2, 1, 1) if axis == "h" else (1, 1.2, 1)  # sobresale 1,5 cm por cada lado del muro
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            give(o, door_wood, bevel=0.005)
    # Ventanas: hueco con antepecho y dintel, marco, cristal y un empty para el fondo de ciudad de Godot.
    for zid, (axis, coord, pos) in WINDOWS.items():
        span = (pos - WIN_W / 2, pos + WIN_W / 2)
        walls[(axis, coord)] = subtract(walls[(axis, coord)], span)
        lintels.append(wall_box("Sill_%s-col" % zid, axis, coord, span[0], span[1], 0, WIN_BOT))
        lintels.append(wall_box("Lintel_win_%s-col" % zid, axis, coord, span[0], span[1], WIN_TOP, H))
        f = 0.05
        for name, (a0, a1), z0, z1 in (("WinFrameTop", span, WIN_TOP - f, WIN_TOP), ("WinFrameBottom", span, WIN_BOT, WIN_BOT + f),
                                       ("WinFrameL", (span[0], span[0] + f), WIN_BOT, WIN_TOP), ("WinFrameR", (span[1] - f, span[1]), WIN_BOT, WIN_TOP),
                                       ("WinFrameMid", (pos - 0.02, pos + 0.02), WIN_BOT, WIN_TOP)):
            give(wall_box("%s_%s" % (name, zid), axis, coord, a0, a1, z0, z1), white_frame, bevel=0.004)
        g = wall_box("WindowGlass_%s" % zid, axis, coord, span[0] + f, span[1] - f, WIN_BOT + f, WIN_TOP - f)
        g.scale = (0.04, 1, 1) if axis == "h" else (1, 0.04, 1)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        give(g, glass)
        bx, by = to_b(pos, coord)
        bpy.ops.object.empty_add(location=(bx, by, (WIN_BOT + WIN_TOP) / 2))
        bpy.context.active_object.name = "Window_%s" % zid
    # Muros.
    n = 0
    for (axis, coord), spans in walls.items():
        for a, b in spans:
            o = wall_box("Wall_%d-col" % n, axis, coord, a, b, 0, H)
            if o:
                give(o, wallpaper)
                uv_world(o, 2.5)
                n += 1
    for o in lintels:
        if o:
            give(o, wallpaper)
            uv_world(o, 2.5)


def main():
    reset()
    build()
    os.makedirs(os.path.join(ROOT, "art_source"), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "art_source", "flat.blend"))
    export_final(os.path.join(OUT, "flat.gltf"))
    mirror_all(recalc_normals=False)
    export_final(os.path.join(OUT, "flat_mirror.gltf"))
    L.write_tres(os.path.join(ROOT, "data", "flat_layout.tres"))
    print("BUILD_OK flat")


main()
