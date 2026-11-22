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
reset, mirror_all, export_final, join = _helpers["reset"], _helpers["mirror_all"], _helpers["export_final"], _helpers["join"]
GEN = _helpers["GEN"]

T, H = L.T, L.H
DOOR_TOP = 2.1
WIN_W, WIN_BOT, WIN_TOP = 1.2, 0.9, 2.1
# Ventanas: zona -> posición a lo largo del muro exterior. Fachada (py = Y0) y patio de luces (py = Y5).
WINDOWS = {"bedroom_main": ("h", L.Y0, 2.2), "dining_room": ("h", L.Y0, 11.8), "workshop": ("h", L.Y0, 15.8),
           "gallery": ("h", L.Y5, 1.5), "kitchen": ("h", L.Y5, 12.3)}
OUT = os.path.join(ROOT, "assets", "models", "living_room")  # misma carpeta que el salón: comparten texturas
# Acabado de cada habitación como el salón (usuario, 2026-11-21): papel (make_wallpapers.py) y zócalo de madera,
# rodapié o azulejo hasta 1,4 m. El salón ya tiene el suyo.
PAPER = {"damask": "wallpaper_damask", "stripes": "wallpaper_stripes", "sprig": "wallpaper_sprig", "paint": "wall_paint"}  # pintura vieja y vivida; el yeso desconchado parecía de la guerra (usuario, 2026-11-22)
FINISH = {"bedroom_main": ("damask", "wainscot"), "dining_room": ("damask", "wainscot"), "entrance_hall": ("damask", "wainscot"),
          "bedroom_2": ("sprig", "skirt"), "bedroom_3": ("sprig", "skirt"),
          "workshop": ("paint", "skirt"), "pantry_hall": ("paint", "skirt"), "gallery": ("paint", "skirt"),
          "storage": ("paint", "skirt"), "larder": ("paint", "skirt"),
          "kitchen": ("sprig", "tiles"), "bathroom": ("paint", "tiles"), "service_toilet": ("paint", "tiles")}
WAINSCOT_H, TILE_H, SKIRT_H = 0.9, 1.37, 0.08  # el azulejo acaba justo encima de la cenefa (fila de 1,2-1,35 m)
# Suelo de baldosa por zona (make_wallpapers.py); el taller y el trastero siguen con la de Poly Haven.
FLOOR_TILE = {"kitchen": "floor_hydraulic", "bathroom": "floor_hydraulic", "service_toilet": "floor_hydraulic",
              "gallery": "floor_hydraulic", "pantry_hall": "floor_checker", "larder": "floor_checker"}
FINISH.update({z[0]: ("stripes", "wainscot") for z in L.ZONES if z[1] == "ZONE_CORRIDOR"})  # pasillos: rayas


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


def lines(skip_living=True):
    """Todos los tramos de muro: línea -> lista de intervalos, sin los del salón (ya existen; skip_living=False los
    deja, para forrar su cara de fuera) ni las juntas abiertas."""
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
    for key, span in [] if not skip_living else ((("h", lr[1]), (lr[0] + T / 2, lr[2] - T / 2)), (("h", lr[3]), (lr[0] + T / 2, lr[2] - T / 2)),
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
    wallpaper = tex_mat("WallPaint", "wall_paint", "2k", root=GEN)  # solo se ve en los cantos: cada cara lleva su papel
    parquet = tex_mat("Parquet", "herringbone_parquet", "2k")
    tiles = tex_mat("Tiles", "dirty_tiles", "2k")
    ceiling = tex_mat("Gotele", "white_stucco", "1k", tint=(0.6, 0.57, 0.52))
    door_wood = tex_mat("DoorWood", "dark_wood_worn", "2k", tint=_helpers["DOOR_TINT"], root=GEN)
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
        tile = tex_mat("Floor_" + FLOOR_TILE[zid], FLOOR_TILE[zid], "2k", root=GEN) if zid in FLOOR_TILE else tiles
        give(f, tile if floor == "tile" else parquet)
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
            uv_world(give(o, door_wood, bevel=0.005), 1.2)
    # Ventanas: hueco con antepecho y dintel, marco, cristal y un empty para el fondo de ciudad de Godot.
    for zid, (axis, coord, pos) in WINDOWS.items():
        span = (pos - WIN_W / 2, pos + WIN_W / 2)
        walls[(axis, coord)] = subtract(walls[(axis, coord)], span)
        lintels.append(wall_box("Sill_%s-col" % zid, axis, coord, span[0], span[1], 0, WIN_BOT))
        lintels.append(wall_box("Lintel_win_%s-col" % zid, axis, coord, span[0], span[1], WIN_TOP, H))
        f = 0.07
        # Ventana de madera de BlenderKit (usuario, 2026-11-22: las hechas aquí «parecían de la guerra»). Su exterior
        # mira a -Y: hacia la calle (+X) en la fachada y hacia el patio (-X) en el patio de luces.
        for o in _helpers["import_model"]("classic_window", "1k", (*to_b(pos, coord), WIN_BOT), rot_z_deg=90 if coord == L.Y0 else -90):
            o.name = "WinFrame_%s" % zid
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


def openings(key):
    """Huecos de un muro (a lo largo, desde, hasta, de z0 a z1): puertas, vanos (también la del salón) y ventanas."""
    out = []
    for conn in L.CONNECTIONS:
        if conn[4] is None:
            continue
        axis, coord, _ = L.wall_of(conn)
        if (axis, coord) == key:
            w = L.DOOR_W if conn[3] == "leaf" else L.PASSAGE_W
            out.append((conn[4] - w / 2, conn[4] + w / 2, 0.0, DOOR_TOP))
    for axis, coord, pos in WINDOWS.values():
        if (axis, coord) == key:
            out.append((pos - WIN_W / 2, pos + WIN_W / 2, WIN_BOT, WIN_TOP))
    return out


def cut(rects, hole):
    """Rectángulos (a0, a1, z0, z1) menos un hueco: lo que queda a los lados, debajo y encima."""
    h0, h1, hz0, hz1 = hole
    out = []
    for a0, a1, z0, z1 in rects:
        if h1 <= a0 or h0 >= a1 or hz1 <= z0 or hz0 >= z1:
            out.append((a0, a1, z0, z1))
            continue
        out += [(a0, h0, z0, z1), (h1, a1, z0, z1), (max(a0, h0), min(a1, h1), z0, hz0), (max(a0, h0), min(a1, h1), hz1, z1)]
    return [r for r in out if r[1] - r[0] > 0.01 and r[3] - r[2] > 0.01]


def skin(name, axis, face, inward, a0, a1, z0, z1, thick):
    """Lámina pegada a la cara de un muro, hacia dentro de la zona (inward = ±1 a lo largo del eje normal)."""
    c = face + inward * thick / 2
    if axis == "h":
        (bx, by) = to_b((a0 + a1) / 2, c)
        return box(name, (thick, a1 - a0, z1 - z0), (bx, by, (z0 + z1) / 2))
    (bx, by) = to_b(c, (a0 + a1) / 2)
    return box(name, (a1 - a0, thick, z1 - z0), (bx, by, (z0 + z1) / 2))


def faces(zid):
    """Las caras de muro de una zona: (línea, cara interior, hacia dentro, desde, hasta), sin las juntas abiertas."""
    walls = lines(skip_living=False)
    px0, py0, px1, py1 = L.zone(zid)[2]
    lo_x, lo_y, hi_x, hi_y = L.interior(L.zone(zid)[2], zid)
    out = []
    for key, face, inward, span in ((("h", py0), lo_y, 1, (lo_x, hi_x)), (("h", py1), hi_y, -1, (lo_x, hi_x)),
                                    (("v", px0), lo_x, 1, (lo_y, hi_y)), (("v", px1), hi_x, -1, (lo_y, hi_y))):
        for a, b in walls.get(key, []):
            a, b = max(a, span[0]), min(b, span[1])
            if b - a > 0.01:
                out.append((key, face, inward, a, b))
    return out


def finish_zones():
    wood = mat("DarkWood", (0.05, 0.028, 0.016), 0.45)
    panel = tex_mat("Wainscot", "dark_wood_worn", "2k", tint=(0.75, 0.62, 0.5), root=GEN)
    tile = tex_mat("WallTiles", "wall_tiles", "2k", root=GEN)
    cap = mat("TileCap", (0.6, 0.55, 0.42), 0.18)  # moldura vidriada que remata el azulejo
    for zid, (paper, low) in FINISH.items():
        papers, lows = [], []
        for key, face, inward, a, b in faces(zid):
            axis = key[0]
            holes = openings(key)
            rects = [(a, b, 0.0, H)]
            for hole in holes:
                rects = cut(rects, hole)
            for r in rects:
                papers.append(skin("Paper", axis, face, inward, *r, 0.002))
            top = {"wainscot": WAINSCOT_H, "tiles": TILE_H, "skirt": SKIRT_H}[low]
            low_rects = [(a, b, 0.0, top)]
            for hole in holes:
                low_rects = cut(low_rects, hole)
            for a0, a1, z0, z1 in low_rects:
                if low == "skirt":
                    lows.append(give(skin("Skirt", axis, face, inward, a0, a1, z0, z1, 0.015), wood))
                elif low == "tiles":
                    lows.append(give(skin("WallTile", axis, face, inward, a0, a1, z0, z1, 0.006), tile))
                    lows.append(give(skin("WallTileCap", axis, face, inward, a0, a1, z1 - 0.02, z1 + 0.005, 0.012), cap))
                else:  # zócalo de madera como el del salón: tablero, montantes cada ~0,5 m y moldura arriba
                    lows.append(give(skin("WainscotPanel", axis, face, inward, a0, a1, z0, z1, 0.012), panel))
                    n = max(1, round((a1 - a0) / 0.5))
                    for k in range(n + 1):
                        s = a0 + (a1 - a0) * k / n
                        s = min(max(s, a0 + 0.025), a1 - 0.025)
                        lows.append(give(skin("WainscotStile", axis, face, inward, s - 0.025, s + 0.025, 0.08, z1 - 0.04, 0.02), panel))
                    lows.append(give(skin("WainscotRail", axis, face, inward, a0, a1, z1 - 0.02, z1 + 0.02, 0.035), panel))
                    lows.append(give(skin("Skirt", axis, face, inward, a0, a1, 0.0, SKIRT_H, 0.02), wood))
        o = join(papers, "Paper_%s" % zid)
        # La pintura de las habitaciones de servicio es el yeso gastado de Poly Haven (usuario, 2026-11-22: más sucio).
        give(o, tex_mat("Paper_" + paper, PAPER[paper], "2k", root=GEN))
        uv_world(o, 2.5)
        if lows:
            w = join(lows, "%s_%s" % ("Wainscot" if low == "wainscot" else "WallTile" if low == "tiles" else "Skirt", zid))
            uv_world(w, 2.4 if low == "tiles" else 1.2)


def main():
    reset()
    build()
    finish_zones()
    exec(open(os.path.join(ROOT, "tools", "blender", "furnish_flat.py"), encoding="utf-8").read(), globals())
    os.makedirs(os.path.join(ROOT, "art_source"), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "art_source", "flat.blend"))
    export_final(os.path.join(OUT, "flat.gltf"))
    mirror_all(recalc_normals=False)
    export_final(os.path.join(OUT, "flat_mirror.gltf"))
    L.write_tres(os.path.join(ROOT, "data", "flat_layout.tres"))
    print("BUILD_OK flat")


main()
