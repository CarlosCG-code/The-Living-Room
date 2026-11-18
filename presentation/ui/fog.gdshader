shader_type canvas_item;
// Niebla baja de la tele: dos capas de ruido que se arrastran a distinto ritmo, recortadas a la
// rejilla de 320 × 240 y con la opacidad en escalones tramados (dither) para que siga siendo pixel art.

uniform sampler2D noise : repeat_enable, filter_nearest;
uniform vec4 tint : source_color = vec4(0.62, 0.68, 0.82, 1.0);
uniform float strength = 0.28;
uniform vec2 pixels = vec2(320.0, 130.0);  // tamaño del rectángulo en píxeles de la tele
uniform float speed = 0.03;

const mat4 BAYER = mat4(
	vec4(0.0, 8.0, 2.0, 10.0), vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0), vec4(15.0, 7.0, 13.0, 5.0)) / 16.0;

void fragment() {
	vec2 px = floor(UV * pixels);
	vec2 uv = px / pixels;
	float a = texture(noise, uv * vec2(1.0, 0.45) + vec2(TIME * speed, 0.0)).r;
	float b = texture(noise, uv * vec2(1.8, 0.8) + vec2(-TIME * speed * 0.6, 0.31)).r;
	float d = a * 0.65 + b * 0.35;
	// Más densa abajo, nada arriba: el borde superior se deshace.
	float body = smoothstep(0.0, 0.6, UV.y) * smoothstep(0.32, 0.68, d);
	float level = floor(body * 4.0) / 4.0;
	float threshold = BAYER[int(mod(px.x, 4.0))][int(mod(px.y, 4.0))];
	float alpha = level + step(threshold, fract(body * 4.0)) / 4.0;
	COLOR = vec4(tint.rgb, alpha * strength);
}
