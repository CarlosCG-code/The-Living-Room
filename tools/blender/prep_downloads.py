"""Prepara los modelos descargados de Sketchfab y BlenderKit (tools/fetch_sketchfab.py, tools/fetch_blenderkit.py)
para import_model: los escaneos traen cientos de miles de caras y texturas de 4-8k. Junta las mallas, las reduce,
las pone a su tamaño, de cara a -Y como los de Poly Haven, baja las texturas a 1024 px en PNG y guarda
art_source/<origen>/<n>/<n>_1k.gltf.

    blender -b --factory-startup --python-expr "ROOT = r'<proyecto>'; exec(open(ROOT + '/tools/blender/prep_downloads.py').read())"
"""
import glob
import math
import os

import bmesh
import bpy

ROOT = globals().get("ROOT", os.getcwd())
ART = os.path.join(ROOT, "art_source")
# nombre: (origen, tamaño, giro en Z para que mire a -Y, caras, objetos que se quitan, caras que se quitan).
# tamaño: lado mayor en metros, o (ancho, alto) para ajustarlo a un hueco.
MODELS = {
    "old_boots": ("sketchfab", 0.3, 0, 20000, (), None),
    "orava_clock": ("sketchfab", 0.45, 0, 20000, (), None),
    "philips_radio": ("sketchfab", 0.55, 0, 40000, (), None),  # a 20 000 la madera se emborronaba
    "rusty_stove": ("blenderkit", 0.85, 0, 20000, (), None),
    # Ventana de madera de dos hojas: sin el trozo de fachada de piedra, sin los cristales (van pintados en la
    # textura: desde dentro no se veía la calle; los pone build_flat.py, transparentes) y sin las contraventanas
    # abiertas que sobresalen por fuera. Exterior hacia -Y; se ajusta al hueco de 1,2 × 1,2 m.
    "classic_window": ("blenderkit", (1.2, 1.2), 0, 40000, ("Classic Window",), "window"),
    # Decoración (usuario, 2026-11-22: casa vivida como en sus fotos de referencia).
    "lace_curtain": ("blenderkit", 1.3, 0, 40000, (), None),  # visillo con su barra, a lo ancho de la ventana
    "bankers_lamp": ("blenderkit", 0.4, 0, 20000, (), None),
    "enamel_kettle": ("blenderkit", 0.26, 0, 20000, (), None),
    "old_book_tennyson": ("blenderkit", 0.22, 0, 10000, (), None),
    "old_book_st_ives": ("blenderkit", 0.2, 0, 10000, (), None),
    "old_book_balfour": ("blenderkit", 0.2, 0, 10000, (), None),
    "old_book_red": ("blenderkit", 0.24, 0, 10000, (), None),
    "dirty_blanket": ("blenderkit", 0.5, 0, 20000, (), None),  # trapo del taller
    "scarf": ("blenderkit", 0.45, 0, 20000, (), None),
    "black_hat": ("blenderkit", 0.32, 0, 20000, (), None),
    "bread_braid": ("blenderkit", 0.3, 0, 20000, (), None),
    "bread_rustic": ("blenderkit", 0.2, 0, 20000, (), None),
    "letters": ("blenderkit", 0.3, 0, 20000, (), None),
    "rusty_tin": ("blenderkit", 0.15, 0, 20000, (), None),
}


def cut_window(o):
    """Quita los cristales (caras planas grandes de cara a ±Y) y lo que sobresale hacia fuera (-Y) del cerco."""
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.normal_update()
    ys = sorted(v.co.y for v in bm.verts)
    back = ys[-1]
    bad = [f for f in bm.faces if (abs(f.normal.y) > 0.95 and f.calc_area() > 0.3) or f.calc_center_median().y < back - 0.2]
    bmesh.ops.delete(bm, geom=bad, context="FACES")
    bm.to_mesh(o.data)
    bm.free()


for name, (origin, size, rot, target, drop, special) in MODELS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    folder = os.path.join(ART, origin, name)
    bpy.ops.import_scene.gltf(filepath=glob.glob(os.path.join(folder, "scene.gl*"))[0])
    for o in [o for o in bpy.context.scene.objects if o.name in drop]:
        bpy.data.objects.remove(o, do_unlink=True)
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
    if special == "window":
        cut_window(o)
    faces = len(o.data.polygons)
    if faces > target:
        mod = o.modifiers.new("Dec", "DECIMATE")
        mod.ratio = target / faces
        bpy.ops.object.modifier_apply(modifier=mod.name)
    d = o.dimensions
    o.scale = (size[0] / d.x, 1.0, size[1] / d.z) if isinstance(size, tuple) else (size / max(d),) * 3
    o.rotation_euler = (0, 0, math.radians(rot))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for img in bpy.data.images:
        if img.size[0] > 1024:
            img.scale(1024, max(1, int(1024 * img.size[1] / img.size[0])))
        # Se guarda como PNG antes de exportar: el exportador mantiene JPG si el original lo era, y Godot rechaza los
        # JPG que escribe Blender (ERR_PARSE_ERROR al importar).
        os.makedirs(os.path.join(folder, "png"), exist_ok=True)
        img.filepath_raw = os.path.join(folder, "png", bpy.path.clean_name(img.name) + ".png")
        img.file_format = "PNG"
        img.save()
    o.name = name
    bpy.ops.export_scene.gltf(filepath=os.path.join(folder, "%s_1k.gltf" % name), export_format="GLTF_SEPARATE",
                              export_texture_dir="textures_1k", export_image_format="AUTO", use_selection=False)
    print("PREP_OK", name, faces, "->", len(o.data.polygons), "dims", [round(v, 3) for v in o.dimensions])
