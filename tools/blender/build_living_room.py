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
from mathutils import Vector

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


def mat(name, color, rough, metallic=0.0, emission=None):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    if emission:
        b.inputs["Emission Color"].default_value = (*emission, 1.0)
        b.inputs["Emission Strength"].default_value = 4.0
    return m


def give(o, material, bevel=0.0, segments=3):
    o.data.materials.clear()
    o.data.materials.append(material)
    if bevel > 0.0:
        mod = o.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = segments
        mod.limit_method = "ANGLE"
        bpy.ops.object.shade_auto_smooth()
    return o


def cylinder(name, r, depth, loc, rot=(0, 0, 0), verts=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    return o


def build_tv():
    # Tele de tubo de los 80: mueble de madera oscura, marco negro, panel con rejilla y mandos,
    # culo del tubo en pirámide y antena de cuernos. El plano «Screen» (0,52 × 0,39, mira hacia -Y)
    # es el que recibe la imagen y los clics; el resto es decorado (specs/hito2.md D5, D18).
    wood = mat("TvWood", (0.085, 0.05, 0.03), 0.55)
    black = mat("TvBezel", (0.012, 0.012, 0.014), 0.6)
    plastic = mat("TvPlastic", (0.025, 0.024, 0.023), 0.7)
    metal = mat("TvMetal", (0.55, 0.53, 0.5), 0.3, metallic=1.0)
    grille = mat("TvGrille", (0.005, 0.005, 0.005), 0.9)
    led = mat("TvLed", (0.3, 0.02, 0.02), 0.4, emission=(1.0, 0.05, 0.03))

    sz = 0.35  # centro de la pantalla: la franja de abajo deja sitio a los mandos
    give(box("TvBody", (0.68, 0.42, 0.6), (0, -0.04, 0.3)), wood, bevel=0.02)
    # Culo del tubo: caja que se estrecha hacia atrás.
    back = box("TvBack", (0.5, 0.24, 0.44), (0, 0.29, 0.33))
    for v in back.data.vertices:
        if v.co.y > 0:
            v.co.x *= 0.6
            v.co.z = (v.co.z) * 0.6 + 0.02
    give(back, plastic, bevel=0.015)
    # Marco: cuatro listones alrededor de la pantalla, 2 cm por delante del mueble.
    fw, fh, t, depth, y = 0.52, 0.39, 0.035, 0.025, -0.25 - 0.0125
    for name, size, loc in [
        ("TvFrameTop", (fw + 2 * t, depth, t), (0, y, sz + fh / 2 + t / 2)),
        ("TvFrameBottom", (fw + 2 * t, depth, t), (0, y, sz - fh / 2 - t / 2)),
        ("TvFrameLeft", (t, depth, fh), (-fw / 2 - t / 2, y, sz)),
        ("TvFrameRight", (t, depth, fh), (fw / 2 + t / 2, y, sz)),
    ]:
        give(box(name, size, loc), black, bevel=0.006)
    # Panel de abajo: rejilla del altavoz a la izquierda, mandos y piloto a la derecha.
    give(box("TvPanel", (0.62, 0.01, 0.09), (0, -0.255, 0.065)), plastic, bevel=0.003)
    for i in range(7):
        give(box("TvSlot%d" % i, (0.012, 0.006, 0.06), (-0.27 + i * 0.024, -0.261, 0.065)), grille)
    for i, x in enumerate((0.17, 0.235)):
        knob = cylinder("TvKnob%d" % i, 0.022, 0.025, (x, -0.272, 0.065), rot=(math.radians(90), 0, 0))
        give(knob, black, bevel=0.004)
        give(cylinder("TvKnobMark%d" % i, 0.003, 0.004, (x, -0.286, 0.077), rot=(math.radians(90), 0, 0), verts=8),
             metal)
    give(cylinder("TvLed", 0.005, 0.006, (0.285, -0.262, 0.065), rot=(math.radians(90), 0, 0), verts=12), led)
    # Antena de cuernos: base de baquelita y dos varillas abiertas hacia atrás.
    base = cylinder("TvAntennaBase", 0.05, 0.03, (0.12, 0.02, 0.615))
    give(base, plastic, bevel=0.008)
    for i, side in enumerate((-1, 1)):
        rod = cylinder("TvAntennaRod%d" % i, 0.003, 0.45, (0, 0, 0), verts=8)
        rod.rotation_euler = (math.radians(-18), math.radians(side * 32), 0)
        # El cilindro crece desde su centro: se mueve para que arranque en la base.
        direction = rod.rotation_euler.to_matrix() @ Vector((0, 0, 0.225))
        rod.location = (0.12 + direction.x, 0.02 + direction.y, 0.63 + direction.z)
        give(rod, metal)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, -0.251, sz))
    s = bpy.context.active_object
    s.name = "Screen"
    s.scale = (0.52, 0.39, 1.0)
    s.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    if MODE == "tv":  # solo la tele, sin tocar el salón
        reset()
        build_tv()
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "tv.blend"))
        export(os.path.join(OUT, "tv.glb"))
        print("BUILD_OK tv")
        return
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
