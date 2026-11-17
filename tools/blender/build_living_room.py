"""Construye el salón del jugador en Blender y exporta los .glb (specs/hito2.md §4, §6 paso 3).

Se ejecuta dentro de Blender (MCP execute_blender_code) con:
    MODE = "graybox"; ROOT = r"C:/ruta/al/proyecto"; exec(open(ROOT + "/tools/blender/build_living_room.py").read())

Salón de 4 × 5 m, techo de 2,6 m, centrado en x = 0 (plano del espejo). En Blender: X a la derecha,
-Y hacia el fondo (la tele), Z arriba. En Godot (glTF): X, Y arriba, Z hacia el sofá.
Los objetos con sufijo -col generan colisión al importar en Godot.
"""
import math
import os

import bpy

MODE = globals().get("MODE", "graybox")
ROOT = globals().get("ROOT", os.getcwd())
OUT = os.path.join(ROOT, "assets", "models")
SRC = os.path.join(ROOT, "art_source")

W, D, H, T = 4.0, 5.0, 2.6, 0.15  # ancho (X), fondo (Y), alto, grosor de pared


def reset():
    # Sin read_factory_settings: recargaría las preferencias y apagaría el addon del MCP.
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)


def box(name, size, loc):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return o


def build_room():
    box("Floor-col", (W + 2 * T, D + 2 * T, T), (0, 0, -T / 2))
    box("Ceiling-col", (W + 2 * T, D + 2 * T, T), (0, 0, H + T / 2))
    # Pared del fondo (la tele) y pared del sofá.
    box("WallBack-col", (W, T, H), (0, -D / 2 - T / 2, H / 2))
    box("WallFront-col", (W, T, H), (0, D / 2 + T / 2, H / 2))
    # Pared derecha (+X) con hueco de ventana: 1,2 m de ancho, de 0,9 a 2,1 m de alto, centrada en y = 0,5.
    wx = W / 2 + T / 2
    win_y, win_w, win_bot, win_top = 0.5, 1.2, 0.9, 2.1
    y0, y1 = -D / 2, D / 2
    box("WallRightA-col", (T, (win_y - win_w / 2) - y0, H), (wx, (y0 + win_y - win_w / 2) / 2, H / 2))
    box("WallRightB-col", (T, y1 - (win_y + win_w / 2), H), (wx, (y1 + win_y + win_w / 2) / 2, H / 2))
    box("WallRightLow-col", (T, win_w, win_bot), (wx, win_y, win_bot / 2))
    box("WallRightHigh-col", (T, win_w, H - win_top), (wx, win_y, (H + win_top) / 2))
    # Pared izquierda (-X) con hueco de puerta: 0,9 m de ancho, 2,1 m de alto, centrada en y = 1,6.
    dx = -W / 2 - T / 2
    door_y, door_w, door_top = 1.6, 0.9, 2.1
    box("WallLeftA-col", (T, (door_y - door_w / 2) - y0, H), (dx, (y0 + door_y - door_w / 2) / 2, H / 2))
    box("WallLeftB-col", (T, y1 - (door_y + door_w / 2), H), (dx, (y1 + door_y + door_w / 2) / 2, H / 2))
    box("WallLeftHigh-col", (T, door_w, H - door_top), (dx, door_y, (H + door_top) / 2))
    # Muebles en bloques.
    box("TvStand-col", (1.2, 0.45, 0.55), (0, -D / 2 + 0.3, 0.275))
    box("Sofa-col", (2.0, 0.9, 0.45), (0, D / 2 - 0.65, 0.225))
    box("SofaBack-col", (2.0, 0.2, 0.45), (0, D / 2 - 0.2, 0.675))
    box("CoffeeTable-col", (1.0, 0.55, 0.42), (0, 0.6, 0.21))
    box("Shelf-col", (0.35, 1.0, 1.8), (-W / 2 + 0.2, -0.8, 0.9))


def mirror_all():
    for o in bpy.context.scene.objects:
        o.select_set(True)
        o.location.x = -o.location.x
        o.scale.x = -o.scale.x
    bpy.context.view_layer.objects.active = bpy.context.scene.objects[0]
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for o in bpy.context.scene.objects:
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")


def export(path):
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True)


def build_tv():
    # Mueble de tele de tubo: cuerpo y pantalla 4:3 de 0,52 × 0,39 m (el plano «Screen» mira hacia -Y).
    box("TvBody", (0.68, 0.5, 0.52), (0, 0, 0.26))
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, -0.251, 0.27))
    s = bpy.context.active_object
    s.name = "Screen"
    s.scale = (0.52, 0.39, 1.0)
    s.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SRC, exist_ok=True)
    reset()
    build_room()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "living_room.blend"))
    export(os.path.join(OUT, "living_room.glb"))
    mirror_all()
    export(os.path.join(OUT, "living_room_mirror.glb"))
    reset()
    build_tv()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "tv.blend"))
    export(os.path.join(OUT, "tv.glb"))
    print("BUILD_OK", MODE)


main()
