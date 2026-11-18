"""Genera data/lore.tres y las claves LORE_* de locale/strings.csv (specs/incremental_v2.md §7).

Uso: python tools/gen_lore_tres.py
Dos hilos que se cruzan con la señal de la tele:
- «[PISO 3]»: la rutina de la señora del 3.º (pastillas, gafas, dentadura). Se lee amable la primera vez y
  se entiende al final (GDD §2: frases con dos lecturas; las reglas no se dicen, se intuyen).
- «MARCAS»: una tabla de puntuaciones con reinicios que no paran de subir y una línea vacía. Con la
  permanente «Tu nombre», la línea vacía pasa a ser la tuya.
Los ratios están repartidos en escala logarítmica: la Energía crece deprisa al final y así salen a lo largo
de toda la run; los que pasan de 1 solo los ve quien espera para reiniciar.
La fuente pixelada no tiene «º» ni mayúsculas con tilde: «PISO 3», «MARCAS», «USTED».
"""
import csv

# run, ratio, texto, permanente necesaria
LORE = [
    (1, 0.0005, "[PISO 3] Las de las ocho. Siempre con agua, nunca con leche.", ""),
    (1, 0.003, "[PISO 3] ¿Has visto mis gafas? Las dejé al lado de la tele.", ""),
    (1, 0.02, "MARCAS  1. A. FERRER ...... 212 reinicios", ""),
    (1, 0.08, "[PISO 3] Qué bien se ve desde aquí. Mejor que en mi piso.", ""),
    (1, 0.25, "MARCAS  2. M. ORTEGA ...... 97   3. J. LLORENTE ...... 40", ""),
    (1, 0.6, "[PISO 3] No te levantes, hijo. Ya voy yo.", ""),
    (1, 1.0, "MARCAS  4. ______________ ...... 0", ""),
    (1, 1.6, "[PISO 3] Antes venías tan rápido cuando algo se estropeaba...", ""),
    (1, 2.5, "[PISO 3] Gracias por quedarte. De verdad.", ""),
    (1, 4.0, "[PISO 3] Si te quedas un poco más, ya no hace falta que vuelvas.", ""),
    (2, 0.003, "[PISO 3] Se ha ido la luz otra vez. ¿Tú tienes linterna?", ""),
    (2, 0.05, "MARCAS  1. A. FERRER ...... 213 reinicios", ""),
    (2, 0.25, "[PISO 3] Si algo se ve raro, no toques nada. Ya te llamaré.", ""),
    (2, 0.75, "[PISO 3] Mis gafas estaban del otro lado. Todo está del otro lado.", ""),
    (2, 1.0, "MARCAS  4. ______________ ...... 1", ""),
    (2, 1.0, "MARCAS  4. USTED ...... 1 reinicio", "name"),
    (2, 2.5, "[PISO 3] Tranquilo, sin prisa. Yo llevo mucho tiempo esperando.", ""),
    (3, 0.003, "[PISO 3] La dentadura en el vaso. El vaso en la mesa. La mesa en tu salón.", ""),
    (3, 0.05, "MARCAS  1. A. FERRER ...... 214 reinicios", ""),
    (3, 0.25, "[PISO 3] El ascensor lleva días roto. Si te llamo, baja por la escalera.", ""),
    (3, 0.75, "[PISO 3] Me alegra que la tele te haga compañía.", ""),
    (3, 1.0, "MARCAS  4. ______________ ...... 2", ""),
    (3, 1.0, "MARCAS  4. USTED ...... 2 reinicios", "name"),
    (3, 2.5, "[PISO 3] Yo también me quedaba despierta con la tele. Muchas noches.", ""),
    (4, 0.003, "[PISO 3] Ya casi está. Siéntate donde me sentaba yo.", ""),
    (4, 0.05, "MARCAS  1. A. FERRER ...... ya no", ""),
    (4, 0.25, "[PISO 3] Esta tele ya estaba aquí cuando me mudé.", ""),
    (4, 0.75, "[PISO 3] Siento haberte hecho bajar tan tarde.", ""),
    (4, 1.0, "MARCAS  1. ______________ ...... 3", ""),
    (4, 1.0, "MARCAS  1. USTED ...... 3 reinicios", "name"),
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
