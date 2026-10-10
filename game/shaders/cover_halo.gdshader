shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform float night = 0.0;
void vertex() {
	float sx=length(MODEL_MATRIX[0].xyz);
	float sy=length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0]*sx,INV_VIEW_MATRIX[1]*sy,INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment() {
	float r=length(UV-vec2(0.5))*2.0;
	float halo=pow(max(1.0-r,0.0),2.5);
	ALBEDO=vec3(1.0,0.58,0.22);
	ALPHA=halo*night*0.70;
}
