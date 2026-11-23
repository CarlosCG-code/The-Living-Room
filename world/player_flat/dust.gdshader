shader_type spatial;
// Mota de polvo (flat.tscn, Dust): disco suave que mira a la cámara, alumbrado igual desde cualquier lado.
render_mode blend_mix, depth_draw_never, cull_disabled, specular_disabled;

uniform vec4 tint : source_color = vec4(1.0);
// La luz que sale de la cámara (la linterna) apenas la ilumina: si no, se ven pelotas flotando (usuario, 2026-11-23).
uniform float from_camera = 0.3;
// La tele también: es mucho más fuerte que las lámparas y llenaba la pantalla de bolas. Se reconoce por venir de su sitio.
uniform vec3 tv_position;
uniform float from_tv = 0.1;

varying vec3 to_tv;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0]), INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1]),
			INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	to_tv = normalize((VIEW_MATRIX * vec4(tv_position, 1.0)).xyz - VERTEX);
	ALBEDO = tint.rgb;
	// De cerca se desvanece, para no tapar la vista.
	ALPHA = COLOR.a * (1.0 - smoothstep(0.0, 1.0, length(UV - 0.5) * 2.0)) * smoothstep(0.3, 0.9, length(VERTEX));
}

void light() {
	float camera_light = smoothstep(0.8, 0.95, dot(LIGHT, VIEW));
	float tv = dot(LIGHT, to_tv) > 0.9999 ? from_tv : 1.0;
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION / PI * mix(1.0, from_camera, camera_light) * tv;
}
