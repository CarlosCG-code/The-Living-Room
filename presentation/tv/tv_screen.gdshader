shader_type spatial;
// Pantalla de la tele: la imagen del SubViewport con emisión, viñeta y un filtro CRT/VHS barato
// (líneas de barrido, color corrido, grano y una franja de tracking que baja despacio). Sin curvar:
// la curvatura desviaría los clics (specs/hito2.md D5). Filtro sin suavizar: píxeles retro (D19).
render_mode unshaded, cull_back;

uniform sampler2D screen_tex : source_color, filter_nearest;
uniform float brightness = 1.3;
uniform float vignette = 0.35;
// 0 = imagen limpia; 1 = filtro completo. Ajuste de accesibilidad y de calidad.
uniform float crt = 1.0;
uniform vec2 source_size = vec2(320.0, 240.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 texel = 1.0 / source_size;

	// Franja de tracking VHS: baja cada ~11 s y tuerce un poco las filas que pisa.
	float band_y = fract(TIME / 11.0) * 1.3 - 0.15;
	float band = smoothstep(0.06, 0.0, abs(uv.y - band_y)) * crt;
	float row = floor(uv.y * source_size.y);
	uv.x += band * (hash(vec2(row, floor(TIME * 12.0))) - 0.5) * texel.x * 3.0;

	// Color corrido: rojo y azul se separan menos de un píxel; se ve en los bordes.
	float shift = texel.x * 0.6 * crt;
	vec3 color = vec3(
		texture(screen_tex, uv + vec2(shift, 0.0)).r,
		texture(screen_tex, uv).g,
		texture(screen_tex, uv - vec2(shift, 0.0)).b);

	// Líneas de barrido: una por fila de la imagen de 320 × 240.
	float line = 0.5 + 0.5 * cos(fract(UV.y * source_size.y) * 6.2832);
	color *= mix(1.0, 0.72 + 0.28 * (1.0 - line), crt);

	// Grano que cambia 24 veces por segundo y la franja un poco más clara.
	float grain = hash(floor(UV * source_size * 2.0) + floor(TIME * 24.0)) - 0.5;
	color += (grain * 0.05 + band * 0.06) * crt;

	vec2 d = UV - vec2(0.5);
	float v = 1.0 - vignette * dot(d, d) * 4.0;
	ALBEDO = max(color, vec3(0.0)) * brightness * v;
}
