extends GutTest

# Secuencias de transición (specs/hito4b.md D1, D8): reglas puras, tiempos con tick() y cómo para Game.

var _saved: RunState


func before_each() -> void:
	_saved = Game.economy.state
	Game.economy.state = RunState.new_run(Game.economy.config, 2, RandomNumberGenerator.new())
	Game.economy._recalc()


func after_each() -> void:
	Game.running = false
	Game.economy.state = _saved
	Game.economy._recalc()


func test_after_restart() -> void:
	assert_eq(Sequence.after_restart(1), Sequence.NEIGHBOR)
	assert_eq(Sequence.after_restart(2), Sequence.BLACKOUT)
	assert_eq(Sequence.after_restart(3), &"")
	assert_eq(Sequence.first_step(Sequence.NEIGHBOR), &"knock")
	assert_eq(Sequence.first_step(Sequence.BLACKOUT), &"dark")
	assert_eq(Sequence.first_step(&""), &"")


func test_next() -> void:
	var n := Sequence.NEIGHBOR
	var b := Sequence.BLACKOUT
	assert_eq(Sequence.next(n, &"knock", &"handed_over"), &"free")
	assert_eq(Sequence.next(n, &"knock", &"sat"), &"knock", "con el vecino en la puerta, sentarse no cuenta")
	assert_eq(Sequence.next(n, &"free", &"sat"), &"")
	assert_eq(Sequence.next(b, &"dark", &"fuse_fixed"), &"fixed")
	assert_eq(Sequence.next(b, &"dark", &"sat"), &"dark", "a oscuras, sentarse no acaba el apagón")
	assert_eq(Sequence.next(b, &"fixed", &"sat"), &"")
	assert_eq(Sequence.next(n, &"fixed", &"sat"), &"fixed", "un paso de otra secuencia no avanza")


func test_resumes_standing() -> void:
	assert_true(Sequence.resumes_standing(&"free"))
	assert_true(Sequence.resumes_standing(&"fixed"))
	assert_false(Sequence.resumes_standing(&"knock"))
	assert_false(Sequence.resumes_standing(&"dark"))


func test_flat_variant() -> void:
	assert_eq(Sequence.flat_variant(1, &"", &""), {"mirror": false, "dark": false})
	assert_eq(Sequence.flat_variant(2, Sequence.NEIGHBOR, &"knock"), {"mirror": false, "dark": false},
			"el vecino llama en la casa normal")
	assert_eq(Sequence.flat_variant(2, Sequence.NEIGHBOR, &"free"), {"mirror": false, "dark": false})
	assert_eq(Sequence.flat_variant(2, &"", &""), {"mirror": true, "dark": false}, "la run 2 ya es en espejo")
	assert_eq(Sequence.flat_variant(3, Sequence.BLACKOUT, &"dark"), {"mirror": true, "dark": true})
	assert_eq(Sequence.flat_variant(3, Sequence.BLACKOUT, &"fixed"), {"mirror": true, "dark": false})
	assert_eq(Sequence.flat_variant(3, &"", &""), {"mirror": true, "dark": false}, "y lo sigue después")


func _run(seq: Sequence, seconds: float, step := &"knock") -> Array[StringName]:
	var all: Array[StringName] = []
	for i in int(seconds * 10.0):
		all.append_array(seq.tick(0.1, Sequence.NEIGHBOR, step))
	return all


func test_knock_then_stand() -> void:
	var seq := Sequence.new()
	assert_eq(_run(seq, 2.9), [] as Array[StringName], "nada antes de 3 s")
	assert_eq(_run(seq, 0.2), [&"knock"] as Array[StringName])
	assert_eq(_run(seq, 0.8), [] as Array[StringName], "un segundo de silencio")
	assert_eq(_run(seq, 0.2), [&"stand"] as Array[StringName])


func test_knocks_again_louder_until_door_opens() -> void:
	var seq := Sequence.new()
	var cues := _run(seq, 3.1 + 40.0 * 4)
	assert_eq(cues.count(&"knock"), 5)
	assert_eq(cues.count(&"stand"), 1, "solo se levanta una vez")
	assert_eq(Sequence.knock_boost_db(1), 0.0)
	assert_eq(Sequence.knock_boost_db(2), 2.0)
	assert_eq(Sequence.knock_boost_db(5), 6.0, "con tope")
	seq.door_opened()
	assert_eq(_run(seq, 100.0).count(&"knock"), 0, "con la puerta abierta no vuelven a llamar")


func test_no_cues_outside_knock() -> void:
	var seq := Sequence.new()
	assert_eq(_run(seq, 10.0, &"free"), [] as Array[StringName])


func test_game_does_not_advance_in_sequence() -> void:
	var s := Game.economy.state
	s.generators[&"antenna"] = 10
	Game.economy._recalc()
	s.sequence = Sequence.NEIGHBOR
	s.step = &"knock"
	Game.running = true
	var e0 := s.energy
	var t0 := s.play_time
	watch_signals(EventBus)
	for i in 50:
		Game.tick(0.1)
	assert_eq(s.energy, e0, "la tele no produce")
	assert_eq(s.play_time, t0)
	assert_eq(Game.click(), 0.0, "ni se clica")
	assert_signal_emitted_with_parameters(EventBus, "sequence_cue", [&"knock"], 0)


func test_sequence_done_advances_and_finishes() -> void:
	var s := Game.economy.state
	s.sequence = Sequence.NEIGHBOR
	s.step = &"knock"
	watch_signals(EventBus)
	Game.sequence_done(&"sat")
	assert_eq(s.step, &"knock")
	Game.sequence_done(&"handed_over")
	assert_eq(s.step, &"free")
	assert_true(Game.in_sequence())
	Game.sequence_done(&"sat")
	assert_false(Game.in_sequence())
	assert_eq(s.step, &"")
	assert_signal_emitted_with_parameters(EventBus, "sequence_cue", [&"finished"])
