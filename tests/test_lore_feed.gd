extends GutTest

const LORE := preload("res://data/lore.tres")


func _frag(run: int, ratio: float, perk: StringName = &"") -> LoreFragmentDef:
	var f := LoreFragmentDef.new()
	f.run = run
	f.ratio = ratio
	f.text_key = "K%s" % ratio
	f.needs_perk = perk
	return f


func test_due_only_crossed_ratios_of_this_run_in_order() -> void:
	var fr := [_frag(1, 0.5), _frag(1, 0.1), _frag(2, 0.2), _frag(1, 0.9)]
	var due := LoreFeed.due(fr, 1, 0.05, 0.6, [] as Array[StringName])
	assert_eq(due.size(), 2)
	assert_eq(due[0].ratio, 0.1)
	assert_eq(due[1].ratio, 0.5)
	assert_eq(LoreFeed.due(fr, 1, 0.5, 0.6, [] as Array[StringName]).size(), 0, "lo ya pasado no se repite")


func test_perk_gated_fragment() -> void:
	var fr := [_frag(2, 1.0, &"name")]
	assert_eq(LoreFeed.due(fr, 2, 0.9, 1.1, [] as Array[StringName]).size(), 0)
	assert_eq(LoreFeed.due(fr, 2, 0.9, 1.1, [&"name"] as Array[StringName]).size(), 1, "con Tu nombre, la tabla te reconoce")


func test_every_fragment_is_translated_and_each_run_has_lore() -> void:
	var fragments: Array = LORE.get_meta(&"fragments")
	for f: LoreFragmentDef in fragments:
		assert_ne(tr(f.text_key), f.text_key, "traducción de %s" % f.text_key)
	for run in range(1, 5):
		assert_gt(LoreFeed.ratios(fragments, run).size(), 3, "la run %d tiene fragmentos" % run)
