shader_type spatial;
// Gentle stylised sea: animated swell, fresnel sky tint, faint foam.
uniform vec4 deep : source_color = vec4(0.07, 0.27, 0.36, 1.0);
uniform vec4 shallow : source_color = vec4(0.16, 0.50, 0.58, 1.0);
uniform vec4 sky_tint : source_color = vec4(0.55, 0.74, 0.9, 1.0);
varying vec3 wp;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = sin(w.x * 0.11 + TIME * 0.7) * 0.12 + sin(w.z * 0.09 + TIME * 0.55) * 0.12 + sin((w.x + w.z) * 0.2 + TIME * 1.1) * 0.05;
	VERTEX.y += h;
	wp = w;
}

void fragment() {
	float far = clamp(length(VERTEX) / 140.0, 0.0, 1.0);
	float amp = mix(1.0, 0.15, far);
	float nx = (cos(wp.x * 0.3 + TIME * 1.1) * 0.06 + cos((wp.x + wp.z) * 0.45 + TIME * 1.5) * 0.04) * amp;
	float nz = (cos(wp.z * 0.28 + TIME * 0.9) * 0.06 + cos((wp.z - wp.x) * 0.4 + TIME * 1.3) * 0.04) * amp;
	vec3 n = normalize(vec3(-nx, 1.0, -nz));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float mixv = 0.5 + 0.5 * sin(wp.x * 0.02 + wp.z * 0.015);
	vec3 col = mix(deep.rgb, shallow.rgb, 0.3 + 0.35 * mixv);
	col = mix(col, sky_tint.rgb, fres * 0.4);
	float foam = smoothstep(0.9, 0.99, sin(wp.x * 0.35 + TIME * 0.6) * sin(wp.z * 0.3 - TIME * 0.5) * 0.5 + 0.5) * amp;
	col += vec3(foam * 0.025);
	ALBEDO = col;
	ROUGHNESS = 0.12;
	METALLIC = 0.0;
	SPECULAR = 0.7;
	ALPHA = 0.92;
}
