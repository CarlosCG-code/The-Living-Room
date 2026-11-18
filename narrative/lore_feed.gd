class_name LoreFeed
extends RefCounted

## Qué fragmentos tocan al pasar de prev_ratio a ratio en esta run (en orden). Función pura: sin estado ni
## guardado; al cargar una partida se empieza desde el ratio actual y no se repite nada.
static func due(fragments: Array, run: int, prev_ratio: float, ratio: float, perks: Array[StringName]) -> Array:
	var out := []
	for f: LoreFragmentDef in fragments:
		if f.run != run or f.ratio <= prev_ratio or f.ratio > ratio:
			continue
		if f.needs_perk != &"" and not perks.has(f.needs_perk):
			continue
		out.append(f)
	out.sort_custom(func(a: LoreFragmentDef, b: LoreFragmentDef) -> bool: return a.ratio < b.ratio)
	return out


## Ratios de una run, para el test de ritmo (cuentan como algo nuevo en la tele).
static func ratios(fragments: Array, run: int) -> Array[float]:
	var out: Array[float] = []
	for f: LoreFragmentDef in fragments:
		if f.run == run and f.needs_perk == &"":
			out.append(f.ratio)
	return out
