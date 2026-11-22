class_name UserSettings
extends RefCounted

# Ajustes del jugador (pantalla, gráficos, sonido). Van en su propio archivo, aparte de la partida:
# user://settings.cfg (ConfigFile, con versión). Las claves nuevas tienen valor por defecto, así que un
# archivo anterior sigue valiendo sin cambiar de versión.

const VERSION := 1
const QUALITIES: Array[StringName] = [&"low", &"medium", &"high", &"ultra"]
const SECTION := "settings"
## 0 = sin límite.
const FPS_LIMITS: Array[int] = [0, 30, 60, 120, 144, 165, 240]
const COMMON_RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900),
		Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const BRIGHTNESS_MIN := 0.5
const BRIGHTNESS_MAX := 1.5
## Sensibilidad del ratón de pie, en rad por píxel: 10 pasos (specs/hito4a.md D10).
const SENSITIVITY_MIN := 0.0006
const SENSITIVITY_STEP := 0.0002
const SENSITIVITY_MAX := 0.0024

var quality: StringName = &"medium"
var fullscreen := false
## Resolución a la que se dibuja el 3D y, en ventana, tamaño de la ventana. (0, 0) = auto: decide el preset (en
## ventana, maximizada). No hay «escala 3D» aparte (usuario, 2026-11-22: la resolución elegida es la que se dibuja);
## un archivo antiguo con render_scale se lee sin ella.
var resolution := Vector2i.ZERO
var vsync := true
var max_fps := 0
## Multiplicador de la exposición (0,5–1,5).
var brightness := 1.0
var film_grain := true
## Volumen general, 0–1. Bajo por defecto: la primera vez no debe sonar fuerte.
var volume := 0.25
## Volumen del bus de la tele y del de la habitación, 0–1, sobre el general.
var volume_tv := 1.0
var volume_room := 1.0
## Intensidad del filtro CRT/VHS de la tele, 0–1 (0 = imagen limpia).
var crt := 1.0
var mouse_sensitivity := 0.0012


## Lee el archivo; si falta o es ilegible, devuelve los valores por defecto. Corrige valores fuera de rango.
static func load_from(path: String) -> UserSettings:
	var s := UserSettings.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK or int(cfg.get_value(SECTION, "version", 0)) != VERSION:
		return s
	var q := StringName(str(cfg.get_value(SECTION, "quality", s.quality)))
	s.quality = q if q in QUALITIES else s.quality
	s.fullscreen = cfg.get_value(SECTION, "fullscreen", s.fullscreen) == true
	var res: Variant = cfg.get_value(SECTION, "resolution", s.resolution)
	s.resolution = res if res is Vector2i and (res == Vector2i.ZERO or (res.x >= 640 and res.y >= 360)) else s.resolution
	s.vsync = cfg.get_value(SECTION, "vsync", s.vsync) != false
	var fps: Variant = cfg.get_value(SECTION, "max_fps", s.max_fps)
	s.max_fps = fps if fps is int and fps in FPS_LIMITS else s.max_fps
	s.brightness = clampf(_num(cfg.get_value(SECTION, "brightness", s.brightness), s.brightness), BRIGHTNESS_MIN, BRIGHTNESS_MAX)
	s.film_grain = cfg.get_value(SECTION, "film_grain", s.film_grain) != false
	s.volume = clampf(_num(cfg.get_value(SECTION, "volume", s.volume), s.volume), 0.0, 1.0)
	s.volume_tv = clampf(_num(cfg.get_value(SECTION, "volume_tv", s.volume_tv), s.volume_tv), 0.0, 1.0)
	s.volume_room = clampf(_num(cfg.get_value(SECTION, "volume_room", s.volume_room), s.volume_room), 0.0, 1.0)
	s.crt = clampf(_num(cfg.get_value(SECTION, "crt", s.crt), s.crt), 0.0, 1.0)
	s.mouse_sensitivity = clampf(_num(cfg.get_value(SECTION, "mouse_sensitivity", s.mouse_sensitivity), s.mouse_sensitivity),
			SENSITIVITY_MIN, SENSITIVITY_MAX)
	return s


func save_to(path: String) -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "version", VERSION)
	cfg.set_value(SECTION, "quality", String(quality))
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.set_value(SECTION, "resolution", resolution)
	cfg.set_value(SECTION, "vsync", vsync)
	cfg.set_value(SECTION, "max_fps", max_fps)
	cfg.set_value(SECTION, "brightness", brightness)
	cfg.set_value(SECTION, "film_grain", film_grain)
	cfg.set_value(SECTION, "volume", volume)
	cfg.set_value(SECTION, "volume_tv", volume_tv)
	cfg.set_value(SECTION, "volume_room", volume_room)
	cfg.set_value(SECTION, "crt", crt)
	cfg.set_value(SECTION, "mouse_sensitivity", mouse_sensitivity)
	return cfg.save(path) == OK


## Sensibilidad como paso de 1 a 10, para el menú.
func sensitivity_level() -> int:
	return roundi((mouse_sensitivity - SENSITIVITY_MIN) / SENSITIVITY_STEP) + 1


## Siguiente calidad en la lista (vuelve a la primera tras la última).
func next_quality(step: int = 1) -> void:
	quality = QUALITIES[posmod(QUALITIES.find(quality) + step, QUALITIES.size())]


## Resoluciones que caben en la pantalla, empezando por (0, 0) = auto; la de la pantalla siempre está.
static func resolution_options(screen: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [Vector2i.ZERO]
	for r in COMMON_RESOLUTIONS:
		if r.x <= screen.x and r.y <= screen.y:
			out.append(r)
	if screen.x > 0 and screen.y > 0 and screen not in out:
		out.append(screen)
	return out


## El siguiente valor de una lista, dando la vuelta; si el actual no está, empieza por el primero.
static func cycle(options: Array, current: Variant, step: int) -> Variant:
	var i := options.find(current)
	return options[0] if i < 0 else options[posmod(i + step, options.size())]


static func _num(v: Variant, fallback: float) -> float:
	return float(v) if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v)) else fallback
