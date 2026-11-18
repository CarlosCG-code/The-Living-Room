shader_type canvas_item;
// Cuantiza el mundo de la tele a la paleta fija (specs/incremental_v2.md §5): todo lo que se
// dibuja debajo (fondo, máquinas, nieve, niebla, viñeta) cae en ella. Lo que quita el aire «hecho por IA»:
// sin colores intermedios ni degradados suaves. El OSD y los menús van por encima y no se tocan.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

// Solo los colores del mundo: los verdes de fósforo y el rojo son del OSD y de los avisos, que van encima.
const int COUNT = 9;
const vec3 PALETTE[COUNT] = vec3[COUNT](
	vec3(0.020, 0.024, 0.043),  // 05060B
	vec3(0.043, 0.055, 0.086),  // 0B0E16
	vec3(0.082, 0.102, 0.141),  // 151A24
	vec3(0.137, 0.165, 0.212),  // 232A36
	vec3(0.227, 0.259, 0.314),  // 3A4250
	vec3(0.357, 0.388, 0.439),  // 5B6370
	vec3(0.541, 0.561, 0.588),  // 8A8F96
	vec3(0.878, 0.627, 0.282),  // E0A048 (único acento: la luz)
	vec3(0.478, 0.290, 0.118)   // 7A4A1E
);
// Se oscurece un poco antes de elegir color: la nieve cae en los grises medios, no en el más claro.
uniform float exposure = 0.8;
// Tramado 4 × 4 antes de elegir color: los degradados (viñeta, niebla) pasan a trama, no a anillos.
const mat4 BAYER = mat4(
	vec4(0.0, 8.0, 2.0, 10.0), vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0), vec4(15.0, 7.0, 13.0, 5.0)) / 16.0;
uniform float dither = 0.05;

void fragment() {
	vec3 src = texture(screen_tex, SCREEN_UV).rgb * exposure;
	ivec2 px = ivec2(FRAGCOORD.xy);
	src += (BAYER[px.x % 4][px.y % 4] - 0.5) * dither;
	vec3 best = PALETTE[0];
	float best_d = 1e9;
	for (int i = 0; i < COUNT; i++) {
		vec3 d = src - PALETTE[i];
		float dist = dot(d, d);
		if (dist < best_d) {
			best_d = dist;
			best = PALETTE[i];
		}
	}
	COLOR = vec4(mix(src, best, strength), 1.0);
}
