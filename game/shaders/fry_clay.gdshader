shader_type spatial;
render_mode cull_back, ambient_light_disabled, specular_disabled;

// Palette-preserving clay: violet fill plus four soft sun bands in one pass.
// Exclude blue sky irradiance; retain sun direction, shadows, dusk and fog.
// No textures, loops, emission, screen reads or outline.
uniform float glow = 0.0;
uniform float band_softness : hint_range(0.02, 0.2) = 0.12;
uniform float rim_strength : hint_range(0.0, 0.1) = 0.008;

vec3 linear_to_srgb(vec3 c) {
	return mix(12.92 * c, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

void vertex() {
	if (OUTPUT_IS_SRGB) {
		COLOR.rgb = linear_to_srgb(COLOR.rgb);
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * glow;
	ROUGHNESS = 0.92;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float bands = 0.30 * smoothstep(0.12 - band_softness, 0.12 + band_softness, ndl);
	bands += 0.34 * smoothstep(0.45 - band_softness, 0.45 + band_softness, ndl);
	bands += 0.36 * smoothstep(0.78 - band_softness, 0.78 + band_softness, ndl);
	float light_level = max(max(LIGHT_COLOR.r, LIGHT_COLOR.g), LIGHT_COLOR.b) / PI;
	vec3 sun_hue = LIGHT_COLOR / max(max(LIGHT_COLOR.r, LIGHT_COLOR.g), max(LIGHT_COLOR.b, 0.001));
	vec3 lit = vec3(1.00, 0.998, 0.991) * mix(vec3(1.0), sun_hue, 0.03);
	// At most 30% violet in the shadow illumination; no violet in lit paint.
	vec3 shadow = vec3(0.43) * mix(vec3(1.0), vec3(0.90, 0.82, 1.0), 0.30);
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = rim * rim * rim * rim * rim_strength * ndl * ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += (mix(shadow, lit, bands * ATTENUATION) + vec3(rim)) * (0.70 + 0.30 * clamp(light_level, 0.0, 1.0));
	} else {
		DIFFUSE_LIGHT += bands * ATTENUATION * LIGHT_COLOR * 0.12 / PI;
	}
}
