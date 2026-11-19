shader_type spatial;
// Ciudad de noche vista desde un 8.º (D7): bloques de pisos en tres capas, con ventanas encendidas al azar
// (cálidas y alguna fría de tele), cielo con el naranja de las farolas de sodio y bruma de lluvia.
// Hecha aquí por código: sin imágenes externas.
render_mode unshaded, cull_disabled;

uniform float time_scale = 1.0;

float h11(float p) { return fract(sin(p * 127.1) * 43758.5453); }
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// Una capa de edificios: devuelve color (rgb) y si hay edificio (a).
vec4 layer(vec2 uv, float seed, float count, float h_min, float h_max, float bright) {
	float x = uv.x * count + seed * 13.0;
	float id = floor(x);
	float lx = fract(x);
	float height = mix(h_min, h_max, h11(id + seed));
	float gap = step(0.06, lx) * step(lx, 0.94);  // calle entre bloques
	if (uv.y > height || gap < 0.5) {
		return vec4(0.0);
	}
	// Ventanas: rejilla dentro del bloque.
	vec2 w = vec2(lx * 7.0, uv.y * count * 9.0);
	vec2 wid = floor(w) + vec2(id * 31.0, seed * 7.0);
	vec2 wf = fract(w);
	float win = step(0.25, wf.x) * step(wf.x, 0.75) * step(0.3, wf.y) * step(wf.y, 0.8);
	float lit = step(0.78, h21(wid));
	// Alguna ventana con la tele encendida: fría y parpadeante.
	float tv = step(0.985, h21(wid + 3.1));
	float flick = 0.7 + 0.3 * sin(TIME * time_scale * (6.0 + 9.0 * h21(wid)) + h21(wid) * 40.0);
	vec3 warm = mix(vec3(1.0, 0.62, 0.3), vec3(1.0, 0.85, 0.6), h21(wid + 1.7));
	vec3 col = vec3(0.012, 0.012, 0.016) + win * (lit * warm * bright + tv * vec3(0.4, 0.55, 1.0) * flick * bright);
	return vec4(col, 1.0);
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	// Cielo: oscuro arriba, naranja sucio abajo (contaminación lumínica de las farolas).
	vec3 sky = mix(vec3(0.09, 0.05, 0.035), vec3(0.012, 0.014, 0.022), smoothstep(0.1, 0.9, uv.y));
	vec3 col = sky;
	vec4 far = layer(uv, 3.0, 9.0, 0.35, 0.6, 0.35);
	col = mix(col, mix(far.rgb, sky, 0.45), far.a);  // lejos: más bruma
	vec4 mid = layer(uv, 7.0, 5.0, 0.25, 0.5, 0.7);
	col = mix(col, mix(mid.rgb, sky, 0.2), mid.a);
	vec4 near = layer(uv, 11.0, 2.5, 0.1, 0.3, 1.0);
	col = mix(col, near.rgb, near.a);
	ALBEDO = col;
}
