shader_type sky;
uniform vec4 zenith : source_color = vec4(0.28,0.53,0.78,1.0);
uniform vec4 middle : source_color = vec4(0.60,0.72,0.86,1.0);
uniform vec4 horizon : source_color = vec4(0.84,0.86,0.83,1.0);
uniform vec3 sun_direction = vec3(0.0,0.5,1.0);
uniform float dusk = 0.0;
uniform bool compatibility = true;
void sky() {
	float h = max(EYEDIR.y,0.0);
	vec3 col = mix(horizon.rgb,middle.rgb,smoothstep(0.0,0.23,h));
	col = mix(col,zenith.rgb,smoothstep(0.18,0.86,h));
	float facing = pow(max(dot(normalize(vec3(EYEDIR.x,0.04,EYEDIR.z)),normalize(vec3(sun_direction.x,0.04,sun_direction.z))),0.0),3.0);
	col = mix(col,vec3(1.0,0.64,0.35),facing * dusk * 0.16 * (1.0-smoothstep(0.0,0.38,h)));
	// Bounded Compatibility colour response, calibrated against the in-game cover review.
	COLOR=compatibility ? pow(max(col,vec3(0.0)),vec3(1.65)) : col;
}
