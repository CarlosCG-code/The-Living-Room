shader_type spatial;
// Cristal de PlanarMirror: la imagen de su cámara, dada la vuelta (es un espejo), con el azogue viejo algo
// oscuro y amarillento y velado en los bordes. Sin luz propia: la imagen ya viene iluminada.
render_mode unshaded, cull_back;

uniform sampler2D reflection : filter_linear, repeat_disable;  // HDR lineal (use_hdr_2d)
uniform bool active = false;

void fragment() {
	vec2 edge = min(UV, 1.0 - UV);
	float vignette = smoothstep(0.0, 0.12, min(edge.x, edge.y));
	vec3 img = active ? texture(reflection, vec2(1.0 - UV.x, UV.y)).rgb : vec3(0.02);
	ALBEDO = img * vec3(0.8, 0.77, 0.7) * mix(0.55, 1.0, vignette);
}
