extends SceneTree

# Dibuja el pixel art de la pantalla de la tele (specs/hito2.md D19) y lo guarda en assets/textures/tv/.
# Uso: "$GODOT" --headless --path . -s tools/build_tv_sprites.gd
# Paleta fría de 8 bits; cada letra es un color (ver PAL). Todo el arte es propio (sin assets de terceros).

const OUT := "res://assets/textures/tv/"
const PAL := {
	"k": "0b0e1a", "n": "1b2340", "b": "2d3a63", "c": "44558a",
	"w": "e8f0ff", "s": "a9bde0", "S": "7d92bd",
	"p": "16302f", "q": "2f5d50", "g": "4f8a6e",
	"r": "5a2e2e", "R": "8a4b3b", "T": "b06a4f",
	"y": "ffd36b", "o": "ff8a3d", "e": "e8433b",
	"m": "3a3f4f", "M": "6b7390", "l": "b6bfd6",
	"G": "6cf08a", "B": "4aa3ff", "d": "5e3f27", "D": "9a6b40",
}

var _img: Image


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save("background", _background())
	_save("factory", _factory())
	_save("receptor", _receptor())
	_save("antenna", _antenna())
	_save("valves", _valves())
	_save("audio_frequency", _audio())
	_save("tuner", _tuner())
	_save("remote", _remote())
	_save("channel_3", _channel_3())
	for id: String in ICONS:
		_save("icon_" + id, _ascii(ICONS[id]))
	print("SPRITES_OK")
	quit()


# --- Primitivas ---

func _new(w: int, h: int) -> Image:
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	return _img


func _c(key: String) -> Color:
	return Color.html(PAL[key])


func _px(x: int, y: int, key: String) -> void:
	if x >= 0 and y >= 0 and x < _img.get_width() and y < _img.get_height():
		_img.set_pixel(x, y, _c(key))


func _rect(x: int, y: int, w: int, h: int, key: String) -> void:
	for j in h:
		for i in w:
			_px(x + i, y + j, key)


func _frame(x: int, y: int, w: int, h: int, key: String) -> void:
	for i in w:
		_px(x + i, y, key)
		_px(x + i, y + h - 1, key)
	for j in h:
		_px(x, y + j, key)
		_px(x + w - 1, y + j, key)


# Tramado 2×2: mezcla dos colores en una franja.
func _dither(x: int, y: int, w: int, h: int, a: String, b: String) -> void:
	for j in h:
		for i in w:
			_px(x + i, y + j, a if (x + i + y + j) % 2 == 0 else b)


func _line(x0: int, y0: int, x1: int, y1: int, key: String) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	for t in steps + 1:
		var f := 0.0 if steps == 0 else float(t) / steps
		_px(roundi(lerpf(x0, x1, f)), roundi(lerpf(y0, y1, f)), key)


func _disc(cx: int, cy: int, r: int, key: String) -> void:
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			if i * i + j * j <= r * r + r:
				_px(cx + i, cy + j, key)


func _ascii(rows: Array) -> Image:
	_new(rows[0].length(), rows.size())
	for y in rows.size():
		for x in rows[y].length():
			var ch: String = rows[y][x]
			if ch != ".":
				_px(x, y, ch)
	return _img


func _save(name: String, img: Image) -> void:
	img.save_png(OUT + name + ".png")


# --- Fondo: bosque nevado de noche (320 × 240) ---

func _pine(cx: int, base: int, h: int) -> void:
	_rect(cx - 1, base - 4, 3, 5, "d")
	var tiers := maxi(2, h / 10)
	var tier_h := (h - 4) / tiers
	for t in tiers:
		var top := base - 4 - (t + 1) * tier_h - tier_h / 2
		var bottom := base - 4 - t * tier_h
		for y in range(top, bottom + 1):
			var half := int((y - top) * (2 + tiers - t) / 3.0) + 1
			for x in range(cx - half, cx + half + 1):
				_px(x, y, "g" if x < cx - half / 2 else ("q" if x < cx + half / 2 else "p"))
			if y - top < 2 or (y == bottom and (cx + y) % 3 != 0):
				_px(cx - half, y, "w")
				_px(cx + half, y, "s")
		for x in range(cx - (bottom - top) / 2, cx + (bottom - top) / 2, 2):
			_px(x, bottom - 1, "w")


func _background() -> Image:
	_new(320, 240)
	_rect(0, 0, 320, 40, "k")
	_dither(0, 40, 320, 20, "k", "n")
	_rect(0, 60, 320, 30, "n")
	_dither(0, 90, 320, 16, "n", "b")
	_rect(0, 106, 320, 30, "b")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		_px(rng.randi_range(0, 319), rng.randi_range(0, 95), "l" if i % 4 else "w")
	_disc(272, 26, 9, "w")
	_disc(275, 24, 9, "k")
	# Montañas lejanas con nieve en las cumbres.
	var peaks := [[0, 112], [40, 84], [90, 104], [140, 78], [200, 100], [250, 82], [300, 98], [330, 110]]
	for x in 320:
		var y := 120.0
		for k in peaks.size() - 1:
			if x >= peaks[k][0] and x <= peaks[k + 1][0]:
				y = lerpf(peaks[k][1], peaks[k + 1][1], float(x - peaks[k][0]) / (peaks[k + 1][0] - peaks[k][0]))
		for j in range(int(y), 136):
			_px(x, j, "c" if j < int(y) + 4 else "b")
		_px(x, int(y), "s")
	# Fila de pinos lejanos.
	for x in range(0, 320, 7):
		var h := 10 + (x * 13) % 9
		for j in h:
			var half := j / 3
			for i in range(-half, half + 1):
				_px(x + i, 128 - h + j, "p")
	# Suelo nevado.
	# Nieve de noche: azulada, con brillos sueltos y surcos más oscuros.
	_rect(0, 132, 320, 108, "s")
	_dither(0, 132, 320, 4, "S", "s")
	for i in 260:
		_px(rng.randi_range(0, 319), rng.randi_range(138, 239), "w")
	for j in range(150, 240, 18):
		for x in range(0, 320, 1):
			if (x * 7 + j) % 23 < 9:
				_px(x, j + int(2 * sin(x * 0.05)), "S")
	# Pinos cercanos en los bordes.
	for p in [[10, 150, 70], [34, 140, 52], [-4, 200, 90], [300, 150, 76], [282, 138, 50], [322, 205, 92], [56, 236, 40], [266, 236, 44]]:
		_pine(p[0], p[1], p[2])
	return _img


# --- Fábrica (56 × 50) ---

func _factory() -> Image:
	_new(56, 50)
	# Chimenea.
	_rect(40, 2, 8, 16, "r")
	_rect(41, 2, 3, 16, "R")
	_frame(40, 2, 8, 16, "k")
	_rect(39, 1, 10, 2, "w")
	# Tejado en diente de sierra con nieve.
	for t in 3:
		var x0 := 2 + t * 17
		for i in 17:
			var top := 16 - i * 8 / 17
			for y in range(top, 18):
				_px(x0 + i, y, "M" if i < 14 else "m")
			_px(x0 + i, top, "w")
			_px(x0 + i, top + 1, "s")
		_line(x0 + 16, 8, x0 + 16, 17, "k")
	# Cuerpo de ladrillo.
	_rect(2, 18, 52, 30, "R")
	for y in range(18, 48):
		if y % 4 == 0:
			for x in range(2, 54):
				_px(x, y, "r")
		else:
			for x in range(2 + (2 if (y / 4) % 2 else 0), 54, 6):
				_px(x, y, "r")
	_frame(1, 17, 54, 32, "k")
	# Ventanas iluminadas.
	for wx in [6, 22, 38]:
		_rect(wx, 22, 11, 8, "y")
		_rect(wx, 28, 11, 2, "o")
		_frame(wx - 1, 21, 13, 10, "k")
		_line(wx + 5, 22, wx + 5, 29, "k")
		_line(wx, 25, wx + 10, 25, "k")
	# Puerta.
	_rect(23, 34, 10, 14, "d")
	_rect(24, 35, 4, 12, "D")
	_frame(22, 33, 12, 16, "k")
	_px(30, 41, "y")
	# Nieve al pie.
	_dither(0, 47, 56, 3, "w", "s")
	return _img


# --- Máquinas ---

func _receptor() -> Image:
	_new(26, 24)
	_line(6, 0, 10, 9, "l")
	_line(19, 1, 15, 9, "l")
	_px(6, 0, "e")
	_px(19, 1, "e")
	_rect(1, 9, 24, 13, "d")
	_rect(2, 10, 22, 2, "D")
	_frame(0, 8, 26, 15, "k")
	for y in range(13, 20, 2):
		for x in range(3, 11, 2):
			_px(x, y, "k")
	_disc(18, 16, 4, "l")
	_disc(18, 16, 2, "M")
	_line(18, 16, 21, 13, "e")
	_rect(1, 22, 3, 2, "k")
	_rect(22, 22, 3, 2, "k")
	return _img


func _antenna() -> Image:
	_new(16, 36)
	_line(8, 3, 8, 33, "M")
	_line(9, 3, 9, 33, "l")
	for i in 4:
		var y := 7 + i * 5
		var half := 7 - i
		_line(8 - half, y, 9 + half, y, "l")
		_px(8 - half, y - 1, "w")
	_disc(8, 2, 1, "e")
	_rect(4, 33, 9, 3, "m")
	_rect(5, 33, 7, 1, "M")
	return _img


func _valves() -> Image:
	_new(22, 18)
	_rect(0, 12, 22, 6, "m")
	_rect(1, 12, 20, 1, "M")
	_frame(0, 11, 22, 7, "k")
	for i in 3:
		var x := 2 + i * 7
		_rect(x, 3, 5, 9, "n")
		_frame(x, 2, 5, 10, "l")
		_rect(x + 1, 6, 3, 4, "o")
		_px(x + 2, 5, "y")
		_px(x + 1, 3, "w")
	return _img


func _audio() -> Image:
	_new(20, 24)
	_rect(0, 0, 20, 24, "m")
	_rect(1, 1, 18, 1, "M")
	_frame(0, 0, 20, 24, "k")
	_rect(3, 3, 14, 9, "k")
	for x in range(4, 16):
		_px(x, 7 + roundi(2 * sin(x * 0.9)), "G")
	_disc(6, 17, 3, "k")
	_disc(14, 17, 3, "k")
	_px(6, 17, "M")
	_px(14, 17, "M")
	return _img


func _tuner() -> Image:
	_new(22, 18)
	_rect(0, 2, 22, 16, "d")
	_rect(1, 3, 20, 2, "D")
	_frame(0, 2, 22, 16, "k")
	_disc(7, 11, 4, "l")
	_disc(7, 11, 2, "M")
	_line(7, 11, 7, 8, "e")
	_rect(13, 7, 7, 4, "y")
	_frame(12, 6, 9, 6, "k")
	_px(16, 8, "e")
	_px(16, 9, "e")
	return _img


func _remote() -> Image:
	_new(10, 24)
	_rect(0, 0, 10, 24, "m")
	_rect(1, 1, 8, 1, "M")
	_frame(0, 0, 10, 24, "k")
	_rect(4, 2, 2, 2, "e")
	for r in 5:
		for c in 3:
			_px(2 + c * 3 - (1 if c == 2 else 0), 7 + r * 3, "l")
	return _img


func _channel_3() -> Image:
	_new(24, 56)
	for y in range(18, 56):
		var inset := (55 - y) * 5 / 38
		var key := "e" if (y / 6) % 2 == 0 else "w"
		_px(3 + inset, y, key)
		_px(20 - inset, y, key)
		if y % 6 == 0:
			_line(3 + inset, y, 20 - inset, y - 6, "l")
	_rect(2, 4, 20, 14, "k")
	_frame(2, 4, 20, 14, "l")
	_ascii_into(DIGIT_3, 9, 6, "e")
	_disc(12, 1, 1, "e")
	return _img


func _ascii_into(rows: Array, x0: int, y0: int, key: String) -> void:
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == "#":
				_px(x0 + x, y0 + y, key)


const DIGIT_3 := ["#####", "....#", "....#", ".###.", "....#", "....#", "....#", "#####", ".....", "....."]

# Iconos de 12 × 12 para el árbol de mejoras.
const ICONS := {
	"pulse": ["......yy....", ".....yy.....", "....yy......", "...yyyyyy...", "......yy....",
		".....yy.....", "....yy......", "...y........", "............", "............", "............", "............"],
	"pulse_strong": ["...yy..oo...", "..yy..oo....", ".yy..oo.....", "yyyyoooooo..", "..yy..oo....",
		".yy..oo.....", "yy..oo......", "y..o........", "............", "............", "............", "............"],
	"dial_hold": ["....ll......", "....ll.ll...", "....ll.ll.ll", ".ll.ll.ll.ll", ".llllllllll.",
		".llllllllll.", "..lllllllll.", "..llllllll..", "...llllll...", "...llllll...", "............", "............"],
	"resonance": ["............", "..G.........", ".G.G....G...", "G...G..G.G..", ".....G.G...G",
		"......G.....", "............", "....B.......", "...B.B..B...", "..B...BB.B..", "...........B", "............"],
	"dial_auto": ["....llll....", "..l.llll.l..", ".llllllllll.", "..lll..lll..", "lllll..lllll",
		"lllll..lllll", "..lll..lll..", ".llllllllll.", "..l.llll.l..", "....llll....", "............", "............"],
	"dial_auto_2": ["....yyyy....", "..y.yyyy.y..", ".yyyyyyyyyy.", "..yyy..yyy..", "yyyyy..yyyyy",
		"yyyyy..yyyyy", "..yyy..yyy..", ".yyyyyyyyyy.", "..y.yyyy.y..", "....yyyy....", "............", "............"],
	"antenna": ["....e.......", "...lll......", "..l.l.l.....", ".l..l..l....", "lllllllll...",
		"....l.......", "..lllll.....", "....l.......", "....l.......", "....l.......", "...mmm......", "..mmmmm....."],
	"valves": ["............", "..l..l..l...", ".lol.lol.lol", ".lyl.lyl.lyl", ".lol.lol.lol",
		".lol.lol.lol", ".lll.lll.lll", "mmmmmmmmmmmm", "mMMMMMMMMMMm", "mmmmmmmmmmmm", "............", "............"],
	"audio_frequency": ["mmmmmmmmmmm.", "mkkkkkkkkkm.", "mkG...G..km.", "mk.G.G.G.km.", "mk..G...Gkm.",
		"mkkkkkkkkkm.", "mm.......mm.", "m.kk...kk.m.", "m.kk...kk.m.", "mmmmmmmmmmm.", "............", "............"],
	"tuner": ["............", "dddddddddddd", "dDDDDDDDDDDd", "d.lll..kkkkd", "dlMMMl.kyykd",
		"dlMeMl.kyykd", "dlMMMl.kkkkd", "d.lll......d", "dddddddddddd", "............", "............", "............"],
	"remote": ["...mmmmm....", "...mmeem....", "...mmmmm....", "...ml.lm....", "...mmmmm....",
		"...ml.lm....", "...mmmmm....", "...ml.lm....", "...mmmmm....", "...ml.lm....", "...mmmmm....", "............"],
	"channel_3": ["....kkkk....", "....keek....", "....k.ek....", "....keek....", "....k.ek....",
		"....keek....", ".....ee.....", "....e..e....", "....w..w....", "...e....e...", "...w....w...", "..e......e.."],
}
