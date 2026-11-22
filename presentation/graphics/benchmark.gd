class_name Benchmark
extends Node

# Mide el rendimiento según specs/hito2.md D16: sin sincronización vertical ni límite de fps,
# en cada cámara descarta 5 s y mide 10 s; imprime una línea BENCH y cierra el juego.

const WARMUP := 5.0
const SAMPLE := 10.0

var label := ""
var cameras: Array[Camera3D] = []

var _index := 0
var _elapsed := 0.0
var _frames: PackedFloat32Array = []
var _gpu: PackedFloat32Array = []
var _vram_max := 0.0
var _objects := 0  # objetos dibujados en el último fotograma: en pantalla (lo que descarta la oclusión) y en sombras
var _draws := 0
var _results: PackedStringArray = []


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_start_camera()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < WARMUP:
		return
	_frames.append(delta * 1000.0)
	_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
	_vram_max = maxf(_vram_max, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
	if _elapsed >= WARMUP + SAMPLE:
		_objects = get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
		_draws = get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
		_finish_camera()


func _start_camera() -> void:
	cameras[_index].make_current()
	_elapsed = 0.0
	_frames.clear()
	_gpu.clear()


func _finish_camera() -> void:
	_results.append("%s:%.2f/%.2f/%.2f/%d/%d" % [cameras[_index].name, _avg(_frames), _p95(_frames), _p95(_gpu),
			_objects, _draws])
	_index += 1
	if _index < cameras.size():
		_start_camera()
		return
	var all_p95: Array[float] = []
	for r in _results:
		all_p95.append(float(r.split(":")[1].split("/")[1]))
	print("BENCH %s p95_ms_max=%.2f vram_mb=%.0f tex_mb=%.0f buf_mb=%.0f views=%s" % [label, all_p95.max(), _vram_max,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, " ".join(_results)])
	get_tree().quit()


static func _avg(values: PackedFloat32Array) -> float:
	var total := 0.0
	for v in values:
		total += v
	return total / maxf(values.size(), 1)


static func _p95(values: PackedFloat32Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[int(sorted.size() * 0.95)] if sorted.size() > 0 else 0.0
