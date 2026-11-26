"""Exporta los personajes de art_source/characters/ a glTF para Godot (specs/hito4b.md D4).

Uso (después de build_characters.py; sin --factory-startup por MPFB2):
    blender -b --python-expr "ROOT = r'<proyecto>'; exec(open(ROOT + '/tools/blender/export_character.py').read())"

- player: solo los brazos (piel y mangas), lo único que se ve en primera persona.
- neighbor: entero; por la rendija se ve una parte que depende de la pose.
Las animaciones (paso 4) van como acciones del .blend y salen en el mismo glTF.
"""
import os

import bmesh
import bpy

ROOT = globals().get("ROOT") or os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "art_source", "characters")
OUT = os.path.join(ROOT, "assets", "models", "characters")

ARM_BONES = ("clavicle_", "upperarm_", "lowerarm_", "hand_", "index_", "middle_", "pinky_", "ring_", "thumb_")
ARM_MIN_WEIGHT = 0.5  # un vértice es del brazo si al menos la mitad de su peso es de huesos del brazo


def _keep_arms(obj: bpy.types.Object) -> None:
    arm_groups = {g.index for g in obj.vertex_groups if g.name.startswith(ARM_BONES) and not g.name.startswith("clavicle_")}
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    deform = bm.verts.layers.deform.verify()
    drop = [v for v in bm.verts if sum(w for g, w in v[deform].items() if g in arm_groups) < ARM_MIN_WEIGHT]
    bmesh.ops.delete(bm, geom=drop, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()


def _drop_hidden(body: bpy.types.Object) -> None:
    """Aplica las máscaras de MPFB (ayudantes y piel bajo la ropa) para que no viajen al juego."""
    for o in [x for x in bpy.data.objects if x.type == "MESH" and x.data.shape_keys]:
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)  # las formas de MakeHuman quedan fijas
    bpy.context.view_layer.objects.active = body
    for mod in [m for m in body.modifiers if m.type == "MASK"]:
        bpy.ops.object.modifier_apply(modifier=mod.name)


def export(name: str, arms_only: bool) -> None:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(SRC, name + ".blend"))
    body = bpy.data.objects[name + ".body"]
    _drop_hidden(body)
    if arms_only:
        sleeves = [o for o in bpy.data.objects if o.name.endswith("male_worksuit01")]
        for o in list(bpy.data.objects):
            if o.type == "MESH" and o is not body and o not in sleeves:
                bpy.data.objects.remove(o)
        for o in [body] + sleeves:
            _keep_arms(o)
            o.data.name = o.name
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, ("player_arms" if arms_only else name) + ".gltf")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLTF_SEPARATE", export_texture_dir="textures",
                              export_apply=True, export_skins=True, export_animations=True,
                              export_def_bones=False, export_yup=True)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
    print("EXPORTED %s tris=%d" % (out, tris))


export("player", True)
export("neighbor", False)
