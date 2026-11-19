class_name NumberFormat
extends RefCounted


## Energía y costes: entero truncado con punto de miles (12.345).
static func energy(x: float) -> String:
	return _group(int(floorf(maxf(x, 0.0))))


## Producción por segundo: 1 decimal con coma por debajo de 100; entero redondeado con punto de miles desde 100.
static func rate(x: float) -> String:
	var rounded := snappedf(maxf(x, 0.0), 0.1)
	if rounded < 100.0:
		return ("%.1f" % rounded).replace(".", ",") + "/s"
	return _group(int(roundf(x))) + "/s"


## Energía por clic: 2 decimales con coma por debajo de 10 (los bonos de las primeras compras son pequeños);
## entero con punto de miles desde 10.
static func per_click(x: float) -> String:
	var v := maxf(x, 0.0)
	if snappedf(v, 0.01) < 10.0:
		return ("%.2f" % v).replace(".", ",")
	return _group(int(roundf(v)))


## Cifra corta para textos estrechos del OSD: 950 · 12,3 K · 112 M · 1,5 G.
static func short(x: float) -> String:
	var v := maxf(x, 0.0)
	for unit: Array in [[1e12, "T"], [1e9, "G"], [1e6, "M"], [1e3, "K"]]:
		if v >= unit[0]:
			var n: float = floorf(v / unit[0] * 10.0) / 10.0
			return (("%.1f" % n).replace(".", ",") if n < 100.0 else str(int(n))) + " " + unit[1]
	return _group(int(floorf(v)))


static func _group(n: int) -> String:
	var digits := str(n)
	var out := ""
	while digits.length() > 3:
		out = "." + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out
