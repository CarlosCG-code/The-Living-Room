"""Construye el salón del jugador en Blender y exporta los .glb (specs/hito2.md §4, §6 paso 3).

Se ejecuta dentro de Blender (MCP execute_blender_code) con:
    MODE = "graybox"; ROOT = r"C:/ruta/al/proyecto"; exec(open(ROOT + "/tools/blender/build_living_room.py").read())

Salón de 4 × 5 m, techo de 2,6 m, centrado en x = 0 (plano del espejo). En Blender: X a la derecha,
-Y hacia el fondo (la tele), Z arriba. En Godot (glTF): X, Y arriba, Z hacia el sofá.
Los objetos con sufijo -col generan colisión al importar en Godot.
"""
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

MODE = globals().get("MODE", "graybox")
ROOT = globals().get("ROOT", os.getcwd())
OUT = os.path.join(ROOT, "assets", "models")
SRC = os.path.join(ROOT, "art_source")

W, D, H, T = 4.0, 5.0, 2.6, 0.15  # ancho (X), fondo (Y), alto, grosor de pared
DOOR_TINT = (0.42, 0.35, 0.3)  # nogal oscuro sobre dark_wood: puertas y marcos de toda la casa (build_door.py)


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


def open_flat_uvs():
    """Caras con la textura aplastada (área cero en UV): sin tangente posible, su relieve salía arbitrario, distinto en
    cada piso (franjas negras en las cortinas). Se les da un área mínima, menos de un píxel."""
    for me in {o.data for o in bpy.context.scene.objects if o.type == "MESH"}:
        bm = bmesh.new()
        bm.from_mesh(me)
        fixed = False
        for layer in bm.loops.layers.uv.values():
            flat = {a.face for a, b, c in bm.calc_loop_triangles()
                    if abs((b[layer].uv - a[layer].uv).cross(c[layer].uv - a[layer].uv)) < 1e-9}
            fixed = fixed or bool(flat)
            for face in flat:
                for i, loop in enumerate(face.loops):
                    angle = 2 * math.pi * i / len(face.loops)
                    loop[layer].uv += Vector((math.cos(angle), math.sin(angle))) * 2e-4
        if fixed:
            bm.to_mesh(me)
        bm.free()


def mirror_all(recalc_normals=True):
    for o in bpy.context.scene.objects:
        o.select_set(True)
        o.location.x = -o.location.x
        # El giro también se refleja (S·R·S): si no, un objeto girado se reflejaba sobre su propio eje y quedaba dentro del muro.
        q = o.matrix_basis.to_quaternion()
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = (q.w, q.x, -q.y, -q.z)
        o.scale.x = -o.scale.x
    bpy.context.view_layer.objects.active = bpy.context.scene.objects[0]
    # Tras exportar, las mallas con modificadores (biselado) quedan con dos usuarios y no se dejaría aplicar.
    bpy.ops.object.make_single_user(object=True, obdata=True)
    bpy.context.view_layer.objects.active = next(o for o in bpy.context.scene.objects if o.type == "MESH")
    bpy.ops.object.convert(target="MESH")  # modificadores aplicados antes: reflejados, redondeaban distinto
    # Aplicar la escala negativa estropea las normales: se guardan y se reponen reflejadas. Y se triangula antes, como
    # lo hace el exportador: reflejados, los polígonos grandes se partían de otra forma (cortinas, fregadero).
    meshes = list({o.data: o.scale.copy() for o in bpy.context.scene.objects if o.type == "MESH"}.items())
    for me, _ in meshes:
        kept = me.attributes.new("kept_normal", "FLOAT_VECTOR", "CORNER")
        kept.data.foreach_set("vector", [c for n in me.corner_normals for c in n.vector])
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="FIXED", ngon_method="EAR_CLIP")
        bm.to_mesh(me)
        bm.free()
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for me, sc in meshes:
        normals = [Vector((d.vector.x / sc.x, d.vector.y / sc.y, d.vector.z / sc.z)).normalized() for d in me.attributes["kept_normal"].data]
        for name in ("kept_normal", "custom_normal"):
            if name in me.attributes:
                me.attributes.remove(me.attributes[name])
        # Normales libres (Blender 4.5+): normals_split_custom_set promediaba las de alrededor de un mismo vértice.
        free = me.attributes.new("custom_normal", "FLOAT_VECTOR", "CORNER")
        free.data.foreach_set("vector", [c for n in normals for c in n])
    # Blender 5.3 ya deja las normales hacia fuera al aplicar la escala negativa (comprobado 2026-11-19);
    # recalcularlas estropearía mallas abiertas importadas (hojas de la planta, pantalla de la lámpara).
    if not recalc_normals:
        return
    for o in bpy.context.scene.objects:
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode="OBJECT")


def export(path):
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True)


def mat(name, color, rough, metallic=0.0, emission=None, emission_strength=4.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    if emission:
        b.inputs["Emission Color"].default_value = (*emission, 1.0)
        b.inputs["Emission Strength"].default_value = emission_strength
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


# --- Modo final (fase 2b): materiales con texturas CC0 de Poly Haven y muebles CC0 (specs/hito2.md D13, D18) ---

PH = os.path.join(ROOT, "art_source", "polyhaven")  # lo descarga tools/fetch_polyhaven.py
GEN = os.path.join(ROOT, "art_source", "generated")  # papeles pintados y azulejo: make_wallpapers.py
MET = os.path.join(ROOT, "art_source", "met")  # pinturas CC0 del Met (Open Access), copia de Wikimedia Commons


def uv_world(o, tile):
    """UV en metros reales (tile = metros que cubre la textura), proyectadas por la cara: sin estirar en paredes largas."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(o.data)
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in f.loops:
            p = o.matrix_world @ loop.vert.co
            u, v = {0: (p.y, p.z), 1: (p.x, p.z), 2: (p.x, p.y)}[ax]
            loop[uv].uv = (u / tile, v / tile)
    bm.to_mesh(o.data)
    bm.free()


def tint_base(m, tint):
    """Multiplica la textura de color por tint; glTF lo exporta como baseColorFactor."""
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    src = b.inputs["Base Color"].links[0].from_socket
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    mix.inputs["B"].default_value = (*tint, 1.0)
    nt.links.new(src, mix.inputs["A"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])


def tex_mat(name, tex_id, res, tint=None, root=None):
    """Material PBR con las texturas de Poly Haven (o de make_wallpapers.py, root=GEN): color, normal (OpenGL) y
    rugosidad. Si ya existe, se reutiliza tal cual."""
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    folder = os.path.join(root or PH, tex_id)

    def img(kind, colour):
        node = nt.nodes.new("ShaderNodeTexImage")
        path = os.path.join(folder, "%s_%s_%s.jpg" % (tex_id, kind, res))
        if not os.path.exists(path):  # las de make_wallpapers.py son PNG
            path = path[:-4] + ".png"
        node.image = bpy.data.images.load(path, check_existing=True)
        node.image.colorspace_settings.name = "sRGB" if colour else "Non-Color"
        return node

    nt.links.new(img("diff", True).outputs["Color"], b.inputs["Base Color"])
    if tint:
        tint_base(m, tint)
    nt.links.new(img("rough", False).outputs["Color"], b.inputs["Roughness"])
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(img("nor_gl", False).outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], b.inputs["Normal"])
    b.inputs["Metallic"].default_value = 0.0
    return m


def import_model(asset_id, res, loc, rot_z_deg=0.0, scale=1.0, drop=(), tint=None, lay=False):
    """Importa el glTF de Poly Haven, lo deja sin padres, apoyado en loc (el suelo del modelo en loc.z) y girado.
    drop quita las mallas o los materiales (con sus caras) cuyo nombre contenga alguna de esas palabras.
    lay: lo tumba sobre su cara más ancha (martillos, llaves y sierras vienen de pie; usuario, 2026-11-22)."""
    before = set(bpy.context.scene.objects)
    # Los de Sketchfab y BlenderKit, ya reducidos por prep_downloads.py; si no, Poly Haven.
    folder = next((d for d in (os.path.join(ROOT, "art_source", o, asset_id) for o in ("sketchfab", "blenderkit")) if os.path.isdir(d)), os.path.join(PH, asset_id))
    bpy.ops.import_scene.gltf(filepath=os.path.join(folder, "%s_%s.gltf" % (asset_id, res)))
    new = [o for o in bpy.context.scene.objects if o not in before]
    for o in new:
        o.select_set(o.type == "MESH")
    bpy.context.view_layer.objects.active = next(o for o in new if o.type == "MESH")
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    meshes = [o for o in new if o.type == "MESH"]  # antes de borrar: un objeto borrado no se puede ni consultar
    for o in [o for o in new if o.type != "MESH"]:
        bpy.data.objects.remove(o, do_unlink=True)
    for o in [o for o in meshes if any(d in o.name.lower() for d in drop)]:
        meshes.remove(o)
        bpy.data.objects.remove(o, do_unlink=True)
    import bmesh
    for o in meshes:
        bad = {i for i, m in enumerate(o.data.materials) if m and any(d in m.name.lower() for d in drop)}
        if bad:  # p. ej. el cristal de un cuadro como material de la misma malla: en Godot salía negro
            bm = bmesh.new()
            bm.from_mesh(o.data)
            bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index in bad], context="FACES")
            bm.to_mesh(o.data)
            bm.free()
        if tint:
            for m in o.data.materials:
                if m:
                    tint_base(m, tint)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if lay:
        pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
        dims = [max(p[i] for p in pts) - min(p[i] for p in pts) for i in range(3)]
        thin = dims.index(min(dims))
        if thin != 2:  # el eje más fino pasa a ser el vertical
            r = Matrix.Rotation(math.radians(90), 4, "Y" if thin == 0 else "X")
            for o in meshes:
                o.data.transform(r)
    # Pivote: centro en planta y base del modelo, para colocarlo por el suelo. Con los vértices: bound_box se queda
    # con la caja de antes de tumbarlo y el modelo flotaba (usuario, 2026-11-22).
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2
    cy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
    cz = min(p.z for p in pts)
    for o in meshes:
        o.data.transform(Matrix.Translation((-cx, -cy, -cz)))
        o.location = loc
        o.rotation_mode = "XYZ"  # el importador de glTF deja cuaterniones: rotation_euler se ignoraría
        o.rotation_euler = (0, 0, math.radians(rot_z_deg))
        o.scale = (scale, scale, scale)
        o.name = asset_id if len(meshes) == 1 else "%s_%s" % (asset_id, o.name)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return meshes


def cone(name, r_bottom, r_top, depth, loc, verts=32):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r_bottom, radius2=r_top, depth=depth, location=loc,
                                    end_fill_type="NOTHING")
    o = bpy.context.active_object
    o.name = name
    return o


def build_final():
    build_room()
    for name in ("TvStand-col", "Sofa-col", "SofaBack-col", "CoffeeTable-col", "Shelf-col"):
        bpy.data.objects.remove(bpy.data.objects[name], do_unlink=True)  # los bloques del graybox
    # Papel de damasco de los años 40 (usuario, 2026-11-21: el decrepit_wallpaper parecía una obra).
    wall = tex_mat("Wallpaper", "wallpaper_damask", "2k", root=GEN)
    floor = tex_mat("Parquet", "herringbone_parquet", "2k")
    ceiling = tex_mat("Gotele", "white_stucco", "1k", tint=(0.6, 0.57, 0.52))  # techo amarillento, no blanco
    for o in list(bpy.context.scene.objects):
        if o.name.startswith("Wall"):
            give(o, wall)
            uv_world(o, 2.5)
        elif o.name.startswith("Floor"):
            give(o, floor)
            uv_world(o, 3.4)
        elif o.name.startswith("Ceiling"):
            give(o, ceiling)
            uv_world(o, 2.0)

    wood = mat("DarkWood", (0.05, 0.028, 0.016), 0.45)
    door_wood = tex_mat("DoorWood", "dark_wood_worn", "2k", tint=DOOR_TINT, root=GEN)
    marble = mat("Marble", (0.62, 0.6, 0.57), 0.2)
    blind = mat("Blind", (0.42, 0.38, 0.3), 0.6)
    brass = mat("Brass", (0.6, 0.45, 0.22), 0.3, metallic=1.0)
    # La tela deja pasar la luz de la bombilla: brilla un poco (antes se veía gris, como apagada).
    shade = mat("LampShade", (0.42, 0.36, 0.27), 0.8, emission=(1.0, 0.8, 0.6), emission_strength=0.2)
    shade.use_backface_culling = False  # se ve por dentro y por fuera: glTF doubleSided
    glass = mat("Glass", (0.6, 0.65, 0.7), 0.05)
    gb = next(n for n in glass.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    gb.inputs["Alpha"].default_value = 0.12
    glass.surface_render_method = "BLENDED"

    # Rodapiés de madera oscura (8 cm), con hueco en la puerta.
    sh, st = 0.08, 0.015
    y0, y1 = -D / 2, D / 2
    give(box("SkirtBack", (W, st, sh), (0, y0 + st / 2, sh / 2)), wood)
    give(box("SkirtFront", (W, st, sh), (0, y1 - st / 2, sh / 2)), wood)
    give(box("SkirtRight", (st, D, sh), (W / 2 - st / 2, 0, sh / 2)), wood)
    door_y, door_w, door_top = 1.6, 0.9, 2.1
    a1 = door_y - door_w / 2
    give(box("SkirtLeftA", (st, a1 - y0, sh), (-W / 2 + st / 2, (y0 + a1) / 2, sh / 2)), wood)
    a2 = door_y + door_w / 2
    give(box("SkirtLeftB", (st, y1 - a2, sh), (-W / 2 + st / 2, (y1 + a2) / 2, sh / 2)), wood)

    # Ventana (pared +X): marco, cristal, alféizar de mármol, persiana medio bajada por fuera y su cajón.
    wx, win_y, win_w, win_bot, win_top = W / 2 + T / 2, 0.5, 1.2, 0.9, 2.1
    for o in import_model("classic_window", "1k", (wx, win_y, win_bot), rot_z_deg=90):  # de BlenderKit; el exterior, a +X
        o.name = "WinFrame"
    give(box("WindowGlass", (0.006, win_w - 0.14, win_top - win_bot - 0.14), (wx, win_y, (win_top + win_bot) / 2)), glass)
    give(box("WindowSill", (0.2, win_w + 0.1, 0.03), (W / 2 - 0.02, win_y, win_bot - 0.015)), marble, bevel=0.005)
    slats, gap, slat_h = [], 0.006, 0.042
    z = win_top
    while z > 1.5:  # persiana bajada hasta 1,5 m: entre lamas pasa la luz de la calle
        slats.append(box("BlindSlat", (0.012, win_w + 0.06, slat_h), (W / 2 + T + 0.02, win_y, z - slat_h / 2)))
        z -= slat_h + gap
    bpy.ops.object.select_all(action="DESELECT")
    for s in slats:
        s.select_set(True)
    bpy.context.view_layer.objects.active = slats[0]
    bpy.ops.object.join()
    give(bpy.context.active_object, blind).name = "Blind"

    # Puerta (pared -X), cerrada: marco, hoja y manilla. La hoja va aparte para poder abrirla en el hito 4.
    dx = -W / 2 - T / 2
    j = 0.07
    e = 0.003  # el marco entra 3 mm en el hueco, como en el piso: a ras del canto parpadeaba en dientes de sierra
    for name, size, loc in [
        ("DoorJambTop", (T + 0.03, door_w + 2 * j, j + e), (dx, door_y, door_top + (j - e) / 2)),
        ("DoorJambL", (T + 0.03, j + e, door_top), (dx, door_y - door_w / 2 - (j - e) / 2, door_top / 2)),
        ("DoorJambR", (T + 0.03, j + e, door_top), (dx, door_y + door_w / 2 + (j - e) / 2, door_top / 2)),
    ]:
        uv_world(give(box(name, size, loc), door_wood, bevel=0.005), 1.2)
    # La hoja la pone Godot (door.gd, con door_leaf.gltf de build_door.py).

    # Sin lámpara de pie (usuario, 2026-11-20): esa esquina queda en penumbra hasta que haya luz en el pasillo.

    # Muebles CC0 de Poly Haven. Sofá contra la pared del fondo mirando a la tele (-Y).
    import_model("sofa_03", "2k", (0, D / 2 - 0.5, 0))
    import_model("throw_pillows_01", "1k", (-0.75, D / 2 - 0.55, 0.42), rot_z_deg=10)
    import_model("small_wooden_table_01", "1k", (0, -D / 2 + 0.28, 0))  # mueble de la tele
    import_model("side_table_01", "1k", (0, 0.65, 0))  # mesa baja
    # Los modelos de Poly Haven miran a -Y: +90° los pone mirando a +X y -90° a -X.
    import_model("vintage_cabinet_01", "2k", (-W / 2 + 0.36, -1.2, 0), rot_z_deg=90)  # aparador
    import_model("wooden_bookshelf_worn", "1k", (W / 2 - 0.3, -1.6, 0), rot_z_deg=-90)
    # Girado hacia la tele; la tapicería original es casi blanca y destacaba demasiado en la penumbra.
    import_model("ArmChair_01", "1k", (1.45, -0.3, 0), rot_z_deg=-39, tint=(0.38, 0.36, 0.33))
    import_model("potted_plant_02", "1k", (1.62, 0.55, 0))
    decorate()
    decorate_1940s(wood, brass, shade)
    floor_colliders()


SKIP_COLLIDE = ("Wall", "Floor", "Ceiling", "Skirt", "Win", "Door", "Blind", "Jamb", "Lintel", "Sill", "Wainscot", "Paper",
                "Painting", "Fixture", "Rug")


def floor_colliders():
    """Colisión invisible (-colonly) con la caja de cada mueble que se apoya en el suelo (specs/hito4a.md D3):
    sin ella, de pie se atravesarían. La del sofá se llama SeatSofa: hacer clic en ella sienta al jugador."""
    for o in list(bpy.context.scene.objects):
        if o.type != "MESH" or "-col" in o.name or o.name.startswith(SKIP_COLLIDE):
            continue
        pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
        lo, hi = min(p.z for p in pts), max(p.z for p in pts)
        if lo > 0.05 or hi - lo < 0.25:  # colgado en la pared o encima de otro mueble, o casi plano (alfombras, libros)
            continue
        x0, x1 = min(p.x for p in pts), max(p.x for p in pts)
        y0, y1 = min(p.y for p in pts), max(p.y for p in pts)
        if (x1 - x0) * (y1 - y0) > 4.0:  # rodea la habitación (zócalo, alfombra grande): su caja la llenaría
            continue
        name = ("SeatSofa" if o.name.startswith("sofa_03") else "Solid_" + o.name.replace(".", "_")) + "-colonly"
        box(name, (x1 - x0, y1 - y0, hi - lo), ((x0 + x1) / 2, (y0 + y1) / 2, (lo + hi) / 2))


def to_wall(objs, axis, coord):
    """Pega los objetos a la pared: su caja toca el plano axis = coord por el lado de la habitación."""
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    i = "xyz".index(axis)
    gap = coord - (max(p[i] for p in pts) if coord > 0 else min(p[i] for p in pts))
    for o in objs:
        o.location[i] += gap


def books_row(y0, y1, z, max_h, rng, x_front=1.5):
    """Libros hechos aquí, todos distintos: grosor, alto, fondo, color y franjas doradas al azar; alguno
    tumbado o inclinado al final de la fila. Lomos hacia -X (la librería está en la pared +X)."""
    palette = [(0.32, 0.05, 0.04), (0.06, 0.09, 0.22), (0.05, 0.16, 0.08), (0.26, 0.15, 0.06), (0.55, 0.38, 0.12),
               (0.03, 0.03, 0.03), (0.62, 0.57, 0.46), (0.42, 0.1, 0.14), (0.12, 0.2, 0.25), (0.45, 0.42, 0.36)]
    covers = [mat("BookCover%d" % i, c, rng.uniform(0.45, 0.8)) for i, c in enumerate(palette)]
    gold = mat("BookGold", (0.7, 0.52, 0.2), 0.35, metallic=1.0)
    made, y = [], y0
    while y < y1 - 0.02:
        t, h, d = rng.uniform(0.018, 0.05), rng.uniform(0.16, min(0.29, max_h - 0.03)), rng.uniform(0.13, 0.21)
        if y + t > y1:
            break
        if rng.random() < 0.08:  # un hueco de vez en cuando
            y += rng.uniform(0.03, 0.08)
            continue
        b = give(box("Book", (d, t, h), (x_front + d / 2, y + t / 2, z + h / 2)), rng.choice(covers), bevel=0.002)
        made.append(b)
        if rng.random() < 0.4:
            for zz in (z + h * 0.12, z + h * 0.85):
                made.append(give(box("BookBand", (0.002, t * 0.96, 0.006), (x_front - 0.001, y + t / 2, zz)), gold))
        y += t + rng.uniform(0.0, 0.004)
    # Al final de la fila, un libro apoyado en el último.
    if y < y1 - 0.06:
        h = rng.uniform(0.18, min(0.27, max_h - 0.04))
        b = give(box("BookLean", (0.17, 0.03, h), (x_front + 0.085, y + 0.06, z + h / 2 - 0.01)), rng.choice(covers))
        b.rotation_euler = (math.radians(-22), 0, 0)
        made.append(b)
    return made


def books_stack(x, y, z, n, rng):
    palette = [bpy.data.materials["BookCover%d" % i] for i in range(10)]  # los crea books_row
    made = []
    for k in range(n):
        w, l, t = rng.uniform(0.15, 0.22), rng.uniform(0.21, 0.3), rng.uniform(0.02, 0.045)
        b = give(box("BookFlat", (l, w, t), (x, y, z + t / 2)), rng.choice(palette), bevel=0.002)
        b.rotation_euler = (0, 0, math.radians(rng.uniform(-8, 8)))
        z += t
        made.append(b)
    return made


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.convert(target="MESH")  # aplica los biselados antes de unir
    bpy.ops.object.join()
    bpy.context.active_object.name = name
    return bpy.context.active_object


def curtain(name, y0, y1, z_top, z_bottom, x, material, folds=4, depth=0.05):
    """Cortina con pliegues blandos e irregulares (dos senos), más abiertos abajo que en la barra."""
    import bmesh
    bm = bmesh.new()
    nu, nv = folds * 12, 8
    verts = []
    for j in range(nv + 1):
        k = j / nv
        z = z_top + (z_bottom - z_top) * k
        row = []
        for i in range(nu + 1):
            a = i / nu * folds * 2 * math.pi
            off = depth * (0.7 + 0.3 * k) * (math.sin(a) + 0.35 * math.sin(2.3 * a + 1.0 + k))
            row.append(bm.verts.new((x + off, y0 + (y1 - y0) * i / nu, z)))
        verts.append(row)
    uv = bm.loops.layers.uv.verify()
    for j in range(nv):
        for i in range(nu):
            f = bm.faces.new((verts[j][i], verts[j][i + 1], verts[j + 1][i + 1], verts[j + 1][i]))
            f.smooth = True
            for loop in f.loops:
                loop[uv].uv = (loop.vert.co.y / 0.6, loop.vert.co.z / 0.6)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    me.materials.append(material)
    return o


def rug_plane(tex, xy, w, l, rot=0.0, name="Rug"):
    """Alfombra con su textura entera (make_wallpapers.py; usuario, 2026-11-22: casa vivida como en sus fotos): un
    plano a 4 mm del suelo, sin colisión. w a lo largo de X de Blender, l de Y (el largo de la textura)."""
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(xy[0], xy[1], 0.004))
    o = bpy.context.active_object
    o.name = name
    o.scale = (w, l, 1.0)
    o.rotation_euler.z = math.radians(rot)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return [give(o, tex_mat(tex, tex, "2k", root=GEN))]


def decorate():
    """Ronda 2 del look-dev (usuario, 2026-11-19): más decoración, paredes con cuadros, libros variados,
    alfombra, cortinas y lámpara de techo. Todo CC0 de Poly Haven o hecho aquí."""
    import random
    rng = random.Random(7)  # semilla fija: el salón sale igual en cada exportación
    # Librería (pared +X): baldas medidas con rayos (0,39 / 0,67 / 0,96 / 1,28 / 1,66 m), interior y -2,20..-1,00.
    books = []
    books += books_row(-2.19, -1.62, 0.392, 0.28, rng)
    books += books_stack(1.62, -1.25, 0.392, 4, rng)
    books += books_row(-2.19, -1.0, 0.672, 0.29, rng)
    books += books_row(-1.55, -1.0, 0.96, 0.31, rng)
    books += books_row(-2.19, -1.75, 1.277, 0.38, rng)
    books += books_row(-1.45, -1.0, 1.663, 0.39, rng)
    books += books_stack(1.65, -2.0, 1.663, 3, rng)
    books += books_row(-2.19, -1.65, 0.108, 0.28, rng)
    join(books, "Books")
    import_model("book_encyclopedia_set_01", "1k", (W / 2 - 0.25, -1.88, 0.96), rot_z_deg=-90)
    import_model("carved_wooden_elephant", "1k", (W / 2 - 0.27, -1.45, 1.277), rot_z_deg=-120, scale=2.5)
    import_model("standing_picture_frame_02", "1k", (W / 2 - 0.3, -1.3, 2.063), rot_z_deg=-70)
    books_stack(W / 2 - 0.3, -1.85, 2.063, 3, rng)  # sueltos: no entran en el join de arriba

    # Aparador (pared -X): repisa a 0,91 m (franja x -1,55..-1,36) y baldas tras el cristal a 1,37 m.
    import_model("mantel_clock_01", "1k", (-1.46, -1.15, 0.912), rot_z_deg=90)
    import_model("horse_statue_01", "1k", (-1.46, -1.75, 0.912), rot_z_deg=60)
    import_model("standing_picture_frame_01", "1k", (-1.46, -1.5, 0.912), rot_z_deg=110)
    # Velas apagadas: la llama emisiva era el punto más brillante del salón (usuario, 2026-11-19: luces más sutiles).
    import_model("brass_candleholders", "1k", (-1.46, -0.5, 0.912), rot_z_deg=90, scale=0.6, drop=("flame",))
    import_model("tea_set_01", "1k", (-1.8, -1.2, 1.367), rot_z_deg=90, scale=0.75)
    import_model("antique_ceramic_vase_01", "1k", (-1.6, 0.0, 0), rot_z_deg=30)

    # Cuadros y espejo en las paredes.
    to_wall(import_model("hanging_picture_frame_02", "1k", (0.95, -2.3, 1.25), rot_z_deg=180, drop=("glass",)), "y", -D / 2)
    to_wall(import_model("fancy_picture_frame_02", "1k", (0, 2.3, 1.3), drop=("glass",)), "y", D / 2)
    # Espejo de verdad (PlanarMirror busca el material «Mirror»; usuario, 2026-11-22): el de Poly Haven llevaba el
    # cristal en el mismo material que el marco y no se podía separar.
    glass = framed(mat("Mirror", (0.5, 0.5, 0.47), 0.25, metallic=0.6), 0.5, 0.72, "ornate", "Mirror_living_room")
    glass.rotation_euler.z = math.radians(90)
    glass.location = (-1.9, 0.5, 1.15 + 0.36)
    bpy.context.view_layer.update()  # to_wall lee matrix_world: sin esto lo empujaba fuera de la pared
    to_wall([glass], "x", -W / 2)

    # Lámpara de techo (apagada por ahora), alfombra, gafas en la mesa y cesto junto al sofá.
    lamp = import_model("Chandelier_02", "1k", (0, 0.3, 0))
    top = max((o.matrix_world @ Vector(c)).z for o in lamp for c in o.bound_box)
    for o in lamp:
        o.location.z += H - top
    rug_plane("rug_persian_red", (0, 0.55), 1.7, 2.3)
    import_model("round_spectacles", "1k", (0.08, 0.6, 0.551), rot_z_deg=25)
    import_model("wicker_basket_01", "1k", (1.68, 1.55, 0), rot_z_deg=15)

    # Cortinas de raso dorado a los lados de la ventana, hasta el alféizar, y su barra de latón.
    satin = tex_mat("CurtainSatin", "crepe_satin", "1k", tint=(0.55, 0.5, 0.45))
    satin.use_backface_culling = False
    win_y, win_w = 0.5, 1.2
    curtain("CurtainA", win_y - win_w / 2 - 0.2, win_y - win_w / 2 + 0.25, 2.33, 0.82, W / 2 - 0.09, satin)
    curtain("CurtainB", win_y + win_w / 2 - 0.25, win_y + win_w / 2 + 0.2, 2.33, 0.82, W / 2 - 0.09, satin)
    rod = cylinder("CurtainRod", 0.012, win_w + 0.55, (W / 2 - 0.09, win_y, 2.36), rot=(math.radians(90), 0, 0), verts=12)
    give(rod, bpy.data.materials["Brass"])


def wall_plate(loc, rot_z_deg, axis, coord):
    """Plato colgado: el modelo viene tumbado; se pone de pie (cara a -Y) y se gira como los demás."""
    objs = import_model("carved_wooden_plate", "1k", (0, 0, 0))
    for o in objs:
        o.data.transform(Matrix.Rotation(math.radians(90), 4, "X"))
        o.data.transform(Matrix.Rotation(math.radians(rot_z_deg), 4, "Z"))
        o.location = loc
    bpy.context.view_layer.update()  # sin esto, to_wall lee matrix_world viejas y lo saca de la habitación
    to_wall(objs, axis, coord)


# Marcos de Poly Haven (usuario, 2026-11-22: los hechos aquí eran «feísimos»): el dorado ornamentado para los
# cuadros principales y el moldurado, teñido, para el resto. (modelo, tinte del color).
FRAME_STYLES = {"ornate": ("fancy_picture_frame_01", (0.72, 0.6, 0.42)),  # el 02 era enorme (usuario, 2026-11-22)
                "gilt": ("fancy_picture_frame_01", None),
                "ebony": ("fancy_picture_frame_01", (0.16, 0.13, 0.11)), "walnut": ("fancy_picture_frame_01", (0.5, 0.34, 0.22)),
                "silver": ("fancy_picture_frame_01", (0.75, 0.78, 0.82))}


def framed(canvas_mat, w, h, style, name, crop=(0.0, 0.0, 1.0, 1.0)):
    """Marco de Poly Haven ajustado a un lienzo de w × h con canvas_mat dentro (pintura o espejo). Devuelve un objeto
    con el centro del lienzo en el origen, de cara a -Y. El moldurado se gira 90° si el cuadro es vertical."""
    asset, tint = FRAME_STYLES[style]
    objs = import_model(asset, "1k", (0, 0, 0), drop=("glass",), tint=tint)
    canvas = next(o for o in objs if "canvas" in o.name)
    lo, hi = bounds([canvas])
    c = (lo + hi) / 2
    if asset == "fancy_picture_frame_01" and (hi.z - lo.z > hi.x - lo.x) != (h > w):
        r = Matrix.Translation(c) @ Matrix.Rotation(math.radians(90), 4, "Y") @ Matrix.Translation(-c)
        for o in objs:
            o.data.transform(r)
        lo, hi = bounds([canvas])
    fit = Matrix.Diagonal((w / (hi.x - lo.x), 1.0, h / (hi.z - lo.z), 1.0)) @ Matrix.Translation(-c)
    for o in objs:
        o.data.transform(fit)
    canvas.data.materials.clear()
    canvas.data.materials.append(canvas_mat)
    uv = canvas.data.uv_layers.active or canvas.data.uv_layers.new()
    for poly in canvas.data.polygons:  # la pintura entera en el lienzo (el de Poly Haven usaba un trozo de la suya)
        for li in poly.loop_indices:
            v = canvas.data.vertices[canvas.data.loops[li].vertex_index].co
            uv.data[li].uv = (crop[0] + (v.x / w + 0.5) * (crop[2] - crop[0]), crop[1] + (v.z / h + 0.5) * (crop[3] - crop[1]))
    return join(objs, name)


def bounds(objs):
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])


# Recorte (u0, v0, u1, v1; v hacia arriba) de las fotos que el museo retrató dentro de su estuche o con el cartón.
CROP = {"cma:448866": (0.3, 0.25, 0.7, 0.78), "cma:294188": (0.25, 0.22, 0.75, 0.8), "cma:294187": (0.25, 0.22, 0.75, 0.8),
        "cma:536482": (0.27, 0.2, 0.73, 0.8), "cma:285671": (0.05, 0.1, 0.95, 0.97), "cma:523595": (0.08, 0.12, 0.92, 0.92)}


def painting(met_id, loc, rot_z_deg, height, style="gilt", standing=False):
    """Cuadro: una pintura CC0 (Met o Cleveland) en un marco de Poly Haven. loc es el centro del lienzo (de pie: la
    base); de cara a -Y antes de girar, como los modelos de Poly Haven (usuario, 2026-11-21: ningún cuadro repetido)."""
    # "cma:<id>": Cleveland Museum of Art (tools/fetch_cma.py); un número: el Met (tools/fetch_met.py).
    src = os.path.join(ROOT, "art_source", "cma", met_id[4:] + ".jpg") if str(met_id).startswith("cma:") else os.path.join(MET, "%s.jpg" % met_id)
    crop = CROP.get(str(met_id), (0.0, 0.0, 1.0, 1.0))
    met_id = str(met_id).replace(":", "_")
    img = bpy.data.images.load(src, check_existing=True)
    h = height
    w = h * img.size[0] * (crop[2] - crop[0]) / (img.size[1] * (crop[3] - crop[1]))
    canvas = bpy.data.materials.get("Painting_%s" % met_id)
    if not canvas:
        canvas = bpy.data.materials.new("Painting_%s" % met_id)
        canvas.use_nodes = True
        nt = canvas.node_tree
        b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = img
        nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
        b.inputs["Roughness"].default_value = 0.55
    o = framed(canvas, w, h, style, "Painting_%s" % met_id, crop)
    if standing:  # en un mueble: inclinado hacia atrás, apoyado en su pata
        lo, hi = bounds([o])
        o.data.transform(Matrix.Rotation(math.radians(-12), 4, "X"))
        strut = give(box("FrameStrut", (0.02, 0.01, h * 0.8), (0, 0.06 + h * 0.08, -h * 0.08)), mat("FrameStrut", (0.05, 0.035, 0.025), 0.6))
        strut.rotation_euler = (math.radians(20), 0, 0)
        o = join([o, strut], "Painting_%s" % met_id)
        o.data.transform(Matrix.Translation((0, 0, -lo.z)))  # de pie: el origen en la base
    o.rotation_euler = (0, 0, math.radians(rot_z_deg))
    o.location = loc
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=False)
    return [o]


def decorate_1940s(wood, brass, shade):
    """Ronda 3 (usuario, 2026-11-19): un salón de Visage llevado a los años 40. Zócalo de madera, reloj de pie,
    crucifijo y apliques de tela sobre la tele, y paredes llenas de cuadros y platos."""
    # Zócalo de madera hasta 0,9 m con moldura arriba y montantes cada ~0,5 m, salvo en el hueco de la puerta.
    panel = tex_mat("Wainscot", "dark_wood_worn", "2k", tint=(0.75, 0.62, 0.5), root=GEN)
    zh, zt = 0.9, 0.012
    y0, y1 = -D / 2, D / 2
    a1, a2 = 1.6 - 0.45 - 0.07, 1.6 + 0.45 + 0.07  # puerta con su marco
    runs = [("x", -W / 2, W / 2, y0 + zt / 2, 1), ("x", -W / 2, W / 2, y1 - zt / 2, -1),
            ("y", y0, y1, W / 2 - zt / 2, -1), ("y", y0, a1, -W / 2 + zt / 2, 1), ("y", a2, y1, -W / 2 + zt / 2, 1)]
    parts = []
    for along, s0, s1, c, inward in runs:
        n = max(1, round((s1 - s0) / 0.5))
        for k in range(n + 1):
            s = s0 + (s1 - s0) * k / n
            stile = (0.05, 0.008, zh - 0.12) if along == "x" else (0.008, 0.05, zh - 0.12)
            off = c + inward * (zt / 2 + 0.004)
            loc = (s, off, 0.08 + (zh - 0.12) / 2) if along == "x" else (off, s, 0.08 + (zh - 0.12) / 2)
            parts.append(box("WainscotStile", stile, loc))
        mid, length = (s0 + s1) / 2, s1 - s0
        size = (length, zt, zh) if along == "x" else (zt, length, zh)
        parts.append(box("WainscotPanel", size, (mid, c, zh / 2) if along == "x" else (c, mid, zh / 2)))
        rail = (length, 0.035, 0.04) if along == "x" else (0.035, length, 0.04)
        rc = c + inward * 0.012
        parts.append(box("WainscotRail", rail, (mid, rc, zh) if along == "x" else (rc, mid, zh)))
    w = join(parts, "Wainscot")
    give(w, panel)
    uv_world(w, 1.2)

    # Pared de la tele: reloj de pie a la izquierda, crucifijo encima de la tele y dos apliques a los lados.
    import_model("vintage_grandfather_clock_01", "1k", (-0.95, y0 + 0.25, 0), rot_z_deg=180, drop=("glass",))
    cz, cy = 1.8, y0 + 0.012
    give(box("CrossV", (0.03, 0.02, 0.36), (0, cy + 0.01, cz)), wood, bevel=0.003)
    give(box("CrossH", (0.2, 0.02, 0.03), (0, cy + 0.01, cz + 0.07)), wood, bevel=0.003)
    give(box("CorpusBody", (0.022, 0.01, 0.12), (0, cy + 0.025, cz - 0.01)), brass)
    give(box("CorpusArms", (0.15, 0.008, 0.012), (0, cy + 0.025, cz + 0.065)), brass)
    # La luz de Godot (SconceL/SconceR) va dentro de cada pantalla, a 1,66 m.
    for x in (-0.4, 0.4):
        give(cylinder("SconcePlate", 0.045, 0.015, (x, y0 + 0.0075, 1.55), rot=(math.radians(90), 0, 0)), brass)
        give(cylinder("SconceArm", 0.008, 0.16, (x, y0 + 0.08, 1.55), rot=(math.radians(90), 0, 0), verts=10), brass)
        give(cylinder("SconcePost", 0.007, 0.07, (x, y0 + 0.16, 1.585), verts=10), brass)
        give(cone("SconceShade", 0.085, 0.05, 0.12, (x, y0 + 0.16, 1.66)), shade)

    # Pared del sofá: galería de cuadros a los lados del grande.
    to_wall(import_model("fancy_picture_frame_01", "1k", (-1.0, y1 - 0.2, 1.42), drop=("glass",)), "y", y1)
    # Platos de madera: dos en la pared del sofá, encima de la puerta y sobre el cuadro entre la librería y la ventana.
    # Un solo plato, sobre la puerta (usuario, 2026-11-21: nada repetido); en la pared del sofá, una Virgen.
    to_wall(painting(436262, (1.0, y1 - 0.2, 1.62), 0, 0.5, "gilt"), "y", y1)
    wall_plate((-W / 2 + 0.05, 1.6, 2.36), 90, "x", -W / 2)

    # Usuario, 2026-11-22: fuera el cuadro pequeño sobre el paisaje y el ovalado junto a la librería («quedan fatal»).
    # Lo que se ve desde el suelo alrededor de la tele (la cámara de juego solo encuadra esa franja de pared):
    # dos cuadros pequeños a los lados, justo encima del zócalo.
    # Repisa con un jarrón de latón y una brújula de bolsillo (antes, dos cuadros repetidos).
    give(box("TvShelf", (0.42, 0.16, 0.025), (0.62, y0 + 0.08, 0.9)), wood, bevel=0.003)
    for x in (0.47, 0.77):
        give(box("TvShelfBracket", (0.02, 0.12, 0.1), (x, y0 + 0.06, 0.84)), wood)
    import_model("brass_vase_03", "1k", (0.55, y0 + 0.08, 0.9125))
    import_model("seadogs_compass", "1k", (0.72, y0 + 0.09, 0.9125), rot_z_deg=200)
    # Mecedora vacía junto a la tele, girada hacia el salón.
    import_model("Rockingchair_01", "1k", (0.95, y0 + 0.55, 0), rot_z_deg=200)
    # Mesilla junto al sofá con una lamparita (su luz en Godot es TableLamp, muy tenue) y una foto.
    import_model("ClassicNightstand_01", "1k", (1.7, y1 - 0.25, 0))
    give(cylinder("TableLampBase", 0.06, 0.02, (1.78, y1 - 0.25, 0.71)), brass, bevel=0.003)
    give(cylinder("TableLampStem", 0.008, 0.3, (1.78, y1 - 0.25, 0.87), verts=10), brass)
    give(cone("TableLampShade", 0.12, 0.07, 0.16, (1.78, y1 - 0.25, 1.06)), shade)
    import_model("brass_vase_04", "1k", (1.58, y1 - 0.3, 0.7))
    # Libros apilados en el suelo, al lado de la librería.
    import random
    books_stack(1.75, -0.72, 0, 5, random.Random(11))


def export_final(path):
    # glTF separado: las dos versiones (normal y espejo) comparten las mismas texturas.
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLTF_SEPARATE", export_apply=True,
                              export_texture_dir="textures", export_image_format="AUTO")


def main():
    os.makedirs(OUT, exist_ok=True)
    if MODE == "final":
        os.makedirs(SRC, exist_ok=True)
        reset()
        build_final()
        open_flat_uvs()
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "living_room.blend"))
        export_final(os.path.join(OUT, "living_room", "living_room.gltf"))
        mirror_all(recalc_normals=False)
        export_final(os.path.join(OUT, "living_room", "living_room_mirror.gltf"))
        print("BUILD_OK final")
        return
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


if globals().get("RUN_MAIN", True):  # build_flat.py ejecuta este archivo con RUN_MAIN = False para usar sus funciones
    main()
