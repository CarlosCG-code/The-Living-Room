shader_type spatial;
// Pantalla y cristal de la tele en un solo mesh opaco y con luz:
// - la imagen del SubViewport es emisión (con líneas de barrido, color corrido, grano y franja VHS);
// - el cristal es la superficie: el motor pone el Fresnel, el brillo de la lámpara y el reflejo de la sonda;
// - el abombado del cristal solo está en la normal: la malla es plana y los clics no cambian (D5).
// Imagen curvada como un tubo con la misma función que TvScreenMath.warp (los clics caen donde se ve).
// Muestreo «sharp bilinear»: píxeles nítidos a cualquier escala, sin escalera (D19).
render_mode cull_back;

uniform sampler2D screen_tex : source_color, filter_linear, repeat_disable;
uniform vec2 source_size = vec2(320.0, 240.0);
uniform vec2 warp = vec2(0.031, 0.041);  // = TvScreenMath.WARP (tv.gd lo pasa)
uniform float brightness = 1.15;
uniform float vignette = 0.35;
// 0 = imagen limpia; 1 = filtro completo. Ajuste de accesibilidad y de calidad.
uniform float crt = 1.0;
uniform float edge_shadow = 0.025;  // sombra del marco sobre la imagen, en fracción de pantalla
uniform vec2 screen_half_m = vec2(0.26, 0.195);
uniform float glass_radius_m = 1.0;  // radio de la cara del tubo (un 14" anda entre 0,8 y 1,5 m)
uniform vec3 glass_tint : source_color = vec3(0.05, 0.055, 0.06);
uniform float glass_roughness = 0.22;
// Fuerza del reflejo: 0,5 es vidrio real (F0 = 0,04); más bajo, el reflejo no lava la imagen.
uniform float glass_specular = 0.18;  // medido en capturas: más alto, la lámpara parecía un sol en el cielo

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Solo se interpola en el píxel de pantalla que cae en el borde de cada texel.
vec3 sharp(vec2 uv) {
	vec2 px = uv * source_size;
	vec2 seam = floor(px + 0.5);
	px = seam + clamp((px - seam) / max(fwidth(px), vec2(1e-5)), -0.5, 0.5);
	return texture(screen_tex, px / source_size).rgb;
}

vec2 barrel(vec2 uv) {
	vec2 c = uv * 2.0 - 1.0;
	c *= vec2(1.0 + c.y * c.y * warp.x, 1.0 + c.x * c.x * warp.y);
	return c * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = barrel(UV);
	vec2 c = UV * 2.0 - 1.0;
	vec2 texel = 1.0 / source_size;

	// Franja de tracking VHS: baja cada ~11 s y tuerce un poco las filas que pisa.
	float band_y = fract(TIME / 11.0) * 1.3 - 0.15;
	float band = smoothstep(0.06, 0.0, abs(uv.y - band_y)) * crt;
	float row = floor(uv.y * source_size.y);
	uv.x += band * (hash(vec2(row, floor(TIME * 12.0))) - 0.5) * texel.x * 3.0;

	// Color corrido: rojo y azul se separan menos de un píxel; se ve en los bordes.
	float shift = texel.x * 0.6 * crt;
	vec3 color = vec3(sharp(uv + vec2(shift, 0.0)).r, sharp(uv).g, sharp(uv - vec2(shift, 0.0)).b);

	// Líneas de barrido, una por fila de la imagen; por debajo de ~2 px por línea harían moiré y se apagan.
	float line_px = 1.0 / max(fwidth(uv.y) * source_size.y, 1e-5);
	float line = 0.5 + 0.5 * cos(fract(uv.y * source_size.y) * 6.2832);
	color *= mix(1.0, 0.72 + 0.28 * (1.0 - line), smoothstep(2.0, 3.5, line_px) * crt);

	// Grano: solo oscurece (si aclarara, los negros se volverían grises). Una celda por píxel de la imagen.
	float grain = hash(floor(uv * source_size) + floor(TIME * 24.0));
	color *= 1.0 - grain * 0.12 * crt;
	color += band * 0.04;

	// Fuera de la imagen curvada (esquinas), negro; y la sombra del marco hunde un poco los bordes.
	vec2 edge = min(uv, 1.0 - uv);
	float shadow = smoothstep(0.0, edge_shadow, min(edge.x, edge.y * 0.75));
	shadow *= step(0.0, min(edge.x, edge.y));
	float v = 1.0 - vignette * dot(c, c);
	EMISSION = max(color, vec3(0.0)) * brightness * v * shadow;

	// Cristal convexo: normal de una esfera de radio glass_radius_m.
	vec2 slope = c * screen_half_m / glass_radius_m;
	NORMAL_MAP = vec3(slope * vec2(0.5, -0.5) + 0.5, 1.0);
	ROUGHNESS = glass_roughness;
	SPECULAR = glass_specular;
	METALLIC = 0.0;
	ALBEDO = glass_tint;
}
