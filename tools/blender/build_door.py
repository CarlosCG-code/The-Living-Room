"""Hoja de puerta de los años 40 (usuario, 2026-11-21): seis cuarterones con plafón en relieve, madera oscura como
el zócalo del salón, manivela de latón con placa y bocallave, y tres pernios. La usan todas las Door (door.gd).

Blender sin ventana:
    blender -b --factory-startup --python-expr "ROOT = r'<proyecto>'; exec(open(ROOT + '/tools/blender/build_door.py').read())"

Ejes: X a lo largo de la hoja (bisagra en 0), Z arriba (0 = canto de abajo), Y el grueso, centrado. Los pernios
van en la cara +Y (en Godot, -Z): la del lado hacia el que abre. Medidas = Door.LEAF (door.gd).
"""
import math
import os

import bpy

ROOT = globals().get("ROOT", os.getcwd())
_helpers = {"ROOT": ROOT, "MODE": "final", "RUN_MAIN": False, "__file__": os.path.join(ROOT, "tools", "blender", "build_living_room.py")}
exec(open(_helpers["__file__"], encoding="utf-8").read(), _helpers)
box, give, tex_mat, mat, cylinder = _helpers["box"], _helpers["give"], _helpers["tex_mat"], _helpers["mat"], _helpers["cylinder"]
reset, export_final, join = _helpers["reset"], _helpers["export_final"], _helpers["join"]
DOOR_TINT = _helpers["DOOR_TINT"]
GEN = _helpers["GEN"]

W, H, T = 0.885, 2.074, 0.04
STILE, TOP_RAIL, BOTTOM_RAIL, MUNTIN = 0.12, 0.12, 0.22, 0.10
# Travesaños intermedios (desde, hasta): cerradura y friso. Entre ellos, tres filas de plafones.
RAILS = [(0.80, 0.98), (1.62, 1.76)]
RECESS = 0.012  # el tablero queda 12 mm por debajo del bastidor en cada cara
FIELD_IN, FIELD_RISE = 0.035, 0.006  # plafón: 3,5 cm hacia dentro del borde, 6 mm sobre el tablero
OUT = os.path.join(ROOT, "assets", "models", "living_room")


def uv_grain(o, vertical, tile=1.2):
    """UV en metros con la veta a lo largo de la pieza: montantes en vertical, travesaños en horizontal."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(o.data)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in f.loops:
            p = o.matrix_world @ loop.vert.co
            a, b = {0: (p.y, p.z), 1: (p.x, p.z), 2: (p.x, p.y)}[ax]
            u, v = (b, a) if vertical else (a, b)
            loop[uv].uv = (u / tile, v / tile)
    bm.to_mesh(o.data)
    bm.free()


def piece(name, x0, x1, z0, z1, depth, wood, vertical, bevel):
    o = give(box(name, (x1 - x0, depth, z1 - z0), ((x0 + x1) / 2, 0, (z0 + z1) / 2)), wood, bevel=bevel)
    uv_grain(o, vertical)
    return o


def build():
    wood = tex_mat("DoorWood", "dark_wood_worn", "2k", tint=DOOR_TINT, root=GEN)
    brass = bpy.data.materials.get("Brass") or mat("Brass", (0.6, 0.45, 0.22), 0.3, metallic=1.0)
    dark = mat("Keyhole", (0.01, 0.01, 0.01), 0.8)
    parts = []
    # Bastidor: montantes, travesaños y peinazo central, al grueso entero.
    parts.append(piece("StileHinge", 0, STILE, 0, H, T, wood, True, 0.004))
    parts.append(piece("StileLatch", W - STILE, W, 0, H, T, wood, True, 0.004))
    for i, (z0, z1) in enumerate([(0, BOTTOM_RAIL)] + RAILS + [(H - TOP_RAIL, H)]):
        parts.append(piece("Rail%d" % i, STILE, W - STILE, z0, z1, T, wood, False, 0.004))
    rows = [(BOTTOM_RAIL, RAILS[0][0]), (RAILS[0][1], RAILS[1][0]), (RAILS[1][1], H - TOP_RAIL)]
    mx0, mx1 = W / 2 - MUNTIN / 2, W / 2 + MUNTIN / 2
    for i, (z0, z1) in enumerate(rows):
        parts.append(piece("Muntin%d" % i, mx0, mx1, z0, z1, T, wood, True, 0.004))
        # Tablero rehundido y plafón en relieve con el canto biselado ancho.
        for j, (x0, x1) in enumerate([(STILE, mx0), (mx1, W - STILE)]):
            parts.append(piece("Panel%d%d" % (i, j), x0, x1, z0, z1, T - 2 * RECESS, wood, True, 0.0))
            f = FIELD_IN
            parts.append(piece("Field%d%d" % (i, j), x0 + f, x1 - f, z0 + f, z1 - f, T - 2 * (RECESS - FIELD_RISE), wood, True, 0.012))
    leaf = join(parts, "DoorLeafWood")
    bpy.ops.object.shade_auto_smooth()

    # Herrajes de latón en las dos caras: placa con bocallave y manivela que apunta hacia la bisagra.
    hx = W - 0.065
    hw = []
    for side in (-1, 1):
        y = side * (T / 2 + 0.0025)
        hw.append(give(box("HandlePlate", (0.05, 0.005, 0.24), (hx, y, 0.98)), brass, bevel=0.002))
        hw.append(give(cylinder("HandleRose", 0.018, 0.008, (hx, side * (T / 2 + 0.009), 1.04), rot=(math.radians(90), 0, 0), verts=20), brass, bevel=0.002))
        hw.append(give(cylinder("HandleNeck", 0.008, 0.05, (hx, side * (T / 2 + 0.03), 1.04), rot=(math.radians(90), 0, 0), verts=12), brass))
        hw.append(give(cylinder("HandleLever", 0.008, 0.12, (hx - 0.055, side * (T / 2 + 0.05), 1.04), rot=(0, math.radians(90), 0), verts=12), brass))
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.012, location=(hx - 0.115, side * (T / 2 + 0.05), 1.04), segments=16, ring_count=8)
        hw.append(give(bpy.context.active_object, brass))
        hw.append(give(box("Keyhole", (0.008, 0.002, 0.022), (hx, side * (T / 2 + 0.005), 0.92)), dark))
    # Pernios: su eje es el de giro (la esquina de la cara +Y), medio fuera de la hoja.
    for z in (0.25, 1.05, 1.85):
        hw.append(give(cylinder("Hinge", 0.008, 0.11, (0, T / 2, z), verts=14), brass, bevel=0.002))
    join(hw, "DoorHardware")
    for o in bpy.context.scene.objects:
        o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = leaf
    return leaf


def main():
    reset()
    build()
    export_final(os.path.join(OUT, "door_leaf.gltf"))
    print("BUILD_OK door")


main()
