class_name UserSettings
extends RefCounted

# Ajustes del jugador (calidad, pantalla completa, volumen, filtro de la tele). Van en su propio
# archivo, aparte de la partida: user://settings.cfg (ConfigFile, con versión).

const VERSION := 1
const QUALITIES: Array[StringName] = [&"low", &"medium", &"high", &"ultra"]
const SECTION := "settings"

var quality: StringName = &"medium"
var fullscreen := false
## Volumen general, 0–1.
var volume := 0.8
## Intensidad del filtro CRT/VHS de la tele, 0–1 (0 = imagen limpia).
var crt := 1.0


## Lee el archivo; si falta o es ilegible, devuelve los valores por defecto. Corrige valores fuera de rango.
static func load_from(path: String) -> UserSettings:
	var s := UserSettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK or int(cfg.get_value(SECTION, "version", 0)) != VERSION:
		return s
	var q := StringName(str(cfg.get_value(SECTION, "quality", s.quality)))
	s.quality = q if q in QUALITIES else s.quality
	s.fullscreen = cfg.get_value(SECTION, "fullscreen", s.fullscreen) == true
	s.volume = clampf(_num(cfg.get_value(SECTION, "volume", s.volume), s.volume), 0.0, 1.0)
	s.crt = clampf(_num(cfg.get_value(SECTION, "crt", s.crt), s.crt), 0.0, 1.0)
	return s


func save_to(path: String) -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "version", VERSION)
	cfg.set_value(SECTION, "quality", String(quality))
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.set_value(SECTION, "volume", volume)
	cfg.set_value(SECTION, "crt", crt)
	return cfg.save(path) == OK


## Siguiente calidad en la lista (vuelve a la primera tras la última).
func next_quality(step: int = 1) -> void:
	quality = QUALITIES[posmod(QUALITIES.find(quality) + step, QUALITIES.size())]


static func _num(v: Variant, fallback: float) -> float:
	return float(v) if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v)) else fallback
