"""Genera data/economy_run1.tres con los valores del ajuste del ritmo (specs/hito1.md §3.5, §6 paso 3).

Uso: python tools/gen_economy_tres.py
Los valores salen del ajuste del 2026-11-17 (calendario de apariciones «variante I»): cada novedad de la
tienda tiene un minuto objetivo y su requisito de Energía producida la coloca ahí.
"""

A = 6.0  # coste de los generadores: 15 × A^posición
B = 5.5  # producción de los generadores: 0,2 × B^posición
THRESHOLD = 6_986_879.0

# id, clave, energía producida para aparecer
GENERATORS = [
    ("antenna", "GEN_ANTENNA", 0),
    ("valves", "GEN_VALVES", 5_100),
    ("audio_frequency", "GEN_AUDIO_FREQUENCY", 20_221),
    ("tuner", "GEN_TUNER", 71_607),
    ("remote", "GEN_REMOTE", 280_547),
    ("channel_3", "GEN_CHANNEL_3", 1_009_196),
]
GEN_UPGRADE_COST = {10: 12, 25: 120}  # × coste base
# Energía producida que piden además las mejoras ×2 (sin entrada: 0), para repartirlas en los huecos.
GEN_UPGRADE_REQ = {
    "antenna_x2_10": 791, "antenna_x2_25": 2_372,
    "valves_x2_10": 6_793, "valves_x2_25": 202_144,
    "audio_frequency_x2_10": 28_171, "audio_frequency_x2_25": 52_332,
    "tuner_x2_10": 102_521, "tuner_x2_25": 549_007,
    "remote_x2_10": 688_846,
}

# Kind: 0 GENERATOR_MULT, 1 CLICK_MULT, 2 HOLD_RATE, 3 CLICK_PRODUCTION_SHARE, 4 AUTO_CLICK_RATE
# id, clave, kind, value, cost, req_energy_produced
CLICK_UPGRADES = [
    ("pulse", "UPG_PULSE", 1, 2.0, 5, 0),
    ("dial_hold", "UPG_DIAL_HOLD", 2, 4.0, 38, 76),
    ("pulse_strong", "UPG_PULSE_STRONG", 1, 2.0, 4_857, 9_715),
    ("resonance", "UPG_RESONANCE", 3, 0.02, 19_333, 38_666),
    ("dial_auto", "UPG_DIAL_AUTO", 4, 2.0, 71_004, 142_009),
    ("dial_auto_2", "UPG_DIAL_AUTO_2", 4, 5.0, 220_434, 440_868),
]


def num(x: float) -> str:
    return repr(float(x))


def main() -> None:
    subs = []
    gen_ids = []
    upg_ids = []
    for i, (gid, key, req) in enumerate(GENERATORS):
        base_cost = 15 * A ** i
        sid = f"gen_{gid}"
        gen_ids.append(sid)
        subs.append(
            f'[sub_resource type="Resource" id="{sid}"]\n'
            f'script = ExtResource("gen_script")\n'
            f'id = &"{gid}"\n'
            f'name_key = "{key}"\n'
            f"base_cost = {num(round(base_cost))}\n"
            f"base_production = {num(0.2 * B ** i)}\n"
            f"req_energy_produced = {num(req)}\n"
        )
    for gid, _key, _req in GENERATORS:
        i = [g[0] for g in GENERATORS].index(gid)
        base_cost = round(15 * A ** i)
        for count, factor in GEN_UPGRADE_COST.items():
            uid = f"{gid}_x2_{count}"
            sid = f"upg_{uid}"
            upg_ids.append(sid)
            subs.append(
                f'[sub_resource type="Resource" id="{sid}"]\n'
                f'script = ExtResource("upg_script")\n'
                f'id = &"{uid}"\n'
                f'name_key = "UPG_GEN_X2_{count}"\n'
                f'desc_key = "UPG_GEN_X2_DESC"\n'
                f"kind = 0\n"
                f'target_id = &"{gid}"\n'
                f"value = 2.0\n"
                f"cost = {num(base_cost * factor)}\n"
                f"req_energy_produced = {num(GEN_UPGRADE_REQ.get(uid, 0))}\n"
                f"req_generator_count = {count}\n"
            )
    for uid, key, kind, value, cost, req in CLICK_UPGRADES:
        sid = f"upg_{uid}"
        upg_ids.append(sid)
        subs.append(
            f'[sub_resource type="Resource" id="{sid}"]\n'
            f'script = ExtResource("upg_script")\n'
            f'id = &"{uid}"\n'
            f'name_key = "{key}"\n'
            f'desc_key = "{key}_DESC"\n'
            f"kind = {kind}\n"
            f"value = {num(value)}\n"
            f"cost = {num(cost)}\n"
            f"req_energy_produced = {num(req)}\n"
            f"req_generator_count = 0\n"
        )
    steps = 3 + len(subs) + 1
    out = [
        f'[gd_resource type="Resource" script_class="EconomyConfig" load_steps={steps} format=3]\n',
        '[ext_resource type="Script" path="res://core/economy_config.gd" id="config_script"]',
        '[ext_resource type="Script" path="res://core/generator_def.gd" id="gen_script"]',
        '[ext_resource type="Script" path="res://core/upgrade_def.gd" id="upg_script"]\n',
        "\n".join(subs),
        "[resource]",
        'script = ExtResource("config_script")',
        "generators = Array[ExtResource(\"gen_script\")]([" + ", ".join(f'SubResource("{s}")' for s in gen_ids) + "])",
        "upgrades = Array[ExtResource(\"upg_script\")]([" + ", ".join(f'SubResource("{s}")' for s in upg_ids) + "])",
        "cost_growth = 1.15",
        f"threshold = {num(THRESHOLD)}",
        "base_click_value = 1.0",
        "interference_min = 120.0",
        "interference_max = 240.0",
        "interference_duration = 8.0",
        "reward_production_seconds = 15.0",
        "reward_min_clicks = 50.0",
        "",
    ]
    with open("data/economy_run1.tres", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    main()
