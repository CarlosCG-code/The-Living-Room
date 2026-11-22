"""Muebles, lámparas y cuadros del piso (specs/hito4a.md D14). Usuario, 2026-11-21: cada habitación reconocible y
con detalle, como el salón; ningún cuadro ni objeto repetido; una lámpara en cada habitación.

Lo ejecuta build_flat.py con sus funciones (exec en su espacio de nombres). Todo es CC0 de Poly Haven, pinturas
CC0 del Met o modelado aquí con formas simples (lo que no hay en ninguna librería CC0: bañera, inodoro, lavabo, fregadero…).
Coordenadas de plano (flat_layout.py): px a lo largo de la fachada, py hacia dentro. Blender: X = 2 - py, Y = px - 7.
"""
import math

from mathutils import Matrix, Vector

import_model, painting, cylinder, cone = _helpers["import_model"], _helpers["painting"], _helpers["cylinder"], _helpers["cone"]
floor_colliders, framed, rug_plane = _helpers["floor_colliders"], _helpers["framed"], _helpers["rug_plane"]

# Hacia dónde mira un mueble pegado a cada pared (los modelos de Poly Haven miran a -Y: +90° → +X, -90° → -X).
ROT = {"py0": -90.0, "py1": 90.0, "px0": 180.0, "px1": 0.0}


def interior(zid):
    return L.interior(L.zone(zid)[2], zid)


def spot(zid, wall, at, off):
    """Punto del plano junto a una pared: at a lo largo desde su inicio (negativo: desde el final), off de la pared."""
    lo_x, lo_y, hi_x, hi_y = interior(zid)
    if wall in ("py0", "py1"):
        return (lo_x + at if at >= 0 else hi_x + at), (lo_y + off if wall == "py0" else hi_y - off)
    return (lo_x + off if wall == "px0" else hi_x - off), (lo_y + at if at >= 0 else hi_y + at)


def bounds(objs):
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    return Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))), \
        Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))


def snap(objs, zid, wall, gap):
    """Lleva la trasera de los objetos a gap de la pared, moviéndolos solo por su normal."""
    lo_x, lo_y, hi_x, hi_y = interior(zid)
    lo, hi = bounds(objs)
    d, i = {"py0": ((2 - lo_y - gap) - hi.x, 0), "py1": ((2 - hi_y + gap) - lo.x, 0),
            "px0": ((lo_x - 7 + gap) - lo.y, 1), "px1": ((hi_x - 7 - gap) - hi.y, 1)}[wall]
    for o in objs:
        o.location[i] += d
    return objs


def put(asset, zid, wall, at, off=0.4, gap=0.02, rot=0.0, z=0.0, **kw):
    """Modelo de Poly Haven contra una pared (gap=None: no se pega, queda a off de ella)."""
    px, py = spot(zid, wall, at, off)
    objs = import_model(asset, "1k", (*to_b(px, py), z), rot_z_deg=ROT[wall] + rot, **kw)
    return snap(objs, zid, wall, gap) if gap is not None else objs


def free(asset, px, py, rot=0.0, z=0.0, **kw):
    return import_model(asset, "1k", (*to_b(px, py), z), rot_z_deg=rot, **kw)


def on(asset, base, dpx=0.0, dpy=0.0, rot=0.0, top=None, **kw):
    """Encima de otro mueble (de tapa plana): en el centro de su caja más (dpx, dpy) del plano. top: altura de la
    tapa si el mueble tiene algo más alto (el tiro de la cocina económica)."""
    lo, hi = bounds(base)
    x, y = (lo.x + hi.x) / 2 - dpy, (lo.y + hi.y) / 2 + dpx
    if top is None:  # la superficie real bajo ese punto: con lo más alto, un libro en un banco flotaba al alto del respaldo
        hit, loc = bpy.context.scene.ray_cast(bpy.context.evaluated_depsgraph_get(), Vector((x, y, hi.z + 0.01)), Vector((0, 0, -1)))[:2]
        top = loc.z if hit else hi.z
    return import_model(asset, "1k", (x, y, top), rot_z_deg=rot, **kw)


def seg_mid(zid, wall, near, n=1, i=0):
    """«at» del centro del tramo libre de pared (entre esquinas, puertas, vanos y ventanas) que contiene near; con n,
    el de la parte i de n iguales (usuario, 2026-11-22: cuadros sin centrar junto a las puertas)."""
    lo_x, lo_y, hi_x, hi_y = interior(zid)
    rect = L.zone(zid)[2]
    side = {"py0": 1, "py1": 3, "px0": 0, "px1": 2}[wall]
    key, (a, b) = {"py0": (("h", rect[1]), (lo_x, hi_x)), "py1": (("h", rect[3]), (lo_x, hi_x)),
                   "px0": (("v", rect[0]), (lo_y, hi_y)), "px1": (("v", rect[2]), (lo_y, hi_y))}[wall]
    # Un pasillo en tramos es una sola pared: se suman los tramos de la misma línea unidos sin muro.
    chain, todo = {zid}, [zid]
    while todo:
        z0 = todo.pop()
        for p, q in L.OPEN_SEAMS:
            other = q if p == z0 else p if q == z0 else None
            if other and other not in chain and abs(L.zone(other)[2][side] - rect[side]) < 1e-6:
                chain.add(other)
                todo.append(other)
    ends = [interior(c) for c in chain]
    k = 0 if wall in ("py0", "py1") else 1
    A, B = min(r[k] for r in ends), max(r[k + 2] for r in ends)
    spans = [(max(x, A), min(y, B)) for x, y in lines(skip_living=False).get(key, []) if min(y, B) > max(x, A)]
    for h0, h1, _, _ in openings(key):
        h0, h1 = h0 - 0.07, h1 + 0.07  # el marco de madera del hueco (build_flat.py, j) también tapa pared
        spans = [s for x, y in spans for s in ((x, min(y, h0)), (max(x, h1), y)) if s[1] - s[0] > 0.01]
    p = a + near if near >= 0 else b + near
    x, y = next(s for s in spans if s[0] - 1e-6 <= p <= s[1] + 1e-6)
    at = x + (y - x) * (i + 0.5) / n - a
    assert 0.0 <= at <= b - a, "%s %s: el sitio cae en otro tramo del pasillo (%.2f)" % (zid, wall, at)
    return at


def over(objs, zid, wall):
    """«at» del centro de un mueble a lo largo de su pared: para colgar encima un cuadro o un espejo."""
    lo, hi = bounds(objs)
    lo_x, lo_y, _, _ = interior(zid)
    return (lo.y + hi.y) / 2 + 7 - lo_x if wall in ("py0", "py1") else 2 - (lo.x + hi.x) / 2 - lo_y


def pic(met_id, zid, wall, at, z, h, style="gilt"):
    """Cuadro colgado: z es la altura de su centro."""
    px, py = spot(zid, wall, at, 0.1)
    return snap(painting(met_id, (*to_b(px, py), z), ROT[wall], h, style), zid, wall, 0.003)


def rug(tex, zid, w, l, dpx=0.0, dpy=0.0, rot=0.0):
    """Alfombra en el centro de la habitación más (dpx, dpy); w a lo ancho del plano (py), l a lo largo (px)."""
    lo_x, lo_y, hi_x, hi_y = interior(zid)
    return rug_plane(tex, to_b((lo_x + hi_x) / 2 + dpx, (lo_y + hi_y) / 2 + dpy), w, l, rot, "Rug_" + zid)


def photo(cma_id, base, dpx=0.0, dpy=0.0, rot=0.0, h=0.2, style="walnut"):
    """Foto de familia de pie sobre un mueble (Cleveland, CC0), apoyada en su pata."""
    lo, hi = bounds(base)
    return painting("cma:%s" % cma_id, ((lo.x + hi.x) / 2 - dpy, (lo.y + hi.y) / 2 + dpx, hi.z), rot, h, style, standing=True)


def made(parts, name, zid, wall, at, off=0.4, gap=0.02, rot=0.0, z=0.0, uv=0.6):
    """Un modelo hecho aquí (en el origen, de cara a -Y, con la base en z = 0) colocado contra una pared. uv: metros
    que cubre cada textura (None: deja las UV, p. ej. un marco de Poly Haven)."""
    o = join(parts, name)
    if uv:
        uv_world(o, uv)
    # La unión conserva la transformación de la primera pieza (posición y escala): se pasa a la malla.
    o.data.transform(o.matrix_world)
    o.matrix_world = Matrix.Identity(4)
    o.rotation_euler = (0, 0, math.radians(ROT[wall] + rot if wall else rot))
    if wall:
        px, py = spot(zid, wall, at, off)
    else:
        px, py = at
    o.location = (*to_b(px, py), z)
    return snap([o], zid, wall, gap) if wall and gap is not None else [o]


# --- Materiales ---------------------------------------------------------------------------------------------------

def materials():
    """Todo lo modelado aquí lleva texturas fotográficas gastadas de Poly Haven (usuario, 2026-11-22: lo de colores
    lisos «se nota» y parece nuevo): loza y esmalte viejos (make_wallpapers.py), hierro negro con desconchones,
    pintura verde oxidada, terrazo y maderas viejas."""
    return {
        "enamel": tex_mat("PorcelainOld", "porcelain_old", "2k", root=GEN),
        "porcelain": tex_mat("PorcelainOld", "porcelain_old", "2k", root=GEN),
        "iron": tex_mat("IronWorn", "rusty_metal_04", "1k"),
        "tub_paint": tex_mat("GreenPaintRust", "green_metal_rust", "1k"),
        "bench": tex_mat("OldPlanks", "old_planks_02", "1k"),
        "shelf": tex_mat("WornWood", "wood_table_worn", "1k"),
        "walnut": tex_mat("WornWalnut", "wood_table_worn", "1k", tint=(0.55, 0.42, 0.34)),
        "tile": tex_mat("WallTiles", "wall_tiles", "2k", root=GEN),
        "brass": bpy.data.materials.get("Brass") or mat("Brass", (0.6, 0.45, 0.22), 0.3, metallic=1.0),
        "enamel_blue": mat("EnamelBlue", (0.02, 0.05, 0.16), 0.15),
        "wool": tex_mat("CoatWool", "poly_wool_herringbone", "1k", tint=(0.2, 0.18, 0.17)),
        "linen": tex_mat("UsedLinen", "cloth_linen", "2k", root=GEN),  # la lisa parecía nueva (usuario, 2026-11-22)
        "soap": mat("Soap", (0.62, 0.58, 0.48), 0.6),
        "slate": mat("Slate", (0.03, 0.035, 0.035), 0.85),
        "mirror": mat("Mirror", (0.5, 0.5, 0.47), 0.25, metallic=0.6),  # sin sonda de reflejo (paso 6) salía negro
        "shade": glowing(tex_mat("LampShadeFabric", "quatrefoil_jacquard_fabric", "1k", tint=(0.5, 0.32, 0.18)), 0.3),
        "fringe": mat("LampFringe", (0.42, 0.28, 0.14), 0.9),
        "bulb": glowing(mat("LampBulb", (1.0, 0.85, 0.65), 0.3), 4.0),
    }


def glowing(m, strength):
    """Tela o cristal que se ve encendido (la luz va dentro); por las dos caras."""
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Emission Color"].default_value = (1.0, 0.6, 0.3, 1.0)
    b.inputs["Emission Strength"].default_value = strength
    m.use_backface_culling = False
    return m


def lamp_light(zid, objs, at=None):
    """Dónde va la luz de la zona cuando sale de una lámpara de la habitación: un vacío LampAt_<zona> (flat.gd pone
    ahí su OmniLight3D). La lámpara pasa a llamarse Fixture_*, sin sombra, para que no tape su propia luz."""
    lo, hi = bounds(objs)
    bpy.ops.object.empty_add(location=at or ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z + (hi.z - lo.z) * 0.6))
    bpy.context.active_object.name = "LampAt_%s" % zid
    for k, o in enumerate(objs):
        o.name = "Fixture_%s_lamp%d" % (zid, k)
    return objs


def light_up(objs, keys, strength):
    """Enciende las partes de una lámpara de librería cuyos materiales contengan alguna de esas palabras."""
    for o in objs:
        for i, m in enumerate(o.data.materials):
            if m and any(k in m.name.lower() for k in keys):
                on_m = m.copy()
                on_m.name = m.name + "_Lit"
                b = next(n for n in on_m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
                b.inputs["Emission Color"].default_value = (1.0, 0.7, 0.4, 1.0)
                b.inputs["Emission Strength"].default_value = strength
                o.data.materials[i] = on_m


# --- Modelos hechos aquí (de cara a -Y, la trasera en +Y, base en z = 0) ------------------------------------------

def cast(o):
    """Aplica modificadores (biselado, booleana) dejando una malla normal."""
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.convert(target="MESH")
    return o


def hollow(outer, inner):
    mod = outer.modifiers.new("Cut", "BOOLEAN")
    mod.object = inner
    mod.operation = "DIFFERENCE"
    cast(outer)
    bpy.data.objects.remove(inner, do_unlink=True)
    return outer


def lathe(name, prof, loc=(0, 0, 0), sx=1.0, sy=1.0, e=2.0, verts=40):
    """Pieza torneada: el perfil (r, z) gira alrededor del eje Z. e > 2 cuadra la planta (superelipse), como la de
    una bañera o un lavabo; sx, sy estiran r a lo largo y a lo ancho."""
    pts, faces, n = [], [], len(prof)
    for i in range(verts):
        a = 2 * math.pi * i / verts
        c, s = math.cos(a), math.sin(a)
        c, s = math.copysign(abs(c) ** (2 / e), c), math.copysign(abs(s) ** (2 / e), s)
        pts += [(loc[0] + r * c * sx, loc[1] + r * s * sy, loc[2] + z) for r, z in prof]
    for i in range(verts):
        j = (i + 1) % verts
        faces += [(i * n + k, j * n + k, j * n + k + 1, i * n + k + 1) for k in range(n - 1)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(pts, [], faces)
    me.validate()
    for p in me.polygons:
        p.use_smooth = True
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return o


def tap(M, x, y, z, spout=0.09):
    """Grifo de latón de cruceta, de los de antes: cuerpo torneado, cruz arriba y caño hacia delante."""
    parts = [give(lathe("TapBody", [(0, 0), (0.018, 0), (0.016, 0.03), (0.012, 0.06), (0.016, 0.075), (0, 0.08)], (x, y, z), verts=16), M["brass"]),
             give(cylinder("TapSpout", 0.008, spout, (x, y - spout / 2, z + 0.035), rot=(math.radians(100), 0, 0), verts=10), M["brass"])]
    for a in (0, 90):
        bar = give(box("TapCross", (0.07, 0.008, 0.008), (x, y, z + 0.09)), M["brass"])
        bar.rotation_euler.z = math.radians(a + 45)
        parts.append(bar)
    return parts


def bathtub(M):
    """Bañera de hierro fundido con patas de garra (años 20-40): fuera pintada de verde oscuro, dentro esmalte, el
    borde enrollado y dos grifos de cruceta en el extremo."""
    sx, sy, e = 0.78, 0.36, 3.0
    out = [(0, 0.2), (0.86, 0.2), (0.95, 0.27), (0.99, 0.45), (1.01, 0.62), (1.045, 0.64), (1.05, 0.665)]
    inside = [(1.05, 0.665), (1.03, 0.685), (0.99, 0.69), (0.95, 0.67), (0.92, 0.5), (0.85, 0.32), (0.75, 0.25), (0, 0.24)]
    parts = [give(lathe("TubShell", out, sx=sx, sy=sy, e=e, verts=48), M["tub_paint"]),
             give(lathe("TubEnamel", inside, sx=sx, sy=sy, e=e, verts=48), M["enamel"])]
    claw = [(0, 0), (0.05, 0), (0.055, 0.025), (0.035, 0.06), (0.026, 0.11), (0.04, 0.18), (0.05, 0.22), (0, 0.22)]
    for x in (-0.6, 0.6):
        for y in (-0.21, 0.21):
            parts.append(give(lathe("TubClaw", claw, (x, y, 0), verts=14), M["iron"]))
    for y in (-0.09, 0.09):
        parts += tap(M, 0.74, y + 0.02, 0.69, spout=0.0)
    parts.append(give(cylinder("TubSpout", 0.012, 0.16, (0.7, 0.02, 0.76), rot=(0, math.radians(-70), 0), verts=12), M["brass"]))
    return parts


def toilet(M, wooden_tank=False):
    """Inodoro de los años 30: taza de loza torneada con asiento y tapa de madera, cisterna alta sobre ménsulas
    (de hierro pintado, o de madera en el aseo de servicio), bajante de latón y cadena con tirador de loza."""
    bowl = [(0.7, 0), (0.68, 0.03), (0.52, 0.09), (0.5, 0.2), (0.72, 0.3), (0.94, 0.37), (1.0, 0.4), (0.97, 0.415),
            (0.88, 0.41), (0.7, 0.33), (0.45, 0.25), (0, 0.22)]
    parts = [give(lathe("WcBowl", bowl, (0, -0.1, 0), sx=0.19, sy=0.25, verts=36), M["porcelain"])]
    bpy.ops.mesh.primitive_torus_add(major_radius=0.165, minor_radius=0.022, location=(0, -0.1, 0.43))
    seat = bpy.context.active_object
    seat.scale = (1, 1.3, 0.6)
    parts.append(give(seat, M["walnut"]))
    lid = give(box("WcLid", (0.36, 0.022, 0.44), (0, 0.17, 0.66)), M["walnut"], bevel=0.008)
    lid.rotation_euler.x = math.radians(-8)
    parts.append(lid)
    tz, tank = 1.95, M["walnut"] if wooden_tank else M["tub_paint"]
    parts += [give(box("WcTank", (0.46, 0.2, 0.24), (0, 0.13, tz)), tank, bevel=0.01),
              give(box("WcTankLid", (0.5, 0.23, 0.03), (0, 0.13, tz + 0.135)), tank, bevel=0.008)]
    for x in (-0.17, 0.17):
        parts.append(give(box("WcBracket", (0.025, 0.2, 0.025), (x, 0.13, tz - 0.135)), M["iron"]))
        brace = give(box("WcBrace", (0.02, 0.025, 0.24), (x, 0.17, tz - 0.22)), M["iron"])
        brace.rotation_euler.x = math.radians(35)
        parts.append(brace)
    parts.append(give(cylinder("WcPipe", 0.018, tz - 0.48, (0, 0.2, (tz - 0.12 + 0.36) / 2), verts=12), M["brass"]))
    parts.append(give(cylinder("WcChain", 0.003, 0.6, (0.2, 0.07, tz - 0.42), verts=6), M["brass"]))
    parts.append(give(lathe("WcPull", [(0, 0), (0.014, 0.01), (0.018, 0.05), (0.008, 0.08), (0, 0.085)], (0.2, 0.07, tz - 0.8), verts=14), M["porcelain"]))
    return parts


def basin(M):
    """Lavabo de pie de loza: pie torneado, pila con reborde, peto trasero y dos grifos de cruceta."""
    foot = [(0, 0), (0.15, 0), (0.15, 0.02), (0.1, 0.06), (0.065, 0.2), (0.06, 0.45), (0.08, 0.6), (0.12, 0.66), (0, 0.66)]
    bowl = [(0.2, 0.6), (0.55, 0.68), (0.9, 0.79), (1.0, 0.85), (0.98, 0.87), (0.9, 0.865), (0.7, 0.8), (0.35, 0.75), (0, 0.74)]
    parts = [give(lathe("BasinFoot", foot, (0, 0.02, 0), verts=28), M["porcelain"]),
             give(lathe("BasinBowl", bowl, (0, -0.02, 0), sx=0.3, sy=0.23, e=2.6, verts=40), M["porcelain"]),
             give(box("BasinSplash", (0.6, 0.04, 0.16), (0, 0.19, 0.93)), M["porcelain"], bevel=0.015)]
    for x in (-0.12, 0.12):
        parts += tap(M, x, 0.15, 0.86)
    return parts


def washstand(M):
    """Palangana de esmalte en su trípode de hierro, con la jarra abajo y una toalla en la barra (aseo de servicio)."""
    parts = []
    for a in (90, 210, 330):
        x, y = 0.19 * math.cos(math.radians(a)), 0.19 * math.sin(math.radians(a))
        parts.append(give(cylinder("StandLeg", 0.009, 0.82, (x, y, 0.41), verts=8), M["iron"]))
    for z, r in ((0.8, 0.19), (0.3, 0.17)):
        bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=0.008, location=(0, 0, z))
        parts.append(give(bpy.context.active_object, M["iron"]))
    bowl = [(0, 0.76), (0.09, 0.76), (0.17, 0.8), (0.22, 0.86), (0.225, 0.865), (0.215, 0.865), (0.16, 0.81), (0.08, 0.775), (0, 0.775)]
    parts.append(give(lathe("WashBowl", bowl, verts=32), M["enamel"]))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.222, minor_radius=0.005, location=(0, 0, 0.865))
    parts.append(give(bpy.context.active_object, M["enamel_blue"]))
    jug = [(0, 0.3), (0.07, 0.3), (0.085, 0.36), (0.075, 0.44), (0.05, 0.5), (0.06, 0.55), (0.055, 0.555), (0.045, 0.505), (0, 0.5)]
    parts.append(give(lathe("WashJug", jug, (0.02, -0.02, 0.01), verts=24), M["enamel"]))
    parts.append(give(cylinder("StandBar", 0.007, 0.36, (0, 0.17, 0.62), rot=(0, math.radians(90), 0), verts=8), M["iron"]))
    parts.append(give(box("StandTowel", (0.3, 0.012, 0.3), (0, 0.18, 0.48)), M["linen"]))
    return parts


def towel_rail(M, w=0.6, z=1.1):
    """Toallero de pared: barra de madera entre dos soportes de latón, con una toalla de hilo doblada encima."""
    parts = [give(cylinder("TowelRod", 0.012, w, (0, -0.07, z), rot=(0, math.radians(90), 0), verts=12), M["walnut"])]
    for x in (-w / 2, w / 2):
        parts.append(give(box("TowelPost", (0.02, 0.07, 0.02), (x, -0.035, z)), M["brass"]))
    parts += [give(box("TowelFront", (w * 0.6, 0.008, 0.42), (0, -0.085, z - 0.2)), M["linen"]),
              give(box("TowelBack", (w * 0.6, 0.008, 0.3), (0, -0.055, z - 0.14)), M["linen"])]
    return parts


def wall_slate(M):
    """Pizarra de colegio colgada, con marco de pino y repisa con una tiza (dormitorio del niño)."""
    w, h, z = 0.7, 0.5, 1.25
    parts = [give(box("Slate", (w, 0.012, h), (0, -0.008, z)), M["slate"])]
    f = 0.035
    for name, size, at in (("SlateTop", (w + 2 * f, 0.025, f), (0, -0.012, z + h / 2 + f / 2)), ("SlateBottom", (w + 2 * f, 0.025, f), (0, -0.012, z - h / 2 - f / 2)),
                           ("SlateL", (f, 0.025, h), (-w / 2 - f / 2, -0.012, z)), ("SlateR", (f, 0.025, h), (w / 2 + f / 2, -0.012, z))):
        parts.append(give(box(name, size, at), M["shelf"], bevel=0.004))
    parts.append(give(box("SlateLedge", (w, 0.05, 0.012), (0, -0.04, z - h / 2 - f)), M["shelf"]))
    parts.append(give(cylinder("Chalk", 0.005, 0.06, (0.15, -0.04, z - h / 2 - f + 0.011), rot=(0, math.radians(90), 0), verts=8), M["soap"]))
    return parts


def kitchen_sink(M):
    """Fregadero de loza vieja sobre obra alicatada, con grifo de pared (no hay ninguno CC0 de librería)."""
    parts = [give(box("SinkBase", (1.0, 0.55, 0.8), (0, 0, 0.4)), M["tile"])]
    outer = cast(give(box("Sink", (1.0, 0.58, 0.2), (0, -0.01, 0.9)), M["porcelain"], bevel=0.02))
    inner = cast(give(box("SinkIn", (0.7, 0.42, 0.2), (-0.1, -0.02, 0.98)), M["porcelain"], bevel=0.02))
    parts.append(hollow(outer, inner))
    parts.append(give(cylinder("SinkTap", 0.014, 0.2, (-0.1, 0.18, 1.12), rot=(math.radians(-70), 0, 0), verts=10), M["brass"]))
    return parts


def workbench(M):
    parts = [give(box("BenchTop", (1.8, 0.7, 0.07), (0, 0, 0.865)), M["bench"], bevel=0.006),
             give(box("BenchShelf", (1.65, 0.6, 0.03), (0, 0, 0.2)), M["bench"])]
    for x in (-0.82, 0.82):
        for y in (-0.28, 0.28):
            parts.append(give(box("BenchLeg", (0.08, 0.08, 0.83), (x, y, 0.415)), M["bench"], bevel=0.004))
    parts.append(give(box("BenchBackboard", (1.8, 0.02, 0.6), (0, 0.34, 1.2)), M["bench"]))
    return parts


def larder_shelves(M, length):
    parts = []
    for z in (0.05, 0.5, 0.95, 1.4, 1.85):
        parts.append(give(box("LarderShelf", (length, 0.35, 0.025), (0, 0, z)), M["shelf"], bevel=0.003))
    for x in (-length / 2 + 0.012, 0, length / 2 - 0.012):
        parts.append(give(box("LarderSide", (0.025, 0.35, 1.9), (x, 0, 0.95)), M["shelf"]))
    return parts


def floor_lamp(M):
    """Lámpara de pie de los años 40: pie torneado de madera y pantalla de tela con flecos (usuario, 2026-11-22: las de
    sus fotos de referencia). La luz va en el centro de la pantalla, a 1,47 m."""
    parts = [give(lathe("FloorLampBase", [(0.0, 0.0), (0.16, 0.0), (0.16, 0.02), (0.11, 0.05), (0.03, 0.075), (0.0, 0.075)], verts=32), M["walnut"]),
             give(lathe("FloorLampStem", [(0.0, 0.075), (0.022, 0.075), (0.03, 0.12), (0.017, 0.2), (0.017, 0.98), (0.028, 1.03),
                                          (0.015, 1.08), (0.015, 1.38), (0.0, 1.38)], verts=16), M["walnut"]),
             give(lathe("FloorLampShade", [(0.26, 1.34), (0.2, 1.47), (0.15, 1.6)], verts=48), M["shade"])]
    for i in range(96):  # flecos colgando del borde
        a = 2 * math.pi * i / 96
        parts.append(give(box("FloorLampFringe", (0.006, 0.003, 0.075), (0.262 * math.cos(a), 0.262 * math.sin(a), 1.3)), M["fringe"]))
    return parts


def wall_cupboard(M, w=0.8, h=0.75, d=0.26, z0=1.45):
    """Alacena colgada abierta, con una balda en medio y cornisa (usuario, 2026-11-22: «algún armario que cuelgue de
    la pared con cosas dentro»). Baldas a z0 + 0,02 y z0 + h / 2 + 0,01."""
    wood = M["walnut"]
    parts = [give(box("CupboardBack", (w, 0.012, h), (0, -0.006, z0 + h / 2)), wood)]
    for x in (-w / 2 + 0.01, w / 2 - 0.01):
        parts.append(give(box("CupboardSide", (0.02, d, h), (x, -d / 2, z0 + h / 2)), wood, bevel=0.003))
    for z in (z0 + 0.01, z0 + h / 2, z0 + h - 0.01):
        parts.append(give(box("CupboardShelf", (w, d, 0.02), (0, -d / 2, z)), wood, bevel=0.003))
    parts.append(give(box("CupboardCornice", (w + 0.06, d + 0.04, 0.035), (0, -d / 2 - 0.02, z0 + h + 0.0175)), wood, bevel=0.006))
    return parts


def hanging_coat(M, length=1.0):
    """Abrigo de lana colgado por el cuello (usuario, 2026-11-22; no hay ninguno CC0): sección elíptica que baja del
    colgador a los hombros caídos y al bajo algo abierto, con pliegues. Cuelga hacia -Z desde el origen; la espalda
    en x = 0 y el cuerpo hacia +X; el ancho en Y."""
    import bmesh
    rings = ((0.0, 0.05, 0.03), (0.04, 0.13, 0.05), (0.09, 0.2, 0.07), (0.16, 0.21, 0.08), (0.45, 0.2, 0.085),
             (0.75, 0.225, 0.08), (1.0, 0.26, 0.075))
    seg = 32
    bm = bmesh.new()
    loops = []
    for t, a, b in rings:
        ring = []
        for i in range(seg):
            th = 2 * math.pi * i / seg
            fold = 1 + (0.03 + 0.1 * t) * math.sin(7 * th + t * 4) * min(1.0, t * 8)  # pliegues que se abren hacia el bajo
            ring.append(bm.verts.new((b * (1 + math.cos(th)) * fold, a * math.sin(th) * fold, -t * length)))
        loops.append(ring)
    for r0, r1 in zip(loops, loops[1:]):
        for i in range(seg):
            bm.faces.new((r0[i], r0[(i + 1) % seg], r1[(i + 1) % seg], r1[i]))
    bm.faces.new(loops[0][::-1])
    bm.faces.new(loops[-1])
    me = bpy.data.meshes.new("Coat")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("Coat", me)
    bpy.context.collection.objects.link(o)
    for poly in me.polygons:
        poly.use_smooth = True
    parts = [give(o, M["wool"])]
    for side in (-1, 1):  # mangas que cuelgan de los hombros, algo por delante
        sleeve = cylinder("CoatSleeve", 0.05, 0.55 * length, (0.1, side * 0.19, -(0.12 + 0.275) * length), verts=16)
        sleeve.rotation_euler = (math.radians(side * 4), math.radians(-6), 0)
        parts.append(give(sleeve, M["wool"]))
    return parts


def coat_rack(M):
    parts = [give(cylinder("RackPole", 0.022, 1.8, (0, 0, 0.9), verts=12), M["walnut"])]
    for a in (0, 120, 240):
        foot = give(box("RackFoot", (0.36, 0.04, 0.03), (0.16, 0, 0.015)), M["walnut"])
        foot.rotation_euler = (0, 0, math.radians(a))
        parts.append(foot)
    for a in range(0, 360, 90):
        hook = give(cylinder("RackHook", 0.008, 0.14, (0.05, 0, 1.68), rot=(0, math.radians(55), 0), verts=8), M["brass"])
        hook.rotation_euler.z = math.radians(a)
        parts.append(hook)
    return parts


def wardrobe(M):
    """Armario ropero de dos puertas con plafones, cornisa y pomos, de nogal como las puertas."""
    w, d, h = 1.1, 0.55, 1.95
    parts = [give(box("WardrobeBody", (w, d, h), (0, 0, 0.08 + h / 2)), M["walnut"], bevel=0.004),
             give(box("WardrobeCornice", (w + 0.08, d + 0.05, 0.08), (0, -0.01, 0.08 + h + 0.04)), M["walnut"], bevel=0.01),
             give(box("WardrobePlinth", (w + 0.03, d + 0.02, 0.08), (0, 0, 0.04)), M["walnut"], bevel=0.004)]
    for x in (-w / 4, w / 4):
        for z0, z1 in ((0.2, 1.1), (1.2, 1.9)):
            parts.append(give(box("WardrobePanel", (w / 2 - 0.16, 0.012, z1 - z0), (x, -d / 2 - 0.004, (z0 + z1) / 2)), M["walnut"], bevel=0.008))
        parts.append(give(cylinder("WardrobeKnob", 0.012, 0.03, (x + (0.2 if x < 0 else -0.2), -d / 2 - 0.02, 1.15), rot=(math.radians(90), 0, 0), verts=12), M["brass"]))
    parts.append(give(box("WardrobeGap", (0.006, 0.004, h - 0.1), (0, -d / 2 - 0.001, 0.08 + h / 2)), M["iron"]))
    return parts


def wall_shelf(M, w=0.6, z=1.3):
    parts = [give(box("Shelf", (w, 0.18, 0.025), (0, -0.09, z)), M["walnut"], bevel=0.003)]
    for x in (-w / 2 + 0.06, w / 2 - 0.06):
        parts.append(give(box("ShelfBracket", (0.02, 0.15, 0.12), (x, -0.075, z - 0.07)), M["walnut"]))
    return parts


def crucifix(M, h, z):
    """Crucifijo de madera clara con Cristo de latón (el del salón es oscuro y más pequeño)."""
    return [give(box("CrossV", (0.035, 0.025, h), (0, -0.0125, z)), M["shelf"], bevel=0.003),
            give(box("CrossH", (h * 0.55, 0.025, 0.035), (0, -0.0125, z + h * 0.22)), M["shelf"], bevel=0.003),
            give(box("CorpusBody", (0.026, 0.012, h * 0.35), (0, -0.03, z + h * 0.02)), M["brass"]),
            give(box("CorpusArms", (h * 0.42, 0.01, 0.014), (0, -0.03, z + h * 0.2)), M["brass"])]


def peg_rail(M, w=0.9, z=1.65):
    """Colgador de pared con cuatro perchas."""
    parts = [give(box("PegRail", (w, 0.025, 0.09), (0, -0.0125, z)), M["walnut"], bevel=0.003)]
    for k in range(4):
        parts.append(give(cylinder("Peg", 0.012, 0.09, (-w / 2 + 0.15 + k * (w - 0.3) / 3, -0.06, z), rot=(math.radians(70), 0, 0), verts=10), M["brass"]))
    return parts


# --- Lámparas -----------------------------------------------------------------------------------------------------

LIT = set(L.LIT_ZONES)
LAMP_ZONES = {"bedroom_main", "entrance_hall", "bedroom_3"}  # su luz sale de una lámpara de la habitación
CLEAR = 1.85  # ninguna lámpara de techo baja de aquí: el jugador mide 1,75 m


def ceiling(objs):
    """Cuelga del techo: la parte de arriba toca el techo."""
    lo, hi = bounds(objs)
    for o in objs:
        o.location.z += H - hi.z
    return objs


def fixture(zid, asset="pull_chain_light_socket", scale=1.0, drop=()):
    """La lámpara de la habitación, de Poly Haven, en el centro (donde está su luz en Godot: flat_layout.write_tres).
    Usuario, 2026-11-22: las hechas aquí no pegaban; arañas y faroles en las habitaciones buenas y, en las de servicio,
    portalámparas de porcelana con su cadenilla y la bombilla de pera colgando. Se llama Fixture_*: Godot le quita la
    sombra para que la luz de dentro no quede tapada."""
    lo_x, lo_y, hi_x, hi_y = interior(zid)
    cx, cy = (lo_x + hi_x) / 2, (lo_y + hi_y) / 2
    objs = free(asset, cx, cy, scale=scale, drop=drop)
    lo, hi = bounds(objs)
    if H - (hi.z - lo.z) < CLEAR:  # la del taller colgaba hasta 1,24 m: la cabeza la atravesaba
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)
        objs = free(asset, cx, cy, scale=scale * (H - CLEAR) / (hi.z - lo.z), drop=drop)
    objs = ceiling(objs)
    if asset == "pull_chain_light_socket":  # bombilla colgando del portalámparas, con la rosca arriba
        bulb = free("lightbulb_01", cx, cy)
        for o in bulb:
            o.data.transform(Matrix.Rotation(math.pi, 4, "X"))
            o.location.z = H - 0.048
        objs += bulb
    if zid in LIT - LAMP_ZONES:  # cristales y bombillas encendidos
        for o in objs:
            for i, m in enumerate(o.data.materials):
                if m and any(k in m.name.lower() for k in ("shade", "bulb", "glass", "lamps_")):
                    on_m = m.copy()
                    on_m.name = m.name + "_On"
                    b = next(n for n in on_m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
                    b.inputs["Emission Color"].default_value = (1.0, 0.82, 0.6, 1.0)
                    b.inputs["Emission Strength"].default_value = 0.4
                    o.data.materials[i] = on_m
    for k, o in enumerate(objs):
        o.name = "Fixture_%s_%d" % (zid, k)
    return objs


def window_curtain(zid):
    """Visillo de encaje con su barra en lo alto de la ventana (BlenderKit, CC0)."""
    side, wall_py, pos = WINDOWS[zid]
    lo_x = interior(zid)[0]
    return put("lace_curtain", zid, "py0" if wall_py == L.Y0 else "py1", pos - lo_x, gap=0.06, z=WIN_TOP + 0.05 - 0.877)


def mirror(M, zid, wall, at, z, w, h, style):
    """Espejo en un marco de Poly Haven (usuario, 2026-11-22: los hechos aquí no parecían antiguos)."""
    return made([framed(M["mirror"], w, h, style, "Mirror_%s" % zid)], "Mirror_%s" % zid, zid, wall, at, gap=0.0, z=z, uv=None)


def shelf_items(shelves, items):
    """Cosas en las baldas de larder_shelves: (modelo, altura de la balda, desplazamiento a lo largo, giro, tumbado).
    A lo largo es X de Blender: antes se movían por Y, hacia fuera de la balda, y quedaban en el aire."""
    lo, hi = bounds(shelves)
    cx, cy = (lo.x + hi.x) / 2, (lo.y + hi.y) / 2
    for asset, level, along, rot, lay in items:
        pivot = Vector((cx + along, cy, level + 0.0125))
        objs = import_model(asset, "1k", tuple(pivot), rot_z_deg=rot, lay=lay)
        a, b = bounds(objs)
        s = min(1.0, 0.4 / (b.z - a.z), 0.32 / (b.y - a.y))  # usuario, 2026-11-22: cosas metidas dentro de la estantería
        for o in objs:
            o.location = pivot + (o.location - pivot) * s
            o.scale *= s
        a, b = bounds(objs)
        for d in (lo.x + 0.025, cx, hi.x - 0.025):  # montantes
            if a.x < d + 0.015 and b.x > d - 0.015:
                shift = d + 0.015 - a.x if (a.x + b.x) / 2 > d else d - 0.015 - b.x
                for o in objs:
                    o.location.x += shift


# --- Habitaciones -------------------------------------------------------------------------------------------------

def chairs_around(table, asset, per_side=2, gap=0.3, scale=1.0):
    """Sillas a los dos lados largos de la mesa, mirándola."""
    lo, hi = bounds(table)
    c = (lo + hi) / 2
    along = 0 if hi.x - lo.x > hi.y - lo.y else 1
    half_len, half_w = (hi[along] - lo[along]) / 2, (hi[1 - along] - lo[1 - along]) / 2
    for side in (-1, 1):
        for k in range(per_side):
            p = Vector(c)
            p[along] += (k - (per_side - 1) / 2) * half_len * 1.0
            p[1 - along] += side * (half_w + gap)
            d = c - p
            rot = math.degrees(math.atan2(d.x, -d.y))
            import_model(asset, "1k", (p.x, p.y, 0), rot_z_deg=rot, scale=scale)


def furnish():
    """Cada cosa en la habitación que le toca (usuario, 2026-11-21: «en el taller no habrá una cómoda»). Ningún
    modelo se repite salvo las sillas de un mismo juego y las lámparas de un mismo tipo de habitación. Usuario,
    2026-11-22: todo viejo y gastado, de librería antes que hecho aquí, y nada flotando."""
    M = materials()

    # Dormitorio principal: cama gótica con baúl a los pies, mesilla con quinqué y despertador, butaca, armario,
    # cómoda con espejo de marco dorado, y una Virgen sobre la cama.
    z = "bedroom_main"
    bed = put("GothicBed_01", z, "px0", 2.0)
    free("treasure_chest", 2.5, 2.0, rot=180)
    stand = put("painted_wooden_nightstand", z, "px0", 0.55)
    oil = on("vintage_oil_lamp", stand, dpy=-0.06, scale=0.55)
    light_up(oil, ("flame",), 6.0)  # el quinqué encendido es la luz del cuarto: sombras largas de la cama
    light_up(oil, ("glass",), 0.4)
    lamp_light(z, oil)
    on("alarm_clock_01", stand, dpy=0.13, rot=-60, scale=0.6)
    put("GreenChair_01", z, "px0", 3.45, gap=0.1, rot=-20)
    put("GothicCabinet_01", z, "px1", 2.0)
    commode = put("GothicCommode_01", z, "py0", -1.0)
    on("ceramic_vase_02", commode, dpx=0.35)
    on("vintage_pocket_watch", commode, dpx=-0.3, rot=15)
    pic(437336, z, "px0", over(bed, z, "px0"), 1.85, 0.5, "ornate")
    pic("cma:125247", z, "py1", seg_mid(z, "py1", 1.5), 1.6, 0.45, "ebony")
    # Vida (usuario, 2026-11-22, sus fotos de referencia): alfombra a los pies de la cama, foto de ella en la cómoda,
    # visillo en la ventana.
    rug("rug_persian_blue", z, 2.2, 1.6, dpx=-0.3)
    photo(448866, commode, dpx=-0.05, rot=ROT["py0"], h=0.22, style="ornate")
    window_curtain(z)
    fixture(z, "Chandelier_01")
    side = put("gallinera_table", z, "py1", seg_mid(z, "py1", 1.5), gap=0.03)  # mesita bajo el cuadro de la Virgen
    on("brass_vase_02", side, dpx=-0.2)
    on("old_book_st_ives", side, dpx=0.15, rot=25, lay=True)

    # Comedor: mesa con mantel y cuatro sillas, aparador con la foto del abuelo, jarrón de latón en su pie alto, reloj
    # de pared pintado y araña de cristal.
    z = "dining_room"
    lo_x, lo_y, hi_x, hi_y = interior(z)
    table = free("dining_table", (lo_x + hi_x) / 2, 1.55, rot=90)  # hacia la ventana: libre el giro de la puerta
    chairs_around(table, "WoodenChair_01", gap=0.28, scale=0.62)  # el modelo mide 2,27 m de alto
    on("wooden_bowl_01", table)
    on("food_apple_01", table, dpx=0.05, dpy=0.02)
    rug("rug_persian_green", z, 2.6, 3.0, dpy=1.55 - 2.0)
    window_curtain(z)
    console = put("ClassicConsole_01", z, "px1", 2.0)
    on("brass_goblets", console, dpy=-0.5, scale=0.7)
    on("wooden_candlestick", console, dpy=0.5)
    photo(285671, console, rot=ROT["px1"], h=0.24)  # el abuelo con su perro, en el centro del aparador (usuario, 2026-11-22)
    pic("cma:151555", z, "px0", seg_mid(z, "px0", 2.0), 1.6, 0.55)  # bodegón con pescado y pan
    pic("cma:150140", z, "py1", seg_mid(z, "py1", -1.2, 2, 0), 1.6, 0.4, "walnut")  # bodegón de dulces
    stand = put("side_table_tall_01", z, "py0", 0.45, gap=0.1)
    on("brass_vase_01", stand)
    put("orava_clock", z, "px1", 3.4, gap=0.0, z=1.45)  # reloj de pared pintado, de Orava (Sketchfab, escaneo de museo)
    corner = put("round_wooden_table_02", z, "py1", seg_mid(z, "py1", -0.5, 2, 1), gap=0.05)  # velador del rincón con una maceta
    on("potted_plant_04", corner)
    pic("cma:93239", z, "py1", over(corner, z, "py1"), 1.55, 0.35, "walnut")  # bodegón sobre el velador
    fixture(z, "Chandelier_03")

    # Taller: banco de tablas viejas con tornillo, cepillo, martillo, destornilladores, llave y berbiquí (tumbados);
    # caja de herramientas, taladro de columna, estantería con latas, soplete, sierra, llave de tubo, martillo y
    # alicates; mesa baja con caja y serrucho, hacha vieja sobre una caja y palanca.
    z = "workshop"
    bench = made(workbench(M), "Workbench", z, "px1", 2.0)
    # Atornillado al canto del banco: la manivela cuelga 9 cm por debajo de su cuerpo. drop: traía una esfera de 2 m.
    on("bench_vice_01", bench, dpy=-0.72, dpx=-0.3, rot=90, top=0.814, drop=("icosphere",))
    on("hand_plane_no4", bench, dpy=-0.35, rot=20, top=0.9)
    on("cross_pein_hammer", bench, dpy=-0.05, rot=80, top=0.9, lay=True)
    on("screwdrivers_02", bench, dpy=0.2, dpx=-0.1, top=0.9)
    on("flathead_screwdriver", bench, dpy=0.15, dpx=0.12, rot=-30, top=0.9, lay=True)
    on("adjustable_wrench", bench, dpy=0.42, rot=20, top=0.9, lay=True)
    on("vintage_hand_drill", bench, dpy=0.7, rot=30, top=0.9, lay=True)
    put("metal_toolbox", z, "px1", 3.2, gap=0.05)
    free("wooden_stool_01", 16.4, 2.3)
    put("drill_press_01", z, "px1", 4.1)
    rack = made(larder_shelves(M, 1.6), "WorkshopShelves", z, "px1", 6.2)
    shelf_items(rack, (("can_rusted", 0.5, -0.5, 0, False), ("brass_blowtorch", 0.5, 0.25, 90, False),
                       ("oil_tin", 0.95, -0.45, 30, False), ("tongue_groove_pliers", 0.95, 0.0, 70, True),
                       ("small_oil_can_01", 0.95, 0.4, 80, False), ("rusted_hacksaw", 1.4, -0.3, 0, True),
                       ("wooden_hammer_01", 1.4, 0.15, 10, True), ("pipe_wrench", 1.4, 0.5, -15, True),
                       ("rusty_tin", 0.05, -0.5, 0, False), ("rusty_tin", 0.05, -0.3, 40, False),
                       ("combination_wrench", 0.05, 0.3, 20, True), ("ratchet_wrench", 0.05, 0.55, -10, True),
                       ("wooden_axe_02", 1.85, -0.3, 0, True)))
    low = put("WoodenTable_01", z, "px0", 1.8)
    on("wooden_crate_01", low, dpy=-0.4)
    on("handsaw_wood", low, dpy=0.45, rot=90, lay=True)
    on("dirty_blanket", low, dpy=0.0, rot=20)  # trapo
    barrel = put("barrel_03", z, "px0", 3.4, gap=0.05)
    on("wooden_lantern_01", barrel)  # farol de aceite sobre el barril
    put("sledgehammer_01", z, "px0", 6.2, gap=0.05, rot=90, lay=True)  # junto a la pared, pasada la puerta: en medio estorbaba
    crate = put("wooden_crate_02", z, "px0", 7.6)
    on("wooden_axe", crate, rot=70, lay=True)
    put("crowbar_01", z, "py0", 0.5, gap=0.03, lay=True)
    fixture(z)

    # Pasillo principal (farol de cobre como el del recibidor, el mismo pasillo): repisas con una jarra, el león de
    # bronce y una maqueta de galeón, y una santa pequeña en su repisa, como un altarcito.
    shelf = made(wall_shelf(M, 0.5, 1.3), "ShelfMainW", "corridor_main_w", "py0", seg_mid("corridor_main_w", "py0", 1.5, 2, 0), gap=0.0)
    on("ceramic_vase_04", shelf, top=1.3125)
    shelf = made(wall_shelf(M, 0.5, 1.3), "ShelfMainW2", "corridor_main_w", "py1", seg_mid("corridor_main_w", "py1", -0.8), gap=0.0)
    on("lion_head", shelf, top=1.3125, rot=90)
    pic("cma:160885", "corridor_main_w", "py0", seg_mid("corridor_main_w", "py0", 2.5, 2, 1), 1.55, 0.45, "ebony")
    # Fotos de familia en grupo, como en la escalera de las fotos de referencia: los abuelos y la niña.
    fam = seg_mid("corridor_main_w", "py1", 1.5)
    pic("cma:294188", "corridor_main_w", "py1", fam - 0.175, 1.62, 0.22, "ebony")
    pic("cma:294187", "corridor_main_w", "py1", fam + 0.175, 1.62, 0.22, "ebony")
    pic("cma:536482", "corridor_main_w", "py1", fam, 1.32, 0.2, "walnut")
    fixture("corridor_main_w", "lantern_chandelier_01")
    shelf = made(wall_shelf(M, 0.45, 1.35), "Altar", "corridor_main_m", "py0", seg_mid("corridor_main_m", "py0", 1.9, 2, 1), gap=0.0)
    on("gothic_statue", shelf, top=1.3625, rot=-90, scale=0.15)
    pic("cma:109507", "corridor_main_m", "py0", seg_mid("corridor_main_m", "py0", 0.6, 2, 0), 1.6, 0.45)
    pic("cma:148965", "corridor_main_m", "py1", seg_mid("corridor_main_m", "py1", 3.4, 3, 0), 1.55, 0.38, "walnut")
    rug("rug_runner", "corridor_main_m", 0.75, 4.4)
    fixture("corridor_main_m", "lantern_chandelier_01")
    shelf = made(wall_shelf(M, 0.7, 1.3), "ShipShelf", "corridor_main_e", "py0", seg_mid("corridor_main_e", "py0", -1.0), gap=0.0)
    on("dutch_ship_medium", shelf, top=1.3125, rot=-90, scale=0.02)
    pic("cma:151298", "corridor_main_m", "py1", seg_mid("corridor_main_m", "py1", 3.4, 3, 1), 1.55, 0.38, "silver")
    pic("cma:108809", "corridor_main_e", "py1", seg_mid("corridor_main_e", "py1", 1.0, 3, 2), 1.55, 0.36, "walnut")  # bosque
    fixture("corridor_main_e", "lantern_chandelier_01")
    # Pasillo lateral: un Cristo muerto y una banqueta plegable.
    pic(441965, "corridor_side", "px0", seg_mid("corridor_side", "px0", 1.8), 1.55, 0.6)
    put("folding_wooden_stool", "corridor_side", "px1", seg_mid("corridor_side", "px1", 1.8), gap=0.05)
    pic("cma:148758", "corridor_side", "px1", seg_mid("corridor_side", "px1", 1.8), 1.6, 0.5)
    fixture("corridor_side")
    # Pasillo de servicio: farol de aceite para los apagones y un colgador.
    shelf = made(wall_shelf(M, 0.4, 1.35), "LanternShelf", "corridor_service_w", "py0", seg_mid("corridor_service_w", "py0", 3.0, 3, 0), gap=0.0)
    on("Lantern_01", shelf, top=1.3625)
    pic("cma:152006", "corridor_service_w", "py0", seg_mid("corridor_service_w", "py0", 3.0, 3, 1), 1.55, 0.4, "walnut")
    pic("cma:97155", "corridor_service_w", "py1", seg_mid("corridor_service_w", "py1", 2.7), 1.6, 0.45)
    pic("cma:132367", "corridor_service_w", "py1", seg_mid("corridor_service_w", "py1", 5.0), 1.6, 0.42, "ornate")
    fixture("corridor_service_w")
    made(peg_rail(M), "PegRail", "corridor_service_m", "py0", seg_mid("corridor_service_m", "py0", 1.0, 3, 2), gap=0.0)
    pic("cma:171296", "corridor_service_m", "py0", seg_mid("corridor_service_m", "py0", 4.6), 1.55, 0.4, "ebony")
    pic("cma:147016", "corridor_service_m", "py1", seg_mid("corridor_service_m", "py1", 3.3), 1.6, 0.42)  # Virgen con el Niño
    fixture("corridor_service_m")
    pic("cma:145450", "corridor_service_e", "py1", seg_mid("corridor_service_e", "py1", 1.9), 1.55, 0.45, "ebony")
    pic("cma:124089", "corridor_service_e", "py0", seg_mid("corridor_service_e", "py0", 2.5), 1.55, 0.42)
    fixture("corridor_service_e")

    # Dormitorio 2: cama de hierro con crucifijo, banqueta con jarra de noche, armario ropero, silla tallada, maletas
    # y un farolillo de latón colgado de su cadena.
    z = "bedroom_2"
    put("old_bed_frame", z, "px1", -1.2)
    made(crucifix(M, 0.4, 1.55), "Crucifix", z, "px1", -1.2, gap=0.0)
    side = put("WoodenTable_02", z, "px1", -0.45, gap=0.03)
    on("ceramic_vase_01", side)
    photo(523595, side, dpx=0.12, rot=ROT["px1"], h=0.16, style="silver")
    made(wardrobe(M), "Wardrobe", z, "px0", -1.0)
    chair = put("gallinera_chair", z, "py1", 2.0, gap=0.05)
    put("vintage_suitcase", z, "py1", 0.9, gap=0.05, rot=8)
    pic("cma:124080", z, "py1", over(chair, z, "py1"), 1.62, 0.42, "walnut")  # retrato sobre la silla
    rug("rug_rag", z, 1.0, 1.6)
    pic("cma:142472", z, "py0", seg_mid(z, "py0", -0.6), 1.55, 0.4)  # icono de la Virgen
    fixture(z, "brass_diya_lantern", scale=2.0, drop=("flame",))

    # Baño (usuario, 2026-11-22: lo de antes «no pinta nada»): bañera de hierro con patas de garra, pintada de verde
    # y oxidada, esmalte desconchado; inodoro de loza cuarteada con cisterna alta; lavabo de pie con su espejo;
    # toallero sobre la bañera, escabel, cubo y bombilla.
    z = "bathroom"
    made(bathtub(M), "Bathtub", z, "py1", 1.05)
    made(towel_rail(M, 0.6, 1.35), "TowelRail", z, "py1", 1.6, gap=0.0)
    made(toilet(M), "Toilet", z, "px1", -1.4)
    made(basin(M), "Basin", z, "px0", -1.6)
    mirror(M, z, "px0", -1.6, 1.68, 0.36, 0.48, "ebony")  # por encima del remate del azulejo (1,37 m), que asomaba
    put("wooden_bucket_02", z, "px0", -1.05, gap=0.05)  # junto a la bañera se metía dentro
    put("wooden_stool_02", z, "px1", -2.3, gap=0.05)
    put("plunger", z, "px1", -0.85, gap=0.05)
    shelf = made(wall_shelf(M, 0.4, 1.45), "BathShelf", z, "py0", seg_mid(z, "py0", 1.9), gap=0.0)
    on("lambis_shell", shelf, top=1.4625, rot=30)
    fixture(z)

    # Dormitorio 3 (de niño): cama de día, mesa de estudio con ajedrez y su taburete pintado y desconchado, pizarra.
    z = "bedroom_3"
    daybed = put("vintage_day_bed", z, "py0", 1.3)
    desk = put("wooden_table_02", z, "px1", 0.9)
    on("chess_set", desk, dpy=-0.15, scale=0.6, rot=8)
    banker = on("bankers_lamp", desk, dpy=0.35, rot=ROT["px1"])
    lo, hi = bounds(banker)  # el flexo encendido sin nadie en el cuarto: su luz, bajo la pantalla
    bulb = give(cylinder("LampBulb", 0.018, 0.08, ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, hi.z - 0.07), rot=(0, math.radians(90), 0), verts=10), M["bulb"])
    lamp_light(z, banker + [bulb], at=((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, hi.z - 0.1))
    on("old_book_red", desk, dpy=0.05, dpx=0.15, rot=15)
    free("painted_wooden_stool", 9.85, 6.45, rot=180)  # la silla blanca parecía nueva
    made(wall_slate(M), "WallSlate", z, "py1", seg_mid(z, "py1", -0.6), gap=0.0)
    pic("cma:149768", z, "py0", over(daybed, z, "py0"), 1.65, 0.55, "walnut")  # san Juan, sobre la cama
    # Lo del niño: la maqueta de barco y el microscopio con los prismáticos en sus repisas, y una foto de niños.
    shelf = made(wall_shelf(M, 0.7, 1.4), "ShipShelf3", z, "py1", seg_mid(z, "py1", 0.6), gap=0.0)
    on("ship_pinnace", shelf, top=1.4125, rot=90, scale=0.012)
    shelf = made(wall_shelf(M, 0.6, 1.35), "StudyShelf", z, "px0", seg_mid(z, "px0", 1.5), gap=0.0)
    on("vintage_microscope", shelf, top=1.3625, dpy=-0.13, rot=90)
    on("vintage_binocular", shelf, top=1.3625, dpy=0.15, rot=20)
    pic("cma:162316", z, "px1", over(desk, z, "px1"), 1.6, 0.4, "walnut")
    fixture(z)

    # Paso de la despensa: alacena azul, escoba, recogedor, cesto y lechera.
    z = "pantry_hall"
    cupboard = put("painted_wooden_cabinet_02", z, "px1", 1.6)
    put("wooden_broom", z, "px0", 0.5, gap=0.05)
    put("dustpan", z, "px0", 0.9, gap=0.05)
    on("brass_pot_02", cupboard)
    pic("cma:102578", z, "px0", seg_mid(z, "px0", 1.6), 1.6, 0.42, "ebony")  # retrato de una señora
    fixture(z)

    # Galería: rueca, canapé pintado, plantas con su regadera y cubo de la colada.
    z = "gallery"
    wheel = put("spinning_wheel_01", z, "px0", -1.5, gap=0.05)
    pic("cma:136680", z, "px0", over(wheel, z, "px0"), 1.65, 0.5)  # san Jerónimo
    put("painted_wooden_sofa", z, "px1", 1.8)
    put("potted_plant_01", z, "py1", 0.5, gap=0.05)
    put("watering_can_metal_01", z, "py1", 1.1, gap=0.08, rot=30)
    put("planter_pot_clay", z, "py1", 2.45, gap=0.05)
    put("trowel_01", z, "py1", 1.75, gap=0.05, rot=70)
    put("wooden_bucket_01", z, "px0", 0.6, gap=0.05)
    window_curtain(z)
    fixture(z)

    # Trastero (con los fusibles en el hito 4b): escalera, caja militar, máscara de gas colgada, pala y muletas.
    z = "storage"
    put("wooden_ladder", z, "px0", 1.6, gap=0.05)
    crate = put("wooden_military_crate", z, "py1", 0.72, gap=0.05)
    put("old_gas_mask", z, "px0", -0.5, gap=0.03, z=0.55)
    put("rusted_spade_01", z, "px1", 2.6, gap=0.03)
    put("vintage_crutches_01", z, "px1", 0.7, gap=0.03)
    put("metal_jerrycan", z, "px1", 1.6, gap=0.03)
    on("picke_dirty_01", crate, rot=10, lay=True)
    fixture(z)

    # Recibidor (usuario, 2026-11-22: ni busto ni jarrón; zapatero y perchero): banco bajo la Adoración, perchero de
    # madera gastada, zapatero con botas viejas al lado, el espejo encima y farol de cobre.
    z = "entrance_hall"
    bench = put("painted_wooden_bench", z, "px0", 1.6)
    on("letters", bench, dpx=0.08, dpy=0.35, rot=10)  # el correo, en el asiento
    pic("cma:152349", z, "py1", seg_mid(z, "py1", 1.0), 1.6, 0.3, "ebony")
    pic(436200, z, "px0", over(bench, z, "px0"), 1.6, 0.7, "ornate")
    pic("cma:111435", z, "py0", seg_mid(z, "py0", 0.5), 1.6, 0.45)
    pic("cma:127571", z, "py0", seg_mid(z, "py0", 3.3), 1.6, 0.42, "ebony")  # retrato de un caballero
    made(coat_rack(M), "CoatRack", z, None, (8.15, 13.2))
    lamp = made(floor_lamp(M), "FloorLamp", z, None, (4.98, 13.3), uv=0.5)  # en el rincón, junto a la puerta
    lamp_light(z, lamp, at=(*to_b(4.98, 13.3), 1.47))
    # Abrigo y sombrero colgados de los ganchos (usuario, 2026-11-22: la bufanda por un abrigo, el sombrero mejor
    # colgado). Puntas de los ganchos (coat_rack): a 0,107 m del palo y 1,72 m de alto; el de +X da a la habitación.
    rx, ry = to_b(8.15, 13.2)
    coat = made(hanging_coat(M), "Coat", z, None, (8.15, 13.2), uv=0.4)
    for o in coat:
        o.location = (rx + 0.1, ry, 1.72)
    hat = free("black_hat", 8.15, 13.2)
    a, b = bounds(hat)
    pivot = (a + b) / 2
    turn = Matrix.Translation((rx, ry - 0.17, 1.66)) @ Matrix.Rotation(math.radians(80), 4, "X") @ Matrix.Translation(-pivot)
    for o in hat:  # de lado, con la copa en el gancho de -Y (hacia el interior del recibidor)
        o.matrix_world = turn @ o.matrix_world
    put("painted_wooden_shelves", z, "px1", 1.8)  # zapatero
    put("old_boots", z, "px1", 1.2, gap=0.06, rot=-15)  # botas de cuero viejas (Sketchfab, escaneo de museo)
    mirror(M, z, "px1", 1.8, 1.7, 0.45, 0.55, "walnut")
    fixture(z, "lantern_chandelier_01")

    # Fresquera: baldas a lo largo de la pared con olla de barro, cebollas, boniatos, queso, conservas, jarrón,
    # granadas y peras; barril de vino y una ratonera.
    z = "larder"
    lo_x, lo_y, hi_x, hi_y = interior(z)
    shelves = made(larder_shelves(M, hi_y - lo_y - 0.1), "LarderShelves", z, "px0", (hi_y - lo_y) / 2)
    # Llena (usuario, 2026-11-22: «muchas más cosas»): lo de comer se repite como en una despensa de verdad.
    shelf_items(shelves, (("ceramic_pot", 0.05, -1.25, 0, False), ("ceramic_vase_03", 0.05, -0.7, 0, False),
                          ("wine_bottles_01", 0.05, 0.42, 0, False), ("ceramic_pot", 0.05, 1.1, 40, False),
                          ("yellow_onion", 0.5, -1.35, 0, False), ("yellow_onion", 0.5, -1.22, 50, False),
                          ("yellow_onion", 0.5, -1.09, 110, False), ("sweet_potato", 0.5, -0.6, 30, False),
                          ("sweet_potato", 0.5, -0.4, 80, False), ("bread_rustic", 0.5, 0.45, 0, False),
                          ("bread_braid", 0.5, 1.0, 10, False), ("CheeseBox_01", 0.95, -1.1, 0, False),
                          ("russian_food_cans_01", 0.95, -0.55, 20, False), ("russian_food_cans_01", 0.95, -0.35, 70, False),
                          ("food_pears_asian_01", 0.95, 0.45, 0, False), ("food_pomegranate_01", 0.95, 1.1, 0, False),
                          ("food_pomegranate_01", 1.4, -1.25, 60, False), ("food_pomegranate_01", 1.4, -1.1, 0, False),
                          ("ceramic_pot", 1.4, -0.45, 90, False), ("ceramic_vase_03", 1.4, 0.6, 30, False),
                          ("yellow_onion", 1.4, 1.2, 0, False), ("yellow_onion", 1.4, 1.32, 70, False)))
    free("wine_barrel_01", 9.5, 13.05)
    free("mousetrap", 9.4, 10.7, rot=20)
    free("street_rat", 9.75, 11.2, rot=200)  # junto a la ratonera
    pic("cma:128393", z, "py1", seg_mid(z, "py1", 0.7), 1.65, 0.4, "ebony")  # bodegón con raya
    fixture(z)

    # Cocina: cocina esmaltada con olla y cazo, fregadero de loza bajo la ventana, alacena, mesa con dos
    # sillas, la radio sobre la alacena y una repisa con el puchero de latón.
    z = "kitchen"
    stove = put("rusty_stove", z, "px1", 1.7, gap=0.03)  # cocina esmaltada y oxidada (BlenderKit)
    on("pot_enamel_01", stove, dpy=0.13)
    on("brass_pan_01", stove, dpy=-0.15, rot=30)
    sink = made(kitchen_sink(M), "KitchenSink", z, "py1", -0.5, gap=0.01, uv=2.4)  # en la esquina: bajo la ventana no se pasaba
    larder_box = made(wall_cupboard(M), "WallCupboard", z, "py1", over(sink, z, "py1"), gap=0.0)
    low, mid = 1.45 + 0.02, 1.45 + 0.75 / 2 + 0.01
    on("ceramic_pot", larder_box, dpx=-0.24, top=low, scale=0.3)  # orzas de sal y azúcar
    on("ceramic_pot", larder_box, dpx=0.0, top=low, rot=60, scale=0.25)
    on("ceramic_vase_03", larder_box, dpx=0.25, top=low, scale=0.6)  # aceitera
    on("russian_food_cans_01", larder_box, dpx=-0.2, top=mid, rot=10)  # latas de pimentón y especias
    on("can_rusted", larder_box, dpx=0.05, top=mid, scale=0.8)
    on("food_lime_01", larder_box, dpx=0.22, top=mid)
    on("food_lime_01", larder_box, dpx=0.29, top=mid, rot=90)
    on("wicker_basket_02", larder_box, top=1.45 + 0.75 + 0.035)  # cesta encima de la alacena
    put("metal_jug", z, "px1", 2.45, gap=0.05)  # lechera
    cab = put("painted_wooden_cabinet", z, "py0", -0.8)
    on("philips_radio", cab, rot=-90)  # radio Philips de 1939 (Sketchfab, escaneo de museo)
    on("bananas", cab, dpx=0.4, scale=0.45)
    shelf = made(wall_shelf(M, 0.6, 1.5), "KitchenShelf", z, "py0", 2.0, gap=0.0)
    on("brass_pot_01", shelf, top=1.5125, scale=0.7)
    table = free("painted_wooden_table", 12.1, 11.85, scale=0.75)  # 2,4 m: tapaba las dos puertas; a lo largo deja paso
    chairs_around(table, "painted_wooden_chair_02", per_side=1, gap=0.25)
    on("enamel_kettle", table, dpy=-0.25, rot=30)
    window_curtain(z)
    on("wooden_cutting_board", table, dpx=-0.2)
    on("wooden_spoon", table, dpx=-0.15, rot=40)
    on("jug_01", table, dpx=0.3, scale=0.7)
    on("wooden_bowl_02", table, dpx=0.05, dpy=0.2)
    on("lemon", table, dpx=0.03, dpy=0.18)  # limones en el cuenco
    on("lemon", table, dpx=0.08, dpy=0.23, rot=60)
    pic("cma:147607", z, "px0", seg_mid(z, "px0", 0.6), 1.6, 0.38, "walnut")  # bodegón con arenques
    fixture(z)

    # Aseo de servicio: retrete con cisterna de madera y palangana en su trípode con jarra y toalla.
    z = "service_toilet"
    made(toilet(M, wooden_tank=True), "ServiceToilet", z, "py1", 1.4)
    made(washstand(M), "Washstand", z, "px1", 2.2, gap=0.05)
    pic("cma:151015", z, "px0", seg_mid(z, "px0", 1.0), 1.6, 0.3, "walnut")
    fixture(z)

    floor_colliders()
    check_doors()
    check_colliders()


def check_colliders():
    """Aviso si una colisión queda fuera de su habitación (el tornillo de banco traía una esfera de 2 m que llenó
    el salón de una caja invisible: usuario, 2026-11-22, «no se puede andar por ningún sitio»)."""
    rects = [L.interior(r, zid) for zid, _, r, _ in L.ZONES]
    for o in bpy.context.scene.objects:
        if o.name.startswith("Solid_"):
            lo, hi = bounds([o])
            x0, x1, y0, y1 = lo.y + 7, hi.y + 7, 2 - hi.x, 2 - lo.x  # en el plano: px = Y + 7, py = 2 - X
            if not any(a - 0.05 <= x0 and x1 <= c + 0.05 and b - 0.05 <= y0 and y1 <= d + 0.05 for a, b, c, d in rects):
                print("COLLIDER_OUTSIDE %s (px %.2f-%.2f, py %.2f-%.2f)" % (o.name, x0, x1, y0, y1))


def check_doors():
    """Aviso si un mueble queda en el giro de una hoja o delante de un hueco (lo comprueba también test_flat.gd)."""
    solids = []
    for o in bpy.context.scene.objects:
        if o.name.startswith("Solid_"):
            lo, hi = bounds([o])
            solids.append((o.name, lo, hi))
    for conn in L.CONNECTIONS:
        cid, a, b, kind, pos = conn[:5]
        if pos is None:
            continue
        axis, coord, n = L.wall_of(conn)
        w = L.DOOR_W if kind == "leaf" else L.PASSAGE_W
        for side, depth in ((1, 0.95), (-1, 0.5)):  # hacia zona_a: el giro; hacia zona_b: el paso
            if side == -1 and b == "":
                continue
            d0, d1 = sorted((coord + side * n[0 if axis == "v" else 1] * T / 2, coord + side * n[0 if axis == "v" else 1] * (T / 2 + depth)))
            px0, px1, py0, py1 = (pos - w / 2, pos + w / 2, d0, d1) if axis == "h" else (d0, d1, pos - w / 2, pos + w / 2)
            (bx0, by0), (bx1, by1) = to_b(px0, py0), to_b(px1, py1)
            X0, X1, Y0, Y1 = min(bx0, bx1), max(bx0, bx1), min(by0, by1), max(by0, by1)
            for name, lo, hi in solids:
                if lo.x < X1 and hi.x > X0 and lo.y < Y1 and hi.y > Y0:
                    print("DOOR_BLOCKED %s (%s) por %s" % (cid, "giro" if side == 1 else "paso", name))


furnish()
