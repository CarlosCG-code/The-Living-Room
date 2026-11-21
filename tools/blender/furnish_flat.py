"""Muebles, lámparas y cuadros del piso (specs/hito4a.md D14). Usuario, 2026-11-21: cada habitación reconocible y
con detalle, como el salón; ningún cuadro ni objeto repetido; una lámpara en cada habitación.

Lo ejecuta build_flat.py con sus funciones (exec en su espacio de nombres). Todo es CC0 de Poly Haven, pinturas
CC0 del Met o modelado aquí con formas simples (lo que Poly Haven no tiene: baño, cocina económica, fregadero…).
Coordenadas de plano (flat_layout.py): px a lo largo de la fachada, py hacia dentro. Blender: X = 2 - py, Y = px - 7.
"""
import math

from mathutils import Matrix, Vector

import_model, painting, cylinder, cone = _helpers["import_model"], _helpers["painting"], _helpers["cylinder"], _helpers["cone"]
floor_colliders = _helpers["floor_colliders"]

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
    return import_model(asset, "1k", ((lo.x + hi.x) / 2 - dpy, (lo.y + hi.y) / 2 + dpx, top or hi.z), rot_z_deg=rot, **kw)


def pic(met_id, zid, wall, at, z, h, style="gilt"):
    """Cuadro colgado: z es la altura de su centro."""
    px, py = spot(zid, wall, at, 0.1)
    return snap(painting(met_id, (*to_b(px, py), z), ROT[wall], h, style), zid, wall, 0.003)


def made(parts, name, zid, wall, at, off=0.4, gap=0.02, rot=0.0, z=0.0):
    """Un modelo hecho aquí (en el origen, de cara a -Y, con la base en z = 0) colocado contra una pared."""
    o = join(parts, name)
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
    m = {
        "enamel": mat("Enamel", (0.78, 0.77, 0.73), 0.12),
        "iron": mat("CastIron", (0.025, 0.025, 0.025), 0.55, metallic=0.7),
        "brass": bpy.data.materials.get("Brass") or mat("Brass", (0.6, 0.45, 0.22), 0.3, metallic=1.0),
        "chrome": mat("Chrome", (0.75, 0.75, 0.75), 0.12, metallic=1.0),
        "terrazzo": mat("Terrazzo", (0.5, 0.48, 0.45), 0.35),
        "mirror": mat("Mirror", (0.55, 0.55, 0.53), 0.2, metallic=0.6),  # sin sonda de reflejo (paso 6) salía negro
        "bench": tex_mat("WorkbenchWood", "dark_wood", "1k", tint=(1.0, 0.85, 0.7)),
        "shelf": tex_mat("ShelfWood", "dark_wood", "1k", tint=(0.8, 0.65, 0.5)),
        "walnut": tex_mat("DoorWood", "dark_wood", "1k", tint=_helpers["DOOR_TINT"]),
        "tile": tex_mat("WallTiles", "wall_tiles", "2k", root=GEN),
        "shade_on": mat("LampShade", (0.42, 0.36, 0.27), 0.8, emission=(1.0, 0.8, 0.6), emission_strength=0.2),
        "shade2_on": mat("LampShadeGreen", (0.2, 0.26, 0.2), 0.8, emission=(1.0, 0.8, 0.6), emission_strength=0.2),
        "shade2_off": mat("LampShadeGreenOff", (0.16, 0.21, 0.16), 0.8),
        "shade3_on": mat("LampShadeRose", (0.42, 0.28, 0.26), 0.8, emission=(1.0, 0.8, 0.6), emission_strength=0.2),
        "shade3_off": mat("LampShadeRoseOff", (0.34, 0.22, 0.2), 0.8),
        "milk_glass": mat("MilkGlass", (0.62, 0.6, 0.56), 0.3),
        "enamel_green": mat("EnamelGreen", (0.12, 0.22, 0.16), 0.15),
        "gilt": mat("Frame_gilt", (0.42, 0.3, 0.12), 0.38, metallic=1.0),
        "shade_off": mat("LampShadeOff", (0.33, 0.29, 0.23), 0.8),
        "glass_on": mat("GlobeGlassOn", (0.8, 0.78, 0.72), 0.3, emission=(1.0, 0.85, 0.65), emission_strength=0.6),
        "bulb_on": mat("BulbOn", (1.0, 0.9, 0.7), 0.3, emission=(1.0, 0.85, 0.6), emission_strength=1.5),
        "bulb_off": mat("BulbOff", (0.7, 0.7, 0.66), 0.1),
    }
    for k in ("shade_on", "shade_off", "shade2_on", "shade2_off", "shade3_on", "shade3_off"):
        m[k].use_backface_culling = False
    return m


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


def bathtub(M):
    outer = cast(give(box("Tub", (1.6, 0.75, 0.5), (0, 0, 0.4)), M["enamel"], bevel=0.12, segments=5))
    inner = cast(give(box("TubIn", (1.46, 0.61, 0.5), (0, 0, 0.62)), M["enamel"], bevel=0.12, segments=5))
    parts = [hollow(outer, inner)]
    for x in (-0.65, 0.65):
        for y in (-0.27, 0.27):
            parts.append(give(cone("TubFoot", 0.035, 0.05, 0.16, (x, y, 0.08), verts=12), M["brass"]))
    parts.append(give(cylinder("TubTap", 0.012, 0.18, (0.74, 0, 0.72), rot=(0, math.radians(70), 0), verts=10), M["chrome"]))
    return parts


def toilet(M, high_tank=True):
    parts = [give(cylinder("WcFoot", 0.14, 0.36, (0, -0.02, 0.18), verts=20), M["enamel"], bevel=0.02)]
    parts[-1].scale = (1, 1.35, 1)
    parts.append(give(cylinder("WcBowl", 0.2, 0.08, (0, -0.06, 0.38), verts=24), M["enamel"], bevel=0.03))
    parts[-1].scale = (1, 1.3, 1)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.17, minor_radius=0.025, location=(0, -0.06, 0.435))
    seat = bpy.context.active_object
    seat.scale = (1, 1.3, 1)
    parts.append(give(seat, M["walnut"]))
    tz = 1.85 if high_tank else 0.62
    parts.append(give(box("WcTank", (0.45, 0.18, 0.26), (0, 0.2, tz)), M["enamel"], bevel=0.015))
    parts.append(give(cylinder("WcPipe", 0.018, tz - 0.4, (0, 0.22, (tz + 0.4) / 2), verts=10), M["chrome"]))
    if high_tank:
        parts.append(give(cylinder("WcChain", 0.003, 0.5, (0.18, 0.12, tz - 0.38), verts=6), M["chrome"]))
        parts.append(give(cylinder("WcPull", 0.012, 0.07, (0.18, 0.12, tz - 0.66), verts=10), M["walnut"]))
    return parts


def basin(M, small=False):
    w = 0.42 if small else 0.56
    parts = [give(cylinder("BasinFoot", 0.09, 0.7, (0, 0.05, 0.35), verts=16), M["enamel"], bevel=0.02)]
    outer = cast(give(box("Basin", (w, 0.42, 0.17), (0, 0, 0.78)), M["enamel"], bevel=0.05, segments=4))
    inner = cast(give(box("BasinIn", (w - 0.1, 0.3, 0.17), (0, -0.02, 0.86)), M["enamel"], bevel=0.05, segments=4))
    parts.append(hollow(outer, inner))
    for x in (-0.1, 0.1):
        parts.append(give(cylinder("BasinTap", 0.012, 0.12, (x, 0.17, 0.92), verts=10), M["chrome"]))
    return parts


def mirror(M, w, h, z):
    parts = [give(box("MirrorGlass", (w, 0.006, h), (0, -0.012, z)), M["mirror"])]
    f = 0.04
    for name, size, at in (("MirrorTop", (w + 2 * f, 0.03, f), (0, 0, z + h / 2 + f / 2)), ("MirrorBottom", (w + 2 * f, 0.03, f), (0, 0, z - h / 2 - f / 2)),
                           ("MirrorL", (f, 0.03, h), (-w / 2 - f / 2, 0, z)), ("MirrorR", (f, 0.03, h), (w / 2 + f / 2, 0, z))):
        parts.append(give(box(name, size, at), M["walnut"], bevel=0.008))
    return parts


def kitchen_range(M):
    """Cocina económica de hierro con barra de latón, fogones, horno y tiro hasta el techo."""
    parts = [give(box("RangeBody", (1.0, 0.6, 0.78), (0, 0, 0.39)), M["iron"], bevel=0.01),
             give(box("RangeTop", (1.04, 0.64, 0.03), (0, 0, 0.795)), M["iron"], bevel=0.006)]
    for x in (-0.25, 0.15):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.11, minor_radius=0.012, location=(x, -0.05, 0.815))
        parts.append(give(bpy.context.active_object, M["iron"]))
    parts.append(give(cylinder("RangeRail", 0.012, 1.08, (0, -0.36, 0.7), rot=(0, math.radians(90), 0), verts=10), M["brass"]))
    for x, w in ((-0.25, 0.4), (0.25, 0.4)):
        parts.append(give(box("RangeDoor", (w, 0.02, 0.32), (x, -0.31, 0.38)), M["iron"], bevel=0.008))
        parts.append(give(box("RangeHandle", (0.08, 0.02, 0.015), (x, -0.33, 0.5)), M["brass"]))
    parts.append(give(cylinder("RangeFlue", 0.07, H - 0.81, (0.35, 0.18, 0.81 + (H - 0.81) / 2), verts=16), M["iron"]))
    return parts


def kitchen_sink(M):
    """Fregadero de terrazo sobre obra alicatada, con grifo de pared."""
    parts = [give(box("SinkBase", (1.0, 0.55, 0.8), (0, 0, 0.4)), M["tile"])]
    outer = cast(give(box("Sink", (1.0, 0.58, 0.2), (0, -0.01, 0.9)), M["terrazzo"], bevel=0.02))
    inner = cast(give(box("SinkIn", (0.7, 0.42, 0.2), (-0.1, -0.02, 0.98)), M["terrazzo"], bevel=0.02))
    parts.append(hollow(outer, inner))
    parts.append(give(cylinder("SinkTap", 0.014, 0.2, (-0.1, 0.18, 1.12), rot=(math.radians(-70), 0, 0), verts=10), M["chrome"]))
    return parts


def workbench(M):
    parts = [give(box("BenchTop", (1.8, 0.7, 0.07), (0, 0, 0.865)), M["bench"], bevel=0.006),
             give(box("BenchShelf", (1.65, 0.6, 0.03), (0, 0, 0.2)), M["bench"])]
    for x in (-0.82, 0.82):
        for y in (-0.28, 0.28):
            parts.append(give(box("BenchLeg", (0.08, 0.08, 0.83), (x, y, 0.415)), M["bench"], bevel=0.004))
    parts.append(give(box("BenchVise", (0.18, 0.14, 0.12), (-0.7, -0.38, 0.96)), M["iron"], bevel=0.008))
    parts.append(give(box("BenchBackboard", (1.8, 0.02, 0.6), (0, 0.34, 1.2)), M["bench"]))
    return parts


def larder_shelves(M, length):
    parts = []
    for z in (0.05, 0.5, 0.95, 1.4, 1.85):
        parts.append(give(box("LarderShelf", (length, 0.35, 0.025), (0, 0, z)), M["shelf"], bevel=0.003))
    for x in (-length / 2 + 0.012, 0, length / 2 - 0.012):
        parts.append(give(box("LarderSide", (0.025, 0.35, 1.9), (x, 0, 0.95)), M["shelf"]))
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


def pendant(M, kind, lit):
    """Lámpara de techo hecha aquí, una forma por tipo de habitación (usuario, 2026-11-21: casi nada repetido; los
    tramos de un mismo pasillo comparten modelo). La luz de Godot va dentro, a 2,3 m."""
    bulb = M["bulb_on"] if lit else M["bulb_off"]
    parts = [give(cylinder("Rose", 0.05, 0.02, (0, 0, H - 0.01), verts=16), M["brass"])]
    if kind in ("globe", "plafon"):  # pegadas al techo: globo de cristal o plafón de media esfera
        r = 0.14 if kind == "globe" else 0.2
        parts.append(give(cylinder("Neck", 0.06, 0.05, (0, 0, H - 0.04), verts=16), M["brass"]))
        bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=(0, 0, H - (0.2 if kind == "globe" else 0.06)), segments=24, ring_count=12)
        g = bpy.context.active_object
        if kind == "plafon":
            g.scale = (1, 1, 0.45)
        parts.append(give(g, M["glass_on"] if lit else M["milk_glass"]))
        return parts
    drop = {"fabric": 0.42, "drum": 0.5, "bell": 0.35, "enamel": 0.42, "enamel_green": 0.5, "tulip": 0.3, "dome": 0.25}[kind]
    parts.append(give(cylinder("Cord", 0.004, drop, (0, 0, H - drop / 2), verts=6), M["iron"]))
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.03, location=(0, 0, H - drop - 0.04), segments=12, ring_count=6)
    parts.append(give(bpy.context.active_object, bulb))
    z = H - drop
    if kind == "fabric":
        parts.append(give(cone("Shade", 0.21, 0.09, 0.22, (0, 0, z - 0.06)), M["shade_on" if lit else "shade_off"]))
    elif kind == "drum":
        parts.append(give(cone("Shade", 0.2, 0.2, 0.2, (0, 0, z - 0.06)), M["shade2_on" if lit else "shade2_off"]))
    elif kind == "bell":
        parts.append(give(cone("Shade", 0.27, 0.06, 0.26, (0, 0, z - 0.08)), M["shade3_on" if lit else "shade3_off"]))
    elif kind == "tulip":  # tulipa de cristal hacia arriba con su portalámparas de latón
        parts.append(give(cone("Shade", 0.05, 0.16, 0.2, (0, 0, z - 0.02)), M["glass_on"] if lit else M["milk_glass"]))
        parts.append(give(cylinder("Holder", 0.03, 0.06, (0, 0, z - 0.12), verts=12), M["brass"]))
    elif kind == "dome":  # cúpula de latón
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.16, location=(0, 0, z - 0.06), segments=24, ring_count=12)
        d = bpy.context.active_object
        d.scale = (1, 1, 0.5)
        parts.append(give(d, M["brass"]))
    else:  # esmalte de cocina: blanco, o verde en el paso de la despensa
        parts.append(give(cone("Shade", 0.24, 0.05, 0.13, (0, 0, z - 0.01)), M["enamel_green" if kind == "enamel_green" else "enamel"]))
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


def plate_rack(M, z=1.45):
    """Escurreplatos de madera colgado con cinco platos de loza."""
    parts = [give(box("RackRail", (0.7, 0.03, 0.03), (0, -0.04, z + dz)), M["shelf"]) for dz in (0.0, 0.25)]
    parts.append(give(box("RackTray", (0.7, 0.2, 0.02), (0, -0.1, z - 0.02)), M["shelf"]))
    for k in range(5):
        parts.append(give(cylinder("Plate", 0.11, 0.012, (-0.26 + k * 0.13, -0.1, z + 0.1), rot=(math.radians(78), 0, 0), verts=28), M["enamel"], bevel=0.003))
    return parts


def oval_mirror(M, w, h, z):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.5, minor_radius=0.04, location=(0, -0.02, z), rotation=(math.radians(90), 0, 0))
    ring = bpy.context.active_object
    ring.scale = (w, 1, h)
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=0.5, depth=0.006, location=(0, -0.02, z), rotation=(math.radians(90), 0, 0))
    glass = bpy.context.active_object
    glass.scale = (w, h, 1)
    return [give(ring, M["gilt"]), give(glass, M["mirror"])]


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
CLEAR = 1.85  # ninguna lámpara de techo baja de aquí: el jugador mide 1,75 m


def ceiling(objs):
    """Cuelga del techo: la parte de arriba toca el techo."""
    lo, hi = bounds(objs)
    for o in objs:
        o.location.z += H - hi.z
    return objs


def fixture(zid, M, asset=None, kind="fabric", scale=1.0, cord=0.0):
    """La lámpara de la habitación, en el centro (donde está su luz en Godot: flat_layout.write_tres). Se llama
    Fixture_*: Godot le quita la sombra para que la luz de dentro no quede tapada. cord: cuelga de un cable."""
    lo_x, lo_y, hi_x, hi_y = interior(zid)
    cx, cy = (lo_x + hi_x) / 2, (lo_y + hi_y) / 2
    lit = zid in LIT
    if asset:
        objs = free(asset, cx, cy, scale=scale)
        lo, hi = bounds(objs)
        if H - cord - (hi.z - lo.z) < CLEAR:  # la del taller colgaba hasta 1,24 m: la cabeza la atravesaba
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            objs = free(asset, cx, cy, scale=scale * (H - cord - CLEAR) / (hi.z - lo.z))
        objs = ceiling(objs)
        if cord:
            for o in objs:
                o.location.z -= cord
            objs.append(give(cylinder("Cord", 0.004, cord, (*to_b(cx, cy), H - cord / 2), verts=6), M["iron"]))
        if lit:  # pantallas y bombillas encendidas
            for o in objs:
                for i, m in enumerate(o.data.materials):
                    if m and any(k in m.name.lower() for k in ("shade", "bulb", "glass", "light", "lamp")):
                        on_m = m.copy()
                        on_m.name = m.name + "_On"
                        b = next(n for n in on_m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
                        b.inputs["Emission Color"].default_value = (1.0, 0.82, 0.6, 1.0)
                        b.inputs["Emission Strength"].default_value = 0.4
                        o.data.materials[i] = on_m
    else:
        objs = made(pendant(M, kind, lit), "Pendant", zid, None, (cx, cy))
    for k, o in enumerate(objs):
        o.name = "Fixture_%s_%d" % (zid, k)
    return objs


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
    modelo se repite salvo las sillas de un mismo juego; los tramos de un pasillo comparten lámpara."""
    M = materials()

    # Dormitorio principal: cama gótica con baúl a los pies, mesilla con quinqué y despertador, butaca, armario,
    # cómoda con espejo ovalado, y una Virgen sobre la cama.
    z = "bedroom_main"
    put("GothicBed_01", z, "px0", 2.0)
    free("treasure_chest", 2.5, 2.0, rot=180)
    stand = put("painted_wooden_nightstand", z, "px0", 0.55)
    on("vintage_oil_lamp", stand, dpy=-0.06, scale=0.55)
    on("alarm_clock_01", stand, dpy=0.13, rot=-60, scale=0.6)
    put("GreenChair_01", z, "px0", 3.45, gap=0.1, rot=-20)
    put("GothicCabinet_01", z, "px1", 2.0)
    commode = put("GothicCommode_01", z, "py0", -1.0)
    on("ceramic_vase_02", commode, dpx=0.35)
    on("vintage_pocket_watch", commode, dpx=-0.3, rot=15)
    made(oval_mirror(M, 0.5, 0.7, 1.75), "OvalMirror", z, "py0", -1.0, gap=0.0)
    pic(437336, z, "px0", 2.0, 1.85, 0.5)
    pic("cma:125247", z, "py1", 1.5, 1.6, 0.45, "ebony")
    fixture(z, M, "Chandelier_01")

    # Comedor: mesa con mantel y cuatro sillas, aparador con el toro de bronce, reloj encima, repisa con un puchero
    # de latón, macetero alto y araña de cristal.
    z = "dining_room"
    lo_x, lo_y, hi_x, hi_y = interior(z)
    table = free("dining_table", (lo_x + hi_x) / 2, 1.55, rot=90)  # hacia la ventana: libre el giro de la puerta
    chairs_around(table, "WoodenChair_01", gap=0.28, scale=0.62)  # el modelo mide 2,27 m de alto
    on("wooden_bowl_01", table)
    on("food_apple_01", table, dpx=0.05, dpy=0.02)
    console = put("ClassicConsole_01", z, "px1", 2.0)
    on("bull_head", console, rot=-90)
    on("brass_goblets", console, dpy=-0.5, scale=0.7)
    on("wooden_candlestick", console, dpy=0.5)
    put("wall_clock", z, "px1", 2.0, gap=0.003, z=1.55)
    pic("cma:151555", z, "px0", 2.0, 1.6, 0.55)  # bodegón con pescado y pan
    pic("cma:150140", z, "py1", -1.2, 1.6, 0.4, "walnut")  # bodegón de dulces
    stand = put("side_table_tall_01", z, "py0", 0.45, gap=0.1)
    on("potted_plant_04", stand)
    fixture(z, M, "Chandelier_03")

    # Taller: banco con cepillo, martillo, destornilladores, llave inglesa y berbiquí; caja de herramientas,
    # taladro de columna, estantería con latas de aceite y sierra, mesa baja con caja y serrucho, y palanca.
    z = "workshop"
    bench = made(workbench(M), "Workbench", z, "px1", 2.0)
    on("hand_plane_no4", bench, dpy=-0.55, rot=20, top=0.9)
    on("cross_pein_hammer", bench, dpy=-0.15, rot=80, top=0.9)
    on("screwdrivers_02", bench, dpy=0.2, dpx=-0.1, top=0.9)
    on("adjustable_wrench", bench, dpy=0.45, rot=20, top=0.9)
    on("vintage_hand_drill", bench, dpy=0.7, rot=30, top=0.9)
    put("metal_toolbox", z, "px1", 3.2, gap=0.05)
    free("wooden_stool_01", 16.4, 2.3)
    put("drill_press_01", z, "px1", 4.1)
    rack = made(larder_shelves(M, 1.6), "WorkshopShelves", z, "px1", 6.2)
    rl, rh = bounds(rack)
    cx, cy = (rl.x + rh.x) / 2, (rl.y + rh.y) / 2
    for asset, level, dy, rot in (("can_rusted", 0.5, -0.5, 0), ("oil_tin", 0.95, -0.4, 30), ("small_oil_can_01", 0.95, 0.3, 80),
                                  ("rusted_hacksaw", 1.4, 0.0, 0)):
        import_model(asset, "1k", (cx, cy + dy, level + 0.0125), rot_z_deg=rot)
    low = put("WoodenTable_01", z, "px0", 1.8)
    on("wooden_crate_01", low, dpy=-0.4)
    on("handsaw_wood", low, dpy=0.45, rot=90)
    crate = put("wooden_crate_02", z, "px0", 7.6)
    on("hatchet", crate, rot=70)
    put("crowbar_01", z, "py0", 0.4, gap=0.03)
    fixture(z, M, "hanging_industrial_lamp")

    # Pasillo principal (plafón de cristal): repisas con una jarra, el león de bronce y una maqueta de galeón,
    # y una santa pequeña en su repisa, como un altarcito.
    shelf = made(wall_shelf(M, 0.5, 1.3), "ShelfMainW", "corridor_main_w", "py0", 1.5, gap=0.0)
    on("ceramic_vase_04", shelf, top=1.3125)
    shelf = made(wall_shelf(M, 0.5, 1.3), "ShelfMainW2", "corridor_main_w", "py1", -0.8, gap=0.0)
    on("lion_head", shelf, top=1.3125, rot=90)
    pic("cma:160885", "corridor_main_w", "py0", 2.5, 1.55, 0.45, "ebony")
    fixture("corridor_main_w", M, kind="plafon")
    shelf = made(wall_shelf(M, 0.45, 1.35), "Altar", "corridor_main_m", "py0", 1.9, gap=0.0)
    on("gothic_statue", shelf, top=1.3625, rot=-90, scale=0.15)
    pic("cma:109507", "corridor_main_m", "py0", 0.6, 1.6, 0.45)
    pic("cma:148965", "corridor_main_m", "py1", 3.4, 1.55, 0.38, "walnut")
    fixture("corridor_main_m", M, kind="plafon")
    shelf = made(wall_shelf(M, 0.7, 1.3), "ShipShelf", "corridor_main_e", "py0", -1.0, gap=0.0)
    on("dutch_ship_medium", shelf, top=1.3125, rot=-90, scale=0.02)
    pic("cma:151298", "corridor_main_e", "py1", 1.0, 1.55, 0.38, "silver")
    fixture("corridor_main_e", M, kind="plafon")
    # Pasillo lateral (tulipa): un Cristo muerto y una banqueta plegable.
    pic(441965, "corridor_side", "px0", 1.8, 1.55, 0.6)
    put("folding_wooden_stool", "corridor_side", "px1", 0.9, gap=0.05)
    pic("cma:148758", "corridor_side", "px1", 2.5, 1.6, 0.5)
    fixture("corridor_side", M, kind="tulip")
    # Pasillo de servicio (campana de tela): farol de aceite para los apagones y colgador con un sombrero.
    shelf = made(wall_shelf(M, 0.4, 1.35), "LanternShelf", "corridor_service_w", "py0", 3.0, gap=0.0)
    on("Lantern_01", shelf, top=1.3625)
    pic("cma:152006", "corridor_service_w", "py0", 4.5, 1.55, 0.4, "walnut")
    pic("cma:97155", "corridor_service_w", "py1", 2.7, 1.6, 0.45)
    fixture("corridor_service_w", M, kind="bell")
    made(peg_rail(M), "PegRail", "corridor_service_m", "py0", 1.0, gap=0.0)
    put("fishermans_hat", "corridor_service_m", "py0", 0.85, gap=0.03, z=1.5, rot=10)
    pic("cma:171296", "corridor_service_m", "py0", 4.6, 1.55, 0.4, "ebony")
    fixture("corridor_service_m", M, kind="bell")
    pic("cma:145450", "corridor_service_e", "py1", 1.9, 1.55, 0.45, "ebony")
    fixture("corridor_service_e", M, kind="bell")

    # Dormitorio 2: cama de hierro con crucifijo, banqueta con jarra de noche, armario ropero, silla tallada y maletas.
    z = "bedroom_2"
    put("old_bed_frame", z, "px1", -1.2)
    made(crucifix(M, 0.4, 1.55), "Crucifix", z, "px1", -1.2, gap=0.0)
    side = put("WoodenTable_02", z, "px1", -0.45, gap=0.03)
    on("ceramic_vase_01", side)
    made(wardrobe(M), "Wardrobe", z, "px0", -1.0)
    put("gallinera_chair", z, "py1", 2.0, gap=0.05)
    put("vintage_suitcase", z, "py1", 0.9, gap=0.05, rot=8)
    pic("cma:142472", z, "py0", -0.6, 1.55, 0.4)  # icono de la Virgen
    fixture(z, M, kind="fabric")

    # Baño: bañera de patas, inodoro de cisterna alta, lavabo de pie con espejo, cubo y globo de cristal.
    z = "bathroom"
    made(bathtub(M), "Bathtub", z, "py1", 1.05)
    made(toilet(M), "Toilet", z, "px1", -1.4)
    made(basin(M), "Basin", z, "px0", -1.6)
    made(mirror(M, 0.42, 0.55, 1.45), "BathMirror", z, "px0", -1.6, gap=0.0)
    put("wooden_bucket_02", z, "px1", -0.55, gap=0.05)
    fixture(z, M, kind="globe")

    # Dormitorio 3 (de niño): cama de día, mesa de estudio con ajedrez y lupa, silla, estantería con un caballo
    # de bronce y pizarra.
    z = "bedroom_3"
    put("vintage_day_bed", z, "py0", 1.3)
    desk = put("wooden_table_02", z, "px1", 0.9)
    on("chess_set", desk, dpy=-0.15, scale=0.6, rot=8)
    on("magnifying_glass_01", desk, dpy=0.35, rot=-30)
    free("painted_wooden_chair_01", 9.85, 6.4, rot=180)
    shelves = put("painted_wooden_shelves", z, "px0", 1.9)
    on("horse_head", shelves, rot=180, scale=0.7)
    put("standing_chalkboard_01", z, "py1", -0.6, gap=0.1)
    pic("cma:149768", z, "py0", 1.3, 1.65, 0.55, "walnut")  # san Juan, sobre la cama
    fixture(z, M, kind="drum")

    # Paso de la despensa: estantería, escoba, recogedor, cesto y lechera; lámpara de esmalte verde.
    z = "pantry_hall"
    put("Shelf_01", z, "px1", 1.6)
    put("wooden_broom", z, "px0", 0.5, gap=0.05)
    put("dustpan", z, "px0", 0.9, gap=0.05)
    put("wicker_basket_02", z, "px0", 1.6, gap=0.05)
    put("metal_jug", z, "px0", 2.3, gap=0.05)
    fixture(z, M, kind="enamel_green")

    # Galería: rueca, canapé pintado, plantas con su regadera, botas de agua, cubo de la colada y farol colgado.
    z = "gallery"
    put("spinning_wheel_01", z, "px0", -1.5, gap=0.05)
    pic("cma:136680", z, "px0", -1.5, 1.65, 0.5)  # san Jerónimo
    put("painted_wooden_sofa", z, "px1", 1.8)
    put("potted_plant_01", z, "py1", 0.5, gap=0.05)
    put("watering_can_metal_01", z, "py1", 1.1, gap=0.08, rot=30)
    put("planter_pot_clay", z, "py1", 2.45, gap=0.05)
    put("rubber_boots", z, "py0", 2.4, gap=0.05, scale=0.8)
    put("wooden_bucket_01", z, "px0", 0.6, gap=0.05)
    fixture(z, M, "Lantern_01", scale=1.3, cord=0.45)

    # Trastero (con los fusibles en el hito 4b): estantería con una caja de cartón, escalera, caja militar,
    # máscara de gas colgada, bidón, pala y muletas.
    z = "storage"
    rack = put("worn_metal_rack", z, "px1", 1.8)
    on("cardboard_box_01", rack, scale=0.8)
    put("wooden_ladder", z, "px0", 1.6, gap=0.05)
    put("wooden_military_crate", z, "py1", 0.72, gap=0.05)
    put("old_gas_mask", z, "px0", -0.5, gap=0.03, z=0.55)
    put("metal_jerrycan", z, "px0", 2.4, gap=0.05)
    put("rusted_spade_01", z, "px1", 2.6, gap=0.03)
    put("vintage_crutches_01", z, "px1", 0.7, gap=0.03)
    fixture(z, M, "pull_chain_light_socket")

    # Recibidor: banco bajo la Adoración, perchero, espejo sobre un arcón tallado con un busto, paragüero y farol.
    z = "entrance_hall"
    put("painted_wooden_bench", z, "px0", 1.6)
    pic(436200, z, "px0", 1.6, 1.6, 0.7)
    pic("cma:111435", z, "py0", 0.5, 1.6, 0.45)
    made(coat_rack(M), "CoatRack", z, None, (8.15, 13.2))
    made(mirror(M, 0.55, 0.85, 1.55), "HallMirror", z, "px1", 1.8, gap=0.0)
    chest = put("gallinera_table", z, "px1", 1.8)
    on("marble_bust_01", chest, rot=-20)
    made([give(cylinder("UmbrellaStand", 0.12, 0.55, (0, 0, 0.275), verts=20), M["brass"])], "UmbrellaStand", z, "px1", 0.6)
    fixture(z, M, "lantern_chandelier_01")

    # Fresquera: baldas a lo largo de la pared con conservas, queso, olla de barro y cebollas; barril de vino y
    # una ratonera; bombilla colgando del cable.
    z = "larder"
    lo_x, lo_y, hi_x, hi_y = interior(z)
    shelves = made(larder_shelves(M, hi_y - lo_y - 0.1), "LarderShelves", z, "px0", (hi_y - lo_y) / 2)
    sl, sh = bounds(shelves)
    for asset, level, dy in (("ceramic_pot", 0.5, -1.0), ("CheeseBox_01", 0.95, -0.4),
                             ("russian_food_cans_01", 0.95, 0.6), ("yellow_onion", 0.5, 0.3)):
        import_model(asset, "1k", ((sl.x + sh.x) / 2, (sl.y + sh.y) / 2 + dy, level + 0.0125))
    free("wine_barrel_01", 9.5, 13.05)
    free("mousetrap", 9.4, 10.7, rot=20)
    pic("cma:128393", z, "py1", 0.7, 1.65, 0.4, "ebony")  # bodegón con raya
    fixture(z, M, "lightbulb_01", cord=0.5)

    # Cocina: cocina económica con olla, cazo y tetera, fregadero bajo la ventana, alacena, mesa con dos sillas,
    # escurreplatos y una lámpara de esmalte blanco.
    z = "kitchen"
    rng = made(kitchen_range(M), "KitchenRange", z, "px1", 1.7, gap=0.01)
    on("pot_enamel_01", rng, dpy=0.25, top=0.81)
    on("brass_pan_01", rng, dpy=-0.3, rot=30, top=0.81)
    on("vintage_electric_kettle", rng, dpy=-0.05, dpx=0.1, top=0.81, scale=0.8)
    made(kitchen_sink(M), "KitchenSink", z, "py1", 2.03, gap=0.01)
    cab = put("painted_wooden_cabinet", z, "py0", -0.8)
    on("brass_pot_02", cab, dpx=-0.25)
    made(plate_rack(M), "PlateRack", z, "py0", 2.0, gap=0.0)
    table = free("painted_wooden_table", 12.0, 12.0, rot=90, scale=0.75)  # 2,4 m: tapaba las dos puertas
    chairs_around(table, "painted_wooden_chair_02", per_side=1, gap=0.25)
    on("wooden_cutting_board", table, dpx=-0.2)
    on("wooden_spoon", table, dpx=-0.15, rot=40)
    on("jug_01", table, dpx=0.3, scale=0.7)
    on("wooden_bowl_02", table, dpx=0.05, dpy=0.2)
    pic("cma:147607", z, "px0", 0.6, 1.6, 0.38, "walnut")  # bodegón con arenques
    fixture(z, M, kind="enamel")

    # Aseo de servicio: inodoro de tanque bajo, lavabo pequeño, banqueta y desatascador; cúpula de latón.
    z = "service_toilet"
    made(toilet(M, high_tank=False), "ServiceToilet", z, "py1", 1.4)
    made(basin(M, small=True), "ServiceBasin", z, "px1", 2.2)
    put("plunger", z, "py1", 2.0, gap=0.05)
    put("wooden_stool_02", z, "px0", 1.5, gap=0.05)
    fixture(z, M, kind="dome")

    floor_colliders()
    check_doors()


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
