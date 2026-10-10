shader_type spatial;
render_mode cull_back, ambient_light_disabled, specular_disabled;

// S2 faceted paint: cool fill, warm directional bands and restrained warm rim.
// Exclude blue sky irradiance; retain sun direction, shadows, dusk and fog.
// No textures, loops, emission, screen reads or outline.
uniform float band_softness : hint_range(0.02, 0.2) = 0.12;
uniform float rim_strength : hint_range(0.0, 0.1) = 0.035;
// Only the gull material opts in. Scenery retains the original palette response.
uniform float plumage_fill : hint_range(0.0, 1.0) = 0.0;

vec3 linear_to_srgb(vec3 c) {
	return mix(12.92 * c, 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

void vertex() {
	if (OUTPUT_IS_SRGB) {
		COLOR.rgb = linear_to_srgb(COLOR.rgb);
	}
	// Only neutral gull wing paint; retain charcoal tips, eyes and cosmetic tints.
	float region=floor(UV.x*7.0+0.5);
	float neutral=1.0-smoothstep(0.08,0.20,max(COLOR.r,max(COLOR.g,COLOR.b))-min(COLOR.r,min(COLOR.g,COLOR.b)));
	float wing=step(2.5,region)*step(region,5.5)*smoothstep(.40,.62,min(COLOR.r,min(COLOR.g,COLOR.b)))*plumage_fill*neutral;
	COLOR.rgb=mix(COLOR.rgb,mix(COLOR.rgb,vec3(.91,.92,.96),.66),wing);
	// S3b pigment response. Preserve the approved gull's independent white response.
	vec3 pigment=pow(max(COLOR.rgb,vec3(0.0)),vec3(1.40));
	float value=dot(pigment,vec3(.2126,.7152,.0722));
	pigment=clamp(mix(vec3(value),pigment,1.20),vec3(0.0),vec3(1.0));
	float foliage=step(pigment.r*1.18,pigment.g)*step(pigment.b*1.35,pigment.g);
	pigment=mix(pigment,pigment*vec3(1.14,.91,.82),foliage);
	COLOR.rgb=mix(pigment,COLOR.rgb,plumage_fill);
}

void fragment() {
	ALBEDO = COLOR.rgb;
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
	vec3 lit = vec3(1.00, 0.998, 0.991) * mix(vec3(1.0), sun_hue, mix(0.24,0.10,plumage_fill));
	// At most 30% violet in the shadow illumination; no violet in lit paint.
	vec3 shadow = mix(vec3(0.25,0.31,0.47),vec3(0.43,0.46,0.62),plumage_fill);
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = rim * rim * rim * rim * rim_strength * ndl * ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		float white_mask = plumage_fill * smoothstep(0.87, 0.95, min(ALBEDO.r, min(ALBEDO.g, ALBEDO.b)));
		vec3 white_light = mix(vec3(0.79, 0.81, 0.90), lit, smoothstep(0.0, 0.8, ndl) * ATTENUATION);
		DIFFUSE_LIGHT += (mix(mix(shadow, lit, bands * ATTENUATION), white_light, white_mask) + vec3(1.0,0.79,0.49)*rim) * (0.70 + 0.30 * clamp(light_level, 0.0, 1.0));
	} else {
		DIFFUSE_LIGHT += bands * ATTENUATION * LIGHT_COLOR * 0.12 / PI;
	}
}
