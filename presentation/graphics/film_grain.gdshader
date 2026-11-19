shader_type canvas_item;

// Grano y viñeta de película sobre la imagen final (usuario, 2026-11-19: ambiente de Visage). Un solo pase barato.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain = 0.035;
uniform float vignette = 0.35;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	c *= 1.0 - vignette * smoothstep(0.35, 0.95, length((SCREEN_UV - 0.5) * vec2(1.25, 1.0)) * 1.45);
	float n = fract(sin(dot(FRAGCOORD.xy + floor(TIME * 24.0) * 37.0, vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(c + (n - 0.5) * grain, 1.0);
}
