class_name TvFog
extends RefCounted

## Niebla baja de la tele (fog.gdshader): un rectángulo de 320 × 130 en la parte de abajo de la pantalla.
static func make(tint: Color = Color(0.62, 0.68, 0.82)) -> ColorRect:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 128
	tex.seamless = true
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://presentation/ui/fog.gdshader")
	mat.set_shader_parameter(&"noise", tex)
	mat.set_shader_parameter(&"tint", tint)
	var fog := ColorRect.new()
	fog.name = "Fog"
	fog.material = mat
	fog.position = Vector2(0, 110)
	fog.size = Vector2(320, 130)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return fog
