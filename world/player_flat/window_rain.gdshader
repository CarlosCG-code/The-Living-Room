shader_type spatial;
// Cristal de la ventana con lluvia (look-dev ronda 2, usuario 2026-11-19), escrito desde cero: gotas quietas que
// crecen y se secan, y gotas que resbalan por columnas dejando un rastro mojado con gotitas. Cada gota es una
// lente: su forma da directamente cuánto se desvía lo que hay detrás (sin derivadas numéricas).
// Fuera de las gotas el cristal es casi transparente: así se ve la lluvia que cae por detrás.
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float scale = 4.0; // unidades de gota por metro
uniform float speed = 1.0;
uniform float refraction = 0.012; // desvío máximo, en fracción de pantalla
uniform vec4 tint : source_color = vec4(0.55, 0.6, 0.65, 0.07);

varying vec3 world_pos;

float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

// Gotas quietas: una posible por celda. xy = desvío (de -1 a 1 dentro de la gota), z = máscara.
vec3 beads(vec2 uv, float t) {
	vec2 g = uv * 14.0;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = rnd(id);
	vec2 c = (vec2(rnd(id + 3.7), rnd(id + 9.1)) - 0.5) * 0.6;
	float life = fract(t * 0.05 + h);
	float r = mix(0.08, 0.24, rnd(id + 5.3)) * smoothstep(0.0, 0.05, life) * smoothstep(1.0, 0.6, life);
	vec2 d = (f - c) / max(r, 0.001);
	float m = smoothstep(1.0, 0.8, length(d)) * step(0.4, h);
	return vec3(d * m, m);
}

// Gotas que resbalan: una por columna, con un serpenteo propio y un rastro por encima.
vec3 runner(vec2 uv, float t) {
	const float LEN = 2.0; // alto de cada tramo de columna, en unidades de uv
	float x = uv.x * 5.0;
	float id = floor(x);
	float s = rnd(vec2(id, 1.3));
	float wob = sin(uv.y * 3.0 + s * 20.0) * 0.12 + sin(uv.y * 7.3 + s * 5.0) * 0.05;
	float dx = fract(x) - 0.5 - (s - 0.5) * 0.4 - wob;
	float head = fract(t * mix(0.08, 0.25, rnd(vec2(id, 7.7))) + s);
	float dy = (fract(uv.y / LEN - head + 0.5) - 0.5) * LEN; // < 0 por encima de la gota
	vec2 d = vec2(dx / 0.13, dy / 0.18);
	float m = smoothstep(1.0, 0.75, length(d));
	float trail = step(dy, 0.0) * smoothstep(-0.9, 0.0, dy) * smoothstep(0.05, 0.0, abs(dx));
	vec2 bd = vec2(dx / 0.04, (fract(uv.y * 9.0) - 0.5) / 0.25);
	float bm = smoothstep(1.0, 0.6, length(bd)) * trail;
	return vec3(d * m + bd * bm * 0.5, max(m, max(bm, trail * 0.25)));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// La ventana está en un plano YZ (pared ±X): se usan z e y del mundo, así vale también en el espejo.
	vec2 uv = vec2(world_pos.z, -world_pos.y) * scale;
	float t = TIME * speed;
	vec3 a = beads(uv, t);
	vec3 b = runner(uv, t);
	vec3 c = runner(uv * 1.6 + 3.1, t * 1.1);
	vec2 offset = a.xy + b.xy + c.xy;
	float mask = clamp(max(a.z, max(b.z, c.z)), 0.0, 1.0);
	// Una gota invierte lo que hay detrás, como una lente: por eso se resta el desvío.
	vec3 behind = textureLod(screen_tex, SCREEN_UV - offset * refraction, 0.0).rgb;
	float rim = smoothstep(0.6, 1.0, length(offset)) * mask;
	vec3 drop_col = behind * 1.1 + vec3(0.04, 0.05, 0.06) * rim;
	ALBEDO = mix(tint.rgb, drop_col, mask);
	ALPHA = max(tint.a, mask * 0.95);
}
