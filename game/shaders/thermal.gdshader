shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
// Faint rising heat shimmer that marks a thermal (free lift).
void fragment() {
	float band = sin(UV.y * 26.0 - TIME * 2.4 + UV.x * 14.0) * 0.5 + 0.5;
	float fade = smoothstep(0.0, 0.2, UV.y) * smoothstep(0.0, 0.25, 1.0 - UV.y);
	ALBEDO = vec3(1.0, 0.96, 0.88);
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	ALPHA = band * fade * 0.05 * edge;
}
