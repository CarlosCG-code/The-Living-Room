shader_type spatial;
// Pantalla de la tele: la imagen del SubViewport con emisión y una viñeta leve, sin curvar
// (la curvatura desviaría los clics; specs/hito2.md D5). Filtro sin suavizar: píxeles retro (D19).
render_mode unshaded, cull_back;

uniform sampler2D screen_tex : source_color, filter_nearest;
uniform float brightness = 1.3;
uniform float vignette = 0.35;

void fragment() {
	vec3 color = texture(screen_tex, UV).rgb;
	vec2 d = UV - vec2(0.5);
	float v = 1.0 - vignette * dot(d, d) * 4.0;
	ALBEDO = color * brightness * v;
}
