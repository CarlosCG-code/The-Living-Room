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


static func _group(n: int) -> String:
	var digits := str(n)
	var out := ""
	while digits.length() > 3:
		out = "." + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out
