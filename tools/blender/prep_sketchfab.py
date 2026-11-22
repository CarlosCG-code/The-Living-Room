"""Prepara los modelos de Sketchfab (tools/fetch_sketchfab.py) para import_model: los escaneos traen cientos de miles
de caras y texturas de 4-8k. Junta las mallas, las reduce a ~FACES caras, las pone a su tamaño real (lado mayor en
metros), de cara a -Y como los de Poly Haven, baja las texturas a 1024 px y guarda art_source/sketchfab/<n>/<n>_1k.gltf.

    blender -b --factory-startup --python-expr "ROOT = r'<proyecto>'; exec(open(ROOT + '/tools/blender/prep_sketchfab.py').read())"
"""
import math
import os

import bpy

ROOT = globals().get("ROOT", os.getcwd())
SK = os.path.join(ROOT, "art_source", "sketchfab")
FACES = 20000
# nombre: (lado mayor en metros, giro en Z en grados para que mire a -Y, caras); los tres ya miran a -Y.
MODELS = {"old_boots": (0.3, 0, FACES), "orava_clock": (0.45, 0, FACES), "philips_radio": (0.55, 0, 40000)}  # a 20 000 la madera de la radio se emborronaba

for name, (size, rot, target) in MODELS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SK, name, "scene.gltf"))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    o = bpy.context.active_object
    for e in [e for e in bpy.context.scene.objects if e.type != "MESH"]:
        bpy.data.objects.remove(e, do_unlink=True)
    faces = len(o.data.polygons)
    if faces > target:
        mod = o.modifiers.new("Dec", "DECIMATE")
        mod.ratio = target / faces
        bpy.ops.object.modifier_apply(modifier=mod.name)
    dims = o.dimensions
    k = size / max(dims)
    o.scale = (k, k, k)
    o.rotation_euler = (0, 0, math.radians(rot))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for img in bpy.data.images:
        if img.size[0] > 1024:
            img.scale(1024, max(1, int(1024 * img.size[1] / img.size[0])))
        # Se guarda como PNG antes de exportar: el exportador mantiene JPG si el original lo era, y Godot rechaza los
        # JPG que escribe Blender (ERR_PARSE_ERROR al importar).
        os.makedirs(os.path.join(SK, name, "png"), exist_ok=True)
        img.filepath_raw = os.path.join(SK, name, "png", bpy.path.clean_name(img.name) + ".png")
        img.file_format = "PNG"
        img.save()
    o.name = name
    out = os.path.join(SK, name, "%s_1k.gltf" % name)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLTF_SEPARATE", export_texture_dir="textures_1k",
                              export_image_format="AUTO", use_selection=False)
    print("PREP_OK", name, faces, "->", len(o.data.polygons), "dims", [round(v, 3) for v in o.dimensions])
