"""Construye la fábrica del fondo de la tele en Blender y renderiza sus capas (specs/hito2.md D20).

Se ejecuta dentro de Blender (MCP execute_blender_code) con:
    ROOT = r"C:/ruta/al/proyecto"; exec(open(ROOT + "/tools/blender/build_factory.py").read())
Con PREVIEW = True solo construye la escena (para mirarla con look), sin renderizar.

Genera assets/textures/factory/background.png (la nave sin máquinas, 960 × 720, el tamaño del SubViewport)
y una imagen recortada por cada máquina, y escribe presentation/ui/factory_view.tscn con cada una en su
posición en píxeles. Cámara ortográfica a 100 px/m con picado. En Blender: X a la derecha, +Y hacia el
fondo, Z arriba. Las máquinas se renderizan solas sobre transparente, con el suelo como receptor de sombras.
"""
import math
import os

import bmesh
import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT = globals().get("ROOT", os.getcwd())
PREVIEW = globals().get("PREVIEW", False)
SAMPLES = globals().get("SAMPLES", 48)
OUT = os.path.join(ROOT, "assets", "textures", "factory")
TMP = os.path.join(ROOT, "art_source", "factory_tmp")
SCENE_PATH = os.path.join(ROOT, "presentation", "ui", "factory_view.tscn")
W, H = 960, 720
PPM = 100.0  # píxeles por metro
TILT = math.radians(18)
BAND_TOP_PX = 470  # la UI deja libre la franja inferior de la pantalla


def reset():
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.curves, bpy.data.lights, bpy.data.cameras):
        for item in list(coll):
            coll.remove(item)


# --- Materiales ---

def mat(name, color, metal=0.0, rough=0.5, emit=None, strength=0.0, glass=False):
    m = bpy.data.materials.new(name)
    if m.node_tree is None:
        m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1.0)
        b.inputs["Emission Strength"].default_value = strength
    if glass:
        b.inputs["Transmission Weight"].default_value = 1.0
        b.inputs["IOR"].default_value = 1.45
    return m


def brick_mat():
    m = mat("brick", (0.2, 0.08, 0.05), rough=0.9)
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    comb = nt.nodes.new("ShaderNodeCombineXYZ")
    brick = nt.nodes.new("ShaderNodeTexBrick")
    brick.inputs["Color1"].default_value = (0.08, 0.035, 0.025, 1)
    brick.inputs["Color2"].default_value = (0.12, 0.05, 0.035, 1)
    brick.inputs["Mortar"].default_value = (0.04, 0.035, 0.032, 1)
    brick.inputs["Scale"].default_value = 2.0
    nt.links.new(coord.outputs["Object"], sep.inputs[0])
    nt.links.new(sep.outputs["X"], comb.inputs["X"])
    nt.links.new(sep.outputs["Z"], comb.inputs["Y"])
    nt.links.new(comb.outputs[0], brick.inputs["Vector"])
    nt.links.new(brick.outputs["Color"], b.inputs["Base Color"])
    return m


# --- Geometría (dimensiones reales en la malla, sin escala de objeto) ---

def _obj(name, bm, loc, m, parent, rot, smooth=False):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(m)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = rot
    if parent:
        o.parent = parent
    return o


def box(name, size, loc, m, parent=None, rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    return _obj(name, bm, loc, m, parent, rot)


def cyl(name, r, depth, loc, m, parent=None, rot=(0, 0, 0), seg=24):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r, depth=depth)
    return _obj(name, bm, loc, m, parent, rot, smooth=True)


def sphere(name, r, loc, m, parent=None):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=10, radius=r)
    return _obj(name, bm, loc, m, parent, (0, 0, 0), smooth=True)


def empty(name, loc):
    o = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    return o


X90 = (math.radians(90), 0, 0)
Y90 = (0, math.radians(90), 0)


# --- Máquinas (origen en la base, frente hacia -Y) ---

def antenna(p, M):
    box("base", (0.3, 0.3, 0.08), (0, 0, 0.04), M["dark"], p)
    cyl("mast", 0.025, 2.2, (0, 0, 1.18), M["alu"], p)
    for i, (z, length) in enumerate([(1.45, 0.9), (1.7, 0.75), (1.95, 0.6), (2.15, 0.45)]):
        cyl(f"bar{i}", 0.012, length, (0, 0, z), M["alu"], p, Y90, seg=10)
    sphere("light", 0.045, (0, 0, 2.32), M["red_light"], p)


def valves(p, M):
    box("base", (0.55, 0.32, 0.22), (0, 0, 0.11), M["dark"], p)
    for i, x in enumerate((-0.17, 0.0, 0.17)):
        cyl(f"ring{i}", 0.068, 0.04, (x, 0, 0.24), M["copper"], p)
        cyl(f"tube{i}", 0.06, 0.3, (x, 0, 0.37), M["glass"], p)
        sphere(f"cap{i}", 0.06, (x, 0, 0.52), M["glass"], p)
        cyl(f"filament{i}", 0.018, 0.22, (x, 0, 0.36), M["orange_glow"], p, seg=10)


def audio_frequency(p, M):
    box("cabinet", (0.78, 0.5, 1.25), (0, 0, 0.625), M["green_metal"], p)
    box("bezel", (0.56, 0.03, 0.4), (0, -0.26, 0.92), M["black"], p)
    box("screen", (0.48, 0.03, 0.32), (0, -0.27, 0.92), M["green_screen"], p)
    for i in range(12):
        x = -0.21 + i * 0.038
        box(f"wave{i}", (0.036, 0.01, 0.014), (x, -0.29, 0.92 + 0.08 * math.sin(i * 0.9)), M["green_glow"], p)
    for i, x in enumerate((-0.19, 0.19)):
        cyl(f"speaker{i}", 0.13, 0.04, (x, -0.26, 0.42), M["rubber"], p, X90)
        cyl(f"cone{i}", 0.05, 0.05, (x, -0.27, 0.42), M["dark"], p, X90)
    for i, x in enumerate((-0.15, 0.0, 0.15)):
        cyl(f"knob{i}", 0.025, 0.04, (x, -0.27, 0.68), M["chrome"], p, X90, seg=12)


def tuner(p, M):
    box("console", (0.9, 0.6, 0.85), (0, 0, 0.425), M["wood"], p)
    cyl("knob", 0.2, 0.09, (-0.17, -0.32, 0.45), M["chrome"], p, X90, seg=32)
    cyl("grip", 0.06, 0.05, (-0.17, -0.38, 0.45), M["black"], p, X90)
    box("window", (0.36, 0.02, 0.13), (0.2, -0.31, 0.62), M["amber_glow"], p)
    box("needle", (0.01, 0.01, 0.12), (0.25, -0.33, 0.62), M["red_light"], p)


def remote(p, M):
    box("pedestal", (0.6, 0.42, 0.12), (0, 0, 0.06), M["dark"], p)
    body = box("body", (0.42, 0.16, 1.35), (0, 0, 0.795), M["plastic"], p)
    bev = body.modifiers.new("bevel", "BEVEL")
    bev.width = 0.04
    bev.segments = 3
    cyl("power", 0.045, 0.03, (0, -0.09, 1.3), M["red_button"], p, X90)
    for r in range(4):
        for c in range(3):
            cyl(f"btn{r}{c}", 0.035, 0.02, (-0.12 + c * 0.12, -0.085, 1.12 - r * 0.14), M["gray_plastic"], p, X90, seg=12)
    sphere("led", 0.03, (0, 0, 1.47), M["red_light"], p)


def channel_3(p, M):
    for i, (x, y) in enumerate([(-0.32, -0.32), (0.32, -0.32), (-0.32, 0.32), (0.32, 0.32)]):
        cyl(f"leg{i}", 0.035, 3.0, (x, y, 1.5), M["rust"], p, seg=10)
    angle = math.atan2(0.64, 0.6)
    length = math.hypot(0.64, 0.6)
    for k in range(5):
        z = 0.3 + k * 0.6
        sign = 1 if k % 2 == 0 else -1
        for j, y in enumerate((-0.32, 0.32)):
            cyl(f"brace{k}{j}", 0.015, length, (0, y, z), M["rust"], p, (0, sign * angle, 0), seg=8)
    box("sign", (0.9, 0.12, 0.9), (0, 0, 3.45), M["dark"], p)
    curve = bpy.data.curves.new("three", "FONT")
    curve.body = "3"
    curve.size = 0.75
    curve.extrude = 0.02
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    text = bpy.data.objects.new("three", curve)
    bpy.context.scene.collection.objects.link(text)
    text.data.materials.append(M["red_glow"])
    text.location = (0, -0.08, 3.45)
    text.rotation_euler = X90
    text.parent = p
    sphere("beacon", 0.06, (0, 0, 3.98), M["red_light"], p)


# Orden de dibujo (de atrás adelante) y huecos (x, y) en el orden en que aparecen.
LAYOUT = [
    ("channel_3", channel_3, [(-0.4, 3.4)]),
    ("antenna", antenna, [(-3.0, 3.0), (-3.6, 3.0), (-2.4, 3.0), (-4.2, 3.0), (-1.8, 3.0)]),
    ("tuner", tuner, [(1.3, 1.8), (2.35, 1.8), (3.4, 1.8)]),
    ("audio_frequency", audio_frequency, [(-1.2, 0.5), (-0.3, 0.5), (0.6, 0.5)]),
    ("valves", valves, [(-3.55, 0.4), (-2.9, 0.4), (-4.2, 0.4), (-2.25, 0.4)]),
    ("remote", remote, [(3.4, 0.5), (4.2, 0.5)]),
]


def materials():
    return {
        "dark": mat("dark", (0.05, 0.05, 0.055), metal=0.6, rough=0.45),
        "alu": mat("alu", (0.7, 0.7, 0.72), metal=1.0, rough=0.3),
        "chrome": mat("chrome", (0.8, 0.8, 0.8), metal=1.0, rough=0.15),
        "copper": mat("copper", (0.75, 0.38, 0.2), metal=1.0, rough=0.35),
        "rust": mat("rust", (0.3, 0.13, 0.06), metal=0.5, rough=0.8),
        "glass": mat("glass", (0.9, 0.95, 1.0), rough=0.05, glass=True),
        "black": mat("black", (0.01, 0.01, 0.01), rough=0.5),
        "rubber": mat("rubber", (0.02, 0.02, 0.02), rough=0.9),
        "plastic": mat("plastic", (0.025, 0.025, 0.03), rough=0.35),
        "gray_plastic": mat("gray_plastic", (0.25, 0.25, 0.27), rough=0.4),
        "red_button": mat("red_button", (0.5, 0.03, 0.02), rough=0.3, emit=(1.0, 0.1, 0.05), strength=1.5),
        "wood": mat("wood", (0.22, 0.1, 0.04), rough=0.55),
        "green_metal": mat("green_metal", (0.09, 0.13, 0.1), metal=0.4, rough=0.5),
        "green_screen": mat("green_screen", (0.0, 0.05, 0.02), emit=(0.1, 0.6, 0.25), strength=1.5),
        "green_glow": mat("green_glow", (0.2, 1.0, 0.4), emit=(0.3, 1.0, 0.45), strength=8.0),
        "orange_glow": mat("orange_glow", (1.0, 0.4, 0.1), emit=(1.0, 0.45, 0.1), strength=15.0),
        "amber_glow": mat("amber_glow", (1.0, 0.6, 0.2), emit=(1.0, 0.65, 0.25), strength=4.0),
        "red_light": mat("red_light", (1.0, 0.05, 0.03), emit=(1.0, 0.08, 0.04), strength=10.0),
        "red_glow": mat("red_glow", (1.0, 0.05, 0.03), emit=(1.0, 0.1, 0.05), strength=6.0),
        "concrete": mat("concrete", (0.12, 0.12, 0.12), rough=0.85),
        "window": mat("window", (0.0, 0.0, 0.0), emit=(0.1, 0.13, 0.2), strength=0.25),
        "brick": brick_mat(),
    }


def build_hall(M):
    hall = [
        box("floor", (14, 10, 0.1), (0, 2, -0.05), M["concrete"]),
        box("wall", (14, 0.2, 9), (0, 4.7, 4.5), M["brick"]),
    ]
    decor = [
        cyl("pipe_a", 0.08, 14, (0, 4.45, 2.4), M["copper"], rot=Y90),
        cyl("pipe_b", 0.05, 14, (0, 4.45, 2.75), M["copper"], rot=Y90),
        cyl("pipe_l", 0.06, 7, (-4.6, 4.45, 3.5), M["copper"]),
        cyl("pipe_r", 0.06, 7, (4.6, 4.45, 3.5), M["copper"]),
    ]
    for i, x in enumerate((-3.6, -1.2, 1.2, 3.6)):
        decor.append(box(f"window{i}", (1.2, 0.05, 0.8), (x, 4.58, 5.0), M["window"]))
    for i, x in enumerate((-3.0, 0.0, 3.0)):
        # Focos hacia abajo: iluminan las máquinas y dejan oscura la pared de detrás de la UI.
        data = bpy.data.lights.new(f"lamp{i}", "SPOT")
        data.energy = 350.0
        data.spot_size = math.radians(80)
        data.spot_blend = 0.6
        data.shadow_soft_size = 0.3
        data.color = (1.0, 0.75, 0.45)
        o = bpy.data.objects.new(f"lamp{i}", data)
        bpy.context.scene.collection.objects.link(o)
        o.location = (x, 0.9, 3.2)
        o.visible_camera = False
    world = bpy.context.scene.world or bpy.data.worlds.new("world")
    bpy.context.scene.world = world
    if world.node_tree is None:
        world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.01, 0.012, 0.02, 1)
    bg.inputs["Strength"].default_value = 1.0
    return hall, decor


def build_camera():
    f = Vector((0, math.cos(TILT), -math.sin(TILT)))
    u = Vector((0, math.sin(TILT), math.cos(TILT)))
    # El punto del suelo (0; 0,4; 0) cae a 20 px del borde inferior.
    anchor = Vector((0, 0.4, 0))
    q = anchor + u * ((H / 2 - 20) / PPM)
    data = bpy.data.cameras.new("cam")
    data.type = "ORTHO"
    data.ortho_scale = W / PPM
    cam = bpy.data.objects.new("cam", data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = q - f * 20
    cam.rotation_euler = (math.radians(90) - TILT, 0, 0)
    bpy.context.scene.camera = cam
    return cam


def setup_render():
    s = bpy.context.scene
    s.render.engine = "CYCLES"
    s.cycles.samples = SAMPLES
    s.cycles.use_denoising = True
    s.render.resolution_x = W
    s.render.resolution_y = H
    s.render.resolution_percentage = 100
    s.render.image_settings.file_format = "PNG"
    s.render.image_settings.color_depth = "8"
    s.view_settings.view_transform = "Standard"


def descendants(o):
    out = [o]
    for c in o.children:
        out.extend(descendants(c))
    return out


def pixel_rect(objs, cam):
    s = bpy.context.scene
    xs, ys = [], []
    for o in objs:
        if o.type not in ("MESH", "FONT"):
            continue
        for corner in o.bound_box:
            co = world_to_camera_view(s, cam, o.matrix_world @ Vector(corner))
            xs.append(co.x)
            ys.append(co.y)
    return min(xs), max(xs), min(ys), max(ys)


def render_to(path, transparent):
    s = bpy.context.scene
    s.render.film_transparent = transparent
    s.render.image_settings.color_mode = "RGBA" if transparent else "RGB"
    s.render.filepath = path
    bpy.ops.render.render(write_still=True)


def crop_alpha(src, dst):
    """Recorta por alfa. Devuelve (izquierda, arriba, ancho, alto) en píxeles desde arriba a la izquierda."""
    img = bpy.data.images.load(src, check_existing=False)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    rows = np.where(px[:, :, 3].max(axis=1) > 0.02)[0]
    cols = np.where(px[:, :, 3].max(axis=0) > 0.02)[0]
    r0, r1, c0, c1 = rows[0], rows[-1] + 1, cols[0], cols[-1] + 1
    crop = px[r0:r1, c0:c1, :]
    out = bpy.data.images.new(os.path.basename(dst), c1 - c0, r1 - r0, alpha=True)
    out.pixels.foreach_set(crop.ravel())
    out.filepath_raw = dst
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    # Las filas de Blender van de abajo arriba.
    return int(c0), int(h - r1), int(c1 - c0), int(r1 - r0)


def write_scene(rects):
    exts = ['[ext_resource type="Script" path="res://presentation/ui/factory_view.gd" id="script"]',
            '[ext_resource type="Texture2D" path="res://assets/textures/factory/background.png" id="bg"]']
    nodes = [
        '[node name="FactoryView" type="Control"]\nlayout_mode = 3\nanchors_preset = 0\n'
        f'offset_right = {W}.0\noffset_bottom = {H}.0\nmouse_filter = 2\nscript = ExtResource("script")\n',
        '[node name="Background" type="TextureRect" parent="."]\nlayout_mode = 0\n'
        f'offset_right = {W}.0\noffset_bottom = {H}.0\nmouse_filter = 2\ntexture = ExtResource("bg")\n',
    ]
    for gid, _builder, slots in LAYOUT:
        nodes.append(f'[node name="{gid}" type="Control" parent="."]\nlayout_mode = 0\n'
                     f'offset_right = {W}.0\noffset_bottom = {H}.0\nmouse_filter = 2\n')
        for k in range(len(slots)):
            name = f"{gid}_{k}"
            left, top, w, h = rects[name]
            exts.append(f'[ext_resource type="Texture2D" path="res://assets/textures/factory/{name}.png" id="{name}"]')
            nodes.append(f'[node name="slot_{k}" type="TextureRect" parent="{gid}"]\nvisible = false\nlayout_mode = 0\n'
                         f'offset_left = {left}.0\noffset_top = {top}.0\noffset_right = {left + w}.0\n'
                         f'offset_bottom = {top + h}.0\nmouse_filter = 2\ntexture = ExtResource("{name}")\n')
    text = f"[gd_scene load_steps={len(exts) + 1} format=3]\n\n" + "\n".join(exts) + "\n\n" + "\n".join(nodes)
    with open(SCENE_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def main():
    reset()
    M = materials()
    hall, decor = build_hall(M)
    cam = build_camera()
    setup_render()
    instances = {}
    for gid, builder, slots in LAYOUT:
        for k, (x, y) in enumerate(slots):
            root = empty(f"{gid}_{k}", (x, y, 0))
            builder(root, M)
            instances[root.name] = descendants(root)
    if PREVIEW:
        return
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(TMP, exist_ok=True)
    s = bpy.context.scene
    every = [o for objs in instances.values() for o in objs]
    for o in every:
        o.hide_render = True
    s.render.use_border = False
    render_to(os.path.join(OUT, "background.png"), False)

    for o in decor:
        o.hide_render = True
    for o in hall:
        o.is_shadow_catcher = True
    s.render.use_border = True
    s.render.use_crop_to_border = False
    rects = {}
    for name, objs in instances.items():
        for o in every:
            o.hide_render = o not in objs
        x0, x1, y0, y1 = pixel_rect(objs, cam)
        s.render.border_min_x = max(0.0, x0 - 0.05)
        s.render.border_max_x = min(1.0, x1 + 0.05)
        s.render.border_min_y = max(0.0, y0 - 0.06)
        s.render.border_max_y = min(1.0, y1 + 0.03)
        tmp = os.path.join(TMP, name + ".png")
        render_to(tmp, True)
        rects[name] = crop_alpha(tmp, os.path.join(OUT, name + ".png"))
    s.render.use_border = False
    for o in hall:
        o.is_shadow_catcher = False
    for o in every + decor:
        o.hide_render = False
    write_scene(rects)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "art_source", "factory.blend"))
    print("FACTORY_OK", len(rects))


main()
