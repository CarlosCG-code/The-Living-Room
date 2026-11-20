"""Plano del piso del jugador (specs/hito4a.md §2, D1). Python puro, sin bpy: lo importan build_flat.py
(Blender) y los tests de Godot leen el .tres que escribe write_tres().

Coordenadas de autor: «plano», en metros, a eje de muro. px va a lo largo de la fachada; py, de la fachada
hacia dentro. Las zonas son interiores: cada eje se encoge medio muro (T/2). Los vanos entre tramos de un
mismo pasillo no tienen muro: esos tramos se tocan sin hueco.
Blender: X = 2 - py, Y = px - 7 (el salón queda con su interior X [-2, 2], Y [-2.5, 2.5], como hoy).
Godot: x = X de Blender, z = -Y de Blender.

Uso suelto: python tools/blender/flat_layout.py  (escribe data/flat_layout.tres)
"""
import os

T = 0.15  # grosor de muro
H = 2.6
DOOR_W = 0.9

# Ejes de la planta (py): fachada, fondo de la fila de fachada, pasillo principal, bloque central, pasillo de
# servicio, fondo. Los del salón salen de su interior (0..4) ± T/2.
Y0, Y1 = -T / 2, 4 + T / 2
Y2 = Y1 + 1.2 + T
Y3 = Y2 + 3.3 + T
Y4 = Y3 + 1.2 + T
Y5 = Y4 + 3.3 + T
XL, XR = 4.5 - T / 2, 9.5 + T / 2  # salón
XW = 14.0 + T / 2  # taller
XEND = XW + 3.35 + T

# id, clave de nombre, (px0, py0, px1, py1) a eje de muro, suelo, abiertos: lados sin muro (pasillos en tramos)
ZONES = [
    ("bedroom_main", "ZONE_BEDROOM_MAIN", (0, Y0, XL, Y1), "wood"),
    ("living_room", "ZONE_LIVING_ROOM", (XL, Y0, XR, Y1), "wood"),
    ("dining_room", "ZONE_DINING_ROOM", (XR, Y0, XW, Y1), "wood"),
    ("workshop", "ZONE_WORKSHOP", (XW, Y0, XEND, Y3), "tile"),
    ("corridor_main_w", "ZONE_CORRIDOR", (0, Y1, 4.6, Y2), "wood"),
    ("corridor_main_m", "ZONE_CORRIDOR", (4.6, Y1, 9.6, Y2), "wood"),
    ("corridor_main_e", "ZONE_CORRIDOR", (9.6, Y1, XW, Y2), "wood"),
    ("corridor_side", "ZONE_CORRIDOR", (0, Y2, 1.35, Y3), "wood"),
    ("bedroom_2", "ZONE_BEDROOM_2", (1.35, Y2, 4.85, Y3), "wood"),
    ("bathroom", "ZONE_BATHROOM", (4.85, Y2, 7.25, Y3), "tile"),
    ("bedroom_3", "ZONE_BEDROOM_3", (7.25, Y2, 10.75, Y3), "wood"),
    ("pantry_hall", "ZONE_PANTRY_HALL", (10.75, Y2, XW, Y3), "tile"),
    ("corridor_service_w", "ZONE_CORRIDOR", (0, Y3, 5.8, Y4), "wood"),
    ("corridor_service_m", "ZONE_CORRIDOR", (5.8, Y3, 11.6, Y4), "wood"),
    ("corridor_service_e", "ZONE_CORRIDOR", (11.6, Y3, XEND, Y4), "wood"),
    ("gallery", "ZONE_GALLERY", (0, Y4, 3.0, Y5), "tile"),
    ("storage", "ZONE_STORAGE", (3.0, Y4, 4.6, Y5), "tile"),
    ("entrance_hall", "ZONE_ENTRANCE_HALL", (4.6, Y4, 8.6, Y5), "wood"),
    ("larder", "ZONE_LARDER", (8.6, Y4, 10.2, Y5), "tile"),
    ("kitchen", "ZONE_KITCHEN", (10.2, Y4, 14.5, Y5), "tile"),
    ("service_toilet", "ZONE_SERVICE_TOILET", (14.5, Y4, XEND, Y5), "tile"),
]

# Pares de tramos del mismo pasillo: se tocan sin muro (vano a todo lo ancho).
OPEN_SEAMS = [
    ("corridor_main_w", "corridor_main_m"), ("corridor_main_m", "corridor_main_e"),
    ("corridor_service_w", "corridor_service_m"), ("corridor_service_m", "corridor_service_e"),
    ("corridor_side", "corridor_main_w"), ("corridor_side", "corridor_service_w"),
]

# id, zona_a (la hoja abre hacia ella), zona_b ("" = rellano), tipo, posición a lo largo del muro (px o py
# del centro del hueco), estado inicial
CONNECTIONS = [
    # La del salón abre hacia el pasillo: hacia dentro chocaba con el sofá (2,7 m, a 63 cm de esa pared).
    ("door_living", "corridor_main_m", "living_room", "leaf", 8.6, "closed", "lo"),
    ("door_bedroom_main", "bedroom_main", "corridor_main_w", "leaf", 3.6, "closed"),
    ("door_dining", "dining_room", "corridor_main_e", "leaf", 11.0, "ajar"),
    ("door_workshop_main", "workshop", "corridor_main_e", "leaf", Y1 + 0.675, "closed"),
    ("door_workshop_service", "workshop", "corridor_service_e", "leaf", 15.8, "closed"),
    ("door_bedroom_2", "bedroom_2", "corridor_main_w", "leaf", 2.6, "closed"),
    ("door_bathroom", "bathroom", "corridor_main_m", "leaf", 6.0, "ajar"),
    ("door_bedroom_3", "bedroom_3", "corridor_service_m", "leaf", 9.0, "ajar"),
    ("door_pantry_main", "pantry_hall", "corridor_main_e", "leaf", 12.6, "closed"),
    ("door_pantry_service", "pantry_hall", "corridor_service_e", "leaf", 12.9, "closed"),
    ("door_gallery", "gallery", "corridor_service_w", "leaf", 1.5, "closed"),
    ("door_storage", "storage", "corridor_service_w", "leaf", 3.8, "closed"),
    ("pass_entrance", "entrance_hall", "corridor_service_m", "passage", 7.0, "open"),
    ("door_kitchen", "kitchen", "corridor_service_m", "leaf", 11.0, "closed"),
    ("door_larder", "larder", "kitchen", "leaf", Y4 + 1.8, "closed"),
    ("door_service_toilet", "service_toilet", "corridor_service_e", "leaf", 16.0, "closed"),
    ("door_front", "entrance_hall", "", "leaf", 6.6, "locked"),
] + [("pass_" + a + "__" + b, a, b, "passage", None, "open") for a, b in OPEN_SEAMS]

FUSE_BOX_ZONE = "storage"
PASSAGE_W = 1.4  # vano del recibidor

LAMP = {"color": (1.0, 0.82, 0.64), "base_dark": 0.0}
# Luz como en Visage (usuario, 2026-11-20): islas de luz tenue y el resto casi a oscuras; la luz de una zona
# encendida se cuela por las puertas a las vecinas. Energía por zona; las que no salen aquí no tienen lámpara.
LIT_ZONES = {"corridor_main_m": 0.3, "entrance_hall": 0.25, "kitchen": 0.2, "bedroom_main": 0.18,
             "bathroom": 0.15, "corridor_service_e": 0.12}


def zone(zid):
    return next(z for z in ZONES if z[0] == zid)


def interior(rect, zid):
    """Rectángulo interior en el plano. Un lado abierto (OPEN_SEAMS) se alarga solo si el vecino lo cubre entero:
    hasta el eje si el vecino también se alarga (tramos del mismo ancho), si no hasta el interior del vecino."""
    px0, py0, px1, py1 = rect
    h = T / 2
    lo_x, lo_y, hi_x, hi_y = px0 + h, py0 + h, px1 - h, py1 - h

    def covers(outer, inner, axis):  # el lado de outer abarca el de inner (axis 0 = a lo largo de px)
        return outer[axis] <= inner[axis] + 1e-6 and outer[axis + 2] >= inner[axis + 2] - 1e-6

    for a, b in OPEN_SEAMS:
        other = b if a == zid else a if b == zid else None
        if other is None:
            continue
        o = zone(other)[2]
        if abs(o[0] - px1) < 1e-6 and covers(o, rect, 1):
            hi_x = px1 + (0 if covers(rect, o, 1) else h)
        if abs(o[2] - px0) < 1e-6 and covers(o, rect, 1):
            lo_x = px0 - (0 if covers(rect, o, 1) else h)
        if abs(o[1] - py1) < 1e-6 and covers(o, rect, 0):
            hi_y = py1 + (0 if covers(rect, o, 0) else h)
        if abs(o[3] - py0) < 1e-6 and covers(o, rect, 0):
            lo_y = py0 - (0 if covers(rect, o, 0) else h)
    return lo_x, lo_y, hi_x, hi_y


def to_blender(px, py):
    return 2.0 - py, px - 7.0


def to_godot(px, py):
    bx, by = to_blender(px, py)
    return bx, -by


def wall_of(conn):
    """Muro compartido por las dos zonas de una conexión: ('h', py) si es horizontal en el plano (separa filas),
    ('v', px) si es vertical; y la normal (en el plano) que apunta hacia zona_a."""
    _, a, b = conn[:3]
    ra = zone(a)[2]
    if b == "":  # puerta de entrada: muro del fondo del recibidor
        return "h", ra[3], (0.0, -1.0)
    rb = zone(b)[2]
    if abs(ra[3] - rb[1]) < 1e-6:
        return "h", ra[3], (0.0, -1.0)
    if abs(ra[1] - rb[3]) < 1e-6:
        return "h", ra[1], (0.0, 1.0)
    if abs(ra[2] - rb[0]) < 1e-6:
        return "v", ra[2], (-1.0, 0.0)
    if abs(ra[0] - rb[2]) < 1e-6:
        return "v", ra[0], (1.0, 0.0)
    raise ValueError("%s: las zonas no comparten muro" % conn[0])


def door_frame(conn):
    """Bisagra, dirección de la hoja cerrada (bisagra -> pestillo) en el plano, y sentido de giro (swing, ±1) con
    el que se abre hacia zona_a. Sin jamba elegida (7.º campo, "lo" | "hi" a lo largo del muro), la bisagra va
    en la que abre girando en positivo (Godot, eje Y)."""
    axis, coord, n = wall_of(conn)
    pos = conn[4]
    half = DOOR_W / 2
    if axis == "h":
        hinge, d = (pos - half, coord), (1.0, 0.0)
    else:
        hinge, d = (coord, pos - half), (0.0, 1.0)
    # En Godot: x = 2 - py, z = 7 - px. Dirección y normal pasan a (gx, gz) = (-dy, -dx).
    dg, ng = (-d[1], -d[0]), (-n[1], -n[0])
    # R_y(θ) con θ pequeño positivo lleva (x, z) a (x + θz, z - θx): abre hacia ng si dz*nx - dx*nz > 0.
    positive = dg[1] * ng[0] - dg[0] * ng[1] > 0
    end = conn[6] if len(conn) > 6 else ("lo" if positive else "hi")
    if end == "hi":  # bisagra en la otra jamba: la hoja apunta al revés y el sentido de giro también cambia
        hinge = (hinge[0] + 2 * half * d[0], hinge[1] + 2 * half * d[1])
        d = (-d[0], -d[1])
        positive = not positive
    return hinge, d, 1.0 if positive else -1.0


def godot_rect(zid):
    px0, py0, px1, py1 = interior(zone(zid)[2], zid)
    x0, z0 = to_godot(px1, py1)
    x1, z1 = to_godot(px0, py0)
    return x0, z0, x1 - x0, z1 - z0


def _num(x):
    s = "%.4f" % x
    s = s.rstrip("0").rstrip(".")
    return s if s not in ("-0", "") else "0"


def write_tres(path):
    lines = ['[gd_resource type="Resource" script_class="FlatLayout" load_steps=%d format=3]' % (4 + len(ZONES) + len(CONNECTIONS)), "",
             '[ext_resource type="Script" path="res://world/player_flat/flat_layout.gd" id="layout_script"]',
             '[ext_resource type="Script" path="res://world/player_flat/zone_def.gd" id="zone_script"]',
             '[ext_resource type="Script" path="res://world/player_flat/connection_def.gd" id="conn_script"]', ""]
    for zid, key, rect, floor in ZONES:
        x, z, w, d = godot_rect(zid)
        cx, cz = x + w / 2, z + d / 2
        energy = LIT_ZONES.get(zid, 0.0)  # el salón no está: ya tiene las suyas
        lights = "" if energy == 0.0 else '{"pos": Vector3(%s, 2.3, %s), "color": Color(%s, %s, %s, 1), "energy": %s, "range": %s, "base_normal": %s, "base_dark": %s}' % (
            _num(cx), _num(cz), *(_num(c) for c in LAMP["color"]), _num(energy),
            _num(max(w, d) * 0.75 + 1.0), _num(energy), _num(LAMP["base_dark"]))
        lines += ['[sub_resource type="Resource" id="z_%s"]' % zid, 'script = ExtResource("zone_script")',
                  'id = &"%s"' % zid, 'name_key = "%s"' % key,
                  "rect = Rect2(%s, %s, %s, %s)" % tuple(_num(v) for v in (x, z, w, d)),
                  'floor_type = &"%s"' % floor, "lights = Array[Dictionary]([%s])" % lights, ""]
    for conn in CONNECTIONS:
        cid, a, b, kind, pos, start = conn[:6]
        lines += ['[sub_resource type="Resource" id="c_%s"]' % cid, 'script = ExtResource("conn_script")',
                  'id = &"%s"' % cid, 'zone_a = &"%s"' % a, 'zone_b = &"%s"' % b, 'kind = &"%s"' % kind,
                  'start = &"%s"' % start]
        if kind == "leaf":
            (hx, hy), d, swing = door_frame(conn)
            gx, gz = to_godot(hx, hy)
            lines += ["hinge = Vector3(%s, 0, %s)" % (_num(gx), _num(gz)), "swing = %s" % _num(swing),
                      "direction = Vector3(%s, 0, %s)" % (_num(-d[1]), _num(-d[0])), "width = %s" % _num(DOOR_W)]
        elif pos is not None:
            lines += ["width = %s" % _num(PASSAGE_W)]
        lines.append("")
    lines += ["[resource]", 'script = ExtResource("layout_script")',
              'zones = Array[ExtResource("zone_script")]([%s])' % ", ".join('SubResource("z_%s")' % z[0] for z in ZONES),
              'connections = Array[ExtResource("conn_script")]([%s])' % ", ".join('SubResource("c_%s")' % c[0] for c in CONNECTIONS),
              'fuse_box_zone = &"%s"' % FUSE_BOX_ZONE, ""]
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    write_tres(os.path.join(root, "data", "flat_layout.tres"))
    print("flat_layout.tres: %d zonas, %d conexiones" % (len(ZONES), len(CONNECTIONS)))
