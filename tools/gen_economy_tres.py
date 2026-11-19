"""Genera data/economy_run1.tres (specs/incremental_v2.md: árbol de 30 mejoras, 6 permanentes, eventos).

Uso: python tools/gen_economy_tres.py
Generadores: curva del ajuste del 2026-11-18 (cada generador suma Energía a cada clic). Mejoras: cada una
con su minuto objetivo; el coste es una primera pasada que el test de ritmo ajusta. El requisito de Energía
producida es 2 × el coste salvo que la mejora se abra por otra cosa (clics a mano, cintas, eventos, unidades).
"""

A = 6.0  # coste de los generadores: 15 × A^posición
B = 5.5  # escala de los generadores: 0,2 × B^posición
P = 0.4  # producción por segundo: P × 0,2 × B^posición
C = 0.03  # bono por clic (antes del multiplicador de clic): C × 0,2 × B^posición
THRESHOLD = 45_000_000.0
## Techo: la última mejora de cada run cuesta casi el umbral. Quien reinicia en cuanto puede no la alcanza;
## quien aguanta un poco más en la tele (más terror), sí (petición del usuario, 2026-11-19).
TECHO = 0.8 * THRESHOLD
TECHO_APPEARS = 0.2 * THRESHOLD
THRESHOLD_MULT = [1.0, 1.0, 1.0, 1.4]  # umbral de cada run (× THRESHOLD)

# id, clave, energía producida para aparecer
GENERATORS = [
    ("antenna", "GEN_ANTENNA", 0),
    ("valves", "GEN_VALVES", 4_800),
    ("audio_frequency", "GEN_AUDIO_FREQUENCY", 15_527),
    ("tuner", "GEN_TUNER", 52_114),
    ("remote", "GEN_REMOTE", 258_101),
    ("channel_3", "GEN_CHANNEL_3", 1_135_196),
]

CRIT = (0.0, 3.0)  # crítico de partida: probabilidad, multiplicador
PACKAGE_BAR = 300.0  # clics a mano por cinta
PACKAGE_SECONDS = (8, 24)  # premio de la común y la rara, en segundos de ingresos

def machine_cost(position: int, units: int) -> int:
    """Mejora de máquina: 4 veces lo que cuesta la unidad número units de ese generador."""
    return round(4 * 15 * A ** position * 1.15 ** (units - 1))


# UpgradeDef.Kind
GEN_MULT, CLICK_MULT, HOLD, SHARE, AUTO, CRIT_CHANCE, CRIT_MULT, COMBO, MANUAL_MULT, PER_OWNED, \
    GEN_CLICK_MULT, SYNERGY, PKG_UNLOCK, PKG_RATE, PKG_RARITY, PKG_REWARD, EVENT_REWARD, SKILL, ECHO, PROD_MULT = range(20)

# id, kind, coste, padre, celda (columna, fila), icono, campos extra.
# Celdas: rejilla de 10 × 5 en la tele; los generadores van en la fila 2, columnas 0-5.
UPGRADES = [
    # P: pulso a mano
    ("pulse", CLICK_MULT, 5, "", (0, 0), "pulse", {"value": 2.0, "req_energy": 0}),
    ("bare_cable", CRIT_CHANCE, 175, "pulse", (1, 0), "crit", {"value": 0.08}),
    ("discharge", CRIT_MULT, 4_000, "bare_cable", (2, 0), "pulse_strong", {"value": 4.0, "req_manual_clicks": 400}),
    ("no_ground", CRIT_CHANCE, TECHO, "discharge", (3, 0), "crit", {"run": 2, "value": 0.04, "req_manual_clicks": 1500}),
    ("heartbeat", COMBO, 500, "bare_cable", (1, 1), "combo", {"value": 1.2}),
    ("tachycardia", COMBO, 19_000, "heartbeat", (2, 1), "combo", {"value": 1.35}),
    ("every_antenna", PER_OWNED, 3_500, "bare_cable", (3, 1), "listen", {"value": 0.003}),
    ("resonance", SHARE, 6_000, "every_antenna", (4, 1), "resonance", {"value": 0.02}),
    # D: dial automático
    ("dial_hold", HOLD, 61, "", (5, 0), "dial_hold", {"value": 6.0}),
    ("dial_auto", AUTO, 56_500, "dial_hold", (6, 0), "dial_auto", {"value": 2.0}),
    ("echo", ECHO, 2_000_000, "dial_auto", (7, 0), "echo", {"req_energy": 400_000}),
    ("dial_auto_2", AUTO, TECHO, "echo", (8, 0), "dial_auto_2", {"run": 4, "req_energy": TECHO_APPEARS, "value": 4.0}),
    # H: habilidades del mando
    ("sweep", SKILL, 3_000, "dial_hold", (6, 1), "sweep", {"run": 2, "skill": "sweep", "duration": 10.0, "cooldown": 180.0}),
    ("surge", SKILL, 12_000, "sweep", (7, 1), "surge",
     {"run": 2, "skill": "surge", "value": 3.0, "duration": 12.0, "cooldown": 240.0}),
    ("seek", SKILL, 150_000, "surge", (8, 1), "seek", {"run": 2, "skill": "seek", "cooldown": 300.0}),
    ("overload", SKILL, 9_000_000, "seek", (9, 1), "overload",
     {"run": 4, "skill": "overload", "value": 5.0, "value2": 8.0, "duration": 20.0, "cooldown": 300.0, "warning": True}),
    # C: cintas
    ("tuning", PKG_UNLOCK, 1_500, "", (6, 2), "tape", {}),
    ("tuning_fine", PKG_RATE, 8_000, "tuning", (7, 2), "tape", {"value": 0.75, "req_packages": 3}),
    ("blank_tape", PKG_RARITY, 11_000, "tuning_fine", (8, 2), "tape_rare",
     {"value": 0.25, "value2": 0.06, "req_packages": 6}),
    ("double_deck", PKG_REWARD, 200_000, "blank_tape", (9, 2), "tape", {"run": 2, "value": 1.5}),
    ("unlabeled_tape", PKG_RARITY, 6_000_000, "double_deck", (9, 3), "tape_black", {"run": 3, "value": 0.25, "value2": 0.12}),
    # M: máquinas
    ("antenna_tune", GEN_MULT, 180, "antenna", (0, 3), "antenna",
     {"target": "antenna", "value": 2.0, "req_generator_count": 10}),
    ("valves_hot", GEN_CLICK_MULT, 1_080, "valves", (1, 3), "valves",
     {"target": "valves", "value": 3.0, "req_generator_count": 10}),
    ("feedback", SYNERGY, 6_480, "audio_frequency", (2, 3), "audio_frequency",
     {"target": "audio_frequency", "source": "valves", "value": 0.03, "req_generator_count": 10}),
    ("tuner_double", GEN_MULT, 38_880, "tuner", (3, 3), "tuner",
     {"target": "tuner", "value": 2.0, "req_generator_count": 10}),
    ("zapping", SYNERGY, TECHO, "remote", (4, 3), "remote",
     {"source": "remote", "value": 0.02, "req_energy": TECHO_APPEARS}),  # sin target: todas las máquinas
    # M: ×2 de cada máquina al tener muchas (GDD §4: 10 y 25; frecuencia, mandos y Canal 3, 20); rellenan la segunda
    # mitad de la run 1.
    ("antenna_25", GEN_MULT, machine_cost(0, 25), "antenna_tune", (0, 4), "antenna",
     {"target": "antenna", "value": 2.0, "req_generator_count": 25}),
    ("valves_25", GEN_MULT, machine_cost(1, 25), "valves_hot", (1, 4), "valves",
     {"target": "valves", "value": 2.0, "req_generator_count": 25}),
    ("audio_20", GEN_MULT, machine_cost(2, 20), "feedback", (2, 4), "audio_frequency",
     {"target": "audio_frequency", "value": 2.0, "req_generator_count": 20}),
    ("remote_10", GEN_MULT, machine_cost(4, 10), "remote", (5, 1), "remote",
     {"target": "remote", "value": 2.0, "req_generator_count": 10}),
    ("remote_20", GEN_MULT, machine_cost(4, 20), "remote_10", (4, 0), "remote",
     {"target": "remote", "value": 2.0, "req_generator_count": 20}),
    ("channel_3_10", GEN_MULT, machine_cost(5, 10), "channel_3", (5, 3), "channel_3",
     {"target": "channel_3", "value": 2.0, "req_generator_count": 9}),  # a las 9: con 10 quedaba un hueco de 2,6 min
    ("channel_3_20", GEN_MULT, machine_cost(5, 20), "channel_3_10", (5, 4), "channel_3",
     {"target": "channel_3", "value": 2.0, "req_generator_count": 20}),
    # X: consumo
    ("bypass", PROD_MULT, 45_000, "tuner_double", (3, 4), "meter", {"run": 3, "value": 1.5, "warning": True}),
    ("divert", PROD_MULT, TECHO, "bypass", (4, 4), "meter", {"run": 3, "req_energy": TECHO_APPEARS, "value": 2.0, "warning": True}),
    # E: eventos
    ("sharp_eye", EVENT_REWARD, 5_200, "", (6, 4), "eye", {"value": 1.5, "value2": 0.75, "req_events_caught": 1}),
    # Rama escondida: solo existe con Tus ojos (petición del usuario, 2026-11-19).
    ("ghost_image", EVENT_REWARD, 30_000, "sharp_eye", (6, 3), "eye", {"perk": "eyes", "value": 3.0}),
    ("ghost_hands", MANUAL_MULT, 400_000, "ghost_image", (7, 3), "pulse_strong", {"perk": "eyes", "value": 3.0}),
    ("ghost_signal", PROD_MULT, 8_000_000, "ghost_hands", (8, 3), "meter", {"perk": "eyes", "value": 2.5}),
]

# Mejoras permanentes (specs/incremental_v2.md §4), en cualquier orden: id, clave, coste, PerkDef.Kind, datos.
PERKS = [
    ("memory", "PERK_MEMORY", 2, 1,
     'upgrade_ids = Array[StringName]([&"pulse", &"dial_hold", &"bare_cable", &"antenna_tune"])\n'
     'generators = {&"antenna": 15, &"valves": 10, &"audio_frequency": 5}'),
    ("hands", "PERK_HANDS", 2, 5, "value = 3.0\nvalue2 = 0.03"),
    ("eyes", "PERK_EYES", 3, 6, "value = 60.0\nvalue2 = 120.0"),
    ("habit", "PERK_HABIT", 3, 2, "value = 0.65\nvalue2 = 0.5"),
    ("pulse", "PERK_PULSE", 3, 3, "value = 1.4"),
    ("name", "PERK_NAME", 4, 7, "value = 1.2"),
]

# Eventos de la tele: id, peso, duración (s), recompensa (s de ingresos, clics mínimos), multiplicador.
EVENTS = [
    ("interference", 4, 8, 10, 50, 1),
    ("shooting_star", 3, 5, 6, 25, 1),
    ("clear_signal", 2, 20, 0, 0, 2),
]


def num(x: float) -> str:
    return repr(float(x))


def upgrade_block(uid, kind, cost, parent, cell, icon, extra):
    key = "UPG_" + uid.upper()
    req_energy = extra.get("req_energy", 0 if any(k.startswith("req_") for k in extra) else 2 * cost)
    target = extra.get("target", "")
    lines = [
        f'[sub_resource type="Resource" id="upg_{uid}"]',
        'script = ExtResource("upg_script")',
        f'id = &"{uid}"',
        f'name_key = "{key}"',
        f'desc_key = "{key}_DESC"',
        f"kind = {kind}",
        f'target_id = &"{target}"',
        f"value = {num(extra.get('value', 1.0))}",
        f"value2 = {num(extra.get('value2', 1.0))}",
        f"cost = {num(cost)}",
        f"req_energy_produced = {num(req_energy)}",
        f"req_generator_count = {extra.get('req_generator_count', 0)}",
        f"req_manual_clicks = {extra.get('req_manual_clicks', 0)}",
        f"req_packages = {extra.get('req_packages', 0)}",
        f"req_events_caught = {extra.get('req_events_caught', 0)}",
        f"req_run = {extra.get('run', 1)}",
        f'req_perk = &"{extra.get("perk", "")}"',
        f'requires_id = &"{parent}"',
        f'skill = &"{extra.get("skill", "")}"',
        f"duration = {num(extra.get('duration', 0.0))}",
        f"cooldown = {num(extra.get('cooldown', 0.0))}",
        f'source_id = &"{extra.get("source", "")}"',
        f"tree_cell = Vector2i({cell[0]}, {cell[1]})",
        f'icon = &"{icon}"',
        f'warning_key = "{"UPG_WARNING" if extra.get("warning") else ""}"',
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    subs = []
    gen_ids = []
    for i, (gid, key, req) in enumerate(GENERATORS):
        sid = f"gen_{gid}"
        gen_ids.append(sid)
        subs.append(
            f'[sub_resource type="Resource" id="{sid}"]\n'
            f'script = ExtResource("gen_script")\n'
            f'id = &"{gid}"\n'
            f'name_key = "{key}"\n'
            f"base_cost = {num(round(15 * A ** i))}\n"
            f"base_production = {num(P * 0.2 * B ** i)}\n"
            f"click_bonus = {num(C * 0.2 * B ** i)}\n"
            f"req_energy_produced = {num(req)}\n"
            # La cadena de generadores solo se dibuja en el árbol: exigir el anterior retrasa al jugador tranquilo.
            'requires_id = &""\n'
        )
    upg_ids = []
    for uid, kind, cost, parent, cell, icon, extra in UPGRADES:
        upg_ids.append(f"upg_{uid}")
        subs.append(upgrade_block(uid, kind, cost, parent, cell, icon, extra))
    perk_ids = []
    for pid, key, cost, kind, data in PERKS:
        sid = f"perk_{pid}"
        perk_ids.append(sid)
        subs.append(
            f'[sub_resource type="Resource" id="{sid}"]\n'
            f'script = ExtResource("perk_script")\n'
            f'id = &"{pid}"\n'
            f'name_key = "{key}"\n'
            f'desc_key = "{key}_DESC"\n'
            f"cost = {cost}\n"
            f"kind = {kind}\n"
            + (f"{data}\n" if data else "")
        )
    event_ids = []
    for eid, weight, duration, reward_s, reward_clicks, mult in EVENTS:
        sid = f"evt_{eid}"
        event_ids.append(sid)
        subs.append(
            f'[sub_resource type="Resource" id="{sid}"]\n'
            f'script = ExtResource("evt_script")\n'
            f'id = &"{eid}"\n'
            f"weight = {num(weight)}\n"
            f"duration = {num(duration)}\n"
            f"reward_production_seconds = {num(reward_s)}\n"
            f"reward_min_clicks = {num(reward_clicks)}\n"
            f"production_mult = {num(mult)}\n"
        )
    steps = 5 + len(subs) + 1
    out = [
        f'[gd_resource type="Resource" script_class="EconomyConfig" load_steps={steps} format=3]\n',
        '[ext_resource type="Script" path="res://core/economy_config.gd" id="config_script"]',
        '[ext_resource type="Script" path="res://core/generator_def.gd" id="gen_script"]',
        '[ext_resource type="Script" path="res://core/upgrade_def.gd" id="upg_script"]',
        '[ext_resource type="Script" path="res://core/tv_event_def.gd" id="evt_script"]',
        '[ext_resource type="Script" path="res://core/perk_def.gd" id="perk_script"]\n',
        "\n".join(subs),
        "[resource]",
        'script = ExtResource("config_script")',
        "generators = Array[ExtResource(\"gen_script\")]([" + ", ".join(f'SubResource("{s}")' for s in gen_ids) + "])",
        "upgrades = Array[ExtResource(\"upg_script\")]([" + ", ".join(f'SubResource("{s}")' for s in upg_ids) + "])",
        "cost_growth = 1.15",
        f"threshold = {num(THRESHOLD)}",
        "threshold_mult = Array[float]([" + ", ".join(num(x) for x in THRESHOLD_MULT) + "])",
        "base_click_value = 1.0",
        "events = Array[ExtResource(\"evt_script\")]([" + ", ".join(f'SubResource("{s}")' for s in event_ids) + "])",
        "perks = Array[ExtResource(\"perk_script\")]([" + ", ".join(f'SubResource("{s}")' for s in perk_ids) + "])",
        f"crit_chance = {num(CRIT[0])}",
        f"crit_mult = {num(CRIT[1])}",
        f"package_bar = {num(PACKAGE_BAR)}",
        f"package_seconds = Vector2({PACKAGE_SECONDS[0]}, {PACKAGE_SECONDS[1]})",
        "event_min = 120.0",
        "event_max = 240.0",
        "",
    ]
    with open("data/economy_run1.tres", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    main()
