shader_type canvas_item;
// Nieve de cambio de canal: ruido gris por píxel de la tele (320 × 240) que cambia 30 veces por segundo.
// Gris medio y sin blanco puro: es un cambio de imagen, no un destello.

uniform vec2 pixels = vec2(320.0, 240.0);
uniform float amount : hint_range(0.0, 1.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV * pixels);
	float t = floor(TIME * 30.0);
	float n = hash(px + t * 17.0);
	// Bandas horizontales que se desplazan, como una señal que no engancha.
	float band = 0.85 + 0.15 * sin(px.y * 0.35 + TIME * 40.0);
	COLOR = vec4(vec3(0.15 + 0.55 * n) * band, amount);
}
