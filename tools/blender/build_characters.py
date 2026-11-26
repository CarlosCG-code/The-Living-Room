"""Personajes del hito 4b con MPFB2, solo con assets CC0 de MakeHuman (specs/hito4b.md D4).

Uso (sin --factory-startup: MPFB2 es una extensión de las preferencias del usuario):
    blender -b --python-expr "ROOT = r'<proyecto>'; exec(open(ROOT + '/tools/blender/build_characters.py').read())"
Con PREVIEW = r'<carpeta>' guarda además renders de revisión (frente y tres cuartos).

Guarda art_source/characters/<nombre>.blend. La exportación a glTF va aparte (export_character.py).
"""
import math
import os

import bpy
import numpy as np
from mathutils import Vector

from bl_ext.blender_org.mpfb.services.humanservice import HumanService

ROOT = globals().get("ROOT") or os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PREVIEW = globals().get("PREVIEW", "")
OUT = os.path.join(ROOT, "art_source", "characters")


def _age(years: float) -> float:
    # Escala de MakeHuman: 0,5 = 25 años y 1 = 90.
    return 0.5 + (years - 25.0) / 65.0 * 0.5


CHARACTERS = {
    # El electricista: mono de trabajo y camiseta, sin marcas (D4; el uniforme con el nombre es una pista).
    "player": {
        "phenotype": {"gender": 1.0, "age": _age(40), "muscle": 0.62, "weight": 0.55, "proportions": 0.6,
                      "height": 0.55, "cupsize": 0.5, "firmness": 0.5,
                      "race": {"asian": 0.0, "caucasian": 1.0, "african": 0.0}},
        "skin": "middleage_caucasian_male.mhmat",
        "hair": "short02.mhclo",
        "eyebrows": "eyebrow001.mhclo",
        "clothes": ["male_worksuit01.mhclo", "toigo_ankle_boots_male.mhclo"],
        # Mono gastado de color azul marino apagado: el azul claro nuevo parecía de disfraz.
        "tint": {"male_worksuit01": (0.30, 0.34, 0.42, 0.9)},
    },
    # El vecino del 8.º: un señor cualquiera de unos 55 años, con jersey de lana.
    "neighbor": {
        "phenotype": {"gender": 1.0, "age": _age(58), "muscle": 0.42, "weight": 0.64, "proportions": 0.45,
                      "height": 0.45, "cupsize": 0.5, "firmness": 0.35,
                      "race": {"asian": 0.0, "caucasian": 1.0, "african": 0.0}},
        "skin": "old_caucasian_male.mhmat",
        "hair": "short04.mhclo",
        "eyebrows": "eyebrow006.mhclo",
        "clothes": ["toigo_fisherman_sweater.mhclo", "toigo_wool_pants.mhclo", "toigo_ankle_boots_male.mhclo"],
        # Jersey pardo de lana en vez de rojo; pelo canoso.
        "tint": {"toigo_fisherman_sweater": (0.45, 0.36, 0.26, 0.85), "short04": (0.55, 0.53, 0.5, 0.6)},
        "under": ("toigo_wool_pants", "toigo_fisherman_sweater"),
    },
}


def build(name: str, spec: dict) -> bpy.types.Object:
    bpy.ops.wm.read_homefile(use_empty=True)
    info = HumanService._create_default_human_info_dict()
    info.update({
        "name": name,
        "phenotype": spec["phenotype"],
        "rig": "game_engine",  # tiene dedos (D4)
        "eyes": "low-poly.mhclo",
        "eyebrows": spec["eyebrows"],
        "eyelashes": "eyelashes01.mhclo",
        "teeth": "teeth_base.mhclo",
        "hair": spec["hair"],
        "clothes": spec["clothes"],
        "skin_mhmat": spec["skin"],
        "skin_material_type": "GAMEENGINE",  # texturas planas: pasan a glTF; el material procedural no
        "eyes_material_type": "GAMEENGINE",  # con MAKESKIN los ojos salían rojos
    })
    settings = HumanService.get_default_deserialization_settings()
    settings["subdiv_levels"] = 0
    settings["override_clothes_model"] = "GAMEENGINE"
    settings["override_eyes_model"] = "GAMEENGINE"
    body = HumanService.deserialize_from_dict(info, settings)
    for asset, rgb_mix in spec.get("tint", {}).items():
        tint(name, asset, rgb_mix)
    if "under" in spec:
        trim_under(name, *spec["under"])
    eyes_texture(name)
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, name + ".blend"))
    return body


def tint(name: str, asset: str, rgb_mix: tuple) -> None:
    """Tiñe la textura de color de una prenda hacia rgb (mezcla mix, conservando la luminancia) y la guarda aparte."""
    obj = bpy.data.objects[name + "." + asset]
    for slot in obj.material_slots:
        for node in slot.material.node_tree.nodes:
            if node.type != "TEX_IMAGE" or node.image is None or node.name != "DiffuseTexture":
                continue
            img = node.image
            px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, 4)
            lum = px[:, :3] @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
            target = lum[:, None] * np.array(rgb_mix[:3], dtype=np.float32) * 1.6
            px[:, :3] = px[:, :3] * (1.0 - rgb_mix[3]) + target * rgb_mix[3]
            copy = img.copy()
            copy.name = "%s_%s_tinted" % (name, asset)
            copy.pixels[:] = np.clip(px, 0.0, 1.0).ravel()
            os.makedirs(os.path.join(OUT, "textures"), exist_ok=True)
            copy.filepath_raw = os.path.join(OUT, "textures", copy.name + ".png")
            copy.file_format = "PNG"
            copy.save()
            node.image = copy


def eyes_texture(name: str) -> None:
    """Con el material de motor de juego, los ojos llegaban sin textura (rojos): se les pone la marrón a mano."""
    from bl_ext.blender_org.mpfb.services.locationservice import LocationService
    path = os.path.join(LocationService.get_user_data("eyes"), "materials", "brown_eye.png")
    mat = bpy.data.objects[name + ".low-poly"].material_slots[0].material
    tree = mat.node_tree
    bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    tex = tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.get("eyes_brown") or _muted_eyes(path)
    tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.15


def _muted_eyes(path: str) -> bpy.types.Image:
    # El iris marrón de MakeHuman sale naranja: se apaga la mitad de su saturación y se oscurece un poco.
    img = bpy.data.images.load(path).copy()
    img.name = "eyes_brown"
    px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, 4)
    lum = px[:, :3] @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    px[:, :3] = (px[:, :3] * 0.5 + lum[:, None] * 0.5) * 0.85
    img.pixels[:] = np.clip(px, 0.0, 1.0).ravel()
    os.makedirs(os.path.join(OUT, "textures"), exist_ok=True)
    img.filepath_raw = os.path.join(OUT, "textures", "eyes_brown.png")
    img.file_format = "PNG"
    img.save()
    return img


def trim_under(name: str, inner: str, outer: str) -> None:
    """Borra la parte de una prenda que queda tapada por otra y se colaba a través (la cintura bajo el jersey)."""
    hem = min((bpy.data.objects[name + "." + outer].matrix_world @ v.co).z
              for v in bpy.data.objects[name + "." + outer].data.vertices)
    obj = bpy.data.objects[name + "." + inner]
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if (obj.matrix_world @ v.co).z > hem + 0.04], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()


def _tris() -> int:
    total = 0
    for o in bpy.context.scene.objects:
        if o.type == "MESH" and o.visible_get():
            total += sum(len(p.vertices) - 2 for p in o.data.polygons)
    return total


def render_preview(name: str) -> None:
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            pass
    scene.render.resolution_x, scene.render.resolution_y = 800, 1000
    world = bpy.data.worlds.new("preview")
    world.color = (0.05, 0.05, 0.05)
    scene.world = world
    for loc, energy in (((2.0, -3.0, 3.0), 600.0), ((-3.0, -1.0, 2.0), 250.0), ((0.0, 3.0, 2.5), 300.0)):
        light = bpy.data.objects.new("L", bpy.data.lights.new("L", "AREA"))
        light.data.energy = energy
        light.data.size = 2.0
        light.location = loc
        light.rotation_euler = (Vector((0, 0, 1.0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(light)
    cam = bpy.data.objects.new("C", bpy.data.cameras.new("C"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    rig = next(o for o in scene.objects if o.type == "ARMATURE")
    hand = next(b for b in rig.data.bones if b.name.lower() in ("hand_r", "hand.r", "righthand"))
    hand_at = rig.matrix_world @ hand.head_local
    for label, angle, target, dist, lens in (("front", 0.0, Vector((0, 0, 0.95)), 3.6, 50),
                                             ("three_quarter", 35.0, Vector((0, 0, 0.95)), 3.6, 50),
                                             ("face", 20.0, Vector((0, 0, 1.62)), 0.9, 85),
                                             ("hands", -20.0, hand_at, 0.7, 50)):
        a = math.radians(angle)
        cam.location = target + Vector((math.sin(a) * dist, -math.cos(a) * dist, 0.05))
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lens
        scene.render.filepath = os.path.join(PREVIEW, "%s_%s.png" % (name, label))
        bpy.ops.render.render(write_still=True)


for _name, _spec in CHARACTERS.items():
    build(_name, _spec)
    print("CHARACTER %s tris=%d objects=%s" % (_name, _tris(), [o.name for o in bpy.context.scene.objects]))
    if PREVIEW:
        render_preview(_name)
