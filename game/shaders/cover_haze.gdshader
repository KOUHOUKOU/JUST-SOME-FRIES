shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec4 haze_color : source_color = vec4(0.65,0.73,0.83,1.0);
varying float distance_to_camera;
void vertex() { distance_to_camera=length((MODELVIEW_MATRIX*vec4(VERTEX,1.0)).xyz); }
void fragment() {
	float haze=smoothstep(260.0,1200.0,distance_to_camera);
	ALBEDO=mix(COLOR.rgb,haze_color.rgb,0.20+haze*0.38);
}
