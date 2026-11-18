"""Genera data/lore.tres y las claves LORE_* de locale/strings.csv (specs/incremental_v2.md §7).

Uso: python tools/gen_lore_tres.py
Dos hilos que se cruzan con la señal de la tele:
- «[3.º]»: la rutina de la señora del 3.º (pastillas, gafas, dentadura). Se lee amable la primera vez y
  se entiende al final (GDD §2: frases con dos lecturas; las reglas no se dicen, se intuyen).
- «RÉCORDS»: una tabla de puntuaciones con reinicios que no paran de subir y una línea vacía. Con la
  permanente «Tu nombre», la línea vacía pasa a ser la tuya.
Los ratios están repartidos en escala logarítmica: la Energía crece deprisa al final y así salen a lo largo
de toda la run; los que pasan de 1 solo los ve quien espera para reiniciar.
"""
import csv

# run, ratio, texto, permanente necesaria
LORE = [
    (1, 0.0005, "[3.º] Las de las ocho. Siempre con agua, nunca con leche.", ""),
    (1, 0.003, "[3.º] ¿Has visto mis gafas? Las dejé al lado de la tele.", ""),
    (1, 0.02, "RECORDS  1. A. FERRER ...... 212 reinicios", ""),
    (1, 0.08, "[3.º] Qué bien se ve desde aquí. Mejor que en mi piso.", ""),
    (1, 0.25, "RECORDS  2. M. ORTEGA ...... 97   3. J. LLORENTE ...... 40", ""),
    (1, 0.6, "[3.º] No te levantes, hijo. Ya voy yo.", ""),
    (1, 1.0, "RECORDS  4. ______________ ...... 0", ""),
    (1, 1.6, "[3.º] Antes venías tan rápido cuando algo se estropeaba...", ""),
    (1, 2.5, "[3.º] Gracias por quedarte. De verdad.", ""),
    (1, 4.0, "[3.º] Si te quedas un poco más, ya no hace falta que vuelvas.", ""),
    (2, 0.003, "[3.º] Se ha ido la luz otra vez. ¿Tú tienes linterna?", ""),
    (2, 0.05, "RECORDS  1. A. FERRER ...... 213 reinicios", ""),
    (2, 0.25, "[3.º] Mis gafas estaban del otro lado. Todo está del otro lado.", ""),
    (2, 0.75, "[3.º] Cada vez que vuelves, la casa se parece más a ti.", ""),
    (2, 1.0, "RECORDS  4. ______________ ...... 1", ""),
    (2, 1.0, "RECORDS  4. TU ...... 1 reinicio", "name"),
    (2, 2.5, "[3.º] No reinicies todavía. Aún no he terminado de hablar.", ""),
    (3, 0.003, "[3.º] La dentadura en el vaso. El vaso en la mesa. La mesa en tu salón.", ""),
    (3, 0.05, "RECORDS  1. A. FERRER ...... 214 reinicios", ""),
    (3, 0.25, "[3.º] El ascensor no funciona. Pero tú siempre subes por la escalera.", ""),
    (3, 0.75, "[3.º] Te dejé la tele encendida. Para que no estuvieras solo.", ""),
    (3, 1.0, "RECORDS  4. ______________ ...... 2", ""),
    (3, 1.0, "RECORDS  4. TU ...... 2 reinicios", "name"),
    (3, 2.5, "[3.º] Yo también pulsé el botón. Muchas veces.", ""),
    (4, 0.003, "[3.º] Ya casi está. Siéntate donde me sentaba yo.", ""),
    (4, 0.05, "RECORDS  1. A. FERRER ...... ya no", ""),
    (4, 0.25, "[3.º] La tele no se apaga. Solo cambia quién la mira.", ""),
    (4, 0.75, "[3.º] Perdóname.", ""),
    (4, 1.0, "RECORDS  1. ______________ ...... 3", ""),
    (4, 1.0, "RECORDS  1. TU ...... 3 reinicios", "name"),
]


def main() -> None:
    subs = []
    ids = []
    keys = {}
    counters = {}
    for run, ratio, text, perk in LORE:
        counters[run] = counters.get(run, 0) + 1
        key = "LORE_R%d_%02d" % (run, counters[run])
        keys[key] = text
        sid = key.lower()
        ids.append(sid)
        subs.append(
            f'[sub_resource type="Resource" id="{sid}"]\n'
            'script = ExtResource("lore_script")\n'
            f"run = {run}\n"
            f"ratio = {float(ratio)!r}\n"
            f'text_key = "{key}"\n'
            f'needs_perk = &"{perk}"\n'
        )
    out = [
        f'[gd_resource type="Resource" load_steps={len(subs) + 2} format=3]\n',
        '[ext_resource type="Script" path="res://narrative/lore_fragment_def.gd" id="lore_script"]\n',
        "\n".join(subs),
        "[resource]",
        'metadata/fragments = [' + ", ".join(f'SubResource("{s}")' for s in ids) + "]",
        "",
    ]
    with open("data/lore.tres", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    p = "locale/strings.csv"
    rows = [r for r in csv.reader(open(p, encoding="utf-8")) if not r[0].startswith("LORE_")]
    rows += [[k, v] for k, v in keys.items()]
    with open(p, "w", encoding="utf-8", newline="") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)


if __name__ == "__main__":
    main()
