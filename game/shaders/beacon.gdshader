shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
// round 18: the light pillar over a fry: it fades out towards the sky and is brightest at its foot, so that a fry can be found from afar
uniform vec4 col : source_color = vec4(1.0, 0.9, 0.6, 1.0);
uniform float height = 60.0;
uniform float strength = 0.45;
varying float hh;
void vertex() {
	hh = clamp(VERTEX.y / height + 0.5, 0.0, 1.0);
}
void fragment() {
	float a = pow(1.0 - hh, 1.6) * strength;
	// soft edges: the cylinder is seen from every side, fade the silhouette
	float edge = abs(dot(normalize(NORMAL), normalize(VIEW)));
	a *= 0.35 + 0.65 * smoothstep(0.0, 0.6, edge);
	ALBEDO = col.rgb;
	ALPHA = a;
}
